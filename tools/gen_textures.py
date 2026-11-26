#!/usr/bin/env python3
"""Synthesize high-resolution, photorealistic PBR texture sets for DEADCAM: BLACKOUT.
Generates albedo, normal (from heightfield via Scharr/Sobel), roughness, and AO maps
at 1024x1024 using tileable periodic multi-octave noise, architectural patterns,
organic weathering, damp streaks, and realistic specular variation.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter

OUT = Path(__file__).resolve().parents[1] / "assets" / "textures"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 1024


def tileable_noise(size: int, freq: int, seed: int) -> np.ndarray:
    """Periodic value noise tiled seamlessly via FFT/bicubic upsampling."""
    rng = np.random.default_rng(seed)
    grid = rng.random((freq, freq)).astype(np.float32)
    # Periodic smooth upsampling by tiling 3x3 then cropping center
    tiled = np.tile(grid, (3, 3))
    im = Image.fromarray((tiled * 255).astype(np.uint8), mode="L")
    up = im.resize((size * 3, size * 3), Image.Resampling.BICUBIC)
    arr = np.asarray(up, dtype=np.float32)[size:2 * size, size:2 * size] / 255.0
    return arr


def fbm(size: int, freqs, weights, seed: int) -> np.ndarray:
    acc = np.zeros((size, size), dtype=np.float32)
    total = 0.0
    for i, (f, w) in enumerate(zip(freqs, weights)):
        acc += tileable_noise(size, f, seed + i * 97) * w
        total += w
    return np.clip(acc / max(total, 1e-6), 0.0, 1.0)


def ridge_noise(size: int, freqs, weights, seed: int) -> np.ndarray:
    acc = np.zeros((size, size), dtype=np.float32)
    total = 0.0
    for i, (f, w) in enumerate(zip(freqs, weights)):
        n = tileable_noise(size, f, seed + i * 131)
        r = 1.0 - np.abs(n * 2.0 - 1.0)
        acc += (r ** 2) * w
        total += w
    return np.clip(acc / max(total, 1e-6), 0.0, 1.0)


def height_to_normal(height: np.ndarray, strength: float = 4.0) -> np.ndarray:
    """Compute crisp OpenGL/Godot tangent-space normal map from tileable heightfield."""
    h = height.astype(np.float32)
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5
    dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5
    # Add medium-scale slope for richer relief
    hb = gaussian_filter(h, sigma=1.4, mode="wrap")
    dx += (np.roll(hb, -1, axis=1) - np.roll(hb, 1, axis=1)) * 0.5
    dy += (np.roll(hb, -1, axis=0) - np.roll(hb, 1, axis=0)) * 0.5
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(h)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz + 1e-8)
    rgb = np.stack([
        (nx * inv * 0.5 + 0.5),
        (ny * inv * 0.5 + 0.5),
        (nz * inv * 0.5 + 0.5),
    ], axis=-1)
    return np.clip(rgb * 255.0, 0, 255).astype(np.uint8)


def height_to_ao(height: np.ndarray, radius: float = 6.0, strength: float = 1.6) -> np.ndarray:
    blur = gaussian_filter(height.astype(np.float32), sigma=radius, mode="wrap")
    cavity = np.clip((height - blur) * strength + 0.82, 0.15, 1.0)
    return np.clip(cavity * 255.0, 0, 255).astype(np.uint8)


def save_pbr(name: str, albedo: np.ndarray, height: np.ndarray, rough: np.ndarray,
             normal_strength: float = 5.0, ao_override=None):
    Image.fromarray(np.clip(albedo, 0, 255).astype(np.uint8), mode="RGB").save(
        OUT / f"{name}_albedo.jpg", quality=92)
    Image.fromarray(height_to_normal(height, normal_strength), mode="RGB").save(
        OUT / f"{name}_normal.jpg", quality=95)
    Image.fromarray(np.clip(rough * 255.0, 0, 255).astype(np.uint8), mode="L").save(
        OUT / f"{name}_rough.jpg", quality=90)
    ao = ao_override if ao_override is not None else height_to_ao(height)
    Image.fromarray(np.clip(ao, 0, 255).astype(np.uint8), mode="L").save(
        OUT / f"{name}_ao.jpg", quality=90)
    print(f"  saved PBR set: {name}")


def lerp3(c1, c2, t):
    t = np.clip(t, 0.0, 1.0)[..., None]
    return np.array(c1, dtype=np.float32) * (1.0 - t) + np.array(c2, dtype=np.float32) * t


def gen_plaster_peeling():
    """Authentic decaying asylum plaster: broad damp yellowed concrete/limewash, fine cracks, subtle flaking (NO wallpaper blobs!)."""
    s = SIZE
    broad = fbm(s, [2, 4, 8, 16], [0.40, 0.30, 0.20, 0.10], 101)
    fine = fbm(s, [24, 64, 128, 256], [0.20, 0.30, 0.30, 0.20], 109)
    cracks = ridge_noise(s, [4, 10, 24], [0.50, 0.32, 0.18], 117)
    # Soft vertical rainwater drip streaks
    streaks = gaussian_filter(tileable_noise(s, 14, 123), sigma=(38, 3.0), mode="wrap")
    peel_mask = np.clip((broad - 0.62) * 7.0, 0.0, 1.0)

    paint_col = lerp3([112, 105, 86], [78, 74, 60], streaks * 0.55 + broad * 0.25 + fine * 0.20)
    exposed_col = lerp3([54, 50, 44], [84, 76, 64], fine)
    albedo = paint_col * (1.0 - peel_mask[..., None]) + exposed_col * peel_mask[..., None]
    # Soft subtle plaster cracks & water-stain darkening
    albedo *= (1.0 - np.clip((cracks - 0.85) * 4.5, 0.0, 0.65)[..., None])
    albedo *= (0.82 + 0.24 * streaks[..., None])

    height = 0.68 - peel_mask * 0.26 + fine * 0.12 - np.clip((cracks - 0.84) * 2.2, 0, 0.32)
    rough = np.clip(0.80 + peel_mask * 0.12 - streaks * 0.18 + (fine - 0.5) * 0.14, 0.42, 0.96)
    save_pbr("plaster_peeling", albedo, height, rough, normal_strength=6.0)


def gen_parquet_worn():
    """Authentic damaged dark oak herringbone parquet flooring (exact ref #16 — long planks, NO checkerboard grid!)."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    # Long realistic 5:1 herringbone strips oriented along 45 degrees
    w = 32.0
    u = (x + y) / w
    v = (x - y) / w
    # Classic interlocking herringbone cell (ratio 4 planks per zigzag)
    plen = 4.0
    iu = np.floor(u)
    iv = np.floor(v)
    band = np.floor((iu + iv) / plen)
    parity = (band.astype(np.int32)) & 1

    fu = u - iu
    fv = v - iv
    # Plank ID & local coordinates
    pu = np.where(parity == 0, band, iu)
    pv = np.where(parity == 0, iv, band)
    plank_id = np.abs(np.sin(pu * 17.31 + pv * 91.17) * 43758.5453) % 1.0

    # End seam occurs along (u+v)/plen integer boundary
    end_f = ((u + v) / plen) - band
    end_seam = np.minimum(end_f, 1.0 - end_f) * plen
    side_seam = np.where(parity == 0, np.minimum(fv, 1.0 - fv), np.minimum(fu, 1.0 - fu))
    grout = np.clip(1.0 - np.minimum(side_seam, end_seam) * 22.0, 0.0, 1.0)

    # Rich wood grain stretched along plank axis
    grain_u = gaussian_filter(tileable_noise(s, 128, 201), sigma=(1.2, 14.0), mode="wrap")
    grain_v = grain_u.T
    grain = np.where(parity == 0, grain_u, grain_v)
    wear = fbm(s, [3, 8, 20, 48], [0.35, 0.30, 0.20, 0.15], 211)

    albedo = lerp3([44, 28, 17], [88, 58, 35], plank_id * 0.58 + grain * 0.42)
    dust = np.clip((wear - 0.54) * 2.3, 0.0, 0.62)
    albedo = albedo * (1.0 - dust[..., None] * 0.42) + np.array([70, 64, 52]) * (dust[..., None] * 0.42)
    albedo *= (1.0 - grout[..., None] * 0.78)

    # Warped individual boards catch raking warm lamp light just like ref #16!
    warp = (plank_id - 0.5) * 0.20 + (grain - 0.5) * 0.08
    height = 0.66 + warp - grout * 0.46
    rough = np.clip(0.32 + dust * 0.44 + grout * 0.42 + (grain - 0.5) * 0.12, 0.18, 0.94)
    save_pbr("parquet_worn", albedo, height, rough, normal_strength=7.0)


def gen_brick_vault():
    """Old European damp catacomb/bunker brickwork with deep recessed mortar & soot."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    rows = 16.0
    cols = 8.0
    ry = (y / s) * rows
    row_i = np.floor(ry)
    rx = (x / s) * cols + (row_i % 2) * 0.5
    col_i = np.floor(rx)
    fy = ry - row_i
    fx = rx - col_i

    # Irregular hand-laid edges
    jitter = (fbm(s, [16, 48, 128], [0.4, 0.35, 0.25], 303) - 0.5) * 0.06
    mx = np.minimum(fx + jitter, 1.0 - fx - jitter)
    my = np.minimum(fy + jitter, 1.0 - fy - jitter)
    mortar = np.clip(1.0 - np.minimum(mx * 16.0, my * 9.5), 0.0, 1.0)

    brick_id = np.abs(np.sin(col_i * 19.19 + row_i * 73.13) * 19843.2) % 1.0
    surface = fbm(s, [12, 32, 96, 192], [0.25, 0.3, 0.25, 0.2], 311)
    damp = fbm(s, [4, 10, 24], [0.5, 0.3, 0.2], 317)

    brick_col = lerp3([72, 46, 38], [116, 76, 58], brick_id * 0.6 + surface * 0.4)
    # Soot & grey aged bricks mixed in
    soot = np.clip((damp - 0.48) * 2.2, 0.0, 0.78)
    brick_col = brick_col * (1.0 - soot[..., None] * 0.58)
    mortar_col = lerp3([58, 55, 50], [92, 86, 78], surface)
    albedo = brick_col * (1.0 - mortar[..., None]) + mortar_col * mortar[..., None]

    # Efflorescence / damp pale salt crust in pockets
    salt = np.clip((fbm(s, [8, 24, 64], [0.4, 0.35, 0.25], 331) - 0.68) * 3.0, 0.0, 0.45)
    albedo = albedo * (1.0 - salt[..., None]) + np.array([145, 140, 130]) * salt[..., None]

    height = (0.72 + (brick_id - 0.5) * 0.14 + (surface - 0.5) * 0.18) * (1.0 - mortar) + (0.20 + surface * 0.12) * mortar
    rough = np.clip(0.84 - soot * 0.38 + mortar * 0.10 + (surface - 0.5) * 0.14, 0.25, 0.97)
    save_pbr("brick_vault", albedo, height, rough, normal_strength=9.0)


def gen_snow_mud():
    """Patchy trampled night snow over dark frozen mud & wet slush (refs #8, #12, #15)."""
    s = SIZE
    macro = fbm(s, [3, 6, 12, 24], [0.35, 0.3, 0.2, 0.15], 401)
    med = fbm(s, [16, 32, 64, 128], [0.25, 0.3, 0.25, 0.2], 409)
    fine = fbm(s, [64, 128, 256], [0.3, 0.4, 0.3], 419)
    ruts = ridge_noise(s, [4, 10, 24], [0.5, 0.35, 0.15], 421)

    # Crisp organic patches of trampled snow revealing dark mud underneath
    snow_mask = np.clip((macro * 0.72 + med * 0.28 - 0.43) * 6.5, 0.0, 1.0)
    snow_mask = gaussian_filter(snow_mask, sigma=1.2, mode="wrap")

    mud_col = lerp3([26, 20, 16], [56, 44, 34], med * 0.65 + fine * 0.35)
    # Wet puddle sheen in deepest mud spots
    puddle = np.clip((0.36 - macro) * 5.0, 0.0, 1.0)
    mud_col *= (1.0 - puddle[..., None] * 0.35)

    snow_col = lerp3([158, 166, 178], [218, 224, 232], fine * 0.5 + med * 0.5)
    # Dirty slush transition edge
    edge = snow_mask * (1.0 - snow_mask) * 4.0
    albedo = mud_col * (1.0 - snow_mask[..., None]) + snow_col * snow_mask[..., None]
    albedo = albedo * (1.0 - edge[..., None] * 0.25) + np.array([68, 60, 52]) * (edge[..., None] * 0.25)

    height = 0.28 + snow_mask * 0.34 + med * 0.16 + fine * 0.08 - ruts * 0.14 - puddle * 0.12
    # Wet mud = glossy (0.18), slush edge = 0.35, packed snow = 0.52 with crystalline micro-glint
    rough = np.clip(
        (0.76 - puddle * 0.58) * (1.0 - snow_mask) +
        (0.48 + (fine - 0.5) * 0.24) * snow_mask -
        edge * 0.18,
        0.12, 0.94
    )
    save_pbr("snow_mud", albedo, height, rough, normal_strength=8.5)


def gen_timber_weathered():
    """Dark weathered vertical wooden cabin planks & porch boards (refs #10, #15)."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    planks = 12.0
    px = (x / s) * planks
    pid = np.floor(px)
    fx = px - pid
    seam = np.clip(1.0 - np.minimum(fx, 1.0 - fx) * 26.0, 0.0, 1.0)

    # Anisotropic vertical wood grain
    grain = tileable_noise(s, 96, 501)
    grain = gaussian_filter(grain, sigma=(18, 1.2), mode="wrap")
    fine = tileable_noise(s, 220, 509)
    fine = gaussian_filter(fine, sigma=(6, 0.8), mode="wrap")
    rot = fbm(s, [4, 12, 32], [0.45, 0.35, 0.2], 517)
    p_var = np.abs(np.sin(pid * 27.13 + 3.1) * 4123.7) % 1.0

    albedo = lerp3([38, 29, 22], [86, 65, 48], p_var * 0.45 + grain * 0.35 + fine * 0.2)
    # Silvery frost / rot streaks
    silver = np.clip((rot - 0.58) * 2.8, 0.0, 0.55)
    albedo = albedo * (1.0 - silver[..., None]) + np.array([108, 106, 102]) * silver[..., None]
    albedo *= (1.0 - seam[..., None] * 0.80)

    height = 0.65 + (p_var - 0.5) * 0.15 + grain * 0.16 + fine * 0.08 - seam * 0.50
    rough = np.clip(0.76 - rot * 0.22 + seam * 0.15 + (fine - 0.5) * 0.14, 0.38, 0.96)
    save_pbr("timber_weathered", albedo, height, rough, normal_strength=8.0)


def gen_wood_carved():
    """Aged varnished walnut/mahogany for Asylum reception desk, staircase, paneling."""
    s = SIZE
    grain = tileable_noise(s, 72, 601)
    grain = gaussian_filter(grain, sigma=(20, 1.5), mode="wrap")
    fine = fbm(s, [32, 96, 192], [0.3, 0.4, 0.3], 607)
    wear = fbm(s, [5, 14, 32], [0.45, 0.35, 0.2], 613)

    albedo = lerp3([44, 28, 18], [94, 62, 38], grain * 0.6 + fine * 0.4)
    scuff = np.clip((wear - 0.60) * 2.5, 0.0, 0.5)
    albedo = albedo * (1.0 - scuff[..., None] * 0.35) + np.array([102, 88, 70]) * (scuff[..., None] * 0.35)
    height = 0.55 + grain * 0.18 + fine * 0.10 - scuff * 0.08
    rough = np.clip(0.36 + scuff * 0.42 + (fine - 0.5) * 0.12, 0.22, 0.88)
    save_pbr("wood_carved", albedo, height, rough, normal_strength=4.5)


def gen_concrete_rubble():
    """Cracked wet bunker floor & stone debris (refs #5, #13)."""
    s = SIZE
    macro = fbm(s, [4, 10, 24, 48], [0.3, 0.3, 0.25, 0.15], 701)
    fine = fbm(s, [48, 128, 256], [0.3, 0.4, 0.3], 709)
    cracks = ridge_noise(s, [6, 14, 28], [0.45, 0.35, 0.2], 719)
    wet = np.clip((0.40 - macro) * 4.5, 0.0, 1.0)

    albedo = lerp3([48, 46, 43], [108, 102, 94], macro * 0.55 + fine * 0.45)
    albedo *= (1.0 - wet[..., None] * 0.42)
    albedo *= (1.0 - np.clip((cracks - 0.80) * 4.0, 0.0, 0.65)[..., None])

    height = 0.55 + macro * 0.20 + fine * 0.16 - np.clip((cracks - 0.78) * 2.5, 0, 0.4) - wet * 0.10
    rough = np.clip(0.84 - wet * 0.66 + (fine - 0.5) * 0.14, 0.12, 0.96)
    save_pbr("concrete_rubble", albedo, height, rough, normal_strength=8.0)


def gen_tile_asylum():
    """Grimy cracked institutional stone/ceramic floor tile (refs #2, #18)."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    n = 8.0
    gx, gy = (x / s) * n, (y / s) * n
    ix, iy = np.floor(gx), np.floor(gy)
    fx, fy = gx - ix, gy - iy
    grout = np.clip(1.0 - np.minimum(np.minimum(fx, 1.0 - fx), np.minimum(fy, 1.0 - fy)) * 28.0, 0.0, 1.0)
    checker = ((ix + iy).astype(np.int32)) & 1
    grime = fbm(s, [4, 12, 32, 96], [0.35, 0.3, 0.2, 0.15], 801)
    cracks = ridge_noise(s, [8, 20], [0.6, 0.4], 811)

    c_light = lerp3([104, 102, 92], [72, 70, 62], grime)
    c_dark = lerp3([52, 54, 50], [34, 36, 34], grime)
    albedo = np.where(checker[..., None] == 0, c_light, c_dark)
    albedo *= (1.0 - grout[..., None] * 0.65)
    albedo *= (1.0 - np.clip((cracks - 0.85) * 4.0, 0.0, 0.55)[..., None])

    height = 0.68 - grout * 0.35 + (grime - 0.5) * 0.08 - np.clip((cracks - 0.85) * 2.2, 0, 0.25)
    rough = np.clip(0.32 + grime * 0.45 + grout * 0.42, 0.18, 0.94)
    save_pbr("tile_asylum", albedo, height, rough, normal_strength=5.5)


def gen_metal_tactical():
    """Parkerized gunmetal / matte anodized rifle & pistol receiver with subtle edge wear."""
    s = SIZE
    micro = fbm(s, [32, 96, 192, 256], [0.2, 0.3, 0.3, 0.2], 901)
    scratches = ridge_noise(s, [12, 36, 96], [0.3, 0.4, 0.3], 907)
    oil = fbm(s, [4, 12, 24], [0.5, 0.3, 0.2], 919)

    albedo = lerp3([24, 26, 28], [52, 55, 60], micro * 0.65 + oil * 0.35)
    wear = np.clip((scratches - 0.84) * 5.0, 0.0, 0.8)
    albedo = albedo * (1.0 - wear[..., None] * 0.4) + np.array([128, 132, 138]) * (wear[..., None] * 0.4)
    height = 0.5 + micro * 0.08 - wear * 0.06
    rough = np.clip(0.38 + (oil - 0.5) * 0.22 - wear * 0.16, 0.16, 0.68)
    save_pbr("metal_tactical", albedo, height, rough, normal_strength=3.0)


def gen_zombie_skin():
    """Pale necrotic rotting flesh with dark dried blood, veins, and wet slimy sheen (ref #4)."""
    s = SIZE
    mottle = fbm(s, [4, 12, 32, 64], [0.3, 0.3, 0.25, 0.15], 1001)
    pores = fbm(s, [64, 128, 256], [0.3, 0.4, 0.3], 1009)
    veins = ridge_noise(s, [8, 20, 48], [0.45, 0.35, 0.2], 1019)
    blood_mask = np.clip((fbm(s, [5, 16, 40], [0.45, 0.35, 0.2], 1031) - 0.58) * 4.5, 0.0, 1.0)

    skin = lerp3([84, 88, 76], [134, 126, 114], mottle * 0.7 + pores * 0.3)
    # Dark necrotic purple-brown veins
    v_str = np.clip((veins - 0.76) * 4.0, 0.0, 0.75)
    skin = skin * (1.0 - v_str[..., None] * 0.55) + np.array([46, 28, 34]) * (v_str[..., None] * 0.55)
    # Coagulated crimson-black gore patches
    gore = lerp3([58, 12, 10], [108, 18, 14], pores)
    albedo = skin * (1.0 - blood_mask[..., None] * 0.82) + gore * (blood_mask[..., None] * 0.82)

    height = 0.55 + pores * 0.14 + v_str * 0.12 - blood_mask * 0.08
    rough = np.clip(0.62 - blood_mask * 0.44 + (pores - 0.5) * 0.18, 0.14, 0.85)
    save_pbr("zombie_skin", albedo, height, rough, normal_strength=5.5)


def gen_tactical_cloth():
    """Grimy tattered military ripstop uniform with mud & blood splatters (ref #4)."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    weave = (np.sin(x * 1.1) * np.sin(y * 1.1) * 0.5 + 0.5) * 0.25
    camo = fbm(s, [5, 10, 22], [0.45, 0.35, 0.2], 1103)
    grime = fbm(s, [8, 24, 64], [0.4, 0.35, 0.25], 1117)
    blood = np.clip((fbm(s, [6, 18, 48], [0.45, 0.35, 0.2], 1129) - 0.66) * 5.0, 0.0, 0.85)

    base = lerp3([38, 42, 34], [74, 72, 56], (camo > 0.48).astype(np.float32) * 0.6 + camo * 0.4)
    base *= (1.0 - grime[..., None] * 0.45)
    albedo = base * (1.0 - blood[..., None]) + np.array([62, 14, 12]) * blood[..., None]

    height = 0.5 + weave * 0.16 + grime * 0.14
    rough = np.clip(0.88 - blood * 0.52 + (grime - 0.5) * 0.12, 0.28, 0.96)
    save_pbr("tactical_cloth", albedo, height, rough, normal_strength=4.5)


def gen_bark_pine():
    """Deeply furrowed wet winter pine bark with frost highlights."""
    s = SIZE
    furrow = ridge_noise(s, [12, 28, 64], [0.45, 0.35, 0.2], 1201)
    furrow = gaussian_filter(furrow, sigma=(10, 1.0), mode="wrap")
    fine = fbm(s, [48, 128, 256], [0.3, 0.4, 0.3], 1213)
    frost = np.clip((fbm(s, [6, 18, 48], [0.4, 0.35, 0.25], 1223) - 0.64) * 3.5, 0.0, 0.65)

    albedo = lerp3([30, 22, 17], [68, 52, 40], furrow * 0.65 + fine * 0.35)
    albedo = albedo * (1.0 - frost[..., None] * 0.5) + np.array([180, 188, 198]) * (frost[..., None] * 0.5)
    height = 0.35 + furrow * 0.45 + fine * 0.15
    rough = np.clip(0.85 - frost * 0.25, 0.45, 0.96)
    save_pbr("bark_pine", albedo, height, rough, normal_strength=9.5)


def gen_barrel_oak():
    """Stacked weathered oak barrel staves with rusty dark iron bands (ref #18)."""
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    staves = 16.0
    px = (x / s) * staves
    pid = np.floor(px)
    fx = px - pid
    seam = np.clip(1.0 - np.minimum(fx, 1.0 - fx) * 24.0, 0.0, 1.0)
    # Iron hoops at y = 0.14, 0.34, 0.66, 0.86
    ny = y / s
    hoop = np.zeros_like(ny)
    for hy in (0.14, 0.33, 0.67, 0.86):
        hoop = np.maximum(hoop, (np.abs(ny - hy) < 0.032).astype(np.float32))

    grain = gaussian_filter(tileable_noise(s, 96, 1301), sigma=(18, 1.0), mode="wrap")
    rust = fbm(s, [8, 24, 64], [0.4, 0.35, 0.25], 1307)
    pvar = np.abs(np.sin(pid * 17.3) * 999.1) % 1.0

    wood = lerp3([72, 54, 38], [122, 94, 66], pvar * 0.4 + grain * 0.6) * (1.0 - seam[..., None] * 0.72)
    iron = lerp3([34, 32, 30], [78, 46, 30], rust)
    albedo = wood * (1.0 - hoop[..., None]) + iron * hoop[..., None]

    height = (0.55 + grain * 0.14 - seam * 0.35) * (1.0 - hoop) + (0.82 + rust * 0.08) * hoop
    rough = np.clip(0.76 * (1.0 - hoop) + (0.48 + rust * 0.32) * hoop, 0.35, 0.94)
    save_pbr("barrel_oak", albedo, height, rough, normal_strength=7.0)


def gen_flashlight_cookie():
    """Photorealistic tactical LED flashlight projector texture matching Bodycam refs (#5, #8, #13, #18):
    Punchy overexposed cool-white center hotspot + crisp circular flood disc + sharp outer bezel ring!
    """
    s = 512
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    u = (x / (s - 1)) * 2.0 - 1.0
    v = (y / (s - 1)) * 2.0 - 1.0
    r = np.sqrt(u * u + v * v)

    hotspot = np.exp(-((r / 0.44) ** 2.6)) * 1.0
    disc = np.clip(1.0 - np.clip((r - 0.72) / 0.12, 0.0, 1.0), 0.0, 1.0) ** 1.4 * 0.58
    ring = np.exp(-(((r - 0.75) / 0.042) ** 2)) * 0.34
    imperf = 0.95 + 0.05 * tileable_noise(s, 14, 1401)

    val = np.clip((hotspot * 0.85 + disc + ring) * imperf, 0.0, 1.0)
    edge_mask = np.clip(1.0 - np.clip((r - 0.80) / 0.08, 0.0, 1.0), 0.0, 1.0) ** 1.8
    val *= edge_mask

    rc = np.clip(val * (0.94 + 0.14 * np.exp(-(((r - 0.77) / 0.05) ** 2))), 0.0, 1.0)
    gc = np.clip(val * 0.98, 0.0, 1.0)
    bc = np.clip(val * (1.06 - 0.16 * np.clip((r - 0.68) / 0.16, 0.0, 1.0)), 0.0, 1.0)
    rgb = np.stack([rc, gc, bc], axis=-1)
    Image.fromarray(np.clip(rgb * 255.0, 0, 255).astype(np.uint8), mode="RGB").save(
        OUT / "flashlight_cookie.png")
    print("  saved flashlight_cookie.png")


def gen_zombie_face():
    """Dedicated UV-aligned terrifying rotting zombie face PBR map (exact zombie_head.obj UVs:
    u=0/1 is front center +Z face, v=0.39 eye sockets, v=0.46 rotted nose, v=0.565 gaping jaw/teeth).
    Darkened necrotic palette + deep anatomical shading so close-range flashlight shows gruesome detail!
    """
    s = SIZE
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    u = x / s
    v = y / s
    du = np.where(u <= 0.5, u, u - 1.0)

    mottle = fbm(s, [4, 12, 32, 64], [0.3, 0.3, 0.25, 0.15], 1601)
    pores = fbm(s, [48, 128, 256], [0.25, 0.40, 0.35], 1609)
    veins = ridge_noise(s, [8, 20, 48], [0.45, 0.35, 0.2], 1619)
    scars = ridge_noise(s, [14, 36], [0.6, 0.4], 1637)

    # Rich dark rotting grey-olive-brown dead skin (never blows out to white under 1m flashlight!)
    skin = lerp3([26, 25, 23], [64, 58, 52], mottle * 0.62 + pores * 0.38)
    v_str = np.clip((veins - 0.68) * 3.6, 0.0, 0.85)
    skin = skin * (1.0 - v_str[..., None] * 0.60) + np.array([18, 10, 14]) * (v_str[..., None] * 0.60)
    # Deep facial skin creases & decaying fissures
    skin *= (1.0 - np.clip((scars - 0.80) * 3.5, 0.0, 0.55)[..., None])

    # Brow shadow & deep pitch-black sunken orbital eye sockets (du = +-0.056, v = 0.39)
    brow_sh = np.exp(-(((v - 0.355) / 0.028) ** 2)) * (np.abs(du) < 0.12)
    skin *= (1.0 - brow_sh[..., None] * 0.45)
    eye_l = np.exp(-(((du + 0.054) / 0.034) ** 2 + ((v - 0.395) / 0.038) ** 2))
    eye_r = np.exp(-(((du - 0.054) / 0.034) ** 2 + ((v - 0.395) / 0.038) ** 2))
    sockets = np.clip(eye_l + eye_r, 0.0, 1.0)
    skin = skin * (1.0 - sockets[..., None] * 0.94) + np.array([5, 4, 5]) * (sockets[..., None] * 0.94)

    # Exposed rotted dark crimson-black nasal cavity (du = 0, v = 0.46)
    nose = np.exp(-((du / 0.022) ** 2 + ((v - 0.465) / 0.028) ** 2))
    skin = skin * (1.0 - nose[..., None] * 0.92) + np.array([16, 5, 5]) * (nose[..., None] * 0.92)

    # Gaunt sunken cheek hollows & nasolabial folds
    cheeks = np.exp(-(((np.abs(du) - 0.095) / 0.042) ** 2 + ((v - 0.52) / 0.065) ** 2))
    skin *= (1.0 - cheeks[..., None] * 0.58)

    # Gaping blackened snarling mouth cavity (du in [-0.068, 0.068], v = 0.565)
    mouth_d = np.sqrt((du / 0.064) ** 2 + ((v - 0.565) / 0.044) ** 2)
    mouth_in = np.clip((1.0 - mouth_d) * 6.0, 0.0, 1.0)
    drip_n = gaussian_filter(tileable_noise(s, 48, 1627), sigma=(18, 1.5), mode="wrap")
    chin_blood = np.exp(-((du / 0.088) ** 2)) * np.clip((v - 0.52) * 4.5, 0.0, 1.0) * np.clip((0.86 - v) * 4.5, 0.0, 1.0)
    blood_ring = np.clip(np.exp(-((mouth_d - 1.05) ** 2) / 0.16) * 0.90 + chin_blood * drip_n * 1.6, 0.0, 1.0)

    gore = lerp3([26, 4, 4], [58, 9, 8], pores)
    albedo = skin * (1.0 - blood_ring[..., None] * 0.88) + gore * (blood_ring[..., None] * 0.88)
    albedo = albedo * (1.0 - mouth_in[..., None] * 0.96) + np.array([7, 2, 2]) * (mouth_in[..., None] * 0.96)

    # Stained crooked jagged rotting teeth along upper & lower jaw margins
    teeth_u = np.exp(-(((v - 0.538) / 0.011) ** 2)) * (np.abs(du) < 0.052) * (np.sin(du * 360.0) > -0.05)
    teeth_l = np.exp(-(((v - 0.590) / 0.010) ** 2)) * (np.abs(du) < 0.046) * (np.sin(du * 380.0 + 1.1) > 0.05)
    teeth = np.clip(teeth_u + teeth_l, 0.0, 1.0) * mouth_in
    albedo = albedo * (1.0 - teeth[..., None] * 0.85) + np.array([98, 86, 66]) * (teeth[..., None] * 0.85)

    # Darkened grime on neck/jawline below chin (v > 0.72)
    neck_sh = np.clip((v - 0.72) * 4.5, 0.0, 0.65)
    albedo *= (1.0 - neck_sh[..., None])

    height = 0.56 + pores * 0.18 + v_str * 0.14 - sockets * 0.40 - nose * 0.28 - mouth_in * 0.42 + teeth * 0.22
    rough = np.clip(0.90 - blood_ring * 0.42 + (pores - 0.5) * 0.12, 0.36, 0.98)
    save_pbr("zombie_face", albedo, height, rough, normal_strength=9.5)


def gen_graffiti_decal():
    """Weathered charcoal/black Asylum stairwell graffiti tags + peeling wall stains (transparent PNG, ref #3)."""
    s = 1024
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im, "RGBA")
    rng = np.random.default_rng(3030)
    # Dense jagged hand-scrawled asylum wall graffiti & charcoal marks
    for _ in range(85):
        x = int(rng.integers(50, s - 50))
        y = int(rng.integers(80, s - 80))
        pts = [(x, y)]
        for _k in range(rng.integers(6, 18)):
            x = int(np.clip(x + rng.integers(-65, 65), 20, s - 20))
            y = int(np.clip(y + rng.integers(-50, 50), 20, s - 20))
            pts.append((x, y))
        alpha = int(rng.integers(65, 165))
        col = (18, 16, 15, alpha) if rng.random() < 0.82 else (48, 22, 18, alpha)
        draw.line(pts, fill=col, width=int(rng.integers(3, 9)), joint="curve")
    # Dark soot / peeling plaster blotches around edges
    for _ in range(36):
        cx, cy = int(rng.integers(60, s - 60)), int(rng.integers(60, s - 60))
        rx, ry = int(rng.integers(25, 110)), int(rng.integers(25, 120))
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(26, 22, 18, int(rng.integers(24, 65))))
    im = im.filter(ImageFilter.GaussianBlur(radius=1.1))
    im.save(OUT / "graffiti_decal.png")
    print("  saved graffiti_decal.png")


def gen_particles():
    """Soft snow flake, gunsmoke puff, and blood decal textures."""
    # Snow flake
    s = 64
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    r = np.sqrt(((x / (s - 1)) * 2 - 1) ** 2 + ((y / (s - 1)) * 2 - 1) ** 2)
    alpha = np.clip(1.0 - r, 0.0, 1.0) ** 1.8
    rgba = np.stack([np.ones_like(alpha), np.ones_like(alpha), np.ones_like(alpha), alpha], axis=-1)
    Image.fromarray((rgba * 255).astype(np.uint8), mode="RGBA").save(OUT / "snow_flake.png")

    # Smoke puff
    s = 256
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    r = np.sqrt(((x / (s - 1)) * 2 - 1) ** 2 + ((y / (s - 1)) * 2 - 1) ** 2)
    n = fbm(s, [4, 8, 16, 32], [0.4, 0.3, 0.2, 0.1], 1501)
    mask = np.clip(1.0 - r * 1.05, 0.0, 1.0) ** 1.6
    alpha = np.clip(mask * (0.45 + 0.75 * n), 0.0, 1.0)
    val = 0.72 + 0.25 * n
    rgba = np.stack([val, val * 0.98, val * 0.95, alpha], axis=-1)
    Image.fromarray((rgba * 255).astype(np.uint8), mode="RGBA").save(OUT / "smoke_puff.png")

    # Blood decal
    s = 256
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    u = (x / (s - 1)) * 2 - 1
    v = (y / (s - 1)) * 2 - 1
    r = np.sqrt(u * u + v * v)
    n = fbm(s, [6, 16, 32], [0.45, 0.35, 0.2], 1511)
    alpha = np.clip((0.72 - r + (n - 0.5) * 0.55) * 4.5, 0.0, 1.0)
    rgba = np.stack([
        np.full_like(alpha, 0.24) + n * 0.12,
        np.full_like(alpha, 0.025),
        np.full_like(alpha, 0.02),
        alpha * 0.92,
    ], axis=-1)
    Image.fromarray((rgba * 255).astype(np.uint8), mode="RGBA").save(OUT / "blood_splat.png")
    print("  saved particle & decal sprites")


if __name__ == "__main__":
    print("Generating photorealistic PBR texture sets...")
    gen_plaster_peeling()
    gen_parquet_worn()
    gen_brick_vault()
    gen_snow_mud()
    gen_timber_weathered()
    gen_wood_carved()
    gen_concrete_rubble()
    gen_tile_asylum()
    gen_metal_tactical()
    gen_zombie_skin()
    gen_zombie_face()
    gen_tactical_cloth()
    gen_bark_pine()
    gen_barrel_oak()
    gen_flashlight_cookie()
    gen_graffiti_decal()
    gen_particles()
    print("All PBR textures generated!")
