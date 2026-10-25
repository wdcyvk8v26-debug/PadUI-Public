# Local team roles - stage 1

This draft adds local role graphics and selection only. It does not announce,
read, intercept or synchronise chat. No extra channel, API, server change,
external graphic/font file, runtime filename or Windows symlink is required.

## Controls

Right-click a PadUI member window, then open **Assign role (local)**:
Tank, Heal, Melee, Ele, Affliction, or No role. In German the parent entry is
**Rolle zuweisen (lokal)**. The submenu uses the same graphics as the cards
and a small graphical tick for the current role.

The symbol appears before the member name:

| Role | Shape | Colour |
| --- | --- | --- |
| Tank | Shield | Blue |
| Heal | Healing cross | Green |
| Melee | Crossed swords | Red / pale blades |
| Ele | Magic burst | Orange / gold |
| Affliction | Skull | Purple |

At 100% team scale the symbol is 12x12 UI pixels followed by a 4px gap.
The four team scales use 9, 12, 15 and 18px symbols. Small 9px masters retain
important features rather than shrinking everything indiscriminately.
Even with No role, the space remains reserved so names do not jump.
The end of the existing name field stays fixed; very long names have less room.
The tooltip includes the full role name in the chosen PadUI language.

Symbols contain no input controls: clicking them uses the existing member
selection area, and right-clicking still opens the member menu. Name/bar
selection, the corner move grip, LOCK, automatic layouts and free positions
are not replaced. The role submenu does not select a different target.

Assignments are local, attached to member UID plus name ID rather than a
visual slot, and reset on observed leave/join, character change, disconnect
or addon reload. They are not saved to character configuration. Hiding self
does not erase a local self role. The self card can preview all five symbols
while solo when Show own character is enabled. Starting a new team clears
that solo preview role. Stale menu actions reject departed/replaced members.

## Integration

The addon is embedded after the existing code in `user/padui_core.lua`, which
is already linked by the Windows installation. `PadUI:start()` registers it
through the existing isolated module startup loop. It extends the existing
team update, rendering and right-click entry points with reload-safe wrappers.
`user/team_compact.lua` itself is unchanged, including its movement logic.
There is no second draw callback or team-data controller.

The original pixel masks compile to merged, coloured `blank.tga` rectangles.
Each icon has a fixed pool of at most 52 bitmap views, reused when roles or
scale change. Only rectangles needed by the selected shape are active.
This is more UI geometry than a one-texture icon, but avoids font availability,
external-asset packaging and additional symlinks for this visual test stage.
It is not an FPS optimisation claim. The visible appearance must be approved
in the actual client before proceeding to synchronisation.

Native menu APIs were checked against RyzomCore client revision a8fb199cf6:
`CGroupSubMenu::luaAddLine` takes four arguments and returns no object;
`luaAddSubMenu` returns a submenu; `setUserGroupLeft/Right` take an index and
group, with native ownership. The addon checks indices, keeps the original
menu entries, and does not reset or replace the native member menu.
The UI uses only reflected string, boolean and signed-32-bit properties.
A role-addon error is isolated from the base team window and target selection.

## Validation

Run from the repository root:

```sh
python3 tests/run_role_tests.py
# Or specify an available Lua interpreter:
python3 tests/run_role_tests.py texlua
```

This pass ran **35 local-role cases under Lua 5.3 (texlua)**, actual generated
XML checks, Python compilation and whitespace checks. Cases cover startup,
all symbol masks/sizes, bounds and distinct silhouettes, reserved name space,
local assignment/removal, graphic menu markers, original menu/selection
behaviour, identity changes, hidden-team leave/join, solo preview, language,
LOCK/font/layout budgets, reload reuse and isolated addon failure. Two hundred
unchanged updates cause no additional UI/DB/action writes in the stand-ins.
The icon rasters were also visually inspected at native size and enlarged.

The test uses strict partial UI/team stand-ins, not the live NeL client.
It does not rerun the earlier 74 modular-team tests or constitute an actual
native menu/input test, Linux/macOS test, Lua-5.1 runtime test or FPS benchmark.
No live-client success is claimed yet; in-game visual acceptance is the gate.

## Windows test

Fully close Ryzom. Run separately, stopping on any Git error:

```powershell
git -C "$HOME\PadUI-Public" fetch origin
git -C "$HOME\PadUI-Public" switch --track origin/feature/local-team-roles
git -C "$HOME\PadUI-Public" log -1 --oneline
```

Restart. Right-click your own or another member's card and try all five roles.
Inspect 75% and 100% scale in particular, then 125% and 150%. Check symbol/name
clicks, long names, LOCK, group/free movement and switching between modes.
Roles clearing after a fresh login is intentional; positions must still persist.

Do not merge merely to test. To roll back, close Ryzom and run:

```powershell
git -C "$HOME\PadUI-Public" switch main
```

No screenshots, logs or crash dumps from the user are included in this change.
