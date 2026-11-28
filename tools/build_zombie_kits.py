#!/usr/bin/env python3
"""Blender 5.3 builder for the zombie attachment kits (Spitter, Screamer, Riot Guard, Bloater).

    blender -b -P tools/build_zombie_kits.py -- --kit all            # build, bake, export, preview
    blender -b -P tools/build_zombie_kits.py -- --kit riot --stage geo   # geometry preview only

Each kit is a GLB of add-on meshes only (no body, no armature).  Mesh nodes are named
`<BoneKey>__<PartName>`; their vertices are in the game's character space (metres, +Y up,
facing +Z, character's left = +X) with identity node transforms, fitted to the rest-pose
reference bodies in <scratch>/zombie_refs.  Surface-texture sources live in
<scratch>/zombie_kits/tex (see zombie_kits/work/gen_textures.sh); they are box-projected,
layered with procedural veins / blood / edge wear, and baked to one 1024px atlas per material
(base colour, tangent normal, occlusion-roughness-metallic).
"""
import bpy, bmesh, math, os, sys, random
from mathutils import Vector, Matrix, noise

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zombie_kit_lib as K
from zombie_kit_lib import V, smoothstep, lerp

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_MODELS = os.path.join(REPO, "assets", "models")

# In-game necrotic body skin is a dark grey-brown; organic parts fade into this where they root.
SKIN = (0.050, 0.037, 0.031)
SKIN_EDGE = (0.062, 0.046, 0.040)

K.SRC_SPECS.update({
    # ---- spitter
    "bile": dict(final="BileSac", tex="src_bile_sac.jpg", scale=2.4, offset=(0.40, 0.20, 0.15), rough=(0.44, 0.22), bump=0.6, bump_dist=0.006,
                 hsv=(0.5, 1.05, 0.92),
                 veins=dict(scale=9.0, width=0.020, amount=0.45, color=(0.07, 0.015, 0.03), warp=0.22, warp_scale=7.0, break_scale=5.0),
                 prox=dict(tex="src_infected_flesh.jpg", scale=3.5, tint=(0.42, 0.34, 0.36), rough=0.55, lo=0.30, hi=0.85)),
    "belly": dict(final="SpitterBelly", tex="src_belly_skin.jpg", scale=2.4, offset=(0.50, 0.15, 0.30), rough=(0.66, 0.46), bump=0.55, bump_dist=0.005,
                  tint=(0.44, 0.385, 0.40),
                  veins=dict(scale=8.0, width=0.016, amount=0.30, color=(0.10, 0.06, 0.12), warp=0.22, warp_scale=6.0, break_scale=4.0),
                  grime=dict(scale=5.0, amount=0.28, color=(0.07, 0.045, 0.04), rough=0.7),
                  prox=dict(color=SKIN_EDGE, rough=0.72, lo=0.25, hi=0.85, breakup=0.45)),
    # ---- bloater
    "pustule": dict(final="PustuleSac", tex="src_pustule.jpg", scale=2.0, offset=(0.55, 0.05, 0.0), rough=(0.40, 0.18), bump=0.6, bump_dist=0.006,
                    hsv=(0.5, 1.08, 0.88),
                    veins=dict(scale=12.0, width=0.020, amount=0.42, color=(0.12, 0.012, 0.01), warp=0.22, warp_scale=7.0, break_scale=6.0),
                    grime=dict(scale=7.0, amount=0.30, color=(0.42, 0.08, 0.02), rough=0.3),
                    prox=dict(tex="src_infected_flesh.jpg", scale=3.5, tint=(0.60, 0.42, 0.40), rough=0.5, lo=0.35, hi=0.9)),
    "pusflesh": dict(final="PustuleFlesh", tex="src_infected_flesh.jpg", scale=3.2, rough=(0.72, 0.42), bump=0.8, bump_dist=0.008,
                     tint=(0.50, 0.38, 0.38),
                     veins=dict(scale=11.0, width=0.03, amount=0.5, color=(0.05, 0.01, 0.03), warp=0.12),
                     prox=dict(color=SKIN_EDGE, rough=0.75, lo=0.45, hi=0.95, breakup=0.5)),
})


# =========================================================================== SPITTER (patient)
def kit_spitter(body):
    parts = []

    # -- main goitre: hangs from under the jaw down over the sternum
    spine = [V((0.0, 1.925, 0.058)), V((-0.003, 1.868, 0.100)), V((-0.008, 1.792, 0.146)), V((-0.013, 1.722, 0.166))]
    radii = [0.046, 0.068, 0.099, 0.103]

    def shape_main(th, v, c):
        d = V((math.cos(th), math.sin(th), v * 2.6))
        m = 1.0 + 0.075 * noise.noise(d * 1.25 + V((3.1, 1.7, 7.3))) + 0.03 * noise.noise(d * 3.3 + V((9, 2, 4)))
        fold = 1.0 - smoothstep(0.05, 0.52, v)                      # skin folds gathering at the throat
        w = 0.5 + 0.5 * math.sin(th * 9.0 + 2.6 * noise.noise(V((math.cos(th) * 1.4, math.sin(th) * 1.4, v * 5.0))))
        m -= 0.19 * fold * w * w
        m += 0.42 * (1.0 - smoothstep(0.0, 0.17, v))                # root flares into the throat and jaw skin
        m += 0.13 * math.exp(-((math.atan2(math.sin(th - 1.15), math.cos(th - 1.15))) / 0.75) ** 2) * math.exp(-((v - 0.60) / 0.2) ** 2)
        m += 0.05 * math.exp(-((math.atan2(math.sin(th + 1.9), math.cos(th + 1.9))) / 0.6) ** 2) * math.exp(-((v - 0.82) / 0.15) ** 2)
        return m

    v_, f_ = K.loft(spine, radii, nth=56, nv=30, ncap=10, cap_len=0.92, squash=(1.04, 0.94), up_hint=(0, 0, 1), shape=shape_main)
    sac = K.new_obj("sac", v_, f_, "bile")
    K.fix_normals(sac, away_from=V((-0.008, 1.76, 0.15)))
    K.shade(sac)
    K.set_prox(sac, body, 0.0, 0.040)
    parts.append(("Neck__GoitreSac", sac))

    # -- second, smaller sac on the LEFT (+X) of the throat
    d = V((0.906, 0.0, 0.423))
    base = V((0.003, 1.897, 0.020))
    spine2 = [base + d * 0.022, base + d * 0.068 + V((0, -0.006, 0)), base + d * 0.097 + V((0, -0.026, 0.004))]
    radii2 = [0.027, 0.043, 0.046]

    def shape_small(th, v, c):
        dd = V((math.cos(th), math.sin(th), v * 2.0))
        m = 1.0 + 0.08 * noise.noise(dd * 1.5 + V((5.5, 8.1, 2.2))) + 0.03 * noise.noise(dd * 3.6)
        fold = 1.0 - smoothstep(0.05, 0.5, v)
        w = 0.5 + 0.5 * math.sin(th * 7.0 + 1.3 + 2.0 * noise.noise(V((math.cos(th), math.sin(th), v * 4.0))))
        return m - 0.20 * fold * w * w + 0.35 * (1.0 - smoothstep(0.0, 0.2, v))

    v_, f_ = K.loft(spine2, radii2, nth=36, nv=16, ncap=8, cap_len=0.95, squash=(1.0, 1.06), up_hint=(0, 1, 0), shape=shape_small)
    small = K.new_obj("small", v_, f_, "bile")
    K.fix_normals(small, away_from=base + d * 0.08)
    K.shade(small)
    K.set_prox(small, body, 0.0, 0.028)
    parts.append(("Neck__GoitreSmall", small))

    # -- distended belly: a swelling of the abdomen surface itself (rim lies on the skin)
    cx, cy, H = 0.0, 1.385, 0.112
    nr, nth = 17, 56

    def rim(th):                      # th = 0 is up (+Y), increasing toward +X
        c, s_ = math.cos(th), math.sin(th)
        ry = 0.205 if c >= 0 else 0.118
        return 1.0 / math.sqrt((s_ / 0.186) ** 2 + (c / ry) ** 2)

    def skin_z(x, y):
        h = body.ray((x, y, 1.0), (0, 0, -1))
        return h.z if h is not None else body.near((x, y, 0.1))[0].z

    nav = V((0.004, cy - 0.052))

    def height(x, y, rho, c):
        prof = (1.0 - rho ** 2.5) ** 1.6
        lump = 1.0 + 0.05 * noise.noise(V((x * 8.0, y * 8.0, 3.3))) + 0.02 * noise.noise(V((x * 22.0, y * 22.0, 8.1)))
        h = H * prof * lump * (1.0 + 0.22 * max(0.0, -c) * rho)            # hangs a little low
        d = (V((x, y)) - nav).length
        h -= 0.007 * math.exp(-(d / 0.013) ** 2)                           # navel pit
        return h

    verts, faces = [], []
    for j in range(1, nr + 1):
        rho = (j / nr) ** 1.15
        for i in range(nth):
            th = 2 * math.pi * i / nth
            c, s_ = math.cos(th), math.sin(th)
            R = rim(th)
            x, y = cx + s_ * R * rho, cy + c * R * rho
            verts.append(V((x, y, skin_z(x, y) - 0.003 + height(x, y, rho, c))))
    pole = len(verts)
    verts.append(V((cx, cy, skin_z(cx, cy) - 0.003 + height(cx, cy, 0.0, 0.0))))
    for i in range(nth):
        faces.append((pole, i, (i + 1) % nth))
    for j in range(nr - 1):
        for i in range(nth):
            a_, b_ = j * nth + i, j * nth + (i + 1) % nth
            faces.append((a_, a_ + nth, b_ + nth, b_))
    belly = K.new_obj("belly", verts, faces, "belly")
    K.fix_normals(belly, toward_dir=V((0, 0, 1)))
    K.shade(belly)
    K.set_prox(belly, body, 0.003, 0.030)
    parts.append(("Spine__Belly", belly))
    return parts


