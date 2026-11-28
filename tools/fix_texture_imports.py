#!/usr/bin/env python3
"""Make every texture under assets/ import as VRAM-compressed with mipmaps.

The world is built in code, so the editor never "sees" these textures used in 3D and leaves newly added ones at the
2D default: lossless, which sits uncompressed in video memory (5.6 MB per 1024px map instead of 0.7-1.4 MB) and bloats
the web package. Only textures still at that default are touched. First-person weapon maps use the high-quality (BC7)
codec so the desktop build loses nothing visible; the web export switches those to S3TC inside its own copy. 
Normal maps are identified from the pixels themselves (extracted GLB textures have meaningless names), so they get
the two-channel normal-map codec and colour maps never do.

Run after adding any model or texture, then re-import:  python tools/fix_texture_imports.py && godot --headless --path . --import
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
HIGH_QUALITY_PREFIXES = ("weapon_", "fp_")
KEEP_LOSSLESS = {"flashlight_cookie.png"}  # light projector: block compression would band the falloff
NORMAL_NAME = re.compile(r"(normal|_nor_|_nor\.|_nrm|_norm)", re.I)


def looks_like_normal_map(path: Path) -> bool:
    """Tangent-space normal maps average out to roughly (128, 128, 255): mid red/green, saturated blue."""
    try:
        from PIL import Image
        im = Image.open(path).convert("RGB").resize((32, 32))
    except Exception:
        return bool(NORMAL_NAME.search(path.name))
    px = list(im.tobytes())
    n = len(px) // 3
    r = sum(px[0::3]) / n
    g = sum(px[1::3]) / n
    b = sum(px[2::3]) / n
    return b > 190 and 100 < r < 160 and 100 < g < 160


def main():
    changed = 0
    normals = 0
    scanned = 0
    models = REPO / "assets" / "models"
    for folder in (models, REPO / "assets" / "textures"):
        for imp in folder.glob("*.import"):
            if not re.search(r"\.(jpg|jpeg|png)\.import$", imp.name, re.I):
                continue
            scanned += 1
            txt = imp.read_text(encoding="utf-8")
            if 'importer="texture"' not in txt:
                continue
            if "compress/mode=0" not in txt:
                continue  # already configured (by hand or by an earlier run): leave it alone
            src_name = imp.name[: -len(".import")]
            if src_name in KEEP_LOSSLESS:
                continue
            is_normal = looks_like_normal_map(imp.with_name(src_name))
            new = txt
            new = re.sub(r"compress/mode=\d", "compress/mode=2", new)
            new = re.sub(r"mipmaps/generate=\w+", "mipmaps/generate=true", new)
            if is_normal:
                new = re.sub(r"compress/normal_map=\d", "compress/normal_map=1", new)
            if src_name.startswith(HIGH_QUALITY_PREFIXES):
                # First-person weapons fill the screen: BC7 keeps them visually lossless at the same memory cost
                new = re.sub(r"compress/high_quality=\w+", "compress/high_quality=true", new)
            if new != txt:
                imp.write_text(new, encoding="utf-8", newline="\n")
                changed += 1
                if is_normal:
                    normals += 1
    print(f"texture imports scanned={scanned} changed={changed} (of which normal maps={normals})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
