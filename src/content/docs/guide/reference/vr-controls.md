---
title: VR controls
description: What each control does in the headset.
sidebar:
  order: 1
---

## The basics

| Control | Does |
| --- | --- |
| **Grip** | Grab whatever your hand is near — an object, a plug, a cartridge |
| **Trigger** | Click the menu, grab at a distance, drag a page |
| **Menu button** *(left)* | Open and close the spawn menu |
| **Thumbstick** | Move, and turn |

Let go of grip and the thing in your hand drops. Objects have weight — they fall, roll and
knock each other over.

## Pointing at things

Point at an object across the room and use the trigger to grab it from where you stand,
rather than walking over. The same ray clicks the menu panel.

Pointing at certain objects — a book, the DVD player, a machine with settings — and
pressing the **menu button** opens a small panel of options for that specific thing.

## Moving

Locomotion is configurable in **`OPTIONS`**:

- **Slide** or **teleport** movement.
- **Snap** or **smooth** turning, with an adjustable snap angle.
- A **vignette** that narrows your field of view while moving, which helps a great deal
  with comfort.
- **Height offset** and **world scale**, so the room fits you.

## Hands

You can play with controller models shown, or with hands. The finger poses follow what you
are doing — a pointing finger when you point, a fist on grip.

On **Meta Quest Touch controllers**, v0.4.0 reads the controllers' **capacitive sensors**,
so your fingers sit where they actually are on the controller rather than snapping between
a few canned poses. A finger lifted off a button is a finger lifted off a button.

:::note[Capsense wants SteamVR on PCVR]
On a PC, use **SteamVR** as the OpenXR runtime if you want this. The Horizon link does not
pass capacitive-sensor data through, so on that route the poses fall back to the canned
ones. Standalone on the headset is unaffected.
:::

**Poking now happens at your index fingertip**, not from a cone off the front of the
controller. Everything you press with a finger — the NES flap, the Wii Remote's SYNC
button, the DualShock's ANALOG button — is reached from where the finger really is.

Haptics fire on the things you would expect: seating a plug, pressing a button on a deck,
completing a page turn.

:::caution[Needs an in-headset pass]
The bindings above come from the code and from the parts of the README that document them.
The comfort options in particular are listed from the options screen's source rather than
from using them, so exact labels may differ. The **Edit this page** link goes straight to
the source if you spot something wrong.
:::

## Not wearing a headset?

There is a full mouse-and-keyboard fallback — see [desktop
controls](/guide/reference/desktop-controls/).
