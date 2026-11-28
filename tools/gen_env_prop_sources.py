#!/usr/bin/env python3
"""Texture SOURCES for tools/build_env_props.py (run with system Python, needs Pillow + numpy).

Writes everything to the scratch dir (never into the repo):
  <SCRATCH>/src/<name>.jpg        raw generated surface photos (gemini-api image, skipped if present)
  <SCRATCH>/src/tile/<name>.jpg   lighting-flattened, seamless 1024px versions the Blender build samples
  <SCRATCH>/src/decal/<name>.png  Pillow-drawn dials, number plates, labels

Usage:  python tools/gen_env_prop_sources.py [--no-generate]
The API key is read for the gemini-api subprocess only and is never printed.
"""
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SCRATCH = r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache\polish\env_props"
SRC = os.path.join(SCRATCH, "src")
TILE = os.path.join(SRC, "tile")
DECAL = os.path.join(SRC, "decal")

SUFFIX = ("Flat orthographic top-down macro photograph filling the entire frame edge to edge, perfectly even "
          "diffuse overcast lighting, no shadows, no highlights, no perspective, no objects, no border, no text, "
          "uniform detail density everywhere, photorealistic PBR albedo texture scan.")

PROMPTS = {
    "rust_heavy": "Heavily corroded old steel plate completely covered in thick flaking rust, deep orange, red-brown and dark umber patches, pitted scaly oxide texture.",
    "rust_light": "Old mild steel sheet with a thin even layer of fine powdery surface rust, warm brown-orange with darker brown mottling and small pits.",
    "cast_iron": "Old sand-cast iron surface, very dark charcoal grey-black, fine grainy pitted casting texture with slight brown oxidation in the pits, matte.",
    "enamel_white": "Antique white vitreous porcelain enamel on steel, slightly yellowed off-white, extremely fine hairline crazing network, faint grey water stains, glossy coating but photographed without reflections.",
    "paint_cream": "Old institutional cream off-white oil paint on sheet steel, thick aged brushed coat, subtle yellowing, faint grime mottling and tiny hairline scratches, no bare metal, no chips.",
    "brass_old": "Old tarnished sheet brass, dull golden-brown patina with darker brown oxidation blotches and faint fine scratches, slight green-grey verdigris specks.",
    "steel_worn": "Old bare worn mild steel bar surface, mid grey gunmetal with dark mill scale patches, fine scratches and tiny brown rust freckles, matte.",
    "ticking_canvas": "Antique hospital mattress ticking fabric, heavy off-white cotton canvas with narrow evenly spaced vertical faded indigo-blue stripes, coarse visible weave, yellow-brown water stains and grime blotches.",
    "leather_strap": "Old dark brown harness leather, worn and dry with fine cracks and creases, slightly lighter scuffed areas, visible pores.",
    "coal_bed": "Bed of burnt coal and coke lumps with grey ash and clinker, dense tightly packed irregular black and dark grey chunks seen from directly above.",
    "soot_brick": "Old firebrick masonry wall in running bond blackened by soot and coal dust, dark grey-brown bricks, pale ash-grey mortar joints, bricks horizontal.",
    "lime_plaster_core": "Broken edge and back of old lime plaster, pale grey-cream crumbly sandy matrix with visible horsehair fibres and small aggregate grains, chalky.",
    "rubble_plaster": "Dense layer of small broken lime plaster chunks, chalky white-grey crumbs, plaster dust, splinters of old wood lath and grit, seen from directly above.",
    "galvanized": "Old galvanised zinc-coated steel sheet, dull grey with large faded crystalline spangle pattern, white oxide bloom and faint grey stains.",
    "oak_dark": "Old dark stained oak board furniture panel with straight horizontal grain, worn shellac varnish, deep brown, fine scratches and dull patches, grain running left to right.",
    "rubber_old": "Old perished dark grey-black rubber sheet, matte with fine cracking and pale dusty bloom.",
}


