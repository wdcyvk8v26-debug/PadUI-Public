# Native corner grip and rigid team layouts

## Status

The maintainer reported successful Windows testing on 2026-10-16 after the
`efbd326` movement correction: automatic layouts now move together, Free
allows individual placement, and layout switching works. Following the
requested full restart and layout-round-trip check, the maintainer also
confirmed that free positions and LOCK behaved correctly. These are manual
user reports for the tested Windows client, not independent certification
of every native edge case or platform.

The finalization changes documentation only. Runtime and regression-test
files remain unchanged from `efbd326`. The pull request is being prepared
for the maintainer's merge; the documentation update does not itself merge it.

## Controls

In PadUI Settings > Layout, set LOCK off. A small coloured square with four
outward arrows appears in the top-right corner of each member window. Hold
the left mouse button on the arrows and move. PadUI adds no hold delay or
custom movement threshold. Names and resource bars are target areas, not
handles; this replaces the earlier experimental name-row dragging.

The grip measures 8 x 8 UI pixels at 75% and 100% team scale, 10 x 10 at 125%,
and 12 x 12 at 150%. Arrowheads use small rectangles and the existing blank
texture; no additional asset or font is required. The hit area matches the
square. LOCK on hides the grip, disables movement and makes that area
selectable again.

- Vertical and Horizontal: dragging any member's grip moves the complete
  arrangement with a common anchor. Relative row/column positions stay fixed.
- Free: dragging changes only the grabbed member window's free position.
- Name and resource-bar clicks select the member. Right-click outside the
  unlocked grip retains the member context menu. Grip drags never target.

Free positions and the automatic anchor remain separately saved per
character. These positions belong to reusable window slots, not a permanent
per-player database. See [TEAM_MODULAR.md](TEAM_MODULAR.md) for assignment
and reset behaviour. The status label shifts left while the grip is visible;
the tooltip distinguishes one-window movement from whole-team movement.

No runtime filename or Windows symlink was added. Fully restart Ryzom after
updating generated XML: `corner_drag_v3` rejects Lua-only reload over older
instances. Existing saved positions are retained.

## Native boundary and cache correction

The containers use NeL's actual `CCtrlMover` and native mouse capture. Four
non-overlapping descendant target rectangles expose only the grip square to
the mover. Native `updateCoords` owns mover width; PadUI adjusts its vertical
track and active state. Global `container_move_opt` settings are unchanged.

`on_begin_move` snapshots the last commanded position. `on_move` translates
the common anchor in automatic modes, or one free position in Free. Changed
siblings update their real rectangles immediately rather than depending on
the captured window's coordinate refresh to update unrelated windows.

The former layout cache checked layout inputs only. Native movement outside
the callback/snapshot path could leave a member detached despite unchanged
layout inputs. The shared controller now compares actual native positions to
its last commands before accepting that cache. Missed begin/move notifications
can be recovered from actual displacement without reconstructing a mouse drag
from hover or press coordinates. Repeated observations do not apply a delta
twice. Final release displacement is synchronized before saving.

Explicit cancellation, LOCK, held target buttons, mode/scale/roster changes
and viewport changes must not become recovered drags. Invalid displacement
is restored to the selected layout. Recovery and native callbacks never
select a member or write SERVER properties. Earlier unsigned text-ID access
and dynamic-window visibility corrections remain in place.

## Validation record and limits

The runtime at `efbd326` has a recorded run of **74 passing regression cases
under Lua 5.3 (texlua)** with XML emitted by the actual runtime and partial
native-behaviour stand-ins. XML structure, Lua syntax, Python compilation and
trailing-whitespace checks passed in that implementation round. The runtime
and test blobs were checked against the tested local bytes by Git SHA-1.
This documentation-only finalization did not rerun those tests.

Cases cover every member including self in both automatic modes, missing
begin/move callbacks, lost snapshots, immediate sibling real-coordinate
updates, final release movement, cancellation, rigid screen-edge clamping,
Free isolation, half-size arrows and target/grip coverage at all team scales.
Earlier name, roster, targeting, LOCK, layout and simulated restart tests
remain. Two hundred idle updates after movement recovery produced no extra
sorting, layout, UI-property, saved-DB or text-ID writes.

Negative controls using the previous implementation failed the new native
coordinate and missed-callback cases. Those controls reproduce weaknesses
in the old implementation, not a captured live-client event trace.

Manual Windows feedback above now complements, but does not replace, these
stand-in tests. No native Lua-5.1 client was run in the test environment, no
FPS benchmark or automated `.icfg` round trip was performed, and Linux/macOS,
focus loss, desktop changes, global UI scaling, snapping edge cases and all
full-group scenarios have not been separately verified in the live client.
Further platform testing remains useful without resetting the successful
Windows feedback to an untested state.

## Update after merge

Only after the maintainer merges PR #1, fully close Ryzom and switch the
existing checkout back to `main`, then update it. Execute commands one at a
time and stop on errors; do not discard local changes.

```powershell
git -C "$HOME\PadUI-Public" switch main
git -C "$HOME\PadUI-Public" pull --ff-only
```

Before that merge, `main` still has the previous team implementation. Existing
symlinks continue to refer to the same checkout, so no link changes are needed.
Keep backups outside Ryzom's `user` directory. No user logs, dumps or screenshots
are included in the public documentation.
