"""Use the upstream preparation and identity rules for the NativeAOT translator."""
from pathlib import Path
import shutil
import sys

root = Path.cwd()
sys.path.insert(0, str(root / 'tools'))
import build_xlate

if '--identity' in sys.argv:
    build_xlate.write_identity(root / 'build/xlate/nx2navi_xlate')
else:
    build_xlate.verify_vendor()
    build_xlate.prepare_sources()
    work = root / 'build/xlate/xlate'
    work.mkdir(parents=True, exist_ok=True)
    for name in ('Program.cs', 'AmpereLowering.cs', 'MeshSpirv.cs', 'nx2navi_xlate.csproj'):
        shutil.copy2(root / 'tools/xlate' / name, work / name)
    project = work / 'nx2navi_xlate.csproj'
    project.write_text(project.read_text().replace('../vendor/ryujinx', '../ryujinx'))
