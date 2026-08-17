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

## Where the files go

**Every core gets its own firmware folder.** This is the single most important thing on
this page, and it is not how RetroArch does it — there is no shared `system/` pile that
every core reads from.

```
libretro/system/<core name>/
```

| Platform | Full path |
| --- | --- |
| Windows | `%USERPROFILE%\retroxr\libretro\system\<core name>\` |
| Linux / macOS | `~/retroxr/libretro/system/<core name>/` |
| Quest | `libretro/system/<core name>/` in the [web file manager](#on-quest-the-web-file-manager) |

The **core name** is the bare name with no `_libretro` suffix and no extension:
`mednafen_psx_hw`, `pcsx_rearmed`, `dolphin`, `flycast`.

### Two cores means two copies

Because the folder is per core, running two cores for the same machine means the BIOS has
to exist under **both**. Installing a second PlayStation core does not inherit the first
one's firmware:

```
libretro/system/mednafen_psx_hw/scph5500.bin
libretro/system/pcsx_rearmed/scph5500.bin
```

If a game works under one core and hangs on a black screen under another, this is the
first thing to check.

### Some files live in subfolders

The expected path is not always a bare filename — it can carry folders, and those folders
are part of it. Dolphin wants `dolphin-emu/Sys/GC/USA/IPL.bin`; PPSSPP wants
`PPSSPP/ppge_atlas.zim`. Those become:

```
libretro/system/dolphin/dolphin-emu/Sys/GC/USA/IPL.bin
libretro/system/ppsspp/PPSSPP/ppge_atlas.zim
```

The BIOS / Extras view shows the exact path it wants. Reproduce it exactly, folders and
all.

### Names are case-sensitive on Quest and Linux

RetroXR checks for the file by its exact name and does no case-folding, no renaming and no
searching around. On **Quest and Linux** the filesystem is case-sensitive, so
`SCPH5500.BIN` is simply not `scph5500.bin` and will be reported missing while sitting
right there. On Windows and macOS the same mistake happens to work, because those
filesystems ignore case — which makes this an easy thing to get away with on a PC and then
trip over on a headset.

## Getting the files in

### The download button, if you run RomM

If you have a [RomM](https://romm.app) server connected and it holds the file, each entry
in the BIOS view gets a **download button** and RetroXR fetches it for you. This is by far
the best route, for two reasons:

- It writes the file to **every installed core that wants it**, in one action — so the
  two-copies problem above is handled for you.
- It writes it under the **name and subfolder the core expects**, correcting the case and
  nesting on the way in. A file sitting on your server as `MSX.ROM` lands correctly as
  `Machines/Shared Roms/MSX.rom`.

That correction only happens on this path. A file you place by hand is taken exactly as
you named it.

See [connecting RomM](/guide/connecting/romm/).

### On Quest: the web file manager

On a headset this is the only practical route, and it is safe.

`libretro/` lives in the app's **internal** storage — `/data/user/0/com.xenu.retroxr/files/libretro`
— not on `/sdcard` with your games. That means **`adb push` and SideQuest's file browser
cannot reach it at all.** Do not go hunting for it there.

The [web file manager](/guide/adding-games/) can. It is the app's own server, so anything
uploaded through it is owned by the app and stays writable:

1. Turn on **Web File Manager** in `OPTIONS` and open the address it shows.
2. From the root, open **`libretro`** — not `media`.
3. Open `system`, then the folder named after your core, creating it if it is not there.
4. Drop the file in.

### On desktop: straight onto disk

There is no web file manager on Windows, Linux or macOS — it only runs on Android. Copy
the files into the path from the table above with your normal file manager.

## Extras: one-click support packs

The view is called **BIOS / Extras** because it covers a second, much easier kind of file.

Several cores need supporting data that is *not* copyrighted console firmware — databases,
compatibility lists, themes, game data. libretro publishes these as archives, so RetroXR
can simply **download and unpack them for you in one click**. Nothing to find, nothing to
supply, no RomM required.

The ones most people meet:

| Core | Pack | What it is |
| --- | --- | --- |
| **PPSSPP** (PSP) | PPSSPP assets | Compatibility database and the font/UI atlases the core will not start without |
| **Dolphin** (GameCube / Wii) | Dolphin Sys folder | The `Sys` tree, including `codehandler.bin` |
| **ScummVM** | ScummVM themes + extras | Engine data files and the UI theme |
| **PCSX2** (PS2) | PCSX2 resources | `GameIndex.yaml` and friends |

There are a dozen more behind the same button — blueMSX machine definitions, MAME 2003 and
2003-Plus support files, FinalBurn Neo hiscore data, and the self-contained game cores like
PrBoom, Cave Story, ECWolf, Dinothawr, Cannonball and XRick, which need their game data to
run at all.

If a core has a pack, its entry offers it. Take it.

:::caution[A pack is not a BIOS, and does not replace one]
The archives deliberately stop where copyright begins, so downloading one can still leave
required files missing — that is correct behavior, not a failed download.

- **Dolphin** gets `codehandler.bin` from its pack, but the three **GameCube IPL dumps**
  are console firmware and stay yours to provide.
- **PCSX2** gets `GameIndex.yaml`, but the **PS2 BIOS** folder stays yours.

So a system can read "extras installed" and "required files missing" at the same time.
:::

## Optional files

"Optional" means the core runs without it but something is reduced — a region that will
not boot, a peripheral that will not work, or a slower fallback. If a specific game
misbehaves and the system has an optional BIOS file you have not supplied, that is a
reasonable thing to try.

## When a file is there but not detected

In order:

1. **Check the case**, character for character, on Quest and Linux.
2. **Check the subfolder**, if the expected path had one.
3. **Check the core folder** — it must be the core actually launching the system, which the
   [Manager](/guide/cores/downloading/) shows you.
4. Re-open the BIOS view. Presence is re-checked from disk every time, so a correct file
   shows up immediately; there is no cache to clear.