# =========================================================================== BLOATER (patient)
def kit_bloater(body):
    rnd = random.Random(41)
    # (approx position near the skin, sac radius, how far the centre sits out: fraction of r)
    spine2_major = [
        (V((-0.025, 1.655, 0.140)), 0.104, 0.52),   # the big one on the sternum
        (V((-0.105, 1.760, 0.100)), 0.066, 0.50),
        (V((-0.155, 1.690, 0.110)), 0.054, 0.55),
        (V((-0.065, 1.805, 0.070)), 0.044, 0.50),
        (V((0.055, 1.745, 0.105)), 0.048, 0.45),
        (V((-0.125, 1.590, 0.135)), 0.050, 0.50),
        (V((0.045, 1.580, 0.150)), 0.038, 0.45),
        (V((-0.100, 1.760, -0.200)), 0.076, 0.50),   # upper back
        (V((0.000, 1.805, -0.185)), 0.058, 0.50),
        (V((-0.165, 1.685, -0.190)), 0.056, 0.55),
        (V((-0.040, 1.675, -0.190)), 0.066, 0.50),
        (V((0.085, 1.735, -0.200)), 0.048, 0.45),
        (V((-0.095, 1.595, -0.165)), 0.044, 0.50),
        (V((0.055, 1.630, -0.165)), 0.038, 0.45),
    ]
    shoulder_major = [
        (V((-0.130, 1.890, -0.040)), 0.062, 0.55),
        (V((-0.195, 1.885, -0.075)), 0.054, 0.55),
        (V((-0.105, 1.875, -0.115)), 0.047, 0.50),
        (V((-0.170, 1.865, 0.005)), 0.041, 0.50),
        (V((-0.222, 1.872, -0.020)), 0.034, 0.50),
        (V((-0.150, 1.860, -0.135)), 0.036, 0.50),
    ]

    def place(lst):
        out = []
        for (p, r, k) in lst:
            loc, nrm, _d = body.near(p)
            n = (p - loc).normalized() if (p - loc).length > 0.004 and (p - loc).dot(nrm) > 0 else nrm.normalized()
            out.append(dict(p=loc, n=n, r=r, c=loc + n * (r * k)))
        return out

    def satellites(majors, count, lo=0.017, hi=0.032):
        sats = []
        tries = 0
        while len(sats) < count and tries < 400:
            tries += 1
            m = rnd.choice(majors)
            r = rnd.uniform(lo, hi)
            t = m["n"].orthogonal().normalized()
            t.rotate(Matrix.Rotation(rnd.uniform(0, 2 * math.pi), 3, m["n"]))
            q = m["c"] + t * (m["r"] + r) * rnd.uniform(0.78, 0.98)
            loc, nrm, _d = body.near(q)
            if loc.y > 1.905 or loc.x < -0.245 or loc.x > 0.12 or loc.y < 1.52:
                continue
            c = loc + nrm.normalized() * (r * rnd.uniform(0.35, 0.6))
            if any((c - o["c"]).length < (o["r"] + r) * 0.62 for o in majors + sats):
                continue
            sats.append(dict(p=loc, n=nrm.normalized(), r=r, c=c))
        return sats

    def blobs_for(sacs, seed):
        r2 = random.Random(seed)
        out = []
        for s in sacs:
            n = s["n"]
            t1 = n.orthogonal().normalized()
            t2 = n.cross(t1)
            out.append(dict(c=s["c"], r=s["r"], frame=(t1, t2, n),
                            scale=(r2.uniform(0.92, 1.08), r2.uniform(0.92, 1.08), r2.uniform(0.9, 1.12)),
                            lump=0.07 if s["r"] > 0.04 else 0.05, freq=5.0))
        return out

    def base_blobs(sacs):
        out = []
        for s in sacs:
            n = s["n"]
            t1 = n.orthogonal().normalized()
            t2 = n.cross(t1)
            out.append(dict(c=s["p"] - n * 0.004, r=s["r"] * 1.30 + 0.014, frame=(t1, t2, n), scale=(1.0, 1.0, 0.24), lump=0.16, freq=7.0))
        for i, a in enumerate(sacs):                      # webbing between neighbours
            for b in sacs[i + 1:]:
                dd = (a["p"] - b["p"]).length
                if dd < (a["r"] + b["r"]) * 1.9:
                    mid = (a["p"] + b["p"]) * 0.5
                    loc, nrm, _d = body.near(mid)
                    n = nrm.normalized()
                    t1 = n.orthogonal().normalized()
                    out.append(dict(c=loc - n * 0.004, r=dd * 0.55, frame=(t1, n.cross(t1), n), scale=(1.0, 1.0, 0.22), lump=0.18, freq=8.0))
        return out

    parts = []
    for node, majors_raw, nsat, tris_sac, tris_base, seed in (
            ("Spine2__SacCluster", spine2_major, 18, 11800, 4400, 5),
            ("RightShoulder__SacCluster", shoulder_major, 7, 4600, 1800, 9)):
        majors = place(majors_raw)
        sacs = majors + satellites(majors, nsat)
        sac_ob = K.blob_union(node + "_sacs", blobs_for(sacs, seed), "pustule", voxel=0.0032, smooth=2, tris=int(tris_sac * 1.5), seed=seed)
        K.cull_inside(sac_ob, body, 0.010)
        n = K.tri_count(sac_ob)
        if n > tris_sac:
            K.mod(sac_ob, 'DECIMATE', ratio=tris_sac / n)
        K.shade(sac_ob)
        K.set_prox(sac_ob, body, 0.001, 0.022)
        base_ob = K.blob_union(node + "_base", base_blobs(sacs), "pusflesh", voxel=0.0038, smooth=3, tris=int(tris_base * 1.6), seed=seed + 100)
        K.cull_inside(base_ob, body, 0.005)
        n = K.tri_count(base_ob)
        if n > tris_base:
            K.mod(base_ob, 'DECIMATE', ratio=tris_base / n)
        for vtx in base_ob.data.vertices:                 # lay the flesh down on the skin: no lips curling off the body
            loc, _nrm, _d = body.near(vtx.co)
            sd = body.sdist(vtx.co)
            if sd > 0.0:
                vtx.co = loc + (vtx.co - loc).normalized() * (0.014 * (1.0 - math.exp(-sd / 0.014)))
        base_ob.data.update()
        K.shade(base_ob)
        K.set_prox(base_ob, body, 0.003, 0.011)
        parts.append((node, K.join([sac_ob, base_ob], node)))
    return parts


# =========================================================================== SCREAMER (patient)
X, Y, Z = V((1, 0, 0)), V((0, 1, 0)), V((0, 0, 1))
RAD = math.radians

K.SRC_SPECS.update({
    "steel": dict(final="ScreamerMetal", tex="src_rust_steel.jpg", scale=5.0, rough=(0.92, 0.48), metal=(0.25, 0.92), lum_range=(0.10, 0.60),
                  bump=0.9, bump_dist=0.006, wear=dict(color=(0.33, 0.31, 0.29), amount=0.55, rough=0.42, metal=1.0, radius=0.002)),
    "brass": dict(final="ScreamerMetal", tex="src_brass.jpg", scale=7.0, rough=(0.72, 0.34), metal=(0.55, 0.96), lum_range=(0.15, 0.7),
                  tint=(0.86, 0.74, 0.50), bump=0.6, bump_dist=0.004, wear=dict(color=(0.70, 0.52, 0.20), amount=0.5, rough=0.3, metal=1.0, radius=0.0015)),
    "leather": dict(final="ScreamerLeather", tex="src_leather.jpg", scale=5.5, rough=(0.86, 0.56), tint=(0.50, 0.41, 0.36), bump=0.9, bump_dist=0.006,
                    wear=dict(color=(0.30, 0.18, 0.10), amount=0.5, rough=0.72, radius=0.002),
                    blood=dict(amount=0.5, lo=0.60), grime=dict(amount=0.35, scale=6.0)),
    "canvas": dict(final="ScreamerCanvas", tex="src_canvas.jpg", scale=4.5, rough=(0.96, 0.80), tint=(0.60, 0.55, 0.47), bump=1.0, bump_dist=0.006,
                   blood=dict(amount=0.8, lo=0.54, scale=7.0, rough=0.6), grime=dict(amount=0.55, color=(0.09, 0.07, 0.05), scale=5.0)),
})


