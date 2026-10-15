"""Build an installation ZIP from tracked runtime files and documentation."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'P\.version\s*=\s*"([0-9.]+)"', (ROOT / 'user/padui_core.lua').read_text(encoding='utf-8')).group(1)
output = ROOT / 'dist' / f'PadUI_{version}_Gesamtpaket.zip'
output.parent.mkdir(exist_ok=True)
files = sorted((ROOT / 'user').glob('*')) + sorted((ROOT / 'docs').glob('*'))
files += [ROOT / name for name in ('README.md', 'CHANGELOG.md', 'THIRD_PARTY_NOTICES.md')]
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in files:
        if path.is_file():
            info = zipfile.ZipInfo(path.relative_to(ROOT).as_posix(), (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
print(output)
