# Modular team: team-join crash correction

## Finding

The first in-game test reported a native assertion in
`NLGUI::CLuaIHM::luaValueFromReflectedProperty`, `lua_ihm.cpp:1483`,
shortly after a team invitation. The client reports RyzomCore revision
`a8fb199cf6` (v26.09.416).

At that revision, `CViewTextID.textid` is reflected as `UInt32`, but
`luaValueFromReflectedProperty` has no `UInt32` case and reaches `nlstop`.
The original modular team collector read `source.textid` when a group
NAME became nonzero. That code path matches the reported assertion.
A Lua `pcall` cannot make a native assertion safe.

References checked at the reported revision:
- https://github.com/ryzom/ryzomcore/blob/a8fb199cf6/nel/src/gui/lua_ihm.cpp
- https://github.com/ryzom/ryzomcore/blob/a8fb199cf6/nel/include/nel/gui/view_text_id.h

The uploaded crash files are not included in this public repository.
No fully symbolicated native backtrace was obtained; the diagnosis uses
the recorded assertion and the matching source paths.

## Correction

The generated private name resolvers now use numeric `textid="0"`, not
`SERVER:GROUP` DB bindings. Lua assigns their text IDs through the supported
`UInt32` **setter**, never through a read/compare/write helper. Request
identity is stored in ordinary Lua tables. Display text is cleared when
UID or NAME changes and the native resolver supplies the new string
asynchronously. Signed DB name IDs are converted to unsigned setter values.

The no-DB-binding check is essential: the native setter on a DB-linked
text view writes through its binding. This patch never assigns text IDs to
SERVER-bound views. Reloading over the old prototype's generated widgets
therefore requests a full client restart before any such assignment.

Existing-member UID and name-ID matches allow a previously validated name
to remain while server group slots reorder. Replacement members cannot
inherit a cached name or an open context-menu action from another identity.

## Tests actually run

1. The original 27 tests passed with the old mock.
2. Disallowing the UInt32 getter in that mock made the original runtime fail
   at the first nonempty group. This reproduces the offending Lua access,
   not a native renderer or process crash.
3. After correction, all **32** regression tests pass under Lua 5.3
   (`texlua`), including delayed names after invitation, high-bit name IDs,
   rapid slot reuse, old-template reload rejection, identity stability,
   the existing layouts and the steady-state no-redundant-writes check.
4. The generated XML is structurally checked and all eight private name
   resolvers are required to be unbound. Uploaded runtime/test file blob
   hashes match the locally tested files.

No native Ryzom client was executed here. In-game invitation, accept/decline,
group leave/rejoin, names, targeting, dragging and restart persistence
still require a new client test. The PR remains a draft; `main` is unchanged.

## Windows retest

Fully close Ryzom (not just reload Lua), then use the existing checkout:

```powershell
git -C "$HOME\PadUI-Public" fetch origin
git -C "$HOME\PadUI-Public" switch feature/modular-team-windows
git -C "$HOME\PadUI-Public" pull --ff-only
git -C "$HOME\PadUI-Public" log -1 --oneline
```

Stop on any Git error; do not discard local changes. The branch already
exists after the initial test. No additional symlinks are needed.

Rollback with Ryzom closed:

```powershell
git -C "$HOME\PadUI-Public" switch main
```

Re-enable the old team window in Settings if needed after rollback.
