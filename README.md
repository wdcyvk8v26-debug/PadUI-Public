# PadUI

A compact interface modification for **Ryzom**, with German, English and French text.

**Version 0.8.10 — development version, before 1.0.**

[Deutsch](docs/INSTALL_DE.md) · [English](docs/INSTALL_EN.md) · [Français](docs/INSTALL_FR.md) · [Changelog](CHANGELOG.md)

## Funktionen / Features / Fonctionnalités

- Compact player, target and team windows; team sorting by name, HP or missing HP, optional self display, horizontal layout and scaling.
- Quick item bar with saved assignments and horizontal/vertical layouts.
- Selected skill level and progress; compact inventory information.
- Three named countdown timers or stopwatches, with compact controls and scaling.
- Aura countdown icons and a placement preview.
- Nearby creature list, boss notifications and independent named-creature and boss tracking learned from selected targets.
- Central settings for language, accents, transparency and layouts.
- Updated chat, map and action bar appearance; item comparison where client data is available.

## Installation

Close Ryzom, back up your existing `user` folder and character interface settings, then copy the **contents of this repository's `user` folder** into the Ryzom `user` folder. Replace matching files and restart the client. See the installation guides above.

Use GitHub **Code → Download ZIP** for a source snapshot. Extract it first; only the files inside `user` belong in the game's `user` folder. A reproducible installation package can be built with `python3 scripts/package.py`.

## Compatibility and feedback

PadUI uses the client's XML/Lua interface. Client builds can differ across Windows, Linux and macOS; universal compatibility is not guaranteed. Startup guards contributed by Alrekur are included for early native player access. Report your client build, OS, PadUI version and reproduction steps in an issue. Remove personal information from logs before sharing them.

## Credits and provenance

- Ryzom / Ryzom Core: original client UI files and APIs. This repository contains modified native UI files and PadUI additions.
- Alrekur: diagnosis and patches for the Linux startup crash involving early `getPlayerName()` / `getPlayerPos()` access.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). No blanket licence is assigned to third-party code or data by this repository.
