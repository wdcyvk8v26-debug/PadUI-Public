"""Regression checks for the compass PadUI settings shortcut.

Run from the repository root:
    python tests/test_compass_padui_settings.py

Static XML validation only; verify the button and tooltip inside Ryzom.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

USER = Path(__file__).resolve().parents[1] / "user"
compass = ET.parse(USER / "compass.xml").getroot()
interaction = ET.parse(USER / "interaction.xml").getroot()

window = compass.find("./group[@id='compass']")
assert window is not None
buttons = window.findall("./group[@id='padui_settings_shortcut']")
assert len(buttons) == 1, "Exactly one PadUI shortcut is expected"
button = buttons[0]

# Same native handler as the compass map icon and the taskbar window controls.
assert button.get("group_onclick_l") == "show_hide"
assert button.get("group_params_l") == "padui_settings"
assert button.get("tooltip") == "PadUI"
assert button.get("posref") == "TR TR"
assert int(button.get("w", "0")) == int(button.get("h", "0")) == 24

help_icon = window.find("./group[@id='help']")
assert help_icon is not None
assert help_icon.get("posref") == "TR TR"
assert button.get("y") == help_icon.get("y")
assert abs(int(help_icon.get("x")) - int(button.get("x"))) >= 24
assert window.find("./group[@id='visuel']/view[@id='radar']") is not None
assert window.find("./group[@id='map']") is not None
assert window.find("./group[@id='clock']") is not None

assert button.find("./view[@id='back'][@type='bitmap']") is not None
assert button.find("./view[@id='symbol'][@type='text']") is not None
assert interaction.find("./group[@id='padui_settings']") is not None
print("PASS compass PadUI settings shortcut: XML, placement, handler and target")
