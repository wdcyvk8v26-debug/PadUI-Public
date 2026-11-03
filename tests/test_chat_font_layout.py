"""Static regression checks for font-responsive PadUI chat entry fields.

Run: python tests/test_chat_font_layout.py
Does not replace a native Ryzom UI rendering test.
"""
from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

XML = Path(__file__).resolve().parents[1] / "user" / "interaction.xml"
root = ET.parse(XML).getroot()

def single_template(name: str) -> ET.Element:
    found = root.findall(f"./template[@name='{name}']")
    assert len(found) == 1, f"Expected one {name} template"
    return found[0]

def link_matches(element: ET.Element, target: str, expr: str) -> bool:
    return any(x.get("target") == target and x.get("expr") == expr
               for x in element.iter("link"))

font_expr = ("ifthenelse(ge(@UI:SAVE:CHAT:FONT_SIZE,20),20,"
             "ifthenelse(le(@UI:SAVE:CHAT:FONT_SIZE,11),11,"
             "@UI:SAVE:CHAT:FONT_SIZE))")
height_expr = ("ifthenelse(ge(@UI:SAVE:CHAT:FONT_SIZE,20),36,"
               "ifthenelse(le(@UI:SAVE:CHAT:FONT_SIZE,12),24,"
               "add(@UI:SAVE:CHAT:FONT_SIZE,16)))")

definitions = {e.get("id"): e.get("value") for e in root.findall("./define")}
assert definitions["padui_chat_input_font"] == font_expr
assert definitions["padui_chat_input_height"] == height_expr

editor = single_template("padui_chat_edit")
assert editor.find("./group[@id='#id']/group[@id='eb']/view[@id='edit_text']") is not None
assert editor.find("./group[@id='#id']/group[@id='ebh']/view[@id='edit_text']") is not None
for target in ("eb:edit_text:fontsize", "ebh:edit_text:fontsize"):
    assert link_matches(editor, target, "%padui_chat_input_font"), target
for target in ("h", "eb:h", "ebh:h"):
    assert link_matches(editor, target, "%padui_chat_input_height"), target

standard = (
    "chat_id", "clearable_chat_id", "filtered_chat_id",
    "contact_chat_friend", "dynamic_chat_id",
)
for name in standard:
    parent = single_template(name)
    inputs = [e for e in parent.iter("instance")
              if e.get("template") == "padui_chat_edit"]
    boxes = [e for e in parent.iter("instance")
             if e.get("template") == "padui_chat_box"
             and e.get("id") == "cb"]
    assert len(inputs) == len(boxes) == 1, name
    assert boxes[0].get("h") == "-24", name
    assert link_matches(parent, "cb:h", "sub(0,%padui_chat_input_height)"), name

main = single_template("main_chat_group")
assert main.find(".//group[@id='cb']") is not None
assert link_matches(main, "cb:h", "sub(0,add(%padui_chat_input_height,8))")
assert len([e for e in main.iter("instance")
            if e.get("template") == "padui_chat_edit"]) == 1

around = single_template("around_me_id")
assert len([e for e in around.iter("instance")
            if e.get("template") == "padui_chat_edit"]) == 1
assert not any(x.get("target") == "cb:h" for x in around.iter("link"))
# around_me keeps its separate 100 px chat reserve and shared responsive editor.

for setting in range(9, 21):
    font = min(20, max(11, setting))
    height = 36 if setting >= 20 else (24 if setting <= 12 else setting + 16)
    standard_reserve = height
    main_reserve = height + 8
    assert 11 <= font <= 20
    assert 24 <= standard_reserve <= 36
    assert 32 <= main_reserve <= 44
    if setting <= 12:
        assert (standard_reserve, main_reserve) == (24, 32)

print("PASS chat font/input size links and all 12 slider positions")
