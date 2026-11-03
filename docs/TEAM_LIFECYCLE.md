# Modular team: lifecycle and failure containment

Base: `713c9a1bc0c379d6c14a5ad2a66fba92177539bb` (PadUI-Public/main).
Runtime change: **only `user/team_compact.lua`**. The nine independent native
member windows, native corner movers, layouts and saved preferences remain.
No additional runtime file, XML override, symlink, server or client build.

## Failure and recovery

A Lua error previously latched `T.failed` forever, hid the PadUI cards and
showed the native team window, although the Team preference remained enabled.
The new failure state has three bounded automatic retries: 1, 3 and 10 seconds
between attempts. A failed retry does not replenish its own budget. Thirty
seconds of successful updates replenish it; repeated start/forced-update calls
cannot bypass the delay. A held mouse postpones recovery. Missing clocks leave
manual recovery available; clock rollback reschedules rather than busy-loops.

The Team checkbox shows `[Ersatzanzeige]`, `[fallback]` or `[secours]` while
recovery is pending. Turning Team off/on requests a manual rebind without a
relog. Disabled Team stays disabled and does not keep retrying. First-start
failure preserves the old visibility preference even before DB migration.
The native fallback is hidden on recovery only if PadUI originally opened it;
a native team window that was already visible is left alone.

Missing required UI objects, incompatible name resolvers and incomplete XML
trees are structural errors. They stop automatic retries and retain the native
fallback. Manual recovery validates the existing structure again. Missing
roots/movers generally require a full client restart; recovery never attempts
to repair the native tree by deleting/reinserting windows.

## Native-window boundaries

- Long-lived team bindings store Lua proxies containing **IDs**, not native
  userdata. Every property/method access resolves the current native object.
  Methods receive that freshly resolved native object as `self`.
- Only the explicit `start()` hook may create the window tree. Draw callbacks
  and recovery cannot parse another set of roots. A partial or failed parse is
  not retried into an existing tree. Normal updates allocate no GUI objects.
- Complete required bindings, including headers/fonts/movers, are validated
  before publishing a usable binding set. Existing private text-ID resolvers
  must remain unbound. The unsafe UInt32 getter is still never used.
- Coordinate passes guard synchronous/reentrant move callbacks. Mouse actions,
  visibility/layout changes and context-menu actions have protected Lua entry
  points as well as the frame update.
- Failure clears stale member/menu/gesture state and partial property/layout
  caches. A release from a held gesture interrupted by failure cannot select a
  replacement member after recovery. Each root is hidden independently, so one
  failing hide does not skip the other windows or the native fallback.
- Invalid/minimized viewports do not rewrite saved positions. Non-finite DB
  numbers are sanitized. Optional settings failures do not take down the team.

These changes constrain PadUI's Lua/native interaction. Lua `pcall` does not
make an invalid C++ pointer safe. This is **not proof that a native access
violation has been fixed**, and no crash dump, private log or account data is
included in this commit.

## Validation

Run from the repository root:

```text
python tests/run_team_tests.py
```

**104 regression cases passed under Lua 5.3 (`texlua`)**, including the 74
existing cases and 30 added lifecycle/failure cases. The runner also parses
and validates generated XML. Syntax remains Lua 5.1-compatible, but this change
has not been executed under Lua 5.1 or inside Ryzom.

The stand-in now rejects stale native objects and proxy-as-native-self method
calls. Added tests inject render/click/coordinate/hide errors, exhaust retries,
remove/replace UI elements, interrupt gestures, exercise logout and partial
startup, and verify visibility preference/fallback ownership preservation.
The expanded suite run against the original runtime fails at the first new
recovery regression: `Transient failure remained latched`. This negative
control confirms the suite detects the original failure instead of merely
accepting both implementations. The original 74 tests passed before changes.

Limitations: the stand-in is not NeL's renderer/window list, native heap,
OS mouse capture, real frame-time profiler or an actual `.icfg` round trip.
Native Windows testing remains required.

## Windows retest

Completely close Ryzom before switching the existing PadUI-Public checkout to
the fix branch. Preserve local changes; do not reset/clean the checkout. With
the existing user-file links, no new symlinks or executable rebuild are needed.
Restart Ryzom rather than hot-reloading Lua during a native drag.

Check solo/self visibility, invitation/join/leave and delayed names; all layouts
and scales; every member's corner drag; target clicks and context menus; Team
off/on; resizing/minimizing; and a normal relog. Saved positions/layout should
remain. Should a genuine Lua error occur, confirm the native fallback and the
explicit checkbox status, then recovery or manual Team off/on. Keep the log
line `PadUI modular team [phase, retry N/3]` for diagnosis; do not publish private
logs or dumps to public GitHub.
