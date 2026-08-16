---
title: Downloading & managing cores
description: Install a core, choose which one each system uses by default, and change its options.
sidebar:
  order: 2
---

Everything here lives under the **`CORES`** section of the menu, which has three views.

## Download

A scrollable grid of every system RetroXR knows about, each showing how many cores are
available for it.

![The core downloader: the CORES tab's Download view, a scrollable grid of systems with the number of available cores for each.](../../../../assets/screenshots/cores_scrolled.png)

Pick a system, pick a core, and it downloads in the headset. No PC, no unzipping, no
copying files.

Where a system has an obvious best choice it is marked **recommended**.

## Manager

Once you have more than one core for a system, this is where you say which one it launches
with. Systems are shown as a grid, each labeled with its current default.

![The core Manager: a grid of systems, each labeled with its currently selected core.](../../../../assets/screenshots/cores_manager.png)

This is also where **core options** live. Every core exposes its own settings — region,
video filters, accuracy trade-offs, controller emulation — and you can change them here,
or reset them back to the core's defaults if you have made a mess.

## BIOS / Extras

Which systems need firmware, which files exactly, and whether each is required or
optional. It has [its own page](/guide/cores/bios/).

## Updating and removing

Cores can be re-downloaded to pick up a newer build, and removed when you no longer want
them. A system with no core installed simply cannot be spawned — that is the constraint
you are managing.

:::note
Changing the default core for a system does not migrate saves between cores. Different
cores can use different save formats, so a game saved under one may not be seen by
another.
:::
