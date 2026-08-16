---
title: BIOS files
description: Which systems need a BIOS, how RetroXR reports what is missing, and where the files go.
sidebar:
  order: 3
---

Some systems cannot boot without a copy of their original **BIOS** — the small program
that was burned into the console itself. The PlayStation is the best-known example;
Saturn, Dreamcast, 3DO, CD-i, Amiga and several others are the same.

RetroXR does not and cannot ship these files. They are copyrighted, and they belong to the
hardware you own.

## Seeing what a system needs

Open **`CORES`** and go to the **BIOS / Extras** view. Every system is listed with its
status at a glance — complete, a count of optional files, or required files missing.

![The BIOS / Extras overview: a grid of systems, each showing its BIOS status — complete, a number of optional files, or required files missing.](../../../../assets/screenshots/cores_bios.png)

Open one and you get the files themselves, each marked **required** or **optional**, with
its exact expected filename. The PlayStation entry, for instance, lists `scph5500.bin`,
`scph5501.bin`, `scph5502.bin` and `psxonpsp660.bin`.

![The BIOS / Extras view for PlayStation, listing the PS1 BIOS files with their required or optional status and per-file download buttons.](../../../../assets/screenshots/cores_bios_psx.png)

This is worth checking *before* you wonder why a game will not start. A missing BIOS
usually shows up as a console that powers on and does nothing, not as an error.

## Getting the files in

The filename has to match exactly — cores look for a specific name, and a file that is
right in every way except its name will not be found.

Copy them in the same way as anything else, via the web file manager or straight onto
disk. See [adding your games](/guide/adding-games/) for both routes.

If you run a [RomM](https://romm.app) server that holds your firmware, RetroXR can pull
the files down from it directly — see [connecting RomM](/guide/connecting/romm/).

## Optional files

"Optional" means the core runs without it but something is reduced — a region that will
not boot, a peripheral that will not work, or a slower fallback. If a specific game
misbehaves and the system has an optional BIOS file you have not supplied, that is a
reasonable thing to try.