def nearest_index(pts, fn):
    return min(range(len(pts)), key=lambda i: fn(pts[i]))


def kit_screamer(body):
    parts = []
    # ------------------------------------------------------------------ head brace
    steel, brass, leather = K.Buf(), K.Buf(), K.Buf()
    tau = RAD(7.0)
    bc = V((0.003, 2.134, 0.012))
    bf = V((0, math.sin(tau), math.cos(tau)))                 # band plane: higher on the forehead than at the occiput
    bnorm = bf.cross(X).normalized()
    band_w, band_t, st = 0.030, 0.0032, 0.0030
    bpts, bn, _ba = K.arc_path(body, bc, bf, X, 0, 0, 60, R=0.3, clearance=0.0006, smooth=2, closed=True, rmax=0.2)
    steel.add(K.strap(bpts, bn, band_w, band_t, closed=True))

    def over_band(p):
        d = abs((p - bc).dot(bnorm))
        return (band_t + 0.0008) * (1.0 - smoothstep(band_w * 0.5 + 0.002, band_w * 0.5 + 0.03, d))

    hc = V((0.003, 2.100, 0.012))

    def over_coronal(p):
        return (st + 0.0006) * (1.0 - smoothstep(0.012, 0.036, abs(p.z - hc.z)))

    # steel arch over the crown, forehead to occiput
    a0, a1 = K.ang(hc, Z, Y, bpts[0]), K.ang(hc, Z, Y, bpts[30])
    spts, sn, _ = K.arc_path(body, hc, Z, Y, a0, a1, 34, R=0.3, clearance=0.0006, smooth=2, rmax=0.2, lift=lambda p: over_band(p) + over_coronal(p))
    steel.add(K.strap(spts, sn, 0.022, 0.0030))
    # leather crown strap, ear to ear
    a0, a1 = K.ang(hc, X, Y, bpts[15]), K.ang(hc, X, Y, bpts[45])
    kpts, kn, _ = K.arc_path(body, hc, X, Y, a0, a1, 34, R=0.3, clearance=0.0006, smooth=2, rmax=0.2, lift=over_band)
    leather.add(K.strap(kpts, kn, 0.024, st))
    # leather chin strap: temples -> in front of the ears -> under the jaw
    c4 = V((0.003, 2.035, 0.060))
    e2c = V((0, 0.22, -0.018)).normalized()
    pn4 = X.cross(e2c)
    iL = nearest_index(bpts, lambda p: abs((p - c4).dot(pn4)) + (10.0 if p.x < 0.03 else 0.0))
    iR = nearest_index(bpts, lambda p: abs((p - c4).dot(pn4)) + (10.0 if p.x > -0.03 else 0.0))
    aL, aR = K.ang(c4, X, e2c, bpts[iL]), K.ang(c4, X, e2c, bpts[iR])
    cpts, cn, cang = K.arc_path(body, c4, X, e2c, aL, aR - 2 * math.pi, 58, R=0.16, clearance=0.0006, smooth=2, rmax=0.16, lift=over_band)
    leather.add(K.strap(cpts, cn, 0.020, st))
    ib = nearest_index(cang, lambda a: abs(a - 0.25))
    brass.add_all(K.buckle(cpts[ib] + cn[ib] * st, cn[ib], cpts[ib + 1] - cpts[ib - 1], w=0.030, h=0.022, bar=0.0036, lift=0.0018))
    # rivets round the band, bolts where straps meet it
    junction = {0: 0.0030, 15: st, 30: 0.0030, 45: st, iL: st, iR: st}
    for i in range(0, 60, 3):
        if any(abs(i - j) <= 1 or abs(i - j) >= 59 for j in junction):
            continue
        steel.add(K.dome(bpts[i] + bn[i] * band_t, bn[i], 0.0042, 0.0026, seg=8, rings=1))
    for j, extra in junction.items():
        steel.add(K.dome(bpts[j] + bn[j] * (band_t + extra + 0.0008), bn[j], 0.0064, 0.0036, hex_head=True))
    im = nearest_index(spts, lambda p: abs(p.z - hc.z))
    steel.add(K.dome(spts[im] + sn[im] * 0.0030, sn[im], 0.0064, 0.0036, hex_head=True))
    for i in (8, 26):
        steel.add(K.dome(spts[i] + sn[i] * 0.0030, sn[i], 0.0040, 0.0024, seg=8, rings=1))
    brace = K.join([steel.obj("b_steel", "steel", 40), leather.obj("b_leather", "leather", 50), brass.obj("b_brass", "brass", 45)], "Head__Brace")
    parts.append(("Head__Brace", brace))

    # ------------------------------------------------------------------ torn muzzle hanging off the LEFT side
    lea, brs = K.Buf(), K.Buf()
    O = V((0.094, 1.898, 0.094))
    ez = V((0.72, -0.10, 0.68)).normalized()                 # convex side, away from the throat
    up0 = V((-0.16, 0.95, -0.08))
    ex = (up0 - ez * up0.dot(ez)).normalized()               # cup hangs from one side edge, so its width runs vertically
    ey = ez.cross(ex)
    hw, hh, depth = 0.050, 0.040, 0.030

    def cup(p, q, out=0.0):
        p_, q_ = K.squircle(p, q, 4.0)
        return O + ex * (p_ * hw * (1.0 - 0.14 * q_)) + ey * (q_ * hh) + ez * (depth * ((1 - p_ * p_) ** 0.8) * (1 - 0.35 * q_ * q_) - depth * 0.5 + out)

    v_, f_, _pr = K.grid(cup, K.linspace(-1, 1, 15), K.linspace(-1, 1, 11))
    cup_ob = K.new_obj("cup", v_, f_, "leather")
    K.fix_normals(cup_ob, toward_dir=ez)
    K.plate(cup_ob, 0.0034, bevel=0.0009, sharp=50, segments=1)
    band_pts = [cup(0.0, q, 0.0036) for q in K.linspace(-0.92, 0.92, 9)]
    lea.add(K.strap(band_pts, [ez] * len(band_pts), 0.016, 0.0022))
    A, B = cup(0.97, 0.0, 0.0036), cup(-0.97, 0.0, 0.0036)
    ie = nearest_index(cang, lambda a: abs(a - 0.02))
    E = cpts[ie] + cn[ie] * (st + 0.0008)
    ctrl = [A - ex * 0.016, A + ex * 0.012 + ez * 0.002, (A + E) * 0.5 + V((0.012, 0.0, 0.010)), E - Y * 0.004, E + Y * 0.012]
    hang = K.resample([K.catmull(ctrl, t) for t in K.linspace(0, 1, 40)], 0.008)
    hn = [(V((p.x - 0.003, 0.0, p.z - 0.02))).normalized() for p in hang]
    lea.add(K.strap(hang, hn, 0.016, 0.0028))
    torn = [B + ex * 0.014, B - ex * 0.012 + ez * 0.001, B - ex * 0.040 + ez * 0.005 + ey * 0.004, B - ex * 0.074 + ez * 0.008 + ey * 0.010]
    torn = K.resample([K.catmull(torn, t) for t in K.linspace(0, 1, 24)], 0.008)
    lea.add(K.strap(torn, [ez] * len(torn), 0.016, 0.0028))
    brs.add_all(K.buckle(torn[-1] + ez * 0.0028, ez, torn[-1] - torn[-3], w=0.026, h=0.020, bar=0.0032, lift=0.001))
    for pnt, nrm in ((A - ex * 0.006 + ez * 0.0028, ez), (B + ex * 0.006 + ez * 0.0028, ez), (E + cn[ie] * 0.0028, cn[ie]),
                     (cup(0.0, 0.8, 0.0058), ez), (cup(0.0, -0.8, 0.0058), ez)):
        brs.add(K.dome(pnt, nrm, 0.0042, 0.0026, seg=8, rings=1))
    muzzle = K.join([cup_ob, lea.obj("m_leather", "leather", 50), brs.obj("m_brass", "brass", 45)], "Head__Muzzle")
    parts.append(("Head__Muzzle", muzzle))

    # ------------------------------------------------------------------ chest harness
    hl, hb = K.Buf(), K.Buf()
    sw, ht = 0.034, 0.0036
    yA, yB, yU = 1.632, 1.545, 1.748

    def tc(y):
        return V((0.003, y, -0.02))

    loops = {}
    for key, y in (("A", yA), ("B", yB)):
        pts, nr, an = K.arc_path(body, tc(y), Z, X, 0, 0, 72, R=0.45, clearance=0.0008, smooth=2, closed=True, rmax=0.30)
        hl.add(K.strap(pts, nr, sw, ht, closed=True))
        loops[key] = (pts, nr, an)

    def over_loops(p):
        return max((ht + 0.0006) * (1.0 - smoothstep(sw * 0.5 + 0.002, sw * 0.5 + 0.03, abs(p.y - y))) for y in (yA, yB))

    def over_upper(p):
        return (ht + 0.0006) * (1.0 - smoothstep(0.017, 0.045, abs(p.y - yU))) if p.z > 0.0 else 0.0

    shoulder = {}
    for sx in (1, -1):
        c = V((0.105 * sx, 1.69, -0.03))
        f_lo = body.ray(V((0.105 * sx, yB, 1.0)), (0, 0, -1))
        b_lo = body.ray(V((0.105 * sx, yB, -1.0)), (0, 0, 1))
        a0, a1 = K.ang(c, Z, Y, f_lo), K.ang(c, Z, Y, b_lo)
        if a1 < a0:
            a1 += 2 * math.pi
        pts, nr, _ = K.arc_path(body, c, Z, Y, a0, a1, 66, R=0.26, clearance=0.0008, smooth=2, rmax=0.26, lift=over_loops)
        hl.add(K.strap(pts, nr, 0.030, ht))
        shoulder[sx] = (pts, nr)
        for y in (yA, yB):
            for front in (True, False):
                i = nearest_index(pts, lambda p: abs(p.y - y) + (0.0 if (p.z > -0.03) == front else 10.0))
                hb.add(K.dome(pts[i] + nr[i] * ht, nr[i], 0.0055, 0.0032, seg=8, rings=1))
    cU = V((0.003, yU, -0.03))
    pL = shoulder[1][0][nearest_index(shoulder[1][0], lambda p: abs(p.y - yU) + (0.0 if p.z > 0 else 10.0))]
    pR = shoulder[-1][0][nearest_index(shoulder[-1][0], lambda p: abs(p.y - yU) + (0.0 if p.z > 0 else 10.0))]
    a0, a1 = K.ang(cU, Z, X, pR) - 0.10, K.ang(cU, Z, X, pL) + 0.10
    upts, un, uan = K.arc_path(body, cU, Z, X, a0, a1, 30, R=0.3, clearance=0.0008, smooth=2, rmax=0.3,
                               lift=lambda p: (ht + 0.0006) * (1.0 - smoothstep(0.017, 0.045, abs(abs(p.x - 0.003) - 0.105))))
    hl.add(K.strap(upts, un, 0.030, ht))
    for pnt in (pL, pR):
        i = nearest_index(upts, lambda p: (p - pnt).length)
        hb.add(K.dome(upts[i] + un[i] * ht, un[i], 0.0055, 0.0032, seg=8, rings=1))
    cS = V((0.014, 1.65, -0.02))
    f_lo, f_hi = body.ray(V((0.014, yB, 1.0)), (0, 0, -1)), body.ray(V((0.014, yU, 1.0)), (0, 0, -1))
    vpts, vn, _ = K.arc_path(body, cS, Z, Y, K.ang(cS, Z, Y, f_lo), K.ang(cS, Z, Y, f_hi), 26, R=0.3, clearance=0.0008, smooth=2, rmax=0.3,
                             lift=lambda p: max(over_loops(p), over_upper(p)))
    hl.add(K.strap(vpts, vn, 0.026, ht))
    for y in (yA, yB, yU):
        i = nearest_index(vpts, lambda p: abs(p.y - y))
        hb.add(K.dome(vpts[i] + vn[i] * ht, vn[i], 0.0050, 0.0030, seg=8, rings=1))

    def buckle_on(pts, nr, i, step, closed, width):
        n = len(pts)
        tan = pts[(i + 1) % n] - pts[(i - 1) % n]
        hb.add_all(K.buckle(pts[i] + nr[i] * ht, nr[i], tan, w=width + 0.014, h=0.032, bar=0.0058, lift=0.0030))
        idx = [(i + k * step) % n if closed else min(max(i + k * step, 0), n - 1) for k in range(0, 6)]
        tail = [pts[j] + nr[j] * (ht + 0.0012 + (0.007 if k == 5 else 0.0025 if k == 4 else 0.0)) - Y * (0.012 if k == 5 else 0.004 if k == 4 else 0.0)
                for k, j in enumerate(idx)]
        hl.add(K.strap(tail, [nr[j] for j in idx], width - 0.006, 0.0030))

    pa, na, aa = loops["A"]
    buckle_on(pa, na, nearest_index(aa, lambda a: abs(a - RAD(20))), 1, True, sw)
    pb, nb, ab = loops["B"]
    buckle_on(pb, nb, nearest_index(ab, lambda a: abs(a - RAD(346))), -1, True, sw)
    buckle_on(upts, un, nearest_index(upts, lambda p: abs(p.x - 0.052)), -1, False, 0.030)
    harness = K.join([hl.obj("h_leather", "leather", 50), hb.obj("h_brass", "brass", 45)], "Spine2__Harness")
    parts.append(("Spine2__Harness", harness))

    # ------------------------------------------------------------------ torn sleeve ends + dangling buckle straps
    for side, sx in (("Left", 1), ("Right", -1)):
        f, h = body.bone(side + "ForeArm"), body.bone(side + "Hand")
        L = (h - f).length
        a, u, w = K.frame_from(h - f, Y)
        nth, nv = 32, 18
        angs = [2 * math.pi * i / nth for i in range(nth)]
        svals = K.linspace(0.22, 1.56, 15)
        table = []
        for s in svals:
            raw = K.fill_none(K.polar_radii(body, f + a * (s * L), u, w, angs, R=0.25, rmax=0.13), True, 0.05)
            sm = K.smooth_list(raw, 3, True)
            table.append([max(p, q) for p, q in zip(raw, sm)])
        for i in range(nth):                                   # keep the cloth smooth along the arm too
            col = [row[i] for row in table]
            sm = K.smooth_list(col, 2)
            for j, row in enumerate(table):
                row[i] = max(col[j], sm[j])

        def cloth_r(s, i):
            x = (min(max(s, svals[0]), svals[-1]) - svals[0]) / (svals[-1] - svals[0]) * (len(svals) - 1)
            j = min(int(x), len(svals) - 2)
            return lerp(table[j][i], table[j + 1][i], x - j) + 0.007 + 0.013 * smoothstep(0.8, 1.35, s)

        def s_range(i):
            th = angs[i]
            c_, s_ = math.cos(th), math.sin(th)
            s0 = 0.36 + 0.08 * noise.noise(V((c_ * 1.6, s_ * 1.6, 1.3 + sx)))
            s1 = 1.38 + 0.06 * noise.noise(V((c_ * 2.2, s_ * 2.2, 7.7 + sx))) + 0.07 * max(0.0, noise.noise(V((c_ * 4.0, s_ * 4.0, 2.2 - sx))))
            return s0, s1

        verts, faces = [], []
        for j in range(nv):
            v = j / (nv - 1)
            for i in range(nth):
                th = angs[i]
                s0, s1 = s_range(i)
                s = lerp(s0, s1, v)
                fold = 1.0 + 0.05 * math.sin(s * L * 150.0 + 3.0 * noise.noise(V((math.cos(th) * 1.5, math.sin(th) * 1.5, s * 3.0)))) * smoothstep(0.0, 0.2, v)
                fold += 0.05 * noise.noise(V((math.cos(th) * 2.0 + 5.0, math.sin(th) * 2.0, s * 4.0 + sx)))
                verts.append(f + a * (s * L) + (u * math.cos(th) + w * math.sin(th)) * (cloth_r(s, i) * fold))
        for j in range(nv - 1):
            for i in range(nth):
                p_, q_ = j * nth + i, j * nth + (i + 1) % nth
                faces.append((p_, q_, q_ + nth, p_ + nth))
        sleeve = K.new_obj("sleeve", verts, faces, "canvas")
        K.fix_normals(sleeve, away_from=f + a * (L * 0.9))
        K.mod(sleeve, 'SOLIDIFY', thickness=0.0024, offset=1.0, use_even_offset=True)
        K.shade(sleeve, 60)
        lb, bb = K.Buf(), K.Buf()
        s_c = 0.97                                              # cinch strap round the wrist
        ring = [f + a * (s_c * L) + (u * math.cos(angs[i]) + w * math.sin(angs[i])) * (cloth_r(s_c, i) * 1.03 + 0.003) for i in range(nth)]
        rn = [(u * math.cos(t) + w * math.sin(t)) for t in angs]
        lb.add(K.strap(ring, rn, 0.022, 0.0030, closed=True))
        bb.add_all(K.buckle(ring[0] + rn[0] * 0.0030, rn[0], ring[1] - ring[-1], w=0.032, h=0.024, bar=0.0038, lift=0.002))
        s_end = s_range(0)[1]
        tail, tn = [], []
        for k in range(22):                                     # sewn along the top of the sleeve, then hanging free past the cuff
            s = lerp(s_c + 0.04, s_end + 0.46, k / 21.0)
            free = smoothstep(s_end - 0.02, s_end + 0.25, s)
            r_top = cloth_r(min(s, s_end), 0) * 1.03 + 0.0062
            tail.append(f + a * (s * L) + u * (r_top * (1.0 - 0.55 * free)) + w * (0.020 * sx * math.sin(free * math.pi) * free))
            tn.append(u)
        lb.add(K.strap(tail, tn, 0.022, 0.0030))
        bb.add_all(K.buckle(tail[-1] + u * 0.0030, u, a, w=0.032, h=0.026, bar=0.0040, lift=0.0015))
        bb.add(K.dome(tail[1] + u * 0.0030, u, 0.0045, 0.0028, seg=8, rings=1))
        node = side + "ForeArm__SleeveStrap"
        parts.append((node, K.join([sleeve, lb.obj("s_leather", "leather", 50), bb.obj("s_brass", "brass", 45)], node)))
    return parts


