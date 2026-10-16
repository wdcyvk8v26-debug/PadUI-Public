# Native corner grip (test branch)

This supersedes the name-row click/drag instructions in TEAM_MODULAR.md.
The Windows tester reported that name-row dragging was only rarely usable.
That report does not identify one proven cause inside the native client.
Rather than adjust another polling threshold, dragging now uses NeL's
CCtrlMover and its on_begin_move/on_move callbacks.

## Controls

In PadUI Settings > Layout, set LOCK off. A coloured square with a white cross
appears in the top-right corner of each member window. Hold the left mouse
button on this square and move it. No hold delay or four-pixel threshold is
implemented by PadUI. The hit area is at least 16 by 16 UI pixels, increasing
to 24 by 24 at 150% team scale. LOCK on hides the square and disables moving.

Names and resource bars remain native target buttons. With LOCK on, the
entire member card, including the former grip area, selects that member.
With LOCK off, only the separate grip is reserved for movement. It overlays
a small corner while arranging; the status label moves left to make room.
The grip never triggers targeting or a trade/assist action. Other areas keep
the member context menu on right-click.

Vertical and Horizontal move the complete arrangement. Free moves only the
grabbed window. Free positions and the automatic anchor remain separate.
No runtime filename or symlink was added. Fully restart Ryzom after updating;
a marker rejects Lua-only reload over the earlier generated widgets.

## Native boundary

Checked against client revision a8fb199cf6:

- CGroupContainer::setup/updateMover creates a native CCtrlMover with its
  parent set to the member container. No new or guessed XML control type.
- PadUI's container_move_opt has track_w=-8 and track_y=-4. Native
  CGroupContainer::updateCoords owns mover width. PadUI sets only its y and h.
- Four deeper target rectangles leave exactly the visible corner square
  uncovered. The native mover, not a competing button, captures that square.
- on_begin_move snapshots the arrangement. on_move synchronizes the other
  windows directly in the native mouse event; frame polling does not start
  or advance a drag. The shared frame loop observes release to save positions.
- CGroupContainer::setLocked disables the existing mover without rebuilding
  it. The grip and target rectangles follow the same saved LOCK setting.

The old polled name-drag movement calculation is removed. The remaining
pointer snapshot code protects target clicks from roster changes; it cannot
move a card. Native callbacks never target members.

## Validation

61 regression cases passed under Lua 5.3 (texlua), including the existing
roster/name/visibility/layout cases adapted to the new drag entry point.
New checks cover all card pixels at every supported team scale, native
callback start before any rendered frame, absent hover-window information,
100 consecutive one-pixel drags, all four target rectangles, and deferred
position saving. 200 idle updates still cause no redundant sorts, layouts,
UI-property writes, saved-DB writes or text-ID assignments. Generated XML,
Lua syntax, Python compilation and trailing-whitespace checks passed.

These are Lua tests with partial native-behaviour stand-ins, not a live Ryzom
renderer or OS capture test. A native-mover stand-in is an assumption under
test, not proof of actual capture, focus-loss handling, automatic snapping,
UI scaling, Linux behaviour or .icfg persistence. An in-game retest is required.

## Retest

Close Ryzom, update feature/modular-team-windows, and restart the client.
Select Free, switch LOCK off, and drag the white cross immediately. Check
name/bar target selection separately, then LOCK on, both automatic layouts,
release outside the original rectangle, and a complete restart for saving.
Do not merge this draft merely to test. No user logs or screenshots are
included in this public change.
