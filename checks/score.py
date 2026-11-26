#!/usr/bin/env python3
"""Hill-climb visual score runner: captures 6 deterministic Godot 4.7 Forward+ shots,
stitches a 2x3 contact sheet, verifies zero errors, and runs the multi-provider judge panel.
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(r"C:\Users\trayn\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe")
JUDGE = Path(r"C:\Users\trayn\.t3\userdata\providers\antigravity\ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32\config\skills\hill-climb\scripts\judge.py")

SHOTS = [
    ("1. Asylum Lobby & Desk Lamps", "01_asylum_lobby.jpg"),
    ("2. Brick Tunnel & Flashlight", "02_tunnel_flashlight.jpg"),
    ("3. Snowy Path & Lantern Fog", "03_snow_courtyard.jpg"),
    ("4. ADS Sight Cabin Zombie", "04_ads_cabin_combat.jpg"),
    ("5. Zombie Horde Close-Up", "05_zombie_closeup.jpg"),
    ("6. Asylum Grand Staircase", "06_grand_staircase.jpg"),
]

HOLDOUT_SHOTS = [
    ("H1. Dark Room Barrels & Door", "h1_storage_barrels.jpg"),
    ("H2. Brick Archway & Rubble", "h2_tunnel_ambush.jpg"),
    ("H3. Snowy Fence & Pine Fog", "h3_fence_forest.jpg"),
]


def capture(mode: str, out_dir: Path, sheet_path: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(GODOT),
        "--path", str(ROOT),
        "--rendering-method", "forward_plus",
        "--rendering-driver", "d3d12",
        "--resolution", "1280x720",
        "--script", str(ROOT / "checks" / "capture_shots.gd"),
        "--",
        "--mode", mode,
        "--out", str(out_dir),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
    log_text = res.stdout + "\n" + res.stderr
    (out_dir / f"capture_{mode}.log").write_text(log_text, encoding="utf-8")
    if res.returncode != 0 or f"CAPTURE_COMPLETE mode={mode}" not in log_text:
        print(log_text[-2000:], file=sys.stderr)
        raise SystemExit(f"Godot capture failed (rc={res.returncode})")

    # Fail on any shader/script runtime error
    bad_lines = [l for l in log_text.splitlines() if any(k in l for k in ("SCRIPT ERROR:", "Shader compilation", "SHADER ERROR", "Parse Error:"))]
    if bad_lines:
        print("\n".join(bad_lines[:15]), file=sys.stderr)
        raise SystemExit(f"Godot logged {len(bad_lines)} runtime/shader errors!")

    items = HOLDOUT_SHOTS if mode == "holdout" else SHOTS
    cols = 3 if mode == "holdout" else 2
    tw, th, hdr = 640, 360, 26
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw, rows * (th + hdr)), "#101214")
    draw = ImageDraw.Draw(sheet)

    for idx, (label, fname) in enumerate(items):
        p = out_dir / fname
        if not p.is_file():
            raise SystemExit(f"Missing screenshot: {p}")
        im = Image.open(p).convert("RGB")
        arr = np.asarray(im, dtype=np.float32)
        mean_luma = float(arr.mean())
        std_luma = float(arr.std())
        print(f"  shot {fname}: mean={mean_luma:.1f} std={std_luma:.1f}", file=sys.stderr)
        if mean_luma < 1.5 or std_luma < 2.0:
            raise SystemExit(f"Shot {fname} appears blank/black (mean={mean_luma:.2f}, std={std_luma:.2f})")
        thumb = im.resize((tw, th), Image.Resampling.LANCZOS)
        x, y = (idx % cols) * tw, (idx // cols) * (th + hdr)
        sheet.paste(thumb, (x, y + hdr))
        draw.text((x + 10, y + 6), label, fill="#e6e8ea")

    sheet.save(sheet_path, quality=90)
    print(f"Stitched {sheet_path}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["visible", "holdout"], default="visible")
    ap.add_argument("--capture-only", action="store_true")
    ap.add_argument("--rounds", type=int, default=2)
    ap.add_argument("--panel", default="claude,codex")
    args = ap.parse_args()

    work = ROOT / ".hill-climb" / "bodycam-aaa"
    shots_dir = work / ("holdout_shots" if args.mode == "holdout" else "shots")
    sheet_path = work / ("holdout_candidate_sheet.jpg" if args.mode == "holdout" else "candidate_sheet.jpg")
    ref_path = ROOT / "checks" / ("holdout/holdout_ref_sheet.jpg" if args.mode == "holdout" else "refs/ref_sheet.jpg")
    notes_path = ROOT / ".hill-climb" / ("holdout-judge-notes.md" if args.mode == "holdout" else "judge-notes.md")

    capture(args.mode, shots_dir, sheet_path)
    if args.capture_only:
        return

    cmd = [
        sys.executable, str(JUDGE),
        "--rubric", str(ROOT / "checks" / "rubric.md"),
        "--candidate", str(sheet_path),
        "--reference", str(ref_path),
        "--panel", args.panel,
        "--rounds", str(args.rounds),
        "--notes", str(notes_path),
        "--timeout", "240",
    ]
    res = subprocess.run(cmd, text=True, encoding="utf-8", errors="replace")
    sys.exit(res.returncode)


if __name__ == "__main__":
    main()