# =========================================================================== RIOT GUARD (tactical)
_SHELL = dict(tex="src_armor_shell.jpg", scale=3.0, rough=(0.64, 0.40), lum_range=(0.03, 0.35), bump=0.7, bump_dist=0.004, tint=(0.80, 0.80, 0.82),
              wear=dict(color=(0.19, 0.19, 0.20), amount=0.75, rough=0.42, radius=0.004, lo=0.90),
              blood=dict(amount=0.7, lo=0.60, scale=11.0), grime=dict(amount=0.40, color=(0.10, 0.085, 0.07), scale=4.0, rough=0.85))
_STEEL = dict(tex="src_rust_steel.jpg", scale=5.0, hsv=(0.5, 0.40, 0.85), tint=(0.50, 0.50, 0.53), rough=(0.82, 0.40), metal=(0.5, 0.95),
              lum_range=(0.05, 0.35), bump=0.7, bump_dist=0.004, wear=dict(color=(0.42, 0.42, 0.44), amount=0.6, rough=0.35, metal=1.0, radius=0.002))
K.SRC_SPECS.update({
    "shell_a": dict(final="RiotArmorA", **_SHELL),
    "shell_b": dict(final="RiotArmorB", **_SHELL),
    "steel_a": dict(final="RiotArmorA", **_STEEL),
    "steel_b": dict(final="RiotArmorB", **_STEEL),
    "plate_a": dict(final="RiotArmorA", tex="src_chest_plate.jpg", proj=True, crop=(0.07, 0.08, 0.93, 0.92), rough=(0.62, 0.36), lum_range=(0.03, 0.40),
                    bump=0.9, bump_dist=0.006, wear=dict(color=(0.19, 0.19, 0.20), amount=0.6, rough=0.42, radius=0.004, lo=0.90)),
    "fabric": dict(final="RiotFabric", tex="src_armor_fabric.jpg", scale=6.0, rough=(0.98, 0.84), bump=1.0, bump_dist=0.005,
                   blood=dict(amount=0.5, lo=0.58, rough=0.6), grime=dict(amount=0.45, color=(0.09, 0.075, 0.06), scale=5.0)),
    "visor": dict(final="RiotVisor", tex="src_visor.jpg", proj=True, crop=(0.13, 0.11, 0.87, 0.85), rough=(0.34, 0.14), lum_range=(0.15, 0.6), tint=(0.44, 0.47, 0.49),
                  bump=0.6, bump_dist=0.004),
})


