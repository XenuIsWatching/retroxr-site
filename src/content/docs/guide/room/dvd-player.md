---
title: DVD player
description: Play your own DVD images with real disc menus and chapters, on a TV you wired up yourself.
sidebar:
  order: 1
---

The DVD player is a deck you plug into a television, exactly like a console. It plays
**your own** disc images, with the disc's real menus, chapters, audio tracks and
subtitles — driven by libVLC and its `libdvdnav` / `libdvdread` plugins.

:::caution[Not on macOS]
The packaged libVLC backend ships on Windows, Linux and Quest. A macOS build from source
has no DVD player and no VCR.
:::

## Getting a disc in

Put your image into the `dvd/` folder:

- **Windows** — `%USERPROFILE%\retroxr\dvd`
- **Linux / macOS** — `~/retroxr/dvd`
- **Quest** — `/sdcard/Android/data/com.xenu.retroxr/files/dvd`

Two things are recognized: a folder containing a `VIDEO_TS/` directory, or a standalone
`.iso` or `.img` file.

## Playing one

1. Open the menu, go to **`SPAWN`** → **DVDs**, and click a title. A **disc** spawns
   carrying that image — the same way a cartridge carries a ROM.
2. From the **Objects** tab, spawn a **DVD Player** and a **TV**.
3. Run the player's A/V lead into the TV, the same cable the consoles use. See
   [plugging things in](/guide/playing/plugging-in/).
4. Put the disc into the player's slot.
5. Press **PLAY**.

Inserting a disc never starts playback on its own — you press play, like you would have.

![The DVD player stand-in: a black deck with a disc slot and on-unit buttons — play, pause, stop, language, subtitles, menu, rewind and fast-forward, chapter skip, eject, and a direction cluster for disc menus.](../../../../assets/screenshots/obj_dvd.png)

## The buttons on the deck

| Button | Does |
| --- | --- |
| `PLAY` `PAUSE` `STOP` | Transport |
| `EJECT` | Takes the disc back out |
| `<<` `>>` | Rewind and fast-forward scan |
| `\|<<` `>>\|` | Previous and next chapter |
| `MENU` | Back to the disc's root menu |
| `UP` `DOWN` `LEFT` `RIGHT` `SEL` | Navigate the disc's own menus |
| `LANG` `SUB` | Cycle audio and subtitle tracks |

Point at the player and press the **menu button** to open a floating panel that picks
audio and subtitle tracks by name, rather than cycling blindly through them.

## From across the room

You do not have to walk over to the deck. Spawn a **TV Remote** from the **Objects** tab,
point it at the player, and the same controls appear above it — including the disc-menu
cluster. See [the TV remote](/guide/room/tv-remote/).

## Sound and picture

The video renders onto whichever TV the player is plugged into. The **television's** own
volume and power controls drive the player's audio and screen, just as they do for a
console — so if you have picture and no sound, check the set's volume before the deck's.
