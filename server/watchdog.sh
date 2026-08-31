#!/usr/bin/env bash
# Put the punch server back when it wedges.
#
# noray's Bun runtime segfaults (kernel: traps: bun[...] general protection
# fault) and `restart: unless-stopped` brings it back within seconds in a state
# where it accepts TCP, parses register-host, logs the registration, and never
# writes set-oid. Docker sees a running container, the registry half stays
# perfectly healthy, and the outage lasts until somebody presses Host Online:
# the Aug 28 2026 crash went unnoticed for three days.
#
# So the auto-restart is what turns a two-second crash into a multi-day outage,
# and this exists to close that window rather than to prevent the crash.
#
# Two things here are load-bearing:
#
# The check speaks the protocol. A port knock cannot work - noray accepted
# connections throughout every outage so far - and neither can `docker compose
# ps`, which reported `Up 3 days` while the server was dead.
#
# The repair is `down` then `up`, never `restart`. noray binds 2049 relay ports;
# a restart may leave them in a state it cannot cleanly re-acquire, which is how
# it comes back half-alive in the first place.
set -uo pipefail

# Serialise against a deploy, which also takes this lock. Without it the two
# race: a deploy's `down` makes the probe fail, the watchdog calls that an
# outage and starts its own `down`/`up` into the middle of the deploy, and both
# fail on a container-name conflict. Seen on the first install, 2026-08-31.
# Non-blocking on purpose - if a deploy holds the lock the server is being
# attended to, and the next tick is a minute away.
LOCK="${LOCK:-/var/lock/rendezvous-deploy.lock}"
exec {lockfd}>"$LOCK" || exit 0
if ! flock -n "$lockfd"; then
	echo "a deploy holds the lock; skipping this tick"
	exit 0
fi

COMPOSE_DIR="${COMPOSE_DIR:-/home/ryanmcclelland/rendezvous}"
PORT="${PORT:-8890}"
STAMP="${STAMP:-/var/lib/rendezvous-watchdog/last-repair}"
# A repair takes the server down for a few seconds. Repairing on every tick
# would turn a noray that cannot start at all into a permanent outage with the
# door swinging, so a failed repair is left alone until a human looks.
COOLDOWN="${COOLDOWN:-900}"

log() { logger -t rendezvous-watchdog -- "$*"; echo "$*"; }

# Returns 0 only on a set-oid reply. Anything else - refused, silent, garbage -
# is a failure, because anything else is a punch server no player can use.
probe() {
	python3 - "$PORT" <<'PY'
import socket, sys
try:
	s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), 5)
	s.sendall(b"register-host\n")
	s.settimeout(8)
	sys.exit(0 if b"set-oid" in s.recv(4096) else 1)
except Exception:
	sys.exit(1)
PY
}

if probe; then
	exit 0
fi

# One retry. A single miss under load is not an outage, and the cost of being
# wrong here is taking a working server down on top of whoever is playing.
sleep 5
if probe; then
	log "noray missed one probe and answered the retry; not repairing"
	exit 0
fi

now=$(date +%s)
last=0
[ -r "$STAMP" ] && last=$(cat "$STAMP" 2>/dev/null || echo 0)
if [ $((now - last)) -lt "$COOLDOWN" ]; then
	log "noray still not answering, but a repair ran $((now - last))s ago; leaving it for a human"
	exit 1
fi

mkdir -p "$(dirname "$STAMP")"
echo "$now" > "$STAMP"

log "noray is not answering register-host - taking the stack down and back up"
cd "$COMPOSE_DIR" || { log "no compose dir at $COMPOSE_DIR"; exit 1; }
docker compose down >/dev/null 2>&1
docker compose up -d >/dev/null 2>&1
sleep 15

if probe; then
	log "noray answered after the repair"
	exit 0
fi

log "noray did NOT come back after down/up - this needs a human"
exit 1