def kit_riot(body):
    parts = []
    # ------------------------------------------------------------------ helmet
    hc = V((-0.003, 0.805, -0.012))
    ax, ay, az = 0.198, 0.181, 0.210
    S_EQ = 0.56

    def front_angle(th):
        return abs(math.atan2(math.sin(th), math.cos(th)))

    def rim_y(th):
        return lerp(0.792, 0.688, smoothstep(RAD(40), RAD(60), front_angle(th)))

    def shell_xy(th, y, grow=0.0):
        """Point on the shell (grown outward by `grow`) at azimuth th (0 = front, +X = left) and height y."""
        if y >= hc.y:
            k = math.sqrt(max(0.0, 1.0 - ((y - hc.y) / (ay + grow)) ** 2))
        else:
            k = 1.0 - 0.035 * ((hc.y - y) / 0.115) ** 2
        return V((hc.x + (ax + grow) * math.sin(th) * k, y, hc.z + (az + grow) * math.cos(th) * k))

    def shell(th, s):
        if s <= S_EQ:
            ph = (s / S_EQ) * math.pi / 2
            return hc + V((ax * math.sin(th) * math.sin(ph), ay * math.cos(ph), az * math.cos(th) * math.sin(ph)))
        return shell_xy(th, lerp(hc.y, rim_y(th), (s - S_EQ) / (1 - S_EQ)))

    nth = 48
    ths = [2 * math.pi * i / nth for i in range(nth)]
    v_, f_, _ = K.grid(shell, ths, K.linspace(0.07, 1.0, 14), close_u=True)
    pole = len(v_)
    v_.append(hc + V((0, ay, 0)))
    f_ += [(pole, (i + 1) % nth, i) for i in range(nth)]
    helmet = K.new_obj("helmet", v_, f_, "shell_a")
    K.fix_normals(helmet, away_from=hc)
    K.plate(helmet, 0.008, bevel=0.0022, offset=-1.0, sharp=45)
    # how well does it enclose the body's own helmet + goggles?  (shell = opaque helmet, face opening = behind the visor)
    radial, opening, exposed, total, worst_r, worst_y = 0, 0, 0, 0, 0.0, 0.0
    for o in body.objects:
        if not any(o.name[4:].startswith(p) for p in ("SkiGoggle", "WinterHelmet")):
            continue
        for vtx in o.data.vertices:
            p = vtx.co
            th = math.atan2(p.x - hc.x, p.z - hc.z)
            lim = shell_xy(th, max(p.y, rim_y(th)), -0.008)
            excess = math.hypot(p.x - hc.x, p.z - hc.z) - math.hypot(lim.x - hc.x, lim.z - hc.z)
            total += 1
            if excess > 0.0:
                radial += 1
                worst_r = max(worst_r, excess)
            elif p.y < rim_y(th):
                if front_angle(th) < RAD(74) and p.y > 0.66:
                    opening += 1
                else:
                    exposed += 1
                worst_y = max(worst_y, rim_y(th) - p.y)
    print(f"[riot] body helmet/goggle verts: {total} total; {radial} poke through the shell (worst {worst_r * 1000:.1f} mm); "
          f"{opening} sit in the face opening behind the visor (lowest {worst_y * 1000:.0f} mm under the brow); {exposed} below the rim elsewhere")

    trim, st_a, fab = K.Buf(), K.Buf(), K.Buf()
    rim_path = [shell_xy(2 * math.pi * i / 96, rim_y(2 * math.pi * i / 96), -0.004) for i in range(96)]
    trim.add(K.tube(rim_path, 0.0058, 6, closed=True))
    band_y = 0.819
    bth = K.linspace(RAD(-75), RAD(75), 31)
    bpts = [shell_xy(t, band_y, 0.0056) for t in bth]
    bnr = [V((math.sin(t), 0.0, math.cos(t))) for t in bth]
    st_a.add(K.strap(bpts, bnr, 0.026, 0.0040))
    for i in (3, 9, 15, 21, 27):
        st_a.add(K.dome(bpts[i] + bnr[i] * 0.0040, bnr[i], 0.0050, 0.0030, seg=8, rings=1))
    for t in (RAD(79), RAD(-79)):
        n = V((math.sin(t), 0.0, math.cos(t)))
        p = shell_xy(t, 0.812, 0.001)
        st_a.add(K.dome(p, n, 0.023, 0.013, seg=14, rings=2))
        st_a.add(K.dome(p + n * 0.0125, n, 0.0085, 0.0045, hex_head=True))
    for t in (RAD(128), RAD(-128), RAD(180)):                   # vent / liner studs on the back of the shell
        n = V((math.sin(t), 0.0, math.cos(t)))
        st_a.add(K.dome(shell_xy(t, 0.775, 0.0), n, 0.0060, 0.0034, seg=8, rings=1))

    def guard(u_, v_):                                           # padded neck guard hanging from inside the rim
        th = u_
        top = shell_xy(th, 0.708, -0.010)
        yb = 0.598 + 0.045 * (1.0 - smoothstep(RAD(66), RAD(118), front_angle(th)))
        bot = V((hc.x + (ax + 0.030) * math.sin(th), yb, hc.z + (az + 0.038) * math.cos(th)))
        p = top.lerp(bot, v_)
        return p + V((math.sin(th), 0.0, math.cos(th))) * (0.007 * math.sin(math.pi * v_))

    gv, gf, _ = K.grid(guard, K.linspace(RAD(64), RAD(296), 27), K.linspace(0, 1, 6))
    guard_ob = K.new_obj("neckguard", gv, gf, "fabric")
    K.fix_normals(guard_ob, away_from=hc + V((0, -0.15, 0)))
    K.plate(guard_ob, 0.007, bevel=0.0020, offset=-1.0, sharp=50)
    head = K.join([helmet, trim.obj("h_trim", "shell_a", 50), st_a.obj("h_steel", "steel_a", 40), guard_ob], "Head__Helmet")
    parts.append(("Head__Helmet", head))

    # ------------------------------------------------------------------ visor (own node + material)
    vy0 = 0.827

    def visor_pt(u_, v_):
        yb = 0.612 + 0.075 * smoothstep(RAD(46), RAD(76), abs(u_)) ** 1.5
        y = lerp(vy0, yb, v_)
        flare = 0.0015 + 0.016 * ((vy0 - y) / 0.215) ** 1.3
        k = math.sqrt(max(0.0, 1.0 - ((y - hc.y) / ay) ** 2)) if y >= hc.y else 1.0
        return V((hc.x + (ax + flare) * math.sin(u_) * k, y, hc.z + (az + flare) * math.cos(u_) * k))

    vv, vf, vpr = K.grid(visor_pt, K.linspace(RAD(-76), RAD(76), 27), K.linspace(0, 1, 10))
    visor = K.new_obj("visor", vv, vf, "visor", proj=vpr)
    K.fix_normals(visor, away_from=hc)
    K.plate(visor, 0.0035, bevel=0.0008, offset=1.0, sharp=50, segments=1)
    parts.append(("Head__Visor", visor))

    # ------------------------------------------------------------------ torso plates
    def torso(sign, node):
        yc, hh = (0.330, 0.162) if sign > 0 else (0.345, 0.150)
        kx, tilt = (1.55, -0.10) if sign > 0 else (1.15, 0.06)

        def hw(q):
            return lerp(0.172, 0.124, smoothstep(0.30, 1.0, q)) if sign > 0 else lerp(0.156, 0.126, smoothstep(0.4, 1.0, q))

        def surf0(x, y):
            return -kx * x * x - 0.30 * (y - yc) ** 2 + tilt * (y - yc)

        def body_z(x, y):
            h = body.ray((x, y, sign * 1.5), (0, 0, -sign))
            return None if h is None else sign * h.z

        z0 = -9.0
        for q in K.linspace(-0.95, 0.95, 13):
            for p in K.linspace(-0.95, 0.95, 13):
                x, y = p * hw(q), yc + q * hh
                bz = body_z(x, y)
                if bz is not None and bz < 0.40:
                    z0 = max(z0, bz - surf0(x, y))
        z0 += 0.014

        def face(scale_x=1.0, scale_y=1.0, dz=0.0):
            def fn(u_, v_):
                p_, q_ = K.squircle(u_, v_, 6.0)
                x, y = p_ * hw(q_) * scale_x, yc + q_ * hh * scale_y
                return V((x, y, sign * (z0 + surf0(x / scale_x, yc + q_ * hh) + dz)))
            return fn

        us = K.linspace(-1, 1, 13)
        cv, cf, _ = K.grid(face(1.10, 1.07, -0.0015), us, us)
        carrier = K.new_obj("carrier", cv, cf, "fabric")
        K.fix_normals(carrier, toward_dir=Z * sign)
        K.plate(carrier, 0.045, bevel=0.004, offset=-1.0, rim_only=True, sharp=50)
        pv, pf, ppr = K.grid(face(), us, us)
        hard = K.new_obj("hard", pv, pf, "plate_a" if sign > 0 else "shell_a", proj=ppr)
        K.fix_normals(hard, toward_dir=Z * sign)
        K.plate(hard, 0.010, bevel=0.0030, offset=1.0, rim_only=True, sharp=40)
        bolts, web = K.Buf(), K.Buf()
        fn = face()
        for (u_, v_) in ((-0.80, 0.80), (0.80, 0.80), (-0.84, 0.0), (0.84, 0.0), (-0.80, -0.82), (0.80, -0.82)):
            bolts.add(K.dome(fn(u_, v_) + Z * (sign * 0.0100), Z * sign, 0.0068, 0.0038, hex_head=True))
        for sx in (1, -1):                                        # webbing over the shoulder, split at the apex between the two plates
            x = 0.108 * sx
            c = V((x, 0.36, 0.02))
            edge = V((x, yc + hh * 1.02, sign * (z0 + surf0(x, yc + hh) - 0.012)))
            a_e = K.ang(c, Z, Y, edge)
            a0, a1 = (a_e - 0.10, RAD(92)) if sign > 0 else (RAD(88), a_e + 0.10)
            pts, nr, _ = K.arc_path(body, c, Z, Y, a0, a1, 22, R=0.28, clearance=0.003, smooth=5, rmax=0.28)
            web.add(K.strap(pts, nr, 0.048, 0.0050))
            i = 7 if sign > 0 else 14
            bolts.add_all(K.buckle(pts[i] + nr[i] * 0.0050, nr[i], pts[i + 1] - pts[i - 1], w=0.058, h=0.030, bar=0.0050, lift=0.002))
        return (node, K.join([hard, carrier, bolts.obj("t_bolts", "steel_a", 40), web.obj("t_web", "fabric", 50)], node))

    parts.append(torso(1, "Spine2__ChestPlate"))
    parts.append(torso(-1, "Spine2__BackPlate"))

    # ------------------------------------------------------------------ arms
    def shell_patch(name, mat, cen, rad_fn, a, u, w, s0, s1, ang_c, half, ns, na, thick, pad_fn, corner=5.0, rim_only=True):
        def fn(p, q):
            p_, q_ = K.squircle(p, q, corner)
            s = lerp(s0, s1, (q_ + 1) * 0.5)
            t = ang_c + half * p_
            return cen(s) + (u * math.cos(t) + w * math.sin(t)) * (rad_fn(s) + pad_fn(p_, q_))
        v2, f2, _ = K.grid(fn, K.linspace(-1, 1, na), K.linspace(-1, 1, ns))
        ob = K.new_obj(name, v2, f2, mat)
        K.fix_normals(ob, away_from=cen((s0 + s1) * 0.5))
        K.plate(ob, thick, bevel=0.0018, offset=1.0, rim_only=rim_only, sharp=42)
        return ob, fn

    def ring(cen, rad_fn, u, w, s, pad, n=24):
        pts = [cen(s) + (u * math.cos(2 * math.pi * i / n) + w * math.sin(2 * math.pi * i / n)) * (rad_fn(s) + pad) for i in range(n)]
        nrm = [(u * math.cos(2 * math.pi * i / n) + w * math.sin(2 * math.pi * i / n)) for i in range(n)]
        return pts, nrm

    for side, sx in (("Left", 1), ("Right", -1)):
        sh, el, wr = body.bone(side + "Arm"), body.bone(side + "ForeArm"), body.bone(side + "Hand")
        Lu = (el - sh).length
        cen, rad, a, u, w = K.fit_limb(body, sh, el, K.linspace(0.02, Lu * 0.95, 8), Y, RAD(-80), RAD(80), rmax=0.19, rlim=(0.075, 0.115), default_r=0.095)
        bolts, web = K.Buf(), K.Buf()
        cap, cap_fn = shell_patch("cap", "shell_b", cen, rad, a, u, w, -0.040, 0.122, 0.0, RAD(108), 9, 13, 0.0050,
                                  lambda p, q: 0.016 + 0.010 * math.cos(p * math.pi / 2) * math.cos(q * math.pi / 2) + 0.004 * math.exp(-(p / 0.16) ** 2)
                                  + 0.012 * (1.0 - smoothstep(-1.0, -0.35, q)), corner=4.0, rim_only=False)
        low, low_fn = shell_patch("low", "shell_b", cen, rad, a, u, w, 0.100, 0.218, 0.0, RAD(96), 7, 11, 0.0050,
                                  lambda p, q: 0.009 + 0.004 * math.exp(-(p / 0.16) ** 2), corner=5.0)
        for (p, q, fn_, th_) in ((-0.62, 0.35, cap_fn, 0.005), (0.62, 0.35, cap_fn, 0.005), (-0.66, 0.55, low_fn, 0.005), (0.66, 0.55, low_fn, 0.005)):
            pos = fn_(p, q)
            n_ = (pos - cen(0.1)).normalized()
            n_ = (n_ - a * n_.dot(a)).normalized()
            bolts.add(K.dome(pos + n_ * th_, n_, 0.0058, 0.0034, seg=8, rings=1))
        rp, rn = ring(cen, rad, u, w, 0.168, 0.0035)
        web.add(K.strap(rp, rn, 0.032, 0.0040, closed=True))
        node = side + "Arm__Pauldron"
        parts.append((node, K.join([cap, low, bolts.obj("p_bolts", "steel_b", 40), web.obj("p_web", "fabric", 50)], node)))

        Lf = (wr - el).length
        cen2, rad2, a2, u2, w2 = K.fit_limb(body, el, wr, K.linspace(0.03, Lf * 0.8, 7), Y, RAD(-75), RAD(75), rmax=0.17, rlim=(0.052, 0.085),
                                            default_r=0.065, max_off=0.10)
        bolts, web = K.Buf(), K.Buf()
        ac = RAD(-20.0 * sx)
        gd, gd_fn = shell_patch("guard", "shell_b", cen2, rad2, a2, u2, w2, 0.045, 0.252, ac, RAD(100), 9, 13, 0.0050,
                                lambda p, q: 0.010 + 0.0035 * (math.exp(-((p - 0.2) / 0.08) ** 2) + math.exp(-((p + 0.2) / 0.08) ** 2)), corner=5.0)
        rad_e = lambda s: rad2(max(s, 0.0))
        cup, _fn = shell_patch("elbow", "shell_b", cen2, rad_e, a2, u2, w2, -0.058, 0.062, ac - RAD(22.0 * sx), RAD(62), 8, 9, 0.0050,
                               lambda p, q: 0.012 + 0.022 * math.cos(p * math.pi / 2) * math.cos(q * math.pi / 2), corner=2.6, rim_only=False)
        for s in (0.085, 0.215):
            rp, rn = ring(cen2, rad2, u2, w2, s, 0.003)
            web.add(K.strap(rp, rn, 0.028, 0.0040, closed=True))
        for (p, q) in ((-0.7, -0.55), (0.7, -0.55), (-0.7, 0.62), (0.7, 0.62)):
            pos = gd_fn(p, q)
            n_ = (pos - cen2(0.15)).normalized()
            n_ = (n_ - a2 * n_.dot(a2)).normalized()
            bolts.add(K.dome(pos + n_ * 0.005, n_, 0.0052, 0.0030, seg=8, rings=1))
        node = side + "ForeArm__Guard"
        parts.append((node, K.join([gd, cup, bolts.obj("f_bolts", "steel_b", 40), web.obj("f_web", "fabric", 50)], node)))

    # ------------------------------------------------------------------ groin protector
    yt, yb = 0.005, -0.300

    def zc(v):
        return lerp(lerp(0.205, 0.172, v), lerp(0.172, 0.095, v), v)

    def groin(scale=1.0, dz=0.0, v0=0.0, v1=1.0):
        def fn(u_, v_):
            p_, q_ = K.squircle(u_, v_, 3.5)
            v2 = lerp(v0, v1, (q_ + 1) * 0.5)
            x = p_ * lerp(0.120, 0.070, v2 ** 1.3) * scale
            y = lerp(yt, yb, v2)
            z = zc(v2) - 1.6 * x * x
            if y < -0.12:
                h = body.ray((x, y, 1.0), (0, 0, -1))
                if h is not None and h.z < 0.25:
                    z = max(z, h.z + 0.010)
            return V((x, y, z + dz))
        return fn

    us = K.linspace(-1, 1, 11)
    gv, gf, _ = K.grid(groin(), us, us)
    pad = K.new_obj("pad", gv, gf, "fabric")
    K.fix_normals(pad, toward_dir=Z)
    K.plate(pad, 0.014, bevel=0.004, offset=1.0, sharp=50)
    gv, gf, _ = K.grid(groin(0.80, 0.0148, 0.14, 0.93), us, us)
    gpl = K.new_obj("gplate", gv, gf, "shell_a")
    K.fix_normals(gpl, toward_dir=Z)
    K.plate(gpl, 0.0060, bevel=0.0020, offset=1.0, rim_only=True, sharp=42)
    web, bolts = K.Buf(), K.Buf()
    for sx in (1, -1):
        path = [V((0.074 * sx, yt - 0.03, 0.212)), V((0.078 * sx, yt + 0.02, 0.212)), V((0.084 * sx, yt + 0.075, 0.190))]
        web.add(K.strap(path, [Z] * 3, 0.038, 0.0045))
        bolts.add(K.dome(groin(0.80, 0.0208, 0.14, 0.93)(0.72 * sx, -0.8), Z, 0.0058, 0.0034, seg=8, rings=1))
    parts.append(("Hips__GroinGuard", K.join([pad, gpl, web.obj("g_web", "fabric", 50), bolts.obj("g_bolts", "steel_a", 40)], "Hips__GroinGuard")))

    # ------------------------------------------------------------------ knee + shin guards
    for side, sx in (("Left", 1), ("Right", -1)):
        kn, ft = body.bone(side + "Leg"), body.bone(side + "Foot")
        a, u, w = K.frame_from(ft - kn, Z)
        nt = 24
        angs = [2 * math.pi * i / nt for i in range(nt)]
        svals = K.linspace(-0.10, 0.43, 13)
        table = []
        for s in svals:
            raw = K.fill_none(K.polar_radii(body, kn + a * s, u, w, angs, R=0.28, rmax=0.2), True, 0.10)
            sm = K.smooth_list(raw, 3, True)
            table.append([max(p, q) for p, q in zip(raw, sm)])
        for i in range(nt):
            col = [row[i] for row in table]
            sm = K.smooth_list(col, 3)
            for j, row in enumerate(table):
                row[i] = max(col[j], sm[j])

        def leg_r(s, t):
            x = (min(max(s, svals[0]), svals[-1]) - svals[0]) / (svals[-1] - svals[0]) * (len(svals) - 1)
            j = min(int(x), len(svals) - 2)
            y = (t % (2 * math.pi)) / (2 * math.pi) * nt
            i = int(y) % nt
            fy = y - int(y)
            r0 = lerp(table[j][i], table[j][(i + 1) % nt], fy)
            r1 = lerp(table[j + 1][i], table[j + 1][(i + 1) % nt], fy)
            return lerp(r0, r1, x - j)

        def leg_patch(name, s0, s1, half0, half1, ns, na, thick, pad_fn, corner, rim_only=True):
            def fn(p, q):
                p_, q_ = K.squircle(p, q, corner)
                f = (q_ + 1) * 0.5
                s = lerp(s0, s1, f)
                t = lerp(half0, half1, f) * p_
                return kn + a * s + (u * math.cos(t) + w * math.sin(t)) * (leg_r(s, t) + pad_fn(p_, q_))
            v2, f2, _ = K.grid(fn, K.linspace(-1, 1, na), K.linspace(-1, 1, ns))
            ob = K.new_obj(name, v2, f2, "shell_b")
            K.fix_normals(ob, away_from=kn + a * ((s0 + s1) * 0.5))
            K.plate(ob, thick, bevel=0.0020, offset=1.0, rim_only=rim_only, sharp=42)
            return ob, fn

        knee, knee_fn = leg_patch("knee", -0.085, 0.064, RAD(80), RAD(80), 9, 11, 0.0055,
                                  lambda p, q: 0.010 + 0.026 * (math.cos(p * math.pi / 2) ** 0.8) * (math.cos(q * math.pi / 2) ** 0.8), 2.8, rim_only=False)
        shin, shin_fn = leg_patch("shin", 0.048, 0.408, RAD(84), RAD(62), 12, 11, 0.0060,
                                  lambda p, q: 0.009 + 0.006 * math.exp(-(p / 0.15) ** 2) + 0.003 * (math.exp(-((p - 0.5) / 0.07) ** 2) + math.exp(-((p + 0.5) / 0.07) ** 2)), 5.0)
        web, bolts = K.Buf(), K.Buf()
        for s, wd in ((-0.012, 0.030), (0.130, 0.034), (0.330, 0.034)):
            tight = K.smooth_list(K.fill_none(K.polar_radii(body, kn + a * s, u, w, angs, R=0.28, rmax=0.2), True, 0.10), 1, True)
            pts = [kn + a * s + (u * math.cos(t) + w * math.sin(t)) * (max(tight[i], leg_r(s, t) - 0.012) + 0.004) for i, t in enumerate(angs)]
            web.add(K.strap(pts, [(u * math.cos(t) + w * math.sin(t)) for t in angs], wd, 0.0040, closed=True))
        for (p, q, fn_, th_) in ((-0.72, -0.72, shin_fn, 0.006), (0.72, -0.72, shin_fn, 0.006), (-0.70, 0.70, shin_fn, 0.006), (0.70, 0.70, shin_fn, 0.006),
                                 (-0.78, 0.0, knee_fn, 0.0055), (0.78, 0.0, knee_fn, 0.0055)):
            pos = fn_(p, q)
            n_ = pos - (kn + a * (pos - kn).dot(a))
            n_.normalize()
            bolts.add(K.dome(pos + n_ * th_, n_, 0.0058, 0.0034, seg=8, rings=1))
        node = side + "Leg__ShinGuard"
        parts.append((node, K.join([knee, shin, bolts.obj("l_bolts", "steel_b", 40), web.obj("l_web", "fabric", 50)], node)))
    return parts


