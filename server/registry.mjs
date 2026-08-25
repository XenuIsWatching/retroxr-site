// RetroXR room-code registry.
//
// Small on purpose. A room is a host that has punched a hole and wants other
// people to be able to find it; a code is the six characters somebody reads out
// over voice chat. Nothing here carries game traffic - the moment two peers can
// see each other, this server is out of the conversation.
//
// State is one Map with a TTL. There is deliberately no database: everything in
// here is worthless thirty seconds after the host stops asking for it, and a
// restart losing every room only costs each host one keypress.
//
// Written fresh for this repo. Do not paste code in from the game repository:
// that is GPL-3.0 and this is not.

import { createServer } from "node:http";
import { randomBytes, randomInt } from "node:crypto";

const PORT = Number(process.env.PORT || 8080);

// Where clients are told to punch. Sent in every room response so the client
// never hardcodes it, which is what lets this move without anyone shipping a
// build.
const PUNCH_HOST = process.env.PUNCH_HOST || "punch.retroxr.app";
const PUNCH_PORT = Number(process.env.PUNCH_PORT || 8890);

// Seconds a room survives without a heartbeat. Long enough to ride out a bad
// minute of wifi, short enough that a crashed host stops being advertised
// before anyone reads its code out.
const TTL = Number(process.env.ROOM_TTL || 90);

// No I, L, O, U, 0 or 1 - the pairs that go wrong when a code is spoken aloud
// or read off a panel in a headset. Both halves of each pair are gone, so there
// is never a "did you mean" to guess at.
const ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789";
const CODE_LENGTH = 6;

// Caps. This runs on a free-tier machine and the whole service is unauthenticated,
// so the limits are what stands between it and one bored person.
const MAX_ROOMS = Number(process.env.MAX_ROOMS || 500);
const MAX_ROOMS_PER_IP = Number(process.env.MAX_ROOMS_PER_IP || 5);
const CREATE_PER_MINUTE = Number(process.env.CREATE_PER_MINUTE || 12);
const MAX_BODY = 4096;

/** code -> {oid, name, protocolVersion, secret, ip, expiresAt} */
const rooms = new Map();
/** ip -> number[] of recent creation timestamps */
const recentCreates = new Map();

const now = () => Date.now();

function makeCode() {
  // randomInt, not Math.random. Codes are the only thing keeping one session
  // separate from another, and a predictable sequence would let somebody walk
  // into rooms.
  let out = "";
  for (let i = 0; i < CODE_LENGTH; i++) out += ALPHABET[randomInt(ALPHABET.length)];
  return out;
}

function freshCode() {
  // The space is 729 million and live rooms number in the tens, so a collision
  // is a curiosity rather than a case - but an unchecked one would hand two
  // hosts the same code and send joiners to whichever answered last.
  for (let attempt = 0; attempt < 12; attempt++) {
    const code = makeCode();
    if (!rooms.has(code)) return code;
  }
  return null;
}

function sweep() {
  const t = now();
  for (const [code, room] of rooms) if (room.expiresAt <= t) rooms.delete(code);
  for (const [ip, stamps] of recentCreates) {
    const kept = stamps.filter((s) => t - s < 60_000);
    if (kept.length) recentCreates.set(ip, kept);
    else recentCreates.delete(ip);
  }
}
setInterval(sweep, 10_000).unref?.();

function clientIp(req) {
  // Behind Caddy, so the socket address is always the proxy. Only the last hop
  // of the header can be trusted, and only because we know what put it there.
  const fwd = req.headers["x-forwarded-for"];
  if (typeof fwd === "string" && fwd.length) return fwd.split(",").pop().trim();
  return req.socket.remoteAddress || "unknown";
}

