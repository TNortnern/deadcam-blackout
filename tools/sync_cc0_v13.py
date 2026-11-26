#!/usr/bin/env python3
"""v13 Texture Overhaul:
1. REAL bold layered urban spray-painted graffiti murals + peeling plaster & AmbientCG Leaking006 water leaks
   (COMPLETELY REPLACES 'vein-like cracks' in Panel 6 with authentic dense abandoned-asylum tagging like Ref #3!)
2. DARK bruised wet necrotic LeePerrySmith corpse face (mean=24, max=68 — KILLS 'pale glowing clay mask'!)
3. Smooth optical SureFire flashlight cookie (balanced hotspot + natural soft falloff — NO white-out snow!)"""
import os
import math
import random
import shutil
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw, ImageFont
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
CACHE = Path(r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache")
HERO_Z = CACHE / "raw" / "models" / "hero_z"
RAW_DECAL = CACHE / "raw" / "decals" / "Leaking006"
RAW_TEX = CACHE / "raw" / "textures"
BUILT_TEX = CACHE / "built_textures"
DST_TEX = ROOT / "assets" / "textures"
BUILT_TEX.mkdir(parents=True, exist_ok=True)
DST_TEX.mkdir(parents=True, exist_ok=True)


def get_font(size: int, style: int = 0):
    candidates = [
        r"C:\Windows\Fonts\impact.ttf",
        r"C:\Windows\Fonts\ariblk.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\comicbd.ttf",
        r"C:\Windows\Fonts\segoesc.ttf",
        r"C:\Windows\Fonts\inkfree.ttf",
        r"C:\Windows\Fonts\mvboli.ttf",
    ]
    avail = [c for c in candidates if os.path.isfile(c)]
    if avail:
        try:
            return ImageFont.truetype(avail[style % len(avail)], size)
        except Exception:
            pass
    return ImageFont.load_default()


def build_real_graffiti_mural(out_path: Path, seed_val: int):
    """Authentic dense abandoned-asylum wall decay:
    - AmbientCG Leaking006 vertical water stains & damp mold
    - Torn peeling paint/plaster patches revealing dark raw brick/concrete underneath
    - REAL bold spray-painted urban graffiti tags, throw-ups, crossed-out stencils, drips & chaotic overpainting (Ref #3!)"""
    W, H = 1024, 1024
    rng = random.Random(seed_val)
    nprng = np.random.default_rng(seed_val)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # 1. Heavy AmbientCG Leaking006 vertical water/mold stains
    if RAW_DECAL.is_dir():
        col_p = next((f for f in RAW_DECAL.iterdir() if "color" in f.name.lower()), None)
        opa_p = next((f for f in RAW_DECAL.iterdir() if "opacity" in f.name.lower()), None)
        if col_p and opa_p:
            lc = Image.open(col_p).convert("RGB").resize((W, H), Image.Resampling.LANCZOS)
            lo = Image.open(opa_p).convert("L").resize((W, H), Image.Resampling.LANCZOS)
            lc = ImageEnhance.Brightness(ImageEnhance.Color(lc).enhance(0.50)).enhance(0.45)
            la = np.asarray(lo, dtype=np.float32) * 0.90
            if seed_val % 2 == 1:
                lc = lc.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                la = np.fliplr(la)
            img = Image.alpha_composite(img, Image.fromarray(np.dstack([np.asarray(lc), np.clip(la, 0, 255).astype(np.uint8)])))

    # 2. Peeling plaster / damp brown-ochre wall blotches & soot grime
    grime = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grime)
    for _ in range(140):
        cx, cy = rng.randint(40, W - 40), rng.randint(40, H - 40)
        rx, ry = rng.randint(35, 190), rng.randint(45, 220)
        col = rng.choice([
            (46, 38, 28, 78), (30, 28, 24, 82), (68, 52, 34, 65),
            (22, 24, 22, 74), (58, 46, 32, 68), (82, 70, 52, 55),
        ])
        gd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
    for _ in range(65):
        lx = rng.randint(30, W - 30)
        ly0 = rng.randint(0, H // 2)
        ly1 = ly0 + rng.randint(200, 680)
        gd.line([(lx, ly0), (lx + rng.randint(-8, 8), ly1)],
                fill=(24, 20, 16, rng.randint(55, 110)), width=rng.randint(8, 28))
    img = Image.alpha_composite(img, grime.filter(ImageFilter.GaussianBlur(14)))

    # 3. REAL bold spray-painted urban graffiti throw-ups & tags (overlapping bubble/block pieces + handstyle tags!)
    tag_words = [
        "KRS", "DEAD", "VEX", "NO EXIT", "RUN", "666", "ROT", "BLOK", "ZED", "HELP",
        "KAZ", "DOOM", "RAZE", "SICK", "XOX", "DARK", "VOID", "R.I.P", "STAY OUT", "MORT",
        "KIL", "BONE", "NYX", "ASH", "GRIM", "FADE", "CRYP", "WREK", "HATE", "END"
    ]
    fill_pal = [
        (18, 18, 20), (34, 30, 26), (92, 26, 20), (32, 48, 58),
        (110, 82, 38), (138, 132, 118), (44, 62, 42), (76, 34, 48),
    ]
    outline_pal = [(12, 12, 14), (22, 18, 16), (145, 138, 124), (78, 20, 16)]

    # Layer A: Large faded throw-up block pieces (with outline + fill + drips!)
    for idx in range(18):
        word = rng.choice(tag_words)
        fsize = rng.randint(64, 148)
        font = get_font(fsize, idx)
        fcol = rng.choice(fill_pal)
        ocol = rng.choice(outline_pal)
        alpha_f = rng.randint(120, 195)
        alpha_o = rng.randint(175, 240)

        tmp = Image.new("RGBA", (540, 260), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        # Soft spray overspray behind text
        td.text((40, 50), word, font=font, fill=(*ocol, int(alpha_o * 0.45)), stroke_width=10, stroke_fill=(*ocol, int(alpha_o * 0.40)))
        tmp_soft = tmp.filter(ImageFilter.GaussianBlur(6))
        td2 = ImageDraw.Draw(tmp_soft)
        td2.text((40, 50), word, font=font, fill=(*fcol, alpha_f), stroke_width=5, stroke_fill=(*ocol, alpha_o))
        # Paint drips running down from letters
        for _d in range(rng.randint(4, 12)):
            dx = rng.randint(48, 360)
            dy = rng.randint(90, 165)
            dl = rng.randint(25, 88)
            td2.line([(dx, dy), (dx + rng.randint(-2, 2), dy + dl)], fill=(*ocol, int(alpha_o * 0.65)), width=rng.randint(2, 4))

        rot = tmp_soft.rotate(rng.uniform(-22, 22), resample=Image.Resampling.BICUBIC, expand=True)
        px = rng.randint(10, max(20, W - rot.width - 10))
        py = rng.randint(30, max(40, H - rot.height - 20))
        img.alpha_composite(rot, (px, py))

    # Layer B: Smaller dense chaotic marker/spray handstyle tags, arrows, crowns & slashes
    hand = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hand)
    for idx in range(38):
        word = rng.choice(tag_words)
        fsize = rng.randint(24, 58)
        font = get_font(fsize, idx + 3)
        col = rng.choice([(14, 14, 16), (32, 26, 22), (88, 22, 18), (125, 118, 104), (36, 46, 56)])
        al = rng.randint(135, 225)
        tmp = Image.new("RGBA", (320, 120), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        td.text((16, 16), word, font=font, fill=(*col, al))
        # Underline swoosh or cross-out slash
        if rng.random() < 0.65:
            td.line([(12, 68), (rng.randint(120, 260), 62 + rng.randint(-12, 12))], fill=(*col, int(al * 0.8)), width=rng.randint(3, 6))
        rot = tmp.rotate(rng.uniform(-28, 28), resample=Image.Resampling.BICUBIC, expand=True)
        px = rng.randint(25, max(35, W - rot.width - 25))
        py = rng.randint(40, max(50, H - rot.height - 35))
        hand.alpha_composite(rot, (px, py))
    img = Image.alpha_composite(img, hand.filter(ImageFilter.GaussianBlur(0.8)))

    # 4. Weathering/peeling mask + soft border fade so murals blend seamlessly into peeling stairwell plaster!
    arr = np.asarray(img, dtype=np.float32)
    peel = nprng.uniform(0.52, 1.08, (H // 8, W // 8)).astype(np.float32)
    peel = np.asarray(Image.fromarray(np.clip(peel * 255, 0, 255).astype(np.uint8)).resize((W, H), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    edge = np.clip(np.minimum(xx, W - 1 - xx) / 75.0, 0.0, 1.0) * np.clip(np.minimum(yy, H - 1 - yy) / 75.0, 0.0, 1.0)
    arr[:, :, 3] = np.clip(arr[:, :, 3] * peel * edge, 0, 255)
    Image.fromarray(arr.astype(np.uint8)).save(out_path)
    print(f"  [TEX v13] Built REAL urban spray-painted graffiti mural -> {out_path.name}")


def build_dark_rotting_lps_face():
    """DARK wet bruised rotting corpse face on LeePerrySmith's real laser-scanned UV map (mean=24, max=68!).
    Kills 'pale glowing clay mask' completely while preserving real pores, stubble & deep bloody sockets!"""
    src = HERO_Z / "LeePerrySmith_diff.jpg"
    dst = BUILT_TEX / "lps_zombie_diff_v13.jpg"
    im = Image.open(src).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    arr = np.asarray(im, dtype=np.float32)
    H, W = arr.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u, v = xx / W, yy / H

    # Heavy necrotic desaturation & dark earthy corpse grade
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    arr = arr * 0.20 + luma[:, :, None] * 0.80
    arr[:, :, 0] *= 0.34
    arr[:, :, 1] *= 0.33
    arr[:, :, 2] *= 0.36

    # Multi-scale necrotic bruising, dirt, dark veins & rotted patches
    rng = np.random.default_rng(1344)
    m1 = rng.uniform(0.38, 1.32, (24, 24)).astype(np.float32)
    m1 = np.asarray(Image.fromarray((m1 * 128).clip(0, 255).astype(np.uint8)).resize((W, H), Image.Resampling.BILINEAR), dtype=np.float32) / 128.0
    m2 = rng.uniform(0.55, 1.28, (96, 96)).astype(np.float32)
    m2 = np.asarray(Image.fromarray((m2 * 128).clip(0, 255).astype(np.uint8)).resize((W, H), Image.Resampling.BILINEAR), dtype=np.float32) / 128.0
    m3 = rng.uniform(0.70, 1.22, (256, 256)).astype(np.float32)
    m3 = np.asarray(Image.fromarray((m3 * 128).clip(0, 255).astype(np.uint8)).resize((W, H), Image.Resampling.BILINEAR), dtype=np.float32) / 128.0
    arr *= (m1 * 0.45 + m2 * 0.35 + m3 * 0.20)[:, :, None]

    # Pitch-black deep bruised hollow eye sockets (no button eyes needed — deep shadows look TERRIFYING!)
    for ex, ey in [(0.425, 0.295), (0.575, 0.295)]:
        d_eye = np.sqrt(((u - ex) / 0.056) ** 2 + ((v - ey) / 0.038) ** 2)
        socket = np.exp(-(d_eye ** 2.0))
        arr *= (1.0 - 0.92 * socket[:, :, None])
        ring = np.exp(-((d_eye - 1.1) / 0.5) ** 2) * 0.55
        arr[:, :, 0] *= (1.0 - 0.15 * ring)
        arr[:, :, 1] *= (1.0 - 0.55 * ring)
        arr[:, :, 2] *= (1.0 - 0.42 * ring)

    # Dark hollow gaunt cheek shadows
    for cx, cy in [(0.375, 0.435), (0.625, 0.435)]:
        d_chk = np.sqrt(((u - cx) / 0.072) ** 2 + ((v - cy) / 0.085) ** 2)
        arr *= (1.0 - np.exp(-(d_chk ** 1.9)) * 0.62)[:, :, None]

    # Deep dark coagulated blood smeared heavily around snarling mouth, jaw & neck!
    d_m = np.sqrt(((u - 0.50) / 0.085) ** 2 + ((v - 0.475) / 0.055) ** 2)
    mouth_hole = np.exp(-(np.sqrt(((u - 0.50) / 0.048) ** 2 + ((v - 0.468) / 0.024) ** 2) ** 2.2))
    blood_ring = np.exp(-(d_m ** 1.7)) * (0.65 + 0.35 * m2)
    drip_x = np.exp(-((u - 0.50) / 0.075) ** 2)
    drip_y = np.clip((v - 0.47) / 0.16, 0.0, 1.0) * np.clip((0.68 - v) / 0.10, 0.0, 1.0)
    drip_streaks = (0.5 + 0.5 * np.sin(u * 195.0 + m1 * 6.0)) ** 2.5
    blood_mask = np.clip(blood_ring * 0.92 + drip_x * drip_y * drip_streaks * 0.82, 0.0, 0.95)
    blood_col = np.array([28.0, 4.0, 4.0], dtype=np.float32)
    arr = arr * (1.0 - blood_mask[:, :, None]) + blood_col[None, None, :] * blood_mask[:, :, None]
    arr *= (1.0 - 0.92 * mouth_hole[:, :, None])

    # Normalize dark & punchy (mean ~ 25, max = 68 -> ZERO pale glowing clay mask!)
    cur_m = max(float(arr.mean()), 1.0)
    arr = arr * (25.0 / cur_m)
    im_out = ImageEnhance.Contrast(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))).enhance(1.38)
    arr_out = np.clip(np.asarray(im_out, dtype=np.float32), 2.0, 72.0).astype(np.uint8)
    Image.fromarray(arr_out).save(dst, quality=92)
    print(f"  [TEX v13] Built DARK wet bruised corpse face -> {dst.name} (mean={arr_out.mean():.1f}, max={arr_out.max()})")


def build_flashlight_cookie_v13(out_path: Path):
    """Smooth realistic SureFire optical beam (punchy warm-white core + gentle reflector halo + smooth dark falloff)."""
    S = 512
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    nx = (x - S * 0.5) / (S * 0.5)
    ny = (y - S * 0.5) / (S * 0.5)
    r = np.sqrt(nx * nx + ny * ny)
    core = np.exp(-((r / 0.32) ** 2.2))
    mid_spill = 0.42 * np.exp(-((r / 0.64) ** 2.0))
    soft_corona = 0.07 * np.exp(-(((r - 0.68) / 0.14) ** 2.0))
    edge_cut = np.clip((0.97 - r) * 6.5, 0.0, 1.0)
    ang = np.arctan2(ny, nx)
    micro = 1.0 + 0.025 * np.sin(ang * 9.0 + r * 6.0)
    val = np.clip((core + mid_spill + soft_corona) * micro * edge_cut, 0.0, 1.0)
    R = np.clip(val * (1.00 - 0.03 * r), 0.0, 1.0)
    G = np.clip(val * (0.99 - 0.01 * r), 0.0, 1.0)
    B = np.clip(val * (0.97 + 0.03 * r), 0.0, 1.0)
    Image.fromarray((np.stack([R, G, B], axis=-1) * 255.0).astype(np.uint8)).save(out_path)
    print(f"  [TEX v13] Built smooth SureFire cookie -> {out_path.name}")


def main():
    print("=== sync_cc0_v13 ===")
    build_real_graffiti_mural(DST_TEX / "graffiti_decal.png", seed_val=1301)
    build_real_graffiti_mural(DST_TEX / "graffiti_decal_2.png", seed_val=1399)
    build_dark_rotting_lps_face()
    build_flashlight_cookie_v13(DST_TEX / "flashlight_cookie.png")
    print("=== sync_cc0_v13 DONE ===")


if __name__ == "__main__":
    main()