# =========================================================================== registry
KITS = {
    "spitter": dict(variant="patient", build=kit_spitter, file="zombie_kit_spitter.glb", bake=dict(ao_tint=0.30),
                    shots=[("front", (0, 1.12, 0), (0, 0, 1), 2.45, (1000, 1000)), ("left", (0, 1.12, 0), (1, 0, 0), 2.45, (700, 1000)),
                           ("34", (0, 1.12, 0), (0.62, 0.22, 0.75), 2.45, (1000, 1000)),
                           ("c_front", (0, 1.66, 0.1), (0, 0, 1), 0.95, (900, 900)), ("c_left", (0, 1.66, 0.1), (1, 0, 0), 0.95, (900, 900)),
                           ("c_34", (0, 1.66, 0.1), (0.62, 0.22, 0.75), 0.95, (900, 900)), ("c_34r", (0, 1.66, 0.1), (-0.7, 0.1, 0.7), 0.95, (900, 900)),
                           ("c_low", (0, 1.62, 0.1), (0.3, -0.5, 0.8), 0.95, (900, 900))]),
    "bloater": dict(variant="patient", build=kit_bloater, file="zombie_kit_bloater.glb",
                    shots=[("front", (0, 1.12, 0), (0, 0, 1), 2.45, (1000, 1000)), ("left", (0, 1.12, 0), (1, 0, 0), 2.45, (700, 1000)),
                           ("34", (0, 1.12, 0), (-0.62, 0.22, 0.75), 2.45, (1000, 1000)),
                           ("c_front", (-0.03, 1.74, 0.0), (0, 0, 1), 0.85, (900, 900)), ("c_right", (-0.03, 1.74, 0.0), (-1, 0, 0), 0.85, (900, 900)),
                           ("c_34", (-0.03, 1.74, 0.0), (-0.62, 0.3, 0.72), 0.85, (900, 900)), ("c_back", (-0.03, 1.74, 0.0), (-0.25, 0.2, -1), 0.85, (900, 900)),
                           ("c_top", (-0.05, 1.74, 0.0), (-0.2, 1, 0.25), 0.85, (900, 900))]),
    "screamer": dict(variant="patient", build=kit_screamer, file="zombie_kit_screamer.glb",
                     shots=[("front", (0, 1.12, 0), (0, 0, 1), 2.45, (1000, 1000)), ("left", (0, 1.12, 0), (1, 0, 0), 2.45, (700, 1000)),
                            ("34", (0, 1.12, 0), (0.62, 0.22, 0.75), 2.45, (1000, 1000)),
                            ("h_front", (0, 2.03, 0.02), (0, 0, 1), 0.46, (900, 900)), ("h_left", (0, 2.03, 0.02), (1, 0, 0), 0.46, (900, 900)),
                            ("h_34", (0, 2.03, 0.02), (0.62, 0.25, 0.72), 0.46, (900, 900)), ("h_back", (0, 2.03, 0.02), (-0.5, 0.35, -0.8), 0.46, (900, 900)),
                            ("t_front", (0, 1.68, 0.0), (0, 0, 1), 0.62, (900, 900)), ("t_34", (0, 1.68, 0.0), (0.62, 0.22, 0.75), 0.62, (900, 900)),
                            ("t_back", (0, 1.68, 0.0), (0.3, 0.2, -1), 0.62, (900, 900)),
                            ("a_left", (0.95, 1.77, 0.0), (0.2, 0.45, 1), 0.72, (900, 900)), ("a_right", (-0.95, 1.77, 0.0), (-0.2, 0.6, 0.8), 0.72, (900, 900)),
                            ("a_end", (0.95, 1.77, 0.0), (1, 0.3, 0.5), 0.5, (900, 900))]),
    "riot": dict(variant="tactical", build=kit_riot, file="zombie_kit_riot.glb", body=dict(fit_skip=("SkiGoggle", "WinterHelmet")),
                 bake=dict(ao_dist=0.08),
                 shots=[("front", (0, -0.1, 0), (0, 0, 1), 2.45, (1000, 1000)), ("left", (0, -0.1, 0), (1, 0, 0), 2.45, (700, 1000)),
                        ("34", (0, -0.1, 0), (0.62, 0.22, 0.75), 2.45, (1000, 1000)), ("back", (0, -0.1, 0), (-0.3, 0.2, -1), 2.45, (1000, 1000)),
                        ("h_front", (0, 0.76, 0.0), (0, 0, 1), 0.62, (900, 900)), ("h_left", (0, 0.76, 0.0), (1, 0, 0), 0.62, (900, 900)),
                        ("h_34", (0, 0.76, 0.0), (0.62, 0.2, 0.75), 0.62, (900, 900)), ("h_back", (0, 0.76, 0.0), (-0.5, 0.25, -0.8), 0.62, (900, 900)),
                        ("t_front", (0, 0.25, 0.0), (0, 0, 1), 1.25, (900, 900)), ("t_34", (0, 0.25, 0.0), (0.62, 0.3, 0.72), 1.25, (900, 900)),
                        ("t_back", (0, 0.25, 0.0), (-0.35, 0.3, -1), 1.25, (900, 900)), ("t_top", (0, 0.3, 0.0), (0.25, 1, 0.45), 1.25, (900, 900)),
                        ("l_front", (0, -0.6, 0.0), (0, 0, 1), 1.15, (900, 900)), ("l_34", (0, -0.6, 0.0), (0.62, 0.2, 0.75), 1.15, (900, 900)),
                        ("l_left", (0, -0.6, 0.0), (1, 0.1, 0.2), 1.15, (900, 900))]),
}


