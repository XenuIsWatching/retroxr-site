# rendezvous

The server behind **Host Online** in RetroXR. It hands out six-character room
codes and helps two players punch a hole to each other. It carries **no game
traffic** — once the two peers can see each other, this box is out of the
conversation and the session is peer to peer.

It lives in this repo rather than the game repo for two reasons: the game is
GPL-3.0 and this is not, so nothing may be pasted across; and Astro only reads
`src/` and `public/`, so nothing here can break the site build.

## What is in here

| File | |
|---|---|
| `registry.mjs` | The room-code registry. Node, no dependencies, one `Map`, no database. |
| `registry.test.mjs` | Self-test over a real loopback server. Exits non-zero. |
| `docker-compose.yml` | registry + noray + Caddy. |
| `Caddyfile` | TLS for the registry only. |

```sh
node server/registry.test.mjs     # 25 cases, no network beyond loopback
```

## The API

| | | | |
|---|---|---|---|
| `GET` | `/v1/punch` | — | `{punch_host, punch_port}` |
| `POST` | `/v1/rooms` | `{oid, name, protocol_version}` | `{code, secret, ttl, punch_host, punch_port}` |
| `POST` | `/v1/rooms/{code}/heartbeat` | `Authorization: Bearer <secret>` | `{ok, ttl}` |
| `DELETE` | `/v1/rooms/{code}` | `Authorization: Bearer <secret>` | `204` |
| `GET` | `/v1/rooms/{code}` | — | `{oid, name, protocol_version, punch_host, punch_port}` |

Three things about that table are load-bearing:

- **`GET /v1/punch` exists to break a deadlock.** A room is created with an OID,
  an OID only exists after punching, and where to punch is something only this
  server knows. Asking first is what keeps the punch endpoint out of the client,
  which is the entire reason it is returned rather than hardcoded — it can move,
  or be replaced, without anybody shipping a build.
- **A wrong secret and a room that never existed both answer `404`.** The
  heartbeat is otherwise the one call that would let somebody sweep for live
  codes.
- **`protocol_version` is stored and returned** so a joiner is turned away with
  a readable sentence *before* ENet is touched, rather than by a handshake
  rejection from a peer they never see.

## Deploying

**Give it its own workflow.** `deploy.yml` publishes the site on every push to
`main`; a devlog post must not redeploy the rendezvous. Deploy this by hand or
from a `workflow_dispatch`:

```sh
ssh <vm> 'cd retroxr-site/server && git pull && docker compose up -d --build'
```

### Live

Deployed 2026-08-25. `docker compose ps` should show three containers.

| | |
|---|---|
| Project | `retroxr-rendezvous` |
| Instance | `rendezvous`, `us-west1-b`, `e2-micro`, Debian 12 |
| Address | `35.212.202.202` (ephemeral - see below) |
| Network tier | STANDARD |

```sh
gcloud compute ssh rendezvous --zone=us-west1-b --project=retroxr-rendezvous
gcloud compute instances delete rendezvous --zone=us-west1-b --project=retroxr-rendezvous
```

**The external address is ephemeral.** It survives a reboot but not a stop, and
both DNS records point at it by literal IP. If the instance is ever stopped,
either promote the address to static before starting it again or update `net`
and `punch` afterwards - a stale `punch` record is the worse of the two, because
the registry keeps handing out an endpoint that answers nothing.

### The VM

A Google Cloud `e2-micro` in `us-west1`, `us-central1` or `us-east1` is free
forever, and the workload is tiny — a few KB per join, no persistent storage.

**Set the network service tier to Standard.** It includes 200 GB/month of free
egress; the Premium default includes 1 GiB and will bill you for the rest. This
is the single most expensive setting on the page.

US-only adds 80–150 ms to *signalling* for players elsewhere, which does not
matter: game traffic is direct peer to peer and never touches this machine.

### DNS

Two records, and the difference between them matters:

| Record | Purpose | Cloudflare |
|---|---|---|
| `net.retroxr.app` | HTTPS registry, via Caddy | grey cloud to start; orange later needs SSL/TLS **Full** |
| `punch.retroxr.app` | noray, UDP 8809 + TCP 8890 | **grey cloud, mandatory** |

- **`punch.` can never be proxied.** Cloudflare does not carry UDP, and the
  punch is UDP. The IP of this box is therefore public either way, which is
  acceptable at this scale.
- **Start `net.` grey too**, or Caddy cannot complete the HTTP-01 challenge and
  the certificate never arrives. This is the same trap the site README already
  documents for the apex record.
- **HTTPS is not optional.** The game targets Android `target_sdk=32`, which
  blocks cleartext by default, and no network-security-config ships with it.

### Firewall

`tcp:80,443` for Caddy, `tcp:8890` and `udp:8809` for noray.

## What is deliberately not here

**Relay.** noray implements it and it is one command away, but a relayed session
spends this server's bandwidth instead of the bandwidth of the two players:
roughly 0.9 GB/hour for a pair, against a 200 GB/month free allowance. That is
about seven hours a day of one session — fine for testing, not for a public
release. The client never asks for it and ignores an unrequested offer.

If relay is ever wanted, the honest move is a Hetzner CX22 at about €4/month
with 20 TB of traffic, not a bigger free tier.

**Accounts, lobbies, a room list.** A code is told to somebody directly. There is
nothing to browse, so there is nothing to moderate.

**Logs.** This server necessarily sees which addresses are playing with which.
It has no reason to remember that, and does not. The privacy policy should still
say that it sees them.

## The thing this cannot do

Punchthrough connects roughly 70–90% of pairs. Symmetric NAT and carrier CGNAT —
a mobile hotspot, some fibre ISPs — cannot be punched at all, by anyone, and no
amount of work on this server changes that. The client says so plainly and keeps
LAN play as the way out. A green test on one network proves nothing about this;
only two genuinely separate networks do.
