"""Static regression tests for the PadUI shortcut beside the Ryzom minimap.

Run: python tests/test_compass_padui_settings.py
XML-only checks; actual rendering and clicks must be tested in Ryzom.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

USER = Path(__file__).resolve().parents[1] / "user"
compass = ET.parse(USER / "compass.xml").getroot()
interaction = ET.parse(USER / "interaction.xml").getroot()
settings_lua = (USER / "padui_settings.lua").read_text(encoding="utf-8")

window = compass.find("./group[@id='compass']")
assert window is not None
buttons = window.findall("./group[@id='padui_settings_shortcut']")
assert len(buttons) == 1
button = buttons[0]

# 12x12 shortcut sits in the clear upper-right gap above the radar circle.
assert button.get("group_onclick_l") == "show_hide"
assert button.get("group_params_l") == "padui_settings"
assert button.get("tooltip") == "PadUI"
assert button.get("posref") == "TR TR"
assert (button.get("x"), button.get("y")) == ("-29", "-8")
assert (button.get("w"), button.get("h")) == ("12", "12")
assert button.find("./view[@id='back'][@type='bitmap']").get("w") == "12"
assert button.find("./view[@id='symbol'][@type='text']").get("fontsize") == "8"

help_icon = window.find("./group[@id='help']")
assert help_icon is not None
assert help_icon.get("posref") == "TR TR"
# Rectangles do not collide with Help and the button stays in the top band.
compass_width = int(window.get("w"))
def right_anchored_bounds(group):
    x_right = compass_width + int(group.get("x"))
    y_top = abs(int(group.get("y")))
    return (x_right - int(group.get("w")), y_top,
            x_right, y_top + int(group.get("h")))
bx1, by1, bx2, by2 = right_anchored_bounds(button)
hx1, hy1, hx2, hy2 = right_anchored_bounds(help_icon)
assert bx1 >= 138 and bx2 <= 160 and by1 < 15
assert bx2 <= hx1 or hx2 <= bx1 or by2 <= hy1 or hy2 <= by1
assert window.find("./group[@id='visuel']/view[@id='radar']") is not None
assert window.find("./group[@id='map']") is not None

# Default is visible, zero also works before the saved DB leaf is loaded.
flag = interaction.find("./variable[@entry='UI:SAVE:PADUI:HIDE_MINIMAP_ICON']")
assert flag is not None and flag.get("value") == "0"
assert any(link.get("target") == "padui_settings_shortcut:active"
               and link.get("expr") == "eq(@UI:SAVE:PADUI:HIDE_MINIMAP_ICON,0)"
               for link in window.findall("./link"))

# The independent toggle belongs in the Windows tab, NOT the team/layout
# section (which dynamically creates the native team controls).
# It remains accessible even if the minimap icon itself is hidden.
settings = interaction.find("./group[@id='padui_settings']")
assert settings is not None
windows = settings.find("./group[@id='content']/group[@id='page1']")
layout = settings.find("./group[@id='content']/group[@id='page3']")
assert windows is not None and layout is not None
toggle = windows.find("./ctrl[@id='minimap_icon']")
assert toggle is not None
assert toggle.get("onclick_l") == "lua"
assert toggle.get("params_l") == "PadUISettings:toggleMinimapIcon()"
assert (toggle.get("x"), toggle.get("y")) == ("171", "-132")
assert (toggle.get("w"), toggle.get("h")) == ("164", "30")
assert windows.find("./view[@id='minimap_icon_text']") is not None
assert layout.find("./ctrl[@id='minimap_icon']") is None
assert layout.find("./view[@id='minimap_icon_text']") is None
window7 = windows.find("./ctrl[@id='window7']")
assert window7 is not None
assert window7.get("x") == "0" and window7.get("y") == toggle.get("y")
assert int(window7.get("x")) + int(window7.get("w")) <= int(toggle.get("x"))
assert "pl(1,'minimap_icon_text'" in settings_lua
assert "pl(3,'minimap_icon_text'" not in settings_lua
assert "function S:toggleMinimapIcon()" in settings_lua
assert "db('HIDE_MINIMAP_ICON')==1 and 0 or 1" in settings_lua
assert "if key=='HIDE_MINIMAP_ICON' then S:refresh();return end" in settings_lua
for label in (
    "PadUI-Symbol an der Minimap anzeigen",
    "Show PadUI icon by minimap",
    "Afficher l’icône PadUI sur la mini-carte",
):
    assert label in settings_lua
for short_label in ("Minimap: PadUI-Icon", "Minimap: PadUI icon", "Mini-carte : PadUI"):
    assert short_label in settings_lua

print("PASS: PadUI compass button 12px, independent Windows-tab visibility toggle")