def build(kit, stage):
    spec = KITS[kit]
    K.reset_scene()
    body = K.Body(spec["variant"], **spec.get("body", {}))
    parts = spec["build"](body)
    names = [n for n, _o in parts]
    print(f"[kit] {kit}: " + ", ".join(f"{n}={K.tri_count(o)}" for n, o in parts) + f"  TOTAL={sum(K.tri_count(o) for _n, o in parts)}")
    if stage == "geo":
        cam = K.setup_studio('BLENDER_EEVEE')
        for (nm, c, d, s, res) in spec["shots"]:
            K.shot(cam, c, d, s, os.path.join(K.RENDERS, f"{kit}_geo_{nm}.jpg"), res)
        return
    for i, (_n, o) in enumerate(parts):
        K.ensure_prox(o)
        K.tag_part(o, i)
    kit_ob = K.join([o for _n, o in parts], "KIT_" + kit)
    finals = []
    for m in kit_ob.data.materials:
        if m["final"] not in finals:
            finals.append(m["final"])
    K.unwrap_atlases(kit_ob, finals)
    mats = K.bake_atlases(kit, kit_ob, finals, **spec.get("bake", {}))
    K.assign_finals(kit_ob, mats)
    nodes = K.split_parts(kit_ob, names)
    for o in nodes:
        K.freeze(o)
    out = os.path.join(OUT_MODELS, spec["file"])
    K.export_glb(out, nodes)
    print(f"[kit] exported {out} ({os.path.getsize(out) / 1e6:.2f} MB)")
    for o in nodes:
        print(f"[node] {kit} {o.name} tris={K.tri_count(o)} mats={[m.name for m in o.data.materials]}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(K.KITDIR, "work", f"{kit}.blend"), compress=True)
    cam = K.setup_studio('BLENDER_EEVEE')
    for (nm, c, d, s, res) in spec["shots"]:
        K.shot(cam, c, d, s, os.path.join(K.RENDERS, f"{kit}_{nm}.jpg"), res)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    kit, stage = "all", "full"
    for i, a in enumerate(argv):
        if a == "--kit":
            kit = argv[i + 1]
        if a == "--stage":
            stage = argv[i + 1]
    for k in (list(KITS) if kit == "all" else kit.split(",")):
        build(k, stage)


main()
