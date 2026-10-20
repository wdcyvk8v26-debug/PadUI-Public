"""Validate actual role-icon XML and run stand-in tests; not a Ryzom client."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    lua = sys.argv[1] if len(sys.argv) > 1 else next(
        (exe for name in ("lua5.1", "lua", "luajit", "texlua") if (exe := shutil.which(name))), None)
    if not lua:
        raise SystemExit("Lua required; pass the interpreter as the first argument.")
    with tempfile.TemporaryDirectory(prefix="padui-roles-") as tmp:
        emitter = Path(tmp) / "emit.lua"
        emitter.write_text('dofile("user/padui_core.lua")\nio.write(PadUITeamRoles:interfaceXML())\n')
        source = subprocess.run([lua, str(emitter)], cwd=ROOT, check=True, capture_output=True, text=True).stdout
        root = ET.fromstring(source)
        assert root.tag == "interface_config" and len(root) == 1
        template = root.find("template")
        assert template is not None and template.attrib == {"name": "padui_local_role_icon_v1", "keep": "true"}
        group = template.find("group")
        assert group is not None and group.attrib["use_cursor"] == "false"
        assert group.attrib["child_resize_w"] == group.attrib["child_resize_h"] == "false"
        assert group.attrib["w"] == group.attrib["h"] == "12"
        assert not group.findall(".//ctrl"), "Role icons cannot intercept targeting or dragging."
        views = group.findall("view")
        assert 1 <= len(views) <= 64
        for i, view in enumerate(views, 1):
            assert view.attrib["id"] == f"p{i}" and view.attrib["type"] == "bitmap"
            assert view.attrib["texture"] == "blank.tga" and view.attrib["scale"] == "true"
            assert view.attrib["global_color"] == view.attrib["active"] == "false"
        print(f"PASS XML: {len(views)} reusable bitmap slots, no input controls or external assets", flush=True)
    subprocess.run([lua, "tests/test_team_roles.lua"], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
