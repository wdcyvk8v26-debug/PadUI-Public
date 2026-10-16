# Native corner grip and rigid team layouts (test branch)

This supersedes the earlier name-row click/drag instructions in TEAM_MODULAR.md.
The Windows tester confirmed that the native corner grip is usable, but reported
that individual windows could still detach in Vertical and Horizontal modes.
The latest correction reconciles native movement with the shared layout anchor.
The exact sequence of native events in the reported run was not captured.

## Controls

In PadUI Settings > Layout, set LOCK off. A small coloured square with four
outward arrows appears in the top-right corner of each member window. Hold the
left mouse button on the arrows and move. PadUI adds no hold delay or movement
threshold. The former plus has been replaced by an explicit move symbol.

The grip is half the previous width and height: 8 x 8 UI pixels at 75% and 100%
team scale, 10 x 10 at 125%, and 12 x 12 at 150%. Arrowheads are bitmap rectangles
using the existing blank texture; no extra asset or font is required. The actual
hit area matches the square. LOCK on hides the grip and disables movement.

- Vertical and Horizontal: dragging ANY member's grip moves the complete
  arrangement with a common anchor. Relative row/column positions stay fixed.
- Free: dragging changes only the grabbed member window's free position.
- Name and resource-bar clicks still select the member. They do not drag.
  Right-click outside the unlocked grip retains the member context menu.
- With LOCK on, the former grip area also selects the member.

Free positions and the automatic anchor remain separately saved per character.
The status label shifts left while the grip is visible. The tooltip distinguishes
moving one window from moving the entire team. No runtime filename or Windows
symlink was added. Fully restart Ryzom after updating: corner_drag_v3 rejects
Lua-only reload over the earlier generated widgets. Saved positions are retained.

## Native boundary and cache correction

The containers keep NeL's actual CCtrlMover and native mouse capture. Four
non-overlapping descendant target rectangles expose only the grip square to the
mover. Native updateCoords owns mover width; PadUI adjusts only its vertical
track and active state. Global container_move_opt settings are not changed.

on_begin_move snapshots the last commanded position. on_move translates the
common anchor in automatic modes, or the one free position in Free. Changed
siblings now update their real rectangles immediately, rather than depending
on the captured window's coordinate refresh to update unrelated windows.

Previously, the layout cache checked only layout inputs. If native movement
escaped the callback/snapshot path, matching inputs could leave an individual
window detached. The shared controller now compares native positions to its
last commands before accepting that cache. A missed begin or move notification
can be recovered from an actual native displacement; it never reconstructs a
mouse drag from a hover or press position. Repeated observations do not apply
that displacement twice. Final release displacement is synchronized before saving.

Explicit cancellation, LOCK, a held target button, mode/scale/roster changes,
and viewport changes must not become a recovered drag. Invalid movement is
restored to the selected layout. Recovery and native callbacks never target a
member and never write SERVER properties. The earlier unsigned text-ID getter
and dynamic-window visibility corrections remain in place.

## Validation performed

74 regression cases passed under Lua 5.3 (texlua), using the runtime's actual
XML generator and partial native-behaviour stand-ins. XML structure, Lua syntax,
Python compilation, and trailing-whitespace checks passed. The three uploaded
runtime/test blobs were matched against the tested local bytes by Git SHA-1.

The expanded cases include every member (including self) in both automatic
modes, missing begin/move callbacks, loss of a drag snapshot midway, immediate
sibling real-coordinate updates, final mouse-up movement, cancellation, rigid
screen-edge clamping, free-mode isolation, half-size grips with arrowheads,
and exact target-versus-grip coverage at all supported team scales.

Negative controls using the previous movement implementation fail the new
real-coordinate and missing-callback regressions. These reproduce weaknesses
of the old implementation, not a captured live-client event trace. The earlier
name/roster/targeting/LOCK/layout/restart cases remain. Two hundred idle updates
after movement recovery cause no additional sorting, layout, UI-property,
saved-DB, or text-ID writes.

These are tests with stand-ins, not a live Ryzom renderer/OS capture test,
native Lua-5.1 run, FPS benchmark, or actual .icfg round trip. In-game group
movement, automatic snapping, focus loss, global UI scaling, Linux behaviour,
and persistence still require verification.

## Retest

Close Ryzom, update feature/modular-team-windows, and restart the client.
With LOCK off, first select Horizontal and drag the second or third member's
grip: all windows must move together, including during the drag. Repeat in
Vertical, then select Free and confirm that only the grabbed window moves.
Also check name/bar clicks, LOCK on, screen edges, and restart persistence.
Do not merge this draft merely to test. No user logs, dumps or screenshots
are included in this public change.