function send(res, status, body) {
  const payload = body === undefined ? "" : JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json",
    "content-length": Buffer.byteLength(payload),
    "cache-control": "no-store",
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on("data", (c) => {
      size += c.length;
      // An unbounded body on an unauthenticated endpoint is a way to spend all
      // the memory on the box.
      if (size > MAX_BODY) {
        reject(new Error("body too large"));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

function punch() {
  return { punch_host: PUNCH_HOST, punch_port: PUNCH_PORT };
}

function bearer(req) {
  const auth = req.headers.authorization;
  if (typeof auth !== "string" || !auth.startsWith("Bearer ")) return "";
  return auth.slice(7);
}

/** Constant time, so the secret cannot be recovered a character at a time. */
function secretMatches(given, expected) {
  if (given.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < given.length; i++) diff |= given.charCodeAt(i) ^ expected.charCodeAt(i);
  return diff === 0;
}

async function createRoom(req, res) {
  const ip = clientIp(req);
  const stamps = (recentCreates.get(ip) || []).filter((s) => now() - s < 60_000);
  if (stamps.length >= CREATE_PER_MINUTE) return send(res, 429, { error: "slow down" });
  if (rooms.size >= MAX_ROOMS) return send(res, 503, { error: "too many rooms" });

  let mine = 0;
  for (const room of rooms.values()) if (room.ip === ip) mine++;
  if (mine >= MAX_ROOMS_PER_IP) return send(res, 429, { error: "too many rooms from here" });

  let body;
  try {
    body = JSON.parse(await readBody(req));
  } catch {
    return send(res, 400, { error: "bad request" });
  }
  if (!body || typeof body !== "object") return send(res, 400, { error: "bad request" });

  const oid = String(body.oid || "");
  // The oid comes from noray and is what a joiner is sent to punch towards. An
  // empty one would make a room that resolves to nobody.
  if (!oid || oid.length > 128) return send(res, 400, { error: "bad oid" });

  const protocolVersion = Number.isInteger(body.protocol_version) ? body.protocol_version : -1;
  if (protocolVersion < 0) return send(res, 400, { error: "bad protocol_version" });

  const code = freshCode();
  if (!code) return send(res, 503, { error: "no codes available" });

  // randomBytes rather than a couple of randomInts: this is the only thing
  // standing between a stranger and closing somebody else's room, and randomInt
  // caps below 2^48 anyway.
  const secret = randomBytes(24).toString("base64url");
  rooms.set(code, {
    oid,
    name: String(body.name || "").slice(0, 32),
    protocolVersion,
    secret,
    ip,
    expiresAt: now() + TTL * 1000,
  });
  stamps.push(now());
  recentCreates.set(ip, stamps);

  return send(res, 200, { code, secret, ttl: TTL, ...punch() });
}

function heartbeat(req, res, code) {
  const room = rooms.get(code);
  // Deliberately the same answer as a code that never existed: a heartbeat is
  // the one call an attacker could use to find out which codes are live.
  if (!room || !secretMatches(bearer(req), room.secret)) {
    return send(res, 404, { error: "no such room" });
  }
  room.expiresAt = now() + TTL * 1000;
  return send(res, 200, { ok: true, ttl: TTL });
}

function closeRoom(req, res, code) {
  const room = rooms.get(code);
  if (!room || !secretMatches(bearer(req), room.secret)) {
    return send(res, 404, { error: "no such room" });
  }
  rooms.delete(code);
  res.writeHead(204);
  return res.end();
}

function lookup(res, code) {
  const room = rooms.get(code);
  if (!room || room.expiresAt <= now()) return send(res, 404, { error: "no such room" });
  // Never the secret. It goes out once, to whoever created the room.
  return send(res, 200, {
    oid: room.oid,
    name: room.name,
    protocol_version: room.protocolVersion,
    ...punch(),
  });
}

const CODE_RE = new RegExp(`^[${ALPHABET}]{${CODE_LENGTH}}$`);

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url, "http://localhost");
    const path = url.pathname;

    if (req.method === "GET" && path === "/v1/health") return send(res, 200, { ok: true, rooms: rooms.size });
    if (req.method === "GET" && path === "/v1/punch") return send(res, 200, punch());
    if (req.method === "POST" && path === "/v1/rooms") return await createRoom(req, res);

    const m = path.match(/^\/v1\/rooms\/([^/]+)(\/heartbeat)?$/);
    if (m) {
      // Upper-cased before matching, because a player types a code and a
      // player types in whatever case they like.
      const code = decodeURIComponent(m[1]).toUpperCase();
      if (!CODE_RE.test(code)) return send(res, 404, { error: "no such room" });
      if (m[2]) {
        if (req.method === "POST") return heartbeat(req, res, code);
      } else if (req.method === "GET") {
        return lookup(res, code);
      } else if (req.method === "DELETE") {
        return closeRoom(req, res, code);
      }
      return send(res, 405, { error: "method not allowed" });
    }

    return send(res, 404, { error: "not found" });
  } catch (err) {
    // Nothing about the request is logged: this server sees who is playing with
    // whom, and it has no reason to remember it.
    console.error("[registry]", err?.message || err);
    if (!res.headersSent) send(res, 500, { error: "server error" });
  }
});

server.listen(PORT, () => {
  console.log(`[registry] listening on ${PORT}, punch at ${PUNCH_HOST}:${PUNCH_PORT}, ttl ${TTL}s`);
});
