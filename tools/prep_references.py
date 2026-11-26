#!/usr/bin/env python3
"""Build locked reference contact sheets from extracted YouTube Bodycam frames."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
REF_SRC = ROOT / "reference_frames"
VISIBLE_OUT = ROOT / "checks" / "refs"
HOLDOUT_OUT = ROOT / "checks" / "holdout"
VISIBLE_OUT.mkdir(parents=True, exist_ok=True)
HOLDOUT_OUT.mkdir(parents=True, exist_ok=True)

VISIBLE = [
    ("1. Asylum Lobby & Desk Lamps", "000364000ms.png"),
    ("2. Brick Tunnel & Flashlight", "000186000ms.png"),
    ("3. Snowy Path & Lantern Fog", "000178000ms.png"),
    ("4. ADS Sight Cabin Zombie", "000324000ms.png"),
    ("5. Zombie Horde Close-Up", "000036000ms.png"),
    ("6. Asylum Grand Staircase", "000015000ms.png"),
]

HOLDOUT = [
    ("H1. Dark Room Barrels & Door", "000534000ms.png"),
    ("H2. Brick Archway & Rubble", "000049000ms.png"),
    ("H3. Snowy Fence & Pine Fog", "000074000ms.png"),
]


def make_sheet(items, cols, out_path: Path):
    tw, th, hdr = 640, 360, 26
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw, rows * (th + hdr)), "#101214")
    draw = ImageDraw.Draw(sheet)
    for idx, (label, fname) in enumerate(items):
        im = Image.open(REF_SRC / fname).convert("RGB").resize((tw, th), Image.Resampling.LANCZOS)
        x, y = (idx % cols) * tw, (idx // cols) * (th + hdr)
        sheet.paste(im, (x, y + hdr))
        draw.text((x + 10, y + 6), label, fill="#e6e8ea")
    sheet.save(out_path, quality=88)
    print(f"Saved {out_path} ({out_path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    make_sheet(VISIBLE, 2, VISIBLE_OUT / "ref_sheet.jpg")
    make_sheet(HOLDOUT, 3, HOLDOUT_OUT / "holdout_ref_sheet.jpg")