def _key():
    k = os.environ.get("GEMINI_API_KEY")
    if k:
        return k
    p = os.path.join(os.environ.get("LOCALAPPDATA", ""), "GeminiVideoFrames", "private", "api-key")
    with open(p, "r", encoding="utf-8") as f:
        return f.read().strip()


def generate():
    os.makedirs(SRC, exist_ok=True)
    env = None
    for name, prompt in PROMPTS.items():
        out = os.path.join(SRC, name + ".jpg")
        if os.path.isfile(out) and os.path.getsize(out) > 0:
            continue
        if env is None:
            env = dict(os.environ)
            env["GEMINI_API_KEY"] = _key()
        r = subprocess.run(["gemini-api", "image", prompt + " " + SUFFIX, "--aspect-ratio", "1:1",
                            "--image-size", "1K", "--out", out], env=env, capture_output=True, text=True)
        print(("generated " if r.returncode == 0 else "FAILED ") + name)


def _blur_wrap(a, r):
    """Gaussian blur with wrap-around borders."""
    h, w = a.shape[:2]
    p = int(r * 3)
    t = np.pad(a, ((p, p), (p, p), (0, 0)), mode="wrap")
    im = Image.fromarray(np.clip(t, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    return np.asarray(im, np.float32)[p:p + h, p:p + w]


# sources whose large-scale pattern IS the material (stains, coursing, stripes) keep more of their low frequencies
KEEP_LOW = {"ticking_canvas": 0.5, "soot_brick": 0.6, "brass_old": 0.6, "leather_strap": 0.6, "rust_heavy": 0.75,
            "coal_bed": 0.8, "rubble_plaster": 0.8}


def make_tile(name):
    flatten = KEEP_LOW.get(name, 1.0)
    im = Image.open(os.path.join(SRC, name + ".jpg")).convert("RGB").resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(im, np.float32)
    # 1. remove large-scale lighting / colour gradients (keeps the mean) so the cross-fade below leaves no patches
    low = _blur_wrap(a, 60)
    a = a - flatten * (low - a.mean((0, 1), keepdims=True))
    # 2. seamless: one axis at a time, cross-fade with a half-tile-shifted copy through a ragged band mask.
    #    (A single square mask would re-expose the shifted copy's own seam at the middle of every edge.)
    rng = np.random.RandomState(11)

    def tile_noise(cells):
        g = rng.rand(cells, cells).astype(np.float32)
        g = np.pad(g, 2, mode="wrap")
        big = np.asarray(Image.fromarray((g * 255).astype(np.uint8)).resize(((cells + 4) * (1024 // cells),) * 2, Image.BICUBIC),
                         np.float32) / 255.0
        o = 2 * (1024 // cells)
        return big[o:o + 1024, o:o + 1024]

    out = a
    for axis in (1, 0):
        n = tile_noise(8) * 0.6 + tile_noise(32) * 0.4
        c = np.abs(np.arange(1024, dtype=np.float32) - 511.5) / 512.0          # 0 at the centre line, 1 at the border
        d = c[None, :] if axis == 1 else c[:, None]
        m = np.clip((0.62 - d + (n - 0.5) * 0.55) / 0.10, 0, 1)[..., None]
        m = m * m * (3 - 2 * m)
        out = out * m + np.roll(out, 512, axis) * (1 - m)
    os.makedirs(TILE, exist_ok=True)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(TILE, name + ".jpg"), quality=93)


def _font(size, bold=False, serif=True):
    cands = (["georgiab.ttf", "timesbd.ttf"] if bold else ["georgia.ttf", "times.ttf"]) if serif else \
            (["arialbd.ttf"] if bold else ["arial.ttf"])
    for c in cands:
        p = os.path.join(r"C:\Windows\Fonts", c)
        if os.path.isfile(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def _ctext(d, xy, s, font, fill, anchor="mm"):
    d.text(xy, s, font=font, fill=fill, anchor=anchor)


def decal_dial(name, title, sub, lo, hi, step, minor, red_from, needle, unit):
    S = 1024
    im = Image.new("RGB", (S, S), (226, 219, 198))
    d = ImageDraw.Draw(im)
    c = S / 2
    d.ellipse([10, 10, S - 10, S - 10], outline=(30, 28, 26), width=10)
    a0, a1 = 225.0, -45.0  # degrees, counter-clockwise from +x; sweep 270
    def ang(v):
        return np.radians(a0 + (a1 - a0) * (v - lo) / (hi - lo))
    r_out = c - 60
    n_minor = int(round((hi - lo) / minor))
    for i in range(n_minor + 1):
        v = lo + i * minor
        major = abs((v - lo) / step - round((v - lo) / step)) < 1e-6
        a = ang(v)
        r_in = r_out - (62 if major else 30)
        col = (150, 24, 18) if v >= red_from else (24, 22, 20)
        d.line([c + np.cos(a) * r_in, c - np.sin(a) * r_in, c + np.cos(a) * r_out, c - np.sin(a) * r_out],
               fill=col, width=9 if major else 4)
        if major:
            _ctext(d, (c + np.cos(a) * (r_in - 58), c - np.sin(a) * (r_in - 58)), str(int(v)), _font(64, True), col)
    d.arc([c - r_out, c - r_out, c + r_out, c + r_out], -a0, -a1 + 0.0, fill=(24, 22, 20), width=5)
    _ctext(d, (c, c + 150), title, _font(58, True), (24, 22, 20))
    _ctext(d, (c, c + 220), unit, _font(40), (40, 36, 32))
    _ctext(d, (c, c - 170), sub, _font(30), (60, 54, 48))
    a = ang(needle)
    tip = (c + np.cos(a) * (r_out - 40), c - np.sin(a) * (r_out - 40))
    tail = (c - np.cos(a) * 90, c + np.sin(a) * 90)
    d.line([tail, tip], fill=(14, 13, 12), width=14)
    d.ellipse([c - 38, c - 38, c + 38, c + 38], fill=(60, 48, 28), outline=(20, 18, 16), width=4)
    os.makedirs(DECAL, exist_ok=True)
    im.filter(ImageFilter.GaussianBlur(1.2)).resize((512, 512), Image.LANCZOS).save(os.path.join(DECAL, name + ".png"))


def decal_number(n):
    W, H = 512, 384
    im = Image.new("RGB", (W, H), (16, 18, 22))
    d = ImageDraw.Draw(im)
    d.ellipse([6, 6, W - 6, H - 6], fill=(232, 228, 214))
    d.ellipse([26, 26, W - 26, H - 26], outline=(18, 20, 30), width=10)
    _ctext(d, (W / 2, H / 2 - 6), str(n), _font(250, True), (18, 20, 30))
    im.filter(ImageFilter.GaussianBlur(1.0)).resize((256, 192), Image.LANCZOS).save(os.path.join(DECAL, f"num_{n}.png"))


def decal_redcross():
    S = 768
    im = Image.new("RGB", (S, S), (233, 229, 216))
    d = ImageDraw.Draw(im)
    d.rectangle([22, 22, S - 22, S - 22], outline=(26, 26, 30), width=9)
    c, a, b = S / 2, 215, 78
    d.rectangle([c - b, c - a, c + b, c + a], fill=(158, 22, 20))
    d.rectangle([c - a, c - b, c + a, c + b], fill=(158, 22, 20))
    _ctext(d, (c, 92), "DISPENSARY", _font(62, True), (26, 26, 30))
    _ctext(d, (c, S - 92), "WARD  ISSUE", _font(52, True), (26, 26, 30))
    im.filter(ImageFilter.GaussianBlur(1.0)).resize((384, 384), Image.LANCZOS).save(os.path.join(DECAL, "redcross.png"))


def decal_plate(name, lines, size=(768, 512), fg=(196, 160, 92), bg=(26, 24, 22), oval=True):
    W, H = size
    im = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(im)
    if oval:
        d.ellipse([14, 14, W - 14, H - 14], outline=fg, width=12)
    else:
        d.rectangle([14, 14, W - 14, H - 14], outline=fg, width=10)
    n = len(lines)
    for i, (s, px, bold) in enumerate(lines):
        y = H / 2 + (i - (n - 1) / 2) * (H * 0.62 / max(n, 1))
        _ctext(d, (W / 2, y), s, _font(px, bold), fg)
    im.filter(ImageFilter.GaussianBlur(1.1)).resize((W // 2, H // 2), Image.LANCZOS).save(os.path.join(DECAL, name + ".png"))


def decal_label(name, title, sub, poison=False):
    W, H = 384, 320
    paper = (214, 200, 164)
    ink = (120, 22, 18) if poison else (34, 30, 28)
    im = Image.new("RGB", (W, H), paper)
    d = ImageDraw.Draw(im)
    d.rectangle([10, 10, W - 10, H - 10], outline=ink, width=6)
    d.rectangle([22, 22, W - 22, H - 22], outline=ink, width=2)
    _ctext(d, (W / 2, 92), title, _font(54, True), ink)
    d.line([60, 140, W - 60, 140], fill=ink, width=3)
    _ctext(d, (W / 2, 186), sub, _font(34), ink)
    _ctext(d, (W / 2, 252), "POISON" if poison else "ASYLUM  DISPENSARY", _font(40 if poison else 22, True), ink)
    im.filter(ImageFilter.GaussianBlur(0.9)).resize((W // 2, H // 2), Image.LANCZOS).save(os.path.join(DECAL, name + ".png"))


def decals():
    os.makedirs(DECAL, exist_ok=True)
    decal_dial("dial_steam", "STEAM", "HARTWELL & SONS  ENGINEERS", 0, 200, 40, 10, 160, 6, "LBS PER SQ. INCH")
    decal_dial("dial_thermo", "COLD ROOM", "THERMOMETER", -10, 70, 10, 5, 50, 46, "DEG. FAHR.")
    for n in range(1, 7):
        decal_number(n)
    decal_redcross()
    decal_plate("plate_boiler", [("HARTWELL & SONS", 62, True), ("BOILER MAKERS", 44, False),
                                 ("No. 1147    1908", 50, True), ("W.P. 160 LBS", 40, False)])
    decal_plate("plate_cold", [("MORTUARY", 64, True), ("COLD CHAMBER", 50, True), ("PATENT No. 20391", 34, False)],
                size=(768, 384), oval=False)
    decal_plate("plate_dispense", [("DISPENSE", 70, True)], size=(640, 160), fg=(40, 30, 16), bg=(176, 138, 66), oval=False)
    decal_label("label_a", "TINCT. OPII", "Laudanum")
    decal_label("label_b", "ÆTHER", "Sulph. Rect.")
    decal_label("label_c", "ACID. CARBOL.", "Liq. 1 in 20", poison=True)
    decal_label("label_d", "CHLORAL", "Hydrat. gr. xx")
    # blank ruled mortuary card
    im = Image.new("RGB", (228, 128), (206, 196, 164))
    d = ImageDraw.Draw(im)
    d.rectangle([3, 3, 224, 124], outline=(60, 54, 48), width=1)
    _ctext(d, (114, 20), "NAME                    No.", _font(13, True), (50, 44, 40))
    for yy in (44, 68, 92, 112):
        d.line([14, yy, 214, yy], fill=(90, 84, 76), width=1)
    d.line([22, 60, 150, 52], fill=(40, 40, 70), width=2)
    d.line([22, 86, 110, 80], fill=(40, 40, 70), width=2)
    im.save(os.path.join(DECAL, "label_blank.png"))


def main():
    if "--no-generate" not in sys.argv:
        generate()
    for name in PROMPTS:
        if os.path.isfile(os.path.join(SRC, name + ".jpg")):
            make_tile(name)
        else:
            print("MISSING source photo:", name)
    decals()
    print("sources ready in", SRC)


if __name__ == "__main__":
    main()
