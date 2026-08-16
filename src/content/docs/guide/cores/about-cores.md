---
title: What a core is
description: Why RetroXR ships no emulators, and what you are choosing when you pick one.
sidebar:
  order: 1
---

RetroXR is not itself an emulator. It is a room that runs **libretro cores** — and a core
is an emulator for one system, packaged so a program like this one can load it.

That is why the app arrives with none of them. You download the cores for the systems you
actually care about, from inside the headset, and RetroXR runs them.

## What this gets you

Anything libretro supports, RetroXR can play: NES, SNES, Mega Drive, Nintendo 64,
PlayStation, Saturn, Dreamcast, GameCube, Game Boy through to the DS and 3DS, PSP, plus
the long tail — Neo Geo Pocket, WonderSwan, Virtual Boy, Amiga, C64, MSX, DOS, ScummVM,
arcade boards, and fantasy consoles like PICO-8.

RetroXR knows about **76 systems**. How many of them you can play comes down to which
cores you install and which BIOS files you own.

## Several cores per system

Most systems have more than one core, and they are not interchangeable. One may be more
accurate; another faster; another may support something specific.

Where one core is clearly the right default, it is marked **recommended** — take that one
unless you have a reason not to. The Nintendo 3DS is the example worth knowing: its
recommended core renders in **stereoscopic 3D**, which in a headset is the entire point,
and the alternatives do not.

## Where cores come from

Cores are downloaded from the libretro build server, the same source every libretro
frontend uses. Nothing is bundled with RetroXR and nothing is scraped from anywhere
unusual.

## Next

- [Downloading and managing cores](/guide/cores/downloading/)
- [BIOS files](/guide/cores/bios/)
