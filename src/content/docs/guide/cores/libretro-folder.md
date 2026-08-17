---
title: The libretro folder
description: Where cores, BIOS files, core options and battery saves actually live — and which parts you should never touch.
sidebar:
  order: 4
---

Alongside your games sits a second tree, `libretro/`. RetroXR owns this one: the
[core downloader](/guide/cores/downloading/) fills it in, and you rarely need to open it.

It is worth knowing what is in it, because it is where a stubborn BIOS problem or a
corrupted core option actually lives.

## Where it is

| Platform | Location |
| --- | --- |
| Windows | `%USERPROFILE%\retroxr\libretro` |
| Linux / macOS | `~/retroxr/libretro` |
| Quest | internal app storage — reachable as **`libretro/`** in the [web file manager](/guide/adding-games/) |

On Quest this folder is *not* next to your games. Your games live in external storage
where you can copy files freely; `libretro/` is in the app's own private storage. The web
file manager shows both under one root, which is the only place you will see them side by
side.

## What is in it

```
libretro/
  cores/                 the emulator cores themselves
  system/                BIOS and firmware, one folder per core
  core_assets/           asset packs some cores need
  core_options/          your per-core settings
  save/                  battery saves
  temp/                  scratch space
  cores_manifest.json    what is downloadable, and what you have
  core_defaults.json     which core each system launches with
  firmware_state.json    which BIOS files are present
```

### cores

One file per emulator. These arrive through `CORES` → Download and there is no reason to
put them here by hand — a core dropped in manually will not be registered in the manifest.

### system

**This is the one you may legitimately need to open.** Cores look for their BIOS and
firmware here, in a folder named after the core. The PlayStation's `scph5500.bin` and
friends, the Dreamcast's boot ROM, the DS firmware — all of it lands under `system/`.

The [BIOS page](/guide/cores/bios/) is the friendlier route: it tells you which files a
system wants, by exact name, and where they go.

### core_options

Your settings for each core, written when you change something in `CORES` → Manager. If a
core is behaving strangely and you want a clean slate, resetting its options from the
Manager rewrites the file for you — safer than editing it.

### save

Two different things, filed two different ways:

```
save/<core>/<game>/<save>.srm      cartridge battery saves — per core, per game
save/memcards/<systemid>/<name>.mcr  memory cards — per console family, no core
```

A **cartridge** kept its save on its own chip, so the path is keyed by the game. A **memory
card** is one image that every game on that console writes into — which is the entire point
of a card — so it is keyed by the card instead.

The card path carries no core name on purpose: the raw image is identical for every
PlayStation core, so a card survives switching cores the way a real one survives switching
consoles. Cartridge saves do not. See [the PlayStation](/guide/platforms/playstation/) and
[game saves and backups](/guide/connecting/saves/).

### temp

Scratch space. RetroXR copies a core here before running it, so one machine's core cannot
tread on another's. Nothing in here is worth keeping.

:::danger[On Quest, use the web file manager — not adb or SideQuest]
`libretro/` is in the app's **internal** storage, not on `/sdcard` with your games. Two
consequences:

- **`adb push` and SideQuest's file browser cannot reach it**, so there is nothing to find
  there. Don't go looking.
- The **[web file manager](/guide/adding-games/) can**, and it is safe: it is the app's own
  server, so anything uploaded through it is owned by the app and stays writable. This is
  the supported way to put a BIOS file in place.

The rule being protected is about ownership, not the folder: a file forced in from a PC by
other means lands owned by the shell, and RetroXR can no longer write to it. A config it
cannot update looks exactly like a config that was wiped. If something needs replacing,
delete it and let RetroXR fetch it again.
:::

## When a core misbehaves

In rough order of what to try:

1. **Reset the core's options** in `CORES` → Manager. Most odd behavior is a setting.
2. **Check its BIOS** in `CORES` → BIOS / Extras. A missing required file usually shows as
   a machine that powers on and does nothing.
3. **Re-download the core.** It replaces the file in `cores/`.
4. **Try a different core** for that system, if one exists.
