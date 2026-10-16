# Modular team visibility correction

## Report and scope

After the team-join crash correction, the Windows tester reported no crash,
but no visible member windows. No fresh client log was supplied for that run.
This patch fixes two concrete initialization/positioning defects found by
comparing the runtime with the reported client revision. Native retesting is
still required; this is not a report of a successful in-game reproduction.

## Native behavior that the original mock missed

Reference client: RyzomCore `a8fb199cf6`.

- In `nel/src/gui/group_container.cpp`, parsing `opened` sets `_OpenAtStart`.
  `launch()` normally calls `open()`. Merely setting a dynamically created
  container's `active` flag does not open it. `setup()` controls the active
  `header_opened`/`header_closed` groups using the separate `_Opened` state.
- The same file's `setup()` forces root containers to **BL TL**, even if XML
  originally specified TL TL. Native Y is the top edge measured from the bottom
  of the screen. Negative top offsets are not valid native positions; native
  coordinate clamping can collapse multiple cards against the bottom edge.
- `header_active=false` only suppresses the decorative native title bar. It is
  not a substitute for opening the container and was not changed in this patch.

Source: https://github.com/ryzom/ryzomcore/blob/a8fb199cf6/nel/src/gui/group_container.cpp

## Correction

The nine member containers are explicitly set up, opened and laid out once
before use. The runtime keeps the existing per-character **top-offset** saved
positions, but writes `nativeY = screenHeight + topOffset` to root containers.
Dragging transfers native movement deltas back into the same stored coordinates.
A viewport change invalidates layout without treating engine clamping as a user
drag. No saved-position reset or global visibility override is performed.

The previous UInt32/text-ID crash correction is retained unchanged. Only the
already-linked `user/team_compact.lua` changes at runtime; no new UI symlinks,
server requests, global mouseover settings or main-branch changes are needed.

## Validation performed

- The original runtime fails the strengthened mock's first visible-card check.
- Opening alone still fails the native-position regression.
- The complete correction passes **36 regression tests under Lua 5.3 (texlua)**.
- The mock now distinguishes active/opened state, initializes headers as native
  setup does, computes BL TL rectangles, and models borderless root clamping.
- New cases cover explicit opening, saved-to-native coordinates, resize while
  the mouse is held, and non-overlap in fitting grids. Existing invitation,
  delayed-name, illegal UInt32-read, targeting, layout, drag, persistence and
  steady-state counter tests remain in place.
- Generated XML is parsed by the existing Python test runner.

This is still a partial native-behavior model, **not** a NeL renderer, native
mouse-capture test, live FPS measurement or actual `.icfg` round trip.

## Windows retest

Fully close Ryzom. In the existing checkout, stop if any Git command fails:

```powershell
git -C "$HOME\PadUI-Public" switch feature/modular-team-windows
git -C "$HOME\PadUI-Public" pull --ff-only
git -C "$HOME\PadUI-Public" log -1 --oneline
```

Restart the client. Ensure Team is enabled in Settings -> Windows. Check solo
with self enabled, then accept an invitation and check names/bars/targeting.
Try both automatic layouts and Free, including dragging and world clicks through
gaps. Saved visibility and positions are not reset automatically. If windows
remain absent, provide the new `client.log` from that run and a screenshot of
Settings -> Windows and Layout; do not post private logs/dumps to public GitHub.
