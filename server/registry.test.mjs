// Self-test for the room registry. Starts a real server on a loopback port and
// talks to it over HTTP, so what is exercised is the routing and the guards
// rather than a set of functions called directly.
//
//   node server/registry.test.mjs
//
// Exits non-zero on the first failure, so it can gate a deploy.

import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { setTimeout as sleep } from "node:timers/promises";

const PORT = 8791;
const BASE = `http://127.0.0.1:${PORT}/v1`;

let failures = 0;
let ran = 0;

function ok(cond, what) {
  ran++;
  if (cond) console.log(`[test] ok   ${what}`);
  else {
    failures++;
    console.log(`[test] FAIL ${what}`);
  }
}

function eq(got, want, what) {
  ran++;
  if (got === want) console.log(`[test] ok   ${what}`);
  else {
    failures++;
    console.log(`[test] FAIL ${what} - got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);
  }
}

const child = spawn(process.execPath, [fileURLToPath(new URL("registry.mjs", import.meta.url))], {
  env: { ...process.env, PORT: String(PORT), ROOM_TTL: "2", CREATE_PER_MINUTE: "4" },
  stdio: ["ignore", "pipe", "inherit"],
});

async function req(method, path, { body, secret } = {}) {
  const headers = {};
  if (body !== undefined) headers["content-type"] = "application/json";
  if (secret) headers.authorization = `Bearer ${secret}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  let json = null;
  try {
    json = await res.json();
  } catch {
    json = null;
  }
  return { status: res.status, json };
}

try {
  for (let i = 0; i < 50; i++) {
    try {
      await req("GET", "/health");
      break;
    } catch {
      await sleep(100);
    }
  }

  const made = await req("POST", "/rooms", { body: { oid: "abc123", name: "Ryan", protocol_version: 12 } });
  eq(made.status, 200, "a room can be created");
  ok(/^[ABCDEFGHJKMNPQRSTVWXYZ23456789]{6}$/.test(made.json.code), "the code is six symbols of the alphabet");
  ok(!!made.json.secret, "and comes with a secret");
  eq(made.json.punch_host, "punch.retroxr.app", "and says where to punch");
  const { code, secret } = made.json;

  const found = await req("GET", `/rooms/${code}`);
  eq(found.status, 200, "the code resolves");
  eq(found.json.oid, "abc123", "to the host oid");
  eq(found.json.protocol_version, 12, "carrying the protocol version");
  eq(found.json.secret, undefined, "and never the secret");

  eq((await req("GET", `/rooms/${code.toLowerCase()}`)).status, 200,
    "a lower-case code resolves too, because a player types one");
  eq((await req("GET", "/rooms/ZZZZZZ")).status, 404, "an unknown code is not found");
  eq((await req("GET", "/rooms/K7MPQ0")).status, 404, "nor is one holding a confusable");
  eq((await req("GET", "/rooms/TOOLONG1")).status, 404, "nor one of the wrong length");

  eq((await req("POST", `/rooms/${code}/heartbeat`, { secret })).status, 200, "the owner can renew");
  eq((await req("POST", `/rooms/${code}/heartbeat`, { secret: "wrong" })).status, 404,
    "a wrong secret is refused, and looks exactly like a room that never was");
  eq((await req("POST", `/rooms/${code}/heartbeat`)).status, 404, "so does no secret at all");
  eq((await req("DELETE", `/rooms/${code}`, { secret: "wrong" })).status, 404,
    "and a wrong secret cannot delete somebody else's room");

  eq((await req("POST", "/rooms", { body: { name: "no oid", protocol_version: 12 } })).status, 400,
    "a room with no oid is refused");
  eq((await req("POST", "/rooms", { body: { oid: "x" } })).status, 400,
    "so is one with no protocol version");

  const punch = await req("GET", "/punch");
  eq(punch.status, 200, "the punch endpoint can be asked for before there is a room");
  eq(punch.json.punch_port, 8890, "and gives the port");

  eq((await req("DELETE", `/rooms/${code}`, { secret })).status, 204, "the owner can close the room");
  eq((await req("GET", `/rooms/${code}`)).status, 404, "and it is gone");

  // TTL is 2s in this run.
  const doomed = await req("POST", "/rooms", { body: { oid: "ttl", protocol_version: 12 } });
  eq((await req("GET", `/rooms/${doomed.json.code}`)).status, 200, "a new room is alive");
  await sleep(2600);
  eq((await req("GET", `/rooms/${doomed.json.code}`)).status, 404,
    "and expires when nothing renews it");

  // CREATE_PER_MINUTE is 4 in this run; three have been made already.
  let limited = false;
  for (let i = 0; i < 6; i++) {
    const r = await req("POST", "/rooms", { body: { oid: `flood${i}`, protocol_version: 12 } });
    if (r.status === 429) limited = true;
  }
  ok(limited, "creating rooms in a loop is rate limited");

  console.log(`[test] ${ran} cases, ${failures === 0 ? "PASS" : `${failures} FAILURE(S)`}`);
} finally {
  child.kill();
}

process.exit(failures === 0 ? 0 : 1);
