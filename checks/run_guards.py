#!/usr/bin/env python3
"""Regression guard runner: verifies zero script/shader errors & full playable gameplay loop."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(r"C:\Users\trayn\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe")

cmd = [
    str(GODOT),
    "--headless",
    "--path", str(ROOT),
    "--script", str(ROOT / "checks" / "gameplay_guard.gd"),
]
res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=90)
out = res.stdout + "\n" + res.stderr
bad = [l for l in out.splitlines() if any(k in l for k in ("SCRIPT ERROR:", "Parse Error:", "GUARD_FAIL"))]
if res.returncode != 0 or "GAMEPLAY_GUARD_PASS" not in out or bad:
    print(out[-2500:], file=sys.stderr)
    sys.exit(1)
print("GUARDS_OK: gameplay_guard passed cleanly with 0 script/parse errors")
