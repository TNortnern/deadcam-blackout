#!/usr/bin/env python3
"""Build the WebGL2 release from a throw-away copy of the project.

Why a copy: texture import settings are shared by every platform, and the desktop build must keep its full-resolution
maps. The copy gets web-only treatment before it is imported and exported:
  * models and textures that nothing loads are removed (tools/list_unused_assets.gd works out the real set)
  * prop textures are capped at 512 px; hero surfaces (weapons, zombies, floors, stairs, new props) keep 1024 px
  * only the S3TC texture variant is imported, matching what desktop browsers consume
export_presets.cfg is written inside the copy only, so it can never be left behind in the repository.

Usage: python tools/export_web.py <godot console exe> <output dir> [--keep-temp] [--reuse]
  --reuse keeps the temporary copy's import cache from the previous run, so only changed assets are re-imported.
"""
import gzip
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
KEEP_FULL_RES = (
    "weapon_", "zombie_", "prop_", "herringbone_", "grand_staircase_aaa", "worn_oak_flight", "admissions_gallery",
    "reception_desk_aaa", "cabin_facade", "tunnel_", "landing_portal", "sawmill_shed_aaa", "evidence_chest_aaa",
    "upgrade_bench_aaa", "diesel_generator_aaa", "watchtower_aaa", "fp_",
)
SKIP_DIRS = {".git", ".godot", "reference_frames", ".hill-climb", "checks", "tools", "__pycache__"}
PROP_TEXTURE_LIMIT = 512

PRESET = """[preset.0]

name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="{out}/index.html"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
"""


def run(cmd, cwd=None, timeout=3600):
    t0 = time.time()
    p = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    out = p.stdout.decode("utf-8", "replace")
    return p.returncode, out, time.time() - t0


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    godot = sys.argv[1]
    out_dir = Path(sys.argv[2]).resolve()
    keep = "--keep-temp" in sys.argv or "--reuse" in sys.argv
    reuse = "--reuse" in sys.argv
    work = Path(tempfile.gettempdir()) / "deadcam_web_export"
    proj = work / "proj"
    if work.exists() and not reuse:
        shutil.rmtree(work, ignore_errors=True)
    if reuse and proj.exists():
        # Keep the copy's import cache; refresh sources so only changed files re-import
        for sub in ("assets", "scripts", "shaders", "scenes"):
            shutil.rmtree(proj / sub, ignore_errors=True)
    proj.mkdir(parents=True, exist_ok=True)

    # 1. What does the game actually load?
    unused_txt = work / "unused.txt"
    rc, log, _ = run([godot, "--headless", "--path", str(REPO), "--script", "tools/list_unused_assets.gd", "--", str(unused_txt)])
    unused = [l.strip() for l in unused_txt.read_text(encoding="utf-8").splitlines() if l.strip()] if unused_txt.exists() else []
    print(f"[1/6] unused model files: {len(unused)}")

    # 2. Copy the runtime parts of the project
    def ignore(d, names):
        rel = Path(d).resolve().relative_to(REPO) if Path(d).resolve() != REPO else Path(".")
        drop = set()
        for n in names:
            if rel == Path(".") and (n in SKIP_DIRS or n.endswith(".md") or n in ("video_analysis.json", "export_presets.cfg")):
                drop.add(n)
        return drop
    shutil.copytree(REPO, proj, ignore=ignore, dirs_exist_ok=True, copy_function=shutil.copy2)
    removed = 0
    for res_path in unused:
        f = proj / res_path.replace("res://", "")
        for cand in (f, Path(str(f) + ".import")):
            if cand.exists():
                cand.unlink()
                removed += 1
    print(f"[2/6] copied project, removed {removed} unused files")

    # 3. Web-only texture budget
    capped = 0
    for folder in ("models", "textures"):
        for imp in (proj / "assets" / folder).glob("*.import"):
            name = imp.name
            if not re.search(r"\.(jpg|jpeg|png)\.import$", name, re.I):
                continue
            txt = imp.read_text(encoding="utf-8")
            if "compress/mode=2" not in txt:
                continue
            # BC7 is not guaranteed in WebGL2; S3TC is, so the web copy drops the high-quality flag
            new = txt.replace("compress/high_quality=true", "compress/high_quality=false")
            limit = 1024
            if folder == "models" and not name.startswith(KEEP_FULL_RES):
                limit = PROP_TEXTURE_LIMIT
            new = re.sub(r"process/size_limit=\d+", f"process/size_limit={limit}", new)
            if new != txt:
                imp.write_text(new, encoding="utf-8")
                capped += 1
    pg = proj / "project.godot"
    pg.write_text(pg.read_text(encoding="utf-8").replace("textures/vram_compression/import_etc2_astc=true", "textures/vram_compression/import_etc2_astc=false"), encoding="utf-8")
    print(f"[3/6] web texture budget applied to {capped} imports (props {PROP_TEXTURE_LIMIT}px, hero 1024px, S3TC only)")

    # 4. Import, then export
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("index.*"):
        old.unlink()
    (proj / "export_presets.cfg").write_text(PRESET.format(out=str(out_dir).replace("\\", "/")), encoding="utf-8")
    rc, log, secs = run([godot, "--headless", "--path", str(proj), "--import"])
    print(f"[4/6] import rc={rc} in {secs:.0f}s")
    rc, log, secs = run([godot, "--headless", "--path", str(proj), "--export-release", "Web", str(out_dir / "index.html")])
    errs = [l for l in log.splitlines() if "ERROR" in l or "SCRIPT ERROR" in l]
    print(f"[5/6] export rc={rc} in {secs:.0f}s, error lines={len(errs)}")
    for l in errs[:12]:
        print("      " + l[:200])
    if not (out_dir / "index.pck").exists():
        print("EXPORT FAILED: no index.pck written")
        print(log[-3000:])
        return 1

    # 5. Pre-compress for the static server
    total_raw = 0
    total_gz = 0
    for f in sorted(out_dir.glob("index.*")):
        if f.suffix == ".gz":
            continue
        raw = f.stat().st_size
        total_raw += raw
        if f.suffix in (".wasm", ".pck", ".js", ".html"):
            with open(f, "rb") as src, gzip.open(str(f) + ".gz", "wb", compresslevel=6) as dst:
                shutil.copyfileobj(src, dst, 1 << 20)
            gz = Path(str(f) + ".gz").stat().st_size
            total_gz += gz
            print(f"      {f.name:36s} {raw / 1e6:8.1f} MB  -> gzip {gz / 1e6:8.1f} MB")
        else:
            total_gz += raw
    print(f"[6/6] WEB BUILD raw={total_raw / 1e6:.1f} MB  transfer={total_gz / 1e6:.1f} MB  -> {out_dir}")
    if not keep:
        shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
