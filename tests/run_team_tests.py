"""Run the modular team regression suite with Lua 5.1+ (no game required).

Usage: python3 tests/run_team_tests.py [lua-or-texlua-executable]
Uses the real generated XML to build test fixtures. The native renderer,
mouse capture and native saved-interface files still require in-game tests.
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
    # All XML values are ASCII. JSON string escapes also work for these in Lua.
    return json.dumps(value, ensure_ascii=False)


def nodes(group: ET.Element, parent: str) -> dict[str, dict[str, object]]:
    result = {}
    name = group.attrib.get("id")
    if name is None:
        raise AssertionError(f"Missing id: {group.tag}")
    path = f"{parent}:{name}"
    props: dict[str, object] = dict(group.attrib)
    props["id"] = path
    props["tag"] = group.tag
    for key in ("x", "y", "w", "h", "fontsize", "line_maxw"):
        if key in props:
            props[key] = int(str(props[key]))
    for key in ("active", "locked", "use_cursor", "savable", "child_resize_h", "child_resize_w"):
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
        (found for name in ("lua5.1", "lua", "luajit", "texlua") if (found := shutil.which(name))), None
    )
    if executable is None:
        raise SystemExit("Lua 5.1+ is required. Pass its executable as the first argument.")
    with tempfile.TemporaryDirectory(prefix="padui-team-test-") as directory:
        temp = pathlib.Path(directory)
        emit = temp / "emit.lua"
        emit.write_text('dofile("user/team_compact.lua")\nio.write(RyzomTeamUI:interfaceXML())\n', encoding="utf-8")
        generated = subprocess.run([executable, str(emit)], cwd=ROOT, check=True, text=True, capture_output=True).stdout
        root = ET.fromstring(generated)
        assert root.tag == "interface_config"
        groups = root.findall("group")
        assert len(groups) == 10, "One inert driver and exactly nine independent members"
        driver, *members = groups
        assert driver.attrib["use_cursor"] == "false"
        assert driver.attrib["w"] == driver.attrib["h"] == "1"
        assert len(driver.findall("view")) == 8
        for source in driver.findall("view"):
            assert source.attrib["textid"] == "0", "Private name resolvers must not bind to SERVER"
            assert source.attrib["dynamic_string"] == "false"
        assert {g.attrib["id"] for g in members} == {f"padui_team_member{i}" for i in range(1, 10)}
        # Generic root groups also require registration to run native draw/checkCoords.
        assert {t.attrib["node"] for t in root.findall("tree")} == {g.attrib["id"] for g in groups}
        assert "sort_controls" not in generated and "footer" not in generated
        for member in members:
            assert member.attrib["options"] == "no_bordure"
            assert member.attrib["savable"] == "false"
            header = member.find("group[@id='header_opened']")
            assert header is not None
            target = header.find("ctrl[@id='target_button']")
            assert target is not None and target.attrib["x"] == "7"
            assert int(target.attrib["x"]) + int(target.attrib["w"]) == int(member.attrib["w"])
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
        fixture.write_text("return " + lua_table({"roots": root_nodes, "panel": panel_nodes}), encoding="utf-8")
        print(f"PASS generated XML: {len(members)} separate containers, {len(root_nodes)} nodes, no footer", flush=True)
        subprocess.run([executable, str(ROOT / "tests/test_team_modular.lua"), str(fixture)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
