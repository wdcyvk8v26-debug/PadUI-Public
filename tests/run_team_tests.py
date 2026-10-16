"""Validate runtime XML and run the modular team Lua regression suite.

Usage: python3 tests/run_team_tests.py [lua-or-texlua-executable]
These native-interface stand-ins do not replace Ryzom client tests.
"""
from __future__ import annotations
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def nodes(group: ET.Element, parent: str) -> dict:
    result = {}
    name = group.attrib.get("id")
    assert name is not None, f"Missing id: {group.tag}"
    path = f"{parent}:{name}"
    props = dict(group.attrib, id=path, tag=group.tag)
    for key in ("x", "y", "w", "h", "fontsize", "line_maxw"):
        if key in props:
            props[key] = int(props[key])
    for key in ("active", "opened", "locked", "movable", "use_cursor", "savable", "child_resize_h", "child_resize_w"):
        if key in props:
            props[key] = props[key] == "true"
    if group.tag == "view" and props.get("type") == "text_id":
        text_id = str(props.pop("textid"))
        if text_id.lstrip("-").isdigit():
            props["textid"] = int(text_id) & 0xFFFFFFFF
            props["dbBinding"] = ""
        else:
            props["dbBinding"] = text_id
    result[path] = props
    for child in group:
        if child.tag in ("group", "view", "ctrl"):
            children = nodes(child, path)
            assert not (result.keys() & children.keys()), "Duplicate XML id"
            result.update(children)
    return result


def lua_table(value: object) -> str:
    if isinstance(value, dict):
        return "{" + ",".join(f"[{quote(str(k))}]={lua_table(v)}" for k, v in value.items()) + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return quote(str(value))


def main() -> None:
    executable = sys.argv[1] if len(sys.argv) > 1 else next(
        (found for name in ("lua5.1", "lua", "luajit", "texlua") if (found := shutil.which(name))), None)
    if executable is None:
        raise SystemExit("Lua 5.1+ is required; pass the executable as the first argument.")
    with tempfile.TemporaryDirectory(prefix="padui-team-test-") as directory:
        temp = pathlib.Path(directory)
        emit = temp / "emit.lua"
        emit.write_text('dofile("user/team_compact.lua")\nio.write(RyzomTeamUI:interfaceXML())\n', encoding="utf-8")
        generated = subprocess.run([executable, str(emit)], cwd=ROOT, check=True, text=True, capture_output=True).stdout
        root = ET.fromstring(generated)
        assert root.tag == "interface_config"
        groups = root.findall("group")
        assert len(groups) == 10, "Exactly one driver and nine independent windows"
        driver, *members = groups
        assert driver.attrib["use_cursor"] == "false"
        assert driver.attrib["w"] == driver.attrib["h"] == "1"
        assert driver.find("group[@id='name_drag_v1']") is not None
        assert len(driver.findall("view")) == 8
        for source in driver.findall("view"):
            assert source.attrib["textid"] == "0", "Never bind private name resolvers to SERVER"
            assert source.attrib["dynamic_string"] == "false"
        assert {g.attrib["id"] for g in members} == {f"padui_team_member{i}" for i in range(1,10)}
        assert {t.attrib["node"] for t in root.findall("tree")} == {g.attrib["id"] for g in groups}
        assert "sort_controls" not in generated and "footer" not in generated
        for member in members:
            assert member.attrib["options"] == "no_bordure"
            assert member.attrib["savable"] == "false"
            assert member.attrib["posref"] == "BL TL"
            assert member.attrib["movable"] == "false", "Native mover must not compete with click/drag button"
            header = member.find("group[@id='header_opened']")
            assert header is not None
            target = header.find("ctrl[@id='target_button']")
            assert target is not None and target.attrib["x"] == target.attrib["y"] == "0"
            assert target.attrib["w"] == member.attrib["w"] and target.attrib["h"] == member.attrib["h"]
            assert target.attrib["onclick_l"] == target.attrib["onclick_r"] == "lua"
            for score in ("hp", "sap", "sta"):
                assert header.find(f"view[@id='{score}_fill']") is not None
        root_nodes = {}
        for group in groups:
            part = nodes(group, "ui:interface")
            assert not (root_nodes.keys() & part.keys())
            root_nodes.update(part)
        template = root.find("template[@name='padui_modular_team_settings']")
        assert template is not None and template.attrib["keep"] == "true"
        panel = template.find("group")
        assert panel is not None
        panel_nodes = nodes(panel, "ui:interface:padui_settings:content:page3")
        fixture = temp / "fixture.lua"
        fixture.write_text("return " + lua_table({"roots":root_nodes,"panel":panel_nodes}), encoding="utf-8")
        print("PASS XML: nine independent windows, full-card target buttons, unbound name resolvers", flush=True)
        subprocess.run([executable, str(ROOT / "tests/test_team_modular.lua"), str(fixture)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
