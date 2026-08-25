---
title: Your first session
description: Open the menu, download a core, spawn a console and a TV, wire them together and get a picture.
sidebar:
  order: 2
---

This walks you from a freshly installed RetroXR to a game running on a TV you plugged in
yourself. It takes about ten minutes, most of which is waiting for a core to download.

## Opening the menu

Everything starts from the spawn menu.

- **In VR** — press the **Menu button** on your **left** controller (the small ☰ button
  under the thumbstick). The panel appears in front of you, facing wherever you were
  looking.
- **On desktop** — press `Tab`.

Along the top are the sections you will use: `SPAWN`, `CORES`, `CONTROLS`, `OPTIONS`,
`GRAPHICS`, `SCENE`, `NET` and `ABOUT`.

You point at the panel with your controller and pull the **trigger** to click, the same
way you would use a laser pointer.

## Step 1 — Get a core

A **core** is the emulator for one system. RetroXR ships with none, so the first job is
downloading one.

Open **`CORES`**. You are looking at every system RetroXR knows about, each showing how
many cores are available for it. Pick a system — the NES is a good first one — and
download a core for it. Some systems mark one core as *recommended*; take that one unless
you have a reason not to.

Downloads happen inside the headset. You do not need a PC for this step.

:::note
Some systems cannot run without a **BIOS** file that RetroXR is not allowed to distribute
— the PlayStation is the usual example. The `CORES` section tells you which files a system
wants and whether each is required or optional. See [BIOS files](/guide/cores/bios/).
:::

## Step 2 — Get a game in

RetroXR ships no games. Put a ROM into the `roms/` folder for that system — on a Quest,
the easiest way by far is the built-in web file manager.

This is its own page, because it is the step people get stuck on:
**[adding your games](/guide/adding-games/)**.

## Step 3 — Spawn a console and a TV

Back in the menu, open **`SPAWN`**.

1. On the **Objects** tab, spawn a **TV**. It appears in front of you — grab it with
   **grip** and put it somewhere you can see.
2. Still on **Objects**, spawn the **system** you downloaded a core for. Set it on the
   floor or a surface.

Both objects are physical. You can pick them up, put them down, and knock them over.

## Step 4 — Wire it up

This is the part that makes RetroXR what it is: **nothing works until it is actually
connected.**

1. Find the A/V lead coming out of the back of the console.
2. Grab the **plug** on the end of it.
3. Push it into the matching socket on the back of the TV. It snaps in when it is close
   enough and lined up.

The cable hangs and swings under its own weight, so give yourself some slack. If you drop
a plug it falls, and if it lands near a socket it may seat itself in the wrong one — worth
knowing when the picture does not appear.

Full detail, including RF switches and VGA monitors, is on
[plugging things in](/guide/playing/plugging-in/).

## Step 5 — Insert a cartridge and hit power

1. Open **`SPAWN`** → **Games** and click your game. It spawns straight into your
   hand.
2. Push it into the console's slot. It has to go in the right way up.
3. Press the console's **power** button.

The picture comes up on the TV. If the TV is off, press its power button too — the set has
its own power and volume controls, exactly like the real thing.

## Step 6 — Play

Spawn a controller from **`SPAWN`** → **Controllers** and plug it into one of the
console's controller ports. Pick it up and it works.

You can also use a real gamepad — see [controllers and
peripherals](/guide/playing/controllers/).

## When there is no picture

Almost always one of these, in order of likelihood:

- The A/V plug is not seated, or is in the wrong socket.
- The TV is switched off, or is showing a different input.
- No cartridge is seated, or the console is not powered on.
- The core for that system was never downloaded.

The TV shows a blank input rather than an error, because that is what a television does.
[Troubleshooting](/guide/reference/troubleshooting/) goes through the rest.
