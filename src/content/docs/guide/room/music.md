---
title: CD player, tape deck and turntable
description: Play your own music on a CD player, a cassette deck or a record player, through speakers you place.
sidebar:
  order: 3
---

Alongside the video hardware there is audio hardware: a **CD player**, a **cassette deck**
and, new in v0.5.0, a **record player** — all three take your own music files.

## Getting music in

Put audio files into the `music/` folder:

- **Windows** — `%USERPROFILE%\retroxr\music`
- **Linux / macOS** — `~/retroxr/music`
- **Quest** — `/sdcard/Android/data/com.xenu.retroxr/files/music`

## Playing something

Spawn a **CD player**, a **cassette deck** or a **record player** from **`SPAWN`** →
**Objects**, along with a pair of **speakers**. Wire the deck to the speakers with a 3.5 mm lead, put a disc or a
cassette in, and press play.

Both decks have the transport buttons you would expect. The CD player can skip tracks; the
cassette deck cannot, because a cassette could not — you rewind and fast-forward and
listen for the gap.

The [TV remote](/guide/room/tv-remote/) drives them from across the room.

## The record player

The turntable is the odd one out, and deliberately so: **it has no transport row to press.**
You work it by hand, the way you work a real one.

Drop a record onto the platter, then **take hold of the tonearm and swing it over**. The
arm is the control — parked on its rest, the record is loose and liftable; cued over the
band, the deck is committed and the needle is down. Where you set it down across the
record is **where in the album you start**, so dropping the needle two thirds of the way in
starts you two thirds of the way in.

There is no fast-forward or rewind, because a turntable has neither. Those two cells are
greyed out on the TV remote for this deck. START and STOP drive the platter, and it
**spins up and coasts down** rather than snapping between still and turning.

### 33 and 45

The speed switch is real, and so is getting it wrong. Every record here is a 12" LP cut at
33⅓, so playing one at **45** runs it about a third fast and a fifth higher — the whole
point of the control. Flip it back and it settles.

### Touch the record

Put a fingertip on the spinning record and you drag it. The pitch **follows the platter**,
so slowing it down bends the note down, letting go lets it glide back up to speed, and
stopping it dead stops the sound — which is what a record halted under your hand does.

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
