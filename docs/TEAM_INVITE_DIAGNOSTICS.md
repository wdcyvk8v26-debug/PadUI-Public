# Team invitation diagnostics (test branch)

Branch: `diagnostic/team-join-safety-log`. This is a **diagnostic experiment**; keep `main` unchanged until tested.

## What it does

- Rejects malformed team name/string IDs and the reserved 0xFFFFFFFF sentinel before they reach a native `text_id` setter.
- Writes transition-only breadcrumbs to Ryzom's **System** chat and `debugInfo`: `name-id set begin`, `name-id set ok`, `roster changed`, `arrange begin`, `arrange ok`, `card activate begin`, and `render ok`. In steady state, no per-frame messages are produced.
- Includes the current phase and Lua traceback in existing fallback handling. The System chat displays a short error; the client log receives the full Lua traceback when available.
- Leaves native UI tree creation, window count, saved layouts, and normal rendering unchanged.

## One useful test

Completely restart Ryzom with this branch, enable the PadUI team window and accept a team invitation. If the client survives, inspect the **System** tab for a rejected team name ID or any PadUI Team error. If it still crashes, the last `PadUI Team [diag]` message indicates the most recent attempted step. `render ok` does **not** mean the GPU has completed drawing the frame.

`pcall`/`xpcall` can catch Lua errors but **cannot prevent or identify a native NeL/AMD/Direct3D access violation**. The messages are breadcrumbs, not a reconstructed native exception. A native crash may occur before buffered logs reach disk.

No credentials, player names, or character identities are included in diagnostic messages. Avoid posting full personal logs or crash dumps publicly.

Validation status: static source checks complete; the Lua mock suite and in-game test have not been run in this environment.
