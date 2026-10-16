# Changelog

This repository begins with the existing development version 0.8.10. Earlier changes are summarized from the package history, not reconstructed as Git commits.

## Unreleased

- Replace the shared team panel with up to nine independent member windows; remove the on-window sorting footer. Sorting remains in Settings.
- Add Vertical layouts with 1–9 columns, Horizontal layouts with 1–9 rows, and Free placement. Retain team scaling, optional self display, status indicators, targeting and context menus.
- Add small four-arrow corner grips and LOCK. Dragging any member in Vertical/Horizontal moves the complete arrangement; Free moves only the grabbed member. Names and resource bars remain target-selection areas.
- Save the automatic anchor and free positions separately per character. Keep member-to-window assignments stable while members remain in the team; preserve free positions across layout switches.
- Reuse windows and one shared controller. Skip unchanged UI values, redundant sorting and layout work; reconcile native position changes with the automatic grid.
- Correct native text-ID access, explicit opening of dynamically created containers, and bottom-left versus top-offset coordinates encountered during Windows testing. No additional runtime file or symlink is required.
- Record the maintainer's successful Windows feedback on movement, layout switching, LOCK and position persistence after restart. The runtime at efbd326 has a recorded 74-case Lua 5.3 regression run; these stand-in tests are separate from the manual client checks. Other platforms and untested native edge cases are not certified.

## 0.8.10

- Restore native global mouseover fading once after 0.8.9; leave subsequent global preferences alone.
- Retain local background opacity control for known standard windows; exclude the cast bar.

## 0.8.9

- Restore original native background textures.
- Apply opacity through native global settings and the native `set_alpha` action for a fixed list of standard windows.
- Its global rollover change is superseded by 0.8.10.

## 0.8.8

- Persist only boss names missing from the multilingual BM catalogue, using selected-target creature classification, level and native star tier of at least 7.
- Remove redundant catalogue/non-boss cache records; retain missing boss entries.
- Apply native header accents only on explicit accent selection, rather than at login.

## 0.8.7

- Remove hard-coded character priority from team sorting; use alphabetical tie-breaking.

## 0.8.6

- Integrate Alrekur's startup guards for native player name and position access before `game.InGameDbInitialized`.
- Avoid retaining a previous character's cached name across character changes.

## 0.8.5

- Separate full timer mode controls from duration presets to prevent overlap.

## 0.8.4 and earlier

- Reintroduce native styling, team scaling and timer scaling on the stable baseline.
- Add countdown/stopwatch modes and compact timer controls.
- Earlier development added compact player/team/target displays, quick items, skill tracking, aura alerts, item comparison, central multilingual settings and the creature catalogue.
- Experimental source quantity displays and whisper chat containers were withdrawn following crashes or performance problems and are not included.
