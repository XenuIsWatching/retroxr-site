---
title: RetroAchievements
description: Sign in and earn achievements in the games you already own.
sidebar:
  order: 3
---

[RetroAchievements](https://retroachievements.org) adds achievements to retro games. If
you have an account, RetroXR can sign in and unlock them as you play, with a badge toast
appearing when you earn one.

## Signing in

Enter your RetroAchievements **username** and password in the settings to sign in.

:::caution[Two different keys]
The RetroAchievements site shows a **Web API key** in your profile. That is *not* the one
that unlocks achievements — it is a longer, different value for reading data. Signing in
with it will appear to work and then never unlock anything.
:::

## What works

Achievement support depends on the core and the game — the same as any other
RetroAchievements-capable frontend. A system whose core does not support it will simply
never report anything.

:::caution[Needs an in-headset pass]
This page is written from the source rather than from a session in the headset. The
sign-in flow and the two-key distinction are read directly from the code; the exact
location of the settings and the appearance of the unlock toast have not been verified
against a running build.
:::
