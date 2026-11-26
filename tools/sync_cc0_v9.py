#!/usr/bin/env python3
"""Sync & prepare v9 AAA Poly Haven 2K PBR textures:
- Pale weathered dusty plaster for Panel 6 stairwell so dark carved balusters & bold graffiti POP!
- Desaturated weathered driftwood oak (kills 'smooth orange wood' critique!)
- Wide blazing SureFire flashlight cookie (strong close-range hotspot + soft reflector corona ring!)
- Dark sunken-eyed bloody necrotic corpse face (NO glowing white eyes or cartoon white chin!)"""
import os
import shutil
import math
import random
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
CACHE = Path(r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache")
RAW_TEX = CACHE / "raw" / "textures"
RAW_DECAL = CACHE / "raw" / "decals" / "Leaking006"
RAW_ZHEAD = CACHE / "raw" / "zombie_head_orig" / "img_1.png"
BUILT_TEX = CACHE / "built_textures"
BUILT_MOD = CACHE / "built_models"
DST_TEX = ROOT / "assets" / "textures"
DST_MOD = ROOT / "assets" / "models"

BUILT_TEX.mkdir(parents=True, exist_ok=True)
DST_TEX.mkdir(parents=True, exist_ok=True)
DST_MOD.mkdir(parents=True, exist_ok=True)


def find_ch(tex_dir: Path, names):
    for n in names:
        for ext in ("jpg", "png"):
            p = tex_dir / f"{n}.{ext}"
            if p.is_file():
                return p
    for f in tex_dir.iterdir():
        fl = f.name.lower()
        if any(n.lower() in fl for n in names) and f.suffix.lower() in (".jpg", ".png"):
            return f
    return None


def save_jpg(im: Image.Image, path: Path, size=1024, quality=88):
    if im.size != (size, size):
        im = im.resize((size, size), Image.Resampling.LANCZOS)
    im.convert("RGB").save(path, quality=quality, optimize=True)


def build_pbr_set(src_name: str, dst_prefix: str, size=1024, dark=1.0, sat=1.0,
                  tint=(1.0, 1.0, 1.0), rough_shift=0.0, force=False):
    src = RAW_TEX / src_name
    if not src.is_dir():
        return
    alb_dst = BUILT_TEX / f"{dst_prefix}_albedo.jpg"
    if alb_dst.is_file() and not force:
        return

    alb_p = find_ch(src, ["Diffuse", "diff", "albedo", "col"])
    nor_p = find_ch(src, ["nor_gl", "normal", "nor"])
    rgh_p = find_ch(src, ["Rough", "rough", "arm"])
    ao_p = find_ch(src, ["AO", "ao"])
    dsp_p = find_ch(src, ["Displacement", "disp", "height"])

    if alb_p:
        im = Image.open(alb_p).convert("RGB")
        if sat != 1.0:
            im = ImageEnhance.Color(im).enhance(sat)
        if dark != 1.0:
            im = ImageEnhance.Brightness(im).enhance(dark)
        if tint != (1.0, 1.0, 1.0):
            arr = np.asarray(im, dtype=np.float32)
            arr[:, :, 0] *= tint[0]
            arr[:, :, 1] *= tint[1]
            arr[:, :, 2] *= tint[2]
            im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
        save_jpg(im, alb_dst, size)

    if nor_p:
        save_jpg(Image.open(nor_p), BUILT_TEX / f"{dst_prefix}_normal.jpg", size)
    if rgh_p:
        im = Image.open(rgh_p).convert("L")
        if rough_shift != 0.0:
            arr = np.clip(np.asarray(im, dtype=np.float32) + rough_shift * 255.0, 20, 250).astype(np.uint8)
            im = Image.fromarray(arr)
        save_jpg(im, BUILT_TEX / f"{dst_prefix}_rough.jpg", size)
    else:
        save_jpg(Image.new("L", (size, size), 185), BUILT_TEX / f"{dst_prefix}_rough.jpg", size)
    if ao_p:
        save_jpg(Image.open(ao_p).convert("L"), BUILT_TEX / f"{dst_prefix}_ao.jpg", size)
    else:
        save_jpg(Image.new("L", (size, size), 220), BUILT_TEX / f"{dst_prefix}_ao.jpg", size)
    if dsp_p:
        save_jpg(Image.open(dsp_p).convert("L"), BUILT_TEX / f"{dst_prefix}_disp.jpg", size)
    else:
        save_jpg(Image.new("L", (size, size), 128), BUILT_TEX / f"{dst_prefix}_disp.jpg", size)
    print(f"  [TEX v9] Built {dst_prefix} <- {src_name}")


def build_layered_decay_mural(out_path: Path, seed_val: int):
    """Bold high-contrast peeling paint, AmbientCG Leaking006 damp stains & dense overlapping urban wildstyle
    graffiti designed to POP dramatically on pale weathered plaster (exact Ref #3 staircase wall!)."""
    W, H = 1024, 1024
    rng = random.Random(seed_val)
    nprng = np.random.default_rng(seed_val)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    if RAW_DECAL.is_dir():
        col_p = next((f for f in RAW_DECAL.iterdir() if "color" in f.name.lower()), None)
        opa_p = next((f for f in RAW_DECAL.iterdir() if "opacity" in f.name.lower()), None)
        if col_p and opa_p:
            lc = Image.open(col_p).convert("RGB").resize((W, H), Image.Resampling.LANCZOS)
            lo = Image.open(opa_p).convert("L").resize((W, H), Image.Resampling.LANCZOS)
            lc = ImageEnhance.Brightness(ImageEnhance.Color(lc).enhance(0.55)).enhance(0.50)
            la = np.asarray(lo, dtype=np.float32) * 0.85
            if seed_val % 2 == 1:
                lc = lc.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                la = np.fliplr(la)
            leak_rgba = np.dstack([np.asarray(lc), np.clip(la, 0, 255).astype(np.uint8)])
            img = Image.alpha_composite(img, Image.fromarray(leak_rgba))

    grime = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grime)
    for _ in range(160):
        cx, cy = rng.randint(20, W - 20), rng.randint(20, H - 20)
        rx, ry = rng.randint(25, 165), rng.randint(35, 220)
        col = rng.choice([
            (40, 36, 28, 65), (24, 24, 22, 72), (62, 50, 34, 55),
            (18, 20, 18, 68), (52, 44, 34, 58),
        ])
        gd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
    for _ in range(85):
        lx = rng.randint(20, W - 20)
        ly0 = rng.randint(0, H // 2)
        ly1 = ly0 + rng.randint(180, 620)
        gd.line([(lx, ly0), (lx + rng.randint(-12, 12), ly1)],
                fill=(22, 20, 17, rng.randint(52, 102)), width=rng.randint(6, 24))
    grime = grime.filter(ImageFilter.GaussianBlur(12))
    img = Image.alpha_composite(img, grime)

    soft = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    core = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds = ImageDraw.Draw(soft)
    dc = ImageDraw.Draw(core)

    def spray_curve(pts, w, rgb, alpha):
        cs = (rgb[0], rgb[1], rgb[2], int(alpha * 0.50))
        cc = (rgb[0], rgb[1], rgb[2], alpha)
        for i in range(len(pts) - 1):
            p0, p1 = pts[i], pts[i + 1]
            ds.line([p0, p1], fill=cs, width=int(w * 2.5))
            dc.line([p0, p1], fill=cc, width=w)
            if rng.random() < 0.18:
                dl = rng.randint(22, 110)
                dc.line([p1, (p1[0] + rng.uniform(-3, 3), p1[1] + dl)],
                        fill=(rgb[0], rgb[1], rgb[2], int(alpha * 0.68)), width=max(2, w // 3))

    # Rich dense dark charcoal, dried rust, faded blue-slate & ochre urban wildstyle graffiti tags
    tag_colors = [
        (12, 12, 14), (24, 22, 20), (68, 22, 16), (28, 36, 44),
        (82, 58, 30), (14, 14, 16), (48, 36, 26),
    ]
    for _ in range(44):
        ox = rng.randint(60, W - 160)
        oy = rng.randint(75, H - 120)
        col = rng.choice(tag_colors)
        alpha = rng.randint(165, 240)
        w = rng.randint(6, 15)
        pts = [(ox, oy)]
        x, y = ox, oy
        for _s in range(rng.randint(8, 22)):
            ang = rng.uniform(-2.4, 2.4)
            step = rng.uniform(18, 66)
            x = max(30, min(W - 30, x + math.cos(ang) * step + rng.uniform(4, 18)))
            y = max(30, min(H - 30, y + math.sin(ang) * step))
            pts.append((x, y))
        spray_curve(pts, w, col, alpha)

    sp_arr = np.asarray(soft.filter(ImageFilter.GaussianBlur(7)), dtype=np.float32)
    co_arr = np.asarray(core.filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32)
    peel = nprng.uniform(0.48, 1.05, (H // 6, W // 6)).astype(np.float32)
    peel = np.asarray(Image.fromarray(np.clip(peel * 255, 0, 255).astype(np.uint8)).resize((W, H), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    edge_fade = np.clip(np.minimum(xx, W - 1 - xx) / 85.0, 0.0, 1.0) * np.clip(np.minimum(yy, H - 1 - yy) / 85.0, 0.0, 1.0)

    sp_arr[:, :, 3] *= peel * edge_fade
    co_arr[:, :, 3] *= np.clip(peel * 1.15, 0.0, 1.0) * edge_fade
    img_arr = np.asarray(img, dtype=np.float32)
    img_arr[:, :, 3] *= edge_fade
    img = Image.fromarray(np.clip(img_arr, 0, 255).astype(np.uint8))
    img = Image.alpha_composite(img, Image.fromarray(np.clip(sp_arr, 0, 255).astype(np.uint8)))
    img = Image.alpha_composite(img, Image.fromarray(np.clip(co_arr, 0, 255).astype(np.uint8)))
    img.save(out_path)
    print(f"  [TEX v9] Built high-contrast layered decay/graffiti -> {out_path.name}")


def build_zombie_textures():
    """Gritty, deeply anatomical, non-glowing rotting corpse face (crushes white eyes/chin glow!) + flecktarn camo."""
    if RAW_ZHEAD.is_file():
        im = Image.open(RAW_ZHEAD).convert("RGB")
        arr = np.asarray(im, dtype=np.float32)
        # Identify abnormally bright pixels in original texture (eyeballs & inner mouth glow!) and crush them dark!
        luma_raw = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
        # Any super-bright eyeball/specular blob (> 185 in raw image) gets darkened into hollow rotting shadow/dried blood!
        bright_mask = np.clip((luma_raw - 165.0) / 55.0, 0.0, 1.0)
        arr = arr * (1.0 - 0.68 * bright_mask[:, :, None])
        # Desaturate + darken to realistic bruised pale-grey decaying flesh with deep crimson blood contrast
        im2 = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
        im2 = ImageEnhance.Color(im2).enhance(0.52)
        im2 = ImageEnhance.Contrast(im2).enhance(1.42)
        arr = np.asarray(im2, dtype=np.float32)
        cur_m = max(float(arr.mean()), 1.0)
        arr = arr * (38.0 / cur_m)
        # Add realistic mottling, bruised dark veins & blood grime across the UV map
        rng = np.random.default_rng(9101)
        mottle = rng.uniform(0.72, 1.18, (128, 128)).astype(np.float32)
        mottle = np.asarray(Image.fromarray((mottle * 128).clip(0, 255).astype(np.uint8)).resize((arr.shape[1], arr.shape[0]), Image.Resampling.BILINEAR), dtype=np.float32) / 128.0
        arr *= mottle[:, :, None]
        # Cool bruised corpse tint + hard cap max=92 so flashlight at 1.2m NEVER blows out glowing white!
        arr[:, :, 0] *= 0.96
        arr[:, :, 1] *= 0.94
        arr[:, :, 2] *= 1.00
        arr = np.clip(arr, 3.0, 92.0)
        Image.fromarray(arr.astype(np.uint8)).save(BUILT_TEX / "zh_rotting_head_v9.jpg", quality=92)

        lum = np.mean(arr, axis=2) / 255.0
        gx = np.roll(lum, -1, axis=1) - np.roll(lum, 1, axis=1)
        gy = np.roll(lum, -1, axis=0) - np.roll(lum, 1, axis=0)
        nz = np.ones_like(gx) * 0.14
        norm = np.stack([-gx * 3.8, -gy * 3.8, nz], axis=-1)
        norm /= np.linalg.norm(norm, axis=-1, keepdims=True) + 1e-6
        Image.fromarray(((norm * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)).save(
            BUILT_TEX / "zh_rotting_head_v9_normal.jpg", quality=90
        )
        print(f"  [TEX v9] Built dark bruised corpse face (NO glowing eyes!) -> zh_rotting_head_v9.jpg (mean={arr.mean():.1f}, max={arr.max():.1f})")

    # Dark gritty charcoal-olive flecktarn parka (kills bright washed-out camo on close-up zombies!)
    suit_src = BUILT_TEX / "zh_tactical_suit.jpg"
    if suit_src.is_file():
        im_s = Image.open(suit_src).convert("RGB")
        arr_s = np.asarray(im_s, dtype=np.float32)
        cur_sm = max(float(arr_s.mean()), 1.0)
        # Normalize target mean to ~26 (deep dark wet military cloth like Ref #4!)
        arr_s = arr_s * (26.0 / cur_sm)
        im_s = ImageEnhance.Color(Image.fromarray(np.clip(arr_s, 0, 255).astype(np.uint8))).enhance(0.62)
        im_s.save(BUILT_TEX / "zh_tactical_suit_v9.jpg", quality=90)
        print(f"  [TEX v9] Built dark wet parka camo -> zh_tactical_suit_v9.jpg (mean={np.asarray(im_s).mean():.1f})")

    # Slightly readable bruised grey flesh for 18.5K leo_zombie (so his sculpted face & clawed hand read crisply!)
    if (BUILT_TEX / "zh_rotting_head_v9.jpg").is_file():
        im_l = Image.open(BUILT_TEX / "zh_rotting_head_v9.jpg").convert("RGB")
        im_l = ImageEnhance.Brightness(im_l).enhance(1.35)
        im_l.save(BUILT_TEX / "zh_leo_flesh_v9.jpg", quality=90)


def build_flashlight_cookie(out_path: Path):
    """Focused, punchy SureFire tactical LED beam:
    Crisp bright center hotspot (r/0.30) + subtle reflector corona ring (r=0.62) + gentle dark spill!"""
    S = 512
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    nx = (x - S * 0.5) / (S * 0.5)
    ny = (y - S * 0.5) / (S * 0.5)
    r = np.sqrt(nx * nx + ny * ny)
    core = np.exp(-((r / 0.30) ** 2.4))
    ring = 0.20 * np.exp(-(((r - 0.62) / 0.12) ** 2.0))
    spill = 0.18 * np.clip(1.0 - r / 0.96, 0.0, 1.0) ** 1.65
    ang = np.arctan2(ny, nx)
    micro = 1.0 + 0.03 * np.sin(ang * 11.0 + r * 8.0)
    val = np.clip((core + ring + spill) * micro * np.clip((1.0 - r) * 9.0, 0.0, 1.0), 0.0, 1.0)
    R = np.clip(val * (0.99 - 0.04 * r), 0.0, 1.0)
    G = np.clip(val * (0.99 - 0.01 * r), 0.0, 1.0)
    B = np.clip(val * (1.00 + 0.04 * r), 0.0, 1.0)
    Image.fromarray((np.stack([R, G, B], axis=-1) * 255.0).astype(np.uint8)).save(out_path)
    print(f"  [TEX v9] Built focused SureFire flashlight cookie -> {out_path.name}")


def main():
    print("=== sync_cc0_v9 ===")
    # PALE dusty weathered plaster for Panel 6 stairwell so dark carved balusters & bold graffiti POP!
    build_pbr_set("grey_plaster_02", "plaster_peeling", 1024, dark=1.08, sat=0.35, tint=(0.95, 0.95, 0.89), force=True)
    build_pbr_set("plaster_brick_01", "plaster_brick", 1024, dark=0.92, sat=0.42, tint=(0.92, 0.92, 0.88), force=True)
    build_pbr_set("herringbone_parquet", "parquet_worn", 1024, dark=0.92, sat=0.58, tint=(0.94, 0.90, 0.84), rough_shift=-0.18, force=True)
    build_pbr_set("broken_brick_wall", "brick_vault", 1024, dark=1.05, sat=0.68, tint=(0.98, 0.92, 0.86), force=True)
    build_pbr_set("brick_gravel", "tunnel_rubble", 1024, dark=1.10, sat=0.58, tint=(0.98, 0.95, 0.92), rough_shift=-0.20, force=True)
    build_pbr_set("concrete_debris", "concrete_rubble", 1024, dark=0.96, sat=0.50, force=True)
    build_pbr_set("brown_planks_05", "timber_weathered", 1024, dark=0.50, sat=0.45, tint=(0.88, 0.85, 0.80), force=True)
    # DESATURATED weathered aged oak (eliminates 'smooth orange wood' in Panel 6 & Panel 1!)
    build_pbr_set("wood_floor_worn", "wood_carved", 1024, dark=0.64, sat=0.38, tint=(0.88, 0.85, 0.80), rough_shift=-0.10, force=True)
    build_pbr_set("box_profile_metal_sheet", "corrugated_roof", 1024, dark=0.42, sat=0.50, tint=(0.88, 0.85, 0.82), force=True)
    build_pbr_set("brown_mud_leaves_01", "mud_rocks", 1024, dark=0.54, sat=0.60, rough_shift=-0.18, force=True)
    build_pbr_set("snow_02", "snow_pure", 1024, dark=1.02, sat=0.76, tint=(0.96, 0.98, 1.03), force=True)
    build_pbr_set("brown_mud_rocks_01", "snow_mud", 1024, dark=0.72, sat=0.68, force=True)
    build_pbr_set("bark_brown_02", "bark_pine", 1024, dark=0.56, sat=0.58, force=True)
    build_pbr_set("metal_plate_02", "metal_tactical", 1024, dark=0.50, sat=0.48, force=True)
    build_pbr_set("brown_floor_tiles", "tile_asylum", 1024, dark=0.60, sat=0.58, force=True)
    build_pbr_set("wood_planks_dirt", "barrel_oak", 1024, dark=0.66, sat=0.62, force=True)
    build_pbr_set("denim_fabric_04", "tactical_cloth", 1024, dark=0.42, sat=0.48, force=True)

    build_layered_decay_mural(DST_TEX / "graffiti_decal.png", seed_val=7101)
    build_layered_decay_mural(DST_TEX / "graffiti_decal_2.png", seed_val=8209)
    build_zombie_textures()
    build_flashlight_cookie(DST_TEX / "flashlight_cookie.png")

    copied_tex = 0
    for f in BUILT_TEX.glob("*.jpg"):
        shutil.copy2(f, DST_TEX / f.name)
        copied_tex += 1
    for f in BUILT_TEX.glob("*.png"):
        shutil.copy2(f, DST_TEX / f.name)
        copied_tex += 1
    print(f"  [SYNC v9] copied {copied_tex} textures into assets/textures/")

    copied_mod = 0
    for f in BUILT_MOD.glob("*.glb"):
        shutil.copy2(f, DST_MOD / f.name)
        copied_mod += 1
    print(f"  [SYNC v9] copied {copied_mod} cached GLBs into assets/models/")
    print("=== sync_cc0_v9 DONE ===")


if __name__ == "__main__":
    main()
