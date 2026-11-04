#!/usr/bin/env python3
"""Fast, dependency-free static checks for the optional PadUI Action Dock.

Run from a PadUI checkout:
    python scripts/check_action_dock.py
If luac 5.1 is installed, Lua syntax is checked as well.
These checks are not a substitute for in-game window rendering and interaction.
"""
from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

BASE = Path(__file__).resolve().parents[1]
XML = BASE / "user" / "inventory.xml"
CORE = BASE / "user" / "padui_core.lua"
DOCK = BASE / "user" / "padui_action_dock.lua"

root = ET.parse(XML).getroot()
xml = XML.read_text(encoding="utf-8")
lua = DOCK.read_text(encoding="utf-8")
core = CORE.read_text(encoding="utf-8")

def require(ok: bool, what: str) -> None:
    if not ok:
        raise AssertionError(what)

def indexed(template: str) -> list[int]:
    return [
        int(e.attrib["index"])
        for e in root.iter("instance") if e.get("template") == template
    ]

def elements(tag: str, field: str, value: str) -> list[ET.Element]:
    return [
        el for el in root.iter(tag) if el.get(field) == value
    ]

require(indexed("ctrl_memory") == list(range(20)), "Main bar 0..19 changed")
require(indexed("ctrl_alt_memory") == list(range(20)), "Alt bar 0..19 changed")

main_template = elements("template", "name", "ctrl_memory")
alt_template = elements("template", "name", "ctrl_alt_memory")
require(len(main_template) == 1 and len(alt_template) == 1, "Missing native templates")
require(
    main_template[0].find("ctrl").get("value") == "UI:PHRASE:MEMORY:#index",
    "Main bar must use native phrase memories",
)
require(
    alt_template[0].find("ctrl").get("value") == "UI:PHRASE:MEMORY_ALT:#index",
    "Alt bar must use native alternate phrase memories",
)
for template in [main_template[0], alt_template[0]]:
    ctrl = template.find("ctrl")
    for key in ("onclick_l", "ondrop", "oncandrop", "menu_r"):
        require(bool(ctrl.get(key)), f"Missing native input handler: {key}")
    require(ctrl.get("dragable") == "true", "Native draggable sheet must remain")

require(len(elements("group", "id", "gestionsets")) == 1, "Main window changed")
require(len(elements("group", "id", "gestionsets2")) == 1, "Alt window changed")
require(len(elements("group", "id", "padui_dock_chrome")) == 2, "Glass panels missing")
require(len(elements("group", "id", "padui_slot_chrome")) == 2, "Slot panels missing")
for i in range(20):
    require(len(elements("view", "id", f"frame{i}")) == 2, f"Frame {i} missing")
    for part in ("edge_top", "edge_left", "edge_right", "edge_bottom"):
        require(len(elements("view", "id", f"{part}{i}")) == 2,
                f"Bevelled {part}{i} missing")
require(len(elements("view", "id", "padui_mode")) == 2,
        "Theme/spacing status labels missing")
require(len(elements("view", "id", "aux_label")) == 1,
        "Legacy alt label must exist for reversible cosmetics")
for f in root.iter("view"):
    if f.get("id", "").startswith("frame"):
        require(f.get("global_color") in (None, "false", "true"),
                "Invalid bitmap global_color boolean")

for name in ["handl", "handr"]:
    hands = [
        e for e in root.iter("ctrl")
        if e.get("id") == name and e.get("item_slot") in ("LEFT_HAND", "RIGHT_HAND")
    ]
    require(len(hands) >= 1 and hands[0].get("dragable") == "true",
            f"Real weapon slot {name} unavailable")

for action in ["dock_join", "dock_join_above", "dock_split", "dock_spacing_compact",
               "dock_spacing_relaxed", "dock_glass_deep", "dock_glass_soft",
               "dock_glass_clear", "dock_theme_gold", "dock_theme_aether",
               "dock_theme_ember"]:
    require(len(elements("action", "id", action)) == 2, f"Menu action {action} missing")

required_db = [
    "ENABLED", "BACKUP_VALID", "FIRST_ACTIVE", "SECOND_ACTIVE", "SECOND_X",
    "SECOND_Y", "SECOND_MODE", "SPACING", "GLASS", "THEME", "SIDE",
]
for name in required_db:
    require(len(elements("variable", "entry", f"UI:SAVE:PADUI:ACTION_DOCK:{name}")) == 1,
            f"Saved state {name} missing")

require(len(elements("lua", "file", "padui_action_dock.lua")) == 1,
        "Missing Lua loader")
require("PadUIActionDock:start()" in core, "Missing in-game startup hook")
require('on_move="lua:PadUIActionDock:onMainMoved()"' in xml,
        "Missing native current-action positioning hook")
require("game:updateCurrentActionPosition()" in lua,
        "Native cast/current action positioning must be preserved")
require("function D:onMainMoved()" in lua and
        "function D:onAltMoved()" in lua and
        "self:sync(\"main\")" in lua and "self:sync(\"alt\")" in lua,
        "Both-window drag propagation must be installed")
require('on_move="lua:PadUIActionDock:onAltMoved()"' in xml,
        "Second window must have a native Ryzom on_move callback")
require('function D:joinBelow()' in lua and 'function D:joinAbove()' in lua,
        "Dock positioning above/below must be independently selectable")
require('local GAP = 0' in lua, "Dock shells should have no vertical gap")
require('self:placeSlots(mainGrid,pitch)' in lua and
        "for i=0,19 do" in lua and
        'set(MAIN .. ":shortcuts:s" .. i,"y",-math.floor(i/10)*26)' in lua,
        "Native slot layout and exact original 28x26 reset must exist")
require('function D:setTheme(which)' in lua and
        'function D:setGlass(which)' in lua,
        "Live theme and transparency controls are missing")
require('update(find(MAIN))' in lua and 'update(find(ALT))' in lua,
        "Native window coordinates must update after layout changes")
require('source=="alt"' in lua and "function D:moveReal(" in lua,
        "Native independent window move deltas are required")
require('set(chrome .. ":branding","active",i==1)' in lua and
        'set(chrome .. ":aux_label","active",false)' in lua,
        "Supplementary dock must not show a second titlebar")
require("setOnDraw(" not in lua, "No per-frame window mutation allowed")

# Chrome is opt-in and does not modify the global rollover/opacity settings.
require("CONTAINER_ROLLOVER_FACTOR" not in lua
        and "CONTAINER_ALPHA" not in lua, "Global mouseover must not change")
require("PadUIActionDock:disable()" in xml, "No visible opt-out")

print("PASS: XML parses, 20+20 native phrase controls and 160 bevel edges")
print("      Both-window drag callbacks, bottom/top docking menus, saved")
print("      settings and native layout restoration are present.")

compiler = shutil.which("luac5.1") or shutil.which("luac")
if compiler:
    result = subprocess.run([compiler, "-p", str(DOCK)], capture_output=True, text=True)
    require(result.returncode == 0, "Lua compile failed: " + result.stderr)
    print("PASS: Lua syntax check (" + compiler + ")")
else:
    print("SKIP: Lua compiler not installed; runtime/syntax test still required")
