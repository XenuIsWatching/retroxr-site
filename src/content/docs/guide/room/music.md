---
title: CD player and tape deck
description: Play your own music on a CD player or a cassette deck, through speakers you place.
sidebar:
  order: 3
---

Alongside the video hardware there is audio hardware: a **CD player** and a **cassette
deck**, both of which take your own music files.

## Getting music in

Put audio files into the `music/` folder:

- **Windows** — `%USERPROFILE%\retroxr\music`
- **Linux / macOS** — `~/retroxr/music`
- **Quest** — `/sdcard/Android/data/com.xenu.retroxr/files/music`

## Playing something

Spawn a **CD player** or a **cassette deck** from **`SPAWN`** → **Objects**, along with a
pair of **speakers**. Wire the deck to the speakers with a 3.5 mm lead, put a disc or a
cassette in, and press play.

Both decks have the transport buttons you would expect. The CD player can skip tracks; the
cassette deck cannot, because a cassette could not — you rewind and fast-forward and
listen for the gap.

The [TV remote](/guide/room/tv-remote/) drives both from across the room.

## Sound placement

Audio is positioned in the room, so a deck playing across from you sounds like it is
across from you. On Quest this goes through Meta's XR Audio SDK, which renders it with
HRTF — the reason you can point at a sound with your eyes closed. Where that is
unavailable, RetroXR falls back to Godot's own 3D audio.

:::caution[Needs an in-headset pass]
This page is written from the code rather than from a session in the headset. The hardware
and the folder are right; the exact supported audio formats and the deck's full button set
have not been verified against a running build.
:::
