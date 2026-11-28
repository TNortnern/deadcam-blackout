#!/usr/bin/env python3
"""DEADCAM: BLACKOUT - photoreal environment props (Blender 5.3 headless).

    blender -b -P tools/build_env_props.py -- [prop ...] [--out DIR] [--nocache] [--samples N]

Builds assets/models/prop_*.glb (boiler, morgue_table, morgue_drawers, breach_gate, perk_cabinet,
stair_collapse, gurney). Texture sources are prepared by tools/gen_env_prop_sources.py into the
scratch dir; geometry + bake + wear compositing live in tools/env_props_kit.py.

Conventions: metres, +Y up, origin on the floor at the footprint centre (breach gate: hinge edge),
front toward +Z. Named child nodes are separate meshes with their origin on the stated pivot.
"""
import os
import sys
import math
import random

import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import env_props_kit as K
from env_props_kit import (IRON, PAINT, ENAMEL, BRASS, STEEL, BRICK, WOOD, PLASTER, GLASS, BOTTLE, CANVAS, LEATHER,
                           RUBBER, COAL, DECAL, GALV, RUBBLE, SOOT, LAMP, T, R, V, orient, round_path, arc_pts, ss,
                           PI)

SCRATCH = K.SCRATCH
cosd = lambda a: math.cos(math.radians(a))
sind = lambda a: math.sin(math.radians(a))


def fill_ring(part, outer, inner, normal=(0, 1, 0)):
    """Triangulate the area between an outer vertex loop and an inner hole loop."""
    bm = part.bm
    edges = []
    for loop in (outer, inner):
        for i in range(len(loop)):
            a, b = loop[i], loop[(i + 1) % len(loop)]
            e = bm.edges.get((a, b)) or bm.edges.new((a, b))
            edges.append(e)
    res = bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=edges, normal=normal)
    faces = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)]
    bm.normal_update()
    n = Vector(normal)
    flip = [f for f in faces if f.normal.dot(n) < 0]
    if flip:
        bmesh.ops.reverse_faces(bm, faces=flip)
    return faces


# =============================================================================================
# 2. Autopsy table
# =============================================================================================
def build_morgue_table():
    P = K.Prop("prop_morgue_table", ["table"], edge_r=0.010, cav_dist=0.035, voxel=0.012, dust=0.35, seed=2,
               streak_len=0.22)
    WHITE = [0.84, 0.83, 0.77]
    drain = (0.80, 0.0)

    # --- porcelain-enamelled top: rolled rim, perimeter gutter, bed at y = 0.92
    top = P.part(ENAMEL, col=WHITE, wear=1.45, rust=1.2, sharp=50)
    prof = [(0.016, 0.862), (0.004, 0.866), (0.0, 0.876), (0.0, 0.936), (0.004, 0.949), (0.013, 0.956),
            (0.026, 0.957), (0.038, 0.952), (0.046, 0.940), (0.054, 0.916), (0.062, 0.907), (0.074, 0.904),
            (0.088, 0.906), (0.098, 0.913), (0.108, 0.9195), (0.122, 0.92)]
    vs = top.rrloft(2.2, 0.85, 0.11, prof, n=6, caps=(True, False))
    cnt = 4 * 7
    last = vs[-cnt:]
    hole = [top.bm.verts.new((drain[0] + 0.05 * math.cos(-2 * PI * k / 18), 0.92, drain[1] + 0.05 * math.sin(-2 * PI * k / 18)))
            for k in range(18)]
    fill_ring(top, last, hole)
    # funnel down into the drain (inward facing)
    top.lathe([(0.05, 0.0), (0.043, -0.006), (0.036, -0.02), (0.033, -0.04)], segs=18, m=T(drain[0], 0.92, drain[1]))
    # two shallow longitudinal blood grooves modelled into the bed surface as raised ribs between them
    for z in (-0.16, 0.16):
        rib = P.part(ENAMEL, col=WHITE, wear=0.8)
        rib.rrloft(1.50, 0.022, 0.011, [(0.0, 0.9195), (0.002, 0.9235), (0.007, 0.9255)], n=3, caps=(False, True),
                   m=T(-0.12, 0, z))
    # brass strainer + waste pipe
    br = P.part(BRASS, col=[0.95, 0.9, 0.8])
    br.lathe([(0.0, 0.881), (0.0335, 0.881), (0.0335, 0.884), (0.0, 0.884)][1:], segs=18, m=T(drain[0], 0, drain[1]))
    br.lathe([(0.0335, 0.8835), (0.012, 0.886), (0.0, 0.8865)], segs=18, m=T(drain[0], 0, drain[1]))
    for k in range(6):
        a = k * PI / 3
        br.lathe([(0.004, 0.0), (0.004, 0.0012), (0.0, 0.0012)], segs=6,
                 m=T(drain[0] + 0.02 * math.cos(a), 0.8848, drain[1] + 0.02 * math.sin(a)))
    hole_d = P.part(SOOT)
    for k in range(6):
        a = k * PI / 3
        hole_d.lathe([(0.0042, 0.0), (0.0, 0.0)], segs=6, m=T(drain[0] + 0.02 * math.cos(a), 0.8862, drain[1] + 0.02 * math.sin(a)))
    pipe = P.part(BRASS, col=[0.8, 0.8, 0.75])
    pipe.lathe([(0.03, 0.70), (0.03, 0.80), (0.046, 0.806), (0.046, 0.826), (0.036, 0.832), (0.036, 0.863)], segs=14,
               m=T(drain[0], 0, drain[1]))
    pipe.lathe([(0.0, 0.70), (0.03, 0.70)], segs=14, m=T(drain[0], 0, drain[1]))
    pipe.ring((drain[0], 0.74, drain[1]), (0, 1, 0), 0.031, 0.006, segs=14)

    # --- cast pedestal (white stove-enamel paint, heavily chipped)
    ped = P.part(PAINT, col=[0.84, 0.83, 0.77], wear=1.5, rust=1.3, gloss=0.35, sharp=35)
    ped.lathe([(0.33, 0.0), (0.33, 0.028), (0.318, 0.040), (0.25, 0.046), (0.215, 0.060), (0.17, 0.10), (0.132, 0.17),
               (0.112, 0.25), (0.106, 0.31), (0.122, 0.318), (0.126, 0.333), (0.122, 0.348), (0.104, 0.356),
               (0.094, 0.50), (0.092, 0.64), (0.108, 0.648), (0.112, 0.662), (0.108, 0.676), (0.094, 0.684),
               (0.100, 0.74), (0.130, 0.80), (0.185, 0.838), (0.20, 0.848), (0.20, 0.862)], segs=28)
    # flutes are implied by 8 raised ribs on the lower bell
    for k in range(8):
        a = k * PI / 4 + PI / 8
        rib = P.part(PAINT, col=[0.84, 0.83, 0.77], wear=1.6, rust=1.3)
        pts = [(0.262, 0.050), (0.212, 0.066), (0.168, 0.106), (0.132, 0.172), (0.113, 0.25), (0.108, 0.30)]
        rib.tube([V(r * math.cos(a), h, r * math.sin(a)) for r, h in pts], 0.011, segs=6, caps=True,
                 up=V(math.cos(a), 0, math.sin(a)))
    bolts = P.part(STEEL, rust=1.5)
    for k in range(4):
        a = k * PI / 2 + PI / 4
        bolts.hexbolt((0.288 * math.cos(a), 0.041, 0.288 * math.sin(a)), (0, 1, 0), r=0.016, h=0.014, spin=k * 0.4)
    # cruciform cast bracket under the slab
    brk = P.part(PAINT, col=[0.84, 0.83, 0.77], wear=1.4, rust=1.4)
    for ang, L in ((0, 0.86), (180, 0.86), (90, 0.33), (-90, 0.33)):
        brk.extrude([(0.0, -0.17), (0.12, -0.165), (L, -0.035), (L, 0.0), (0.0, 0.0)], 0.05,
                    m=T(0, 0.862, 0) @ R('Y', ang), bevel=0.007, segs=2)
    brk.rrloft(0.56, 0.36, 0.05, [(0.0, 0.838), (0.0, 0.856), (0.006, 0.862)], n=4, caps=(True, False))
    # tilt hand-wheel on the column
    hw = P.part(IRON, col=[0.9, 0.9, 0.9], rust=0.8)
    hw.tube([V(0, 0.56, 0.08), V(0, 0.56, 0.215)], 0.013, segs=8)
    hw.lathe([(0.03, 0.0), (0.03, 0.03), (0.02, 0.036), (0.0, 0.036)], segs=10, m=orient((0, 0.56, 0.19), (0, 0, 1)))
    hw.ring((0, 0.56, 0.205), (0, 0, 1), 0.095, 0.010, segs=20, tsegs=6)
    for k in range(4):
        a = k * PI / 2 + 0.5
        hw.tube([V(0.02 * math.cos(a), 0.56 + 0.02 * math.sin(a), 0.205),
                 V(0.09 * math.cos(a), 0.56 + 0.09 * math.sin(a), 0.205)], 0.007, segs=6)
    hw.lathe([(0.012, 0.0), (0.014, 0.04), (0.011, 0.07), (0.0, 0.074)], segs=8,
             m=orient((0.095 * math.cos(0.5), 0.56 + 0.095 * math.sin(0.5), 0.212), (0, 0, 1)))

    # --- oak neck block at the head end
    blk = P.part(WOOD, tex="oak_dark", col=[0.9, 0.85, 0.8], varnish=0.5, sharp=45)
    poly = [(-0.13, 0.0), (0.13, 0.0), (0.13, 0.082)] + \
           [(0.105 * math.cos(math.radians(a)), 0.092 + 0.05 * math.sin(math.radians(a))) for a in range(0, -181, -20)] + \
           [(-0.13, 0.082)]
    blk.extrude(poly, 0.115, bevel=0.005, segs=1)
    blk.xf(T(-0.83, 0.9205, 0.0) @ R('Y', 97))

    # --- galvanised slop bucket under the drain
    bk = P.part(GALV, sharp=50)
    bk.lathe([(0.105, 0.0), (0.107, 0.012), (0.146, 0.27), (0.151, 0.276), (0.151, 0.283), (0.144, 0.285),
              (0.139, 0.276), (0.103, 0.016), (0.0, 0.014)], segs=22)
    bk.ring((0, 0.10, 0), (0, 1, 0), 0.121, 0.004, segs=22, tsegs=5)
    bk.tube([V(0.154 * math.cos(math.radians(a)), 0.262 - 0.34 * 0.154 * math.sin(math.radians(a)),
               0.154 * math.sin(math.radians(a)) * 0.95) for a in range(0, 181, 15)], 0.004, segs=6)
    for sx in (-1, 1):
        bk.box(0.012, 0.04, 0.03, m=T(sx * 0.152, 0.25, 0), bevel=0.003)
    bk.xf(T(drain[0] + 0.02, 0.0, drain[1] + 0.03) @ R('Y', 25))
    slop = P.part(SOOT, col=[0.09, 0.03, 0.025])
    slop.lathe([(0.118, 0.11), (0.0, 0.11)], segs=22, m=T(drain[0] + 0.02, 0.0, drain[1] + 0.03))

    def hook(tx, a):
        Pp = tx.P
        d = np.hypot(Pp[:, 0] - drain[0], Pp[:, 2] - drain[1])
        n1 = tx.fbm(5.0, 4, 301)
        n2 = tx.fbm(1.6, 3, 302)
        on_top = (Pp[:, 1] > 0.895) & (tx.N[:, 1] > 0.2)
        gutter = ss(0.9165, 0.908, Pp[:, 1]) * on_top
        pool = ss(0.42, 0.04, d + (n1 - 0.5) * 0.3) * on_top
        splat = ss(0.60, 0.74, n2 + ss(0.5, 0.0, np.abs(Pp[:, 0] + 0.1)) * 0.12) * on_top * ss(0.45, 0.6, n1)
        tx.F["blood"] = np.clip(gutter * (0.55 + 0.6 * n1) * ss(-1.2, 0.9, Pp[:, 0]) + pool * 0.85 + splat * 0.7, 0, 1).astype(np.float32)
        tx.F["stain"] = (ss(0.5, 0.75, n2) * 0.25 * on_top + ss(0.862, 0.90, Pp[:, 1]) * 0 +
                         ((Pp[:, 1] < 0.87) & (Pp[:, 1] > 0.855)) * 0.35).astype(np.float32)
        # inside of the bucket and waste pipe are wet / dark
        tx.F["dirt"] = (ss(0.25, 0.0, d) * (Pp[:, 1] < 0.86) * 0.4).astype(np.float32)
    P.hook = hook
    return P


def hinge_node(P, name, pivot, axis, deg):
    """Register node `name` pivoting at `pivot`; returns the matrix that poses closed-pose geometry ajar."""
    Tp = T(*pivot)
    M = Tp @ R(axis, deg)
    P.node(name, M)
    return M @ Tp.inverted()


def loop_wall(part, loop, offset, inward=False):
    """Extrude a closed point loop by `offset`; faces point away from the loop centre (or toward it)."""
    bm = part.bm
    A = [bm.verts.new(p) for p in loop]
    B = [bm.verts.new(Vector(p) + Vector(offset)) for p in loop]
    faces = []
    for i in range(len(loop)):
        j = (i + 1) % len(loop)
        faces.append(bm.faces.new([A[i], B[i], B[j], A[j]]))
    bm.normal_update()
    c = sum((Vector(p) for p in loop), Vector()) / len(loop) + Vector(offset) * 0.5
    out = sum(f.normal.dot(f.calc_center_median() - c) for f in faces)
    if (out > 0) == inward:
        bmesh.ops.reverse_faces(bm, faces=faces)
    return A, B


def valve(part, pos, axis, r=0.03, L=0.12, wheel=0.0, wheel_axis=(0, 1, 0)):
    """Small cock: flanged body along `axis` with a bonnet and optional hand-wheel along wheel_axis."""
    m = orient(pos, axis)
    part.lathe([(r * 1.5, 0.0), (r * 1.5, L * 0.12), (r, L * 0.16), (r, L * 0.34), (r * 1.45, L * 0.42),
                (r * 1.45, L * 0.62), (r, L * 0.70), (r, L * 0.88), (r * 1.3, L * 0.9), (r * 1.3, L), (0, L)], segs=10, m=m)
    c = Vector(pos) + Vector(axis).normalized() * L * 0.52
    wa = Vector(wheel_axis).normalized()
    part.lathe([(r * 0.8, 0.0), (r * 0.8, r * 2.2), (r * 0.45, r * 2.5), (r * 0.45, r * 4.4), (0, r * 4.4)], segs=8,
               m=orient(c + wa * r * 1.2, wa))
    if wheel > 0:
        wc = c + wa * (r * 5.2)
        part.ring(wc, wa, wheel, wheel * 0.13, segs=14, tsegs=5)
        mm = orient(wc, wa)
        for k in range(4):
            a = k * PI / 2
            part.tube([mm @ V(0, 0, 0), mm @ V(wheel * math.cos(a), 0, wheel * math.sin(a))], wheel * 0.09, segs=5, caps=False)
    return c


FACE_NX = R('Y', -90)   # part-local +Z -> world -X (local X -> world +Z)
FACE_PX = R('Y', 90)    # part-local +Z -> world +X


# =============================================================================================
# 1. Fire-tube steam boiler
# =============================================================================================
def build_boiler():
    P = K.Prop("prop_boiler", ["shell", "fit", "base"], edge_r=0.022, ao_dist=0.9, cav_dist=0.07, voxel=0.02,
               streak_len=0.6, dust=0.45, seed=1, samples=16, normal_strength=2.6, streak=1.4,
               uv_pack='CONCAVE')
    CY, RO, RI, RS = 1.80, 1.335, 1.320, 1.350
    XF, XS, XR = -2.60, 1.96, 2.66
    AX = orient((0, CY, 0), (1, 0, 0))
    BLK = [0.72, 0.74, 0.78]

    def cp(x, ang, r):
        return V(x, CY + r * cosd(ang), r * sind(ang))

    def cn(ang):
        return V(0, cosd(ang), sind(ang))

    def arc_plate(part, r0, t, x0, x1, a0, a1, segs):
        vs = part.lathe([(r0, x0), (r0 + t, x0 + t * 0.4), (r0 + t, x1 - t * 0.4), (r0, x1)], segs=segs, arc=(-a1, -a0), m=AX)
        n = segs + 1
        c = sum((v.co for v in vs), Vector()) / len(vs)
        for j in (0, n - 1):
            f = part.bm.faces.new([vs[k * n + j] for k in range(4)])
            f.normal_update()
            if f.normal.dot(f.calc_center_median() - c) < 0:
                f.normal_flip()

    # ---------------- shell courses (front half modelled, mirrored to the back)
    sh = P.part(IRON, atlas=0, mirror=True, col=BLK, rust=1.2, sharp=30)
    edges = [-2.64, -1.49, -0.34, 0.81, XS]
    for i in range(4):
        x0, x1 = edges[i], edges[i + 1]
        if i % 2 == 0:
            a = x0 - (0.0 if i == 0 else 0.07)
            b = x1 + 0.07
            sh.lathe([(RO - 0.016, a), (RO, a), (RO, b), (RO - 0.016, b)], segs=30, arc=(-180, 0), m=AX)
        else:
            sh.lathe([(RI, x0), (RI, x1)], segs=30, arc=(-180, 0), m=AX)
    sh.lathe([(RS - 0.02, XS - 0.05), (RS, XS - 0.05), (RS, XR + 0.02), (RS - 0.02, XR + 0.02)], segs=30, arc=(-180, 0), m=AX)
    strap_ang = [62, 48, 66, 44]
    for i in range(4):
        x0, x1 = edges[i] + 0.10, edges[i + 1] - 0.10
        r0 = RO if i % 2 == 0 else RI
        arc_plate(sh, r0 - 0.002, 0.016, x0, x1, strap_ang[i] - 5.4, strap_ang[i] + 5.4, 3)
    for xc in (-1.5, 1.45):      # saddle wear plates over the cradles
        arc_plate(sh, RO - 0.004, 0.022, xc - 0.34, xc + 0.34, 118, 180, 8)
    rv = P.part(IRON, atlas=0, mirror=True, col=BLK, rust=1.25, sharp=80)
    pitch = 0.150

    def rivet_row(x, r, a0=3.0, a1=177.0, stagger=False):
        n = int((math.radians(a1 - a0) * r) / pitch)
        for k in range(n + 1):
            ang = a0 + (a1 - a0) * (k + (0.5 if stagger else 0.0)) / (n + 1)
            if ang > 121 and (abs(x + 1.5) < 0.36 or abs(x - 1.45) < 0.36):
                continue
            rv.rivet(cp(x, ang, r), cn(ang), r=0.025, segs=6)

    rivet_row(-2.585, RO)
    for xs_, sgn in ((edges[1], 1), (edges[2], -1), (edges[3], 1)):
        rivet_row(xs_ + sgn * 0.022, RO)
        rivet_row(xs_ + sgn * 0.055, RO, stagger=True)
    rivet_row(XS - 0.02, RS)
    rivet_row(XR - 0.04, RS, stagger=True)
    for i in range(4):
        x0, x1 = edges[i] + 0.16, edges[i + 1] - 0.16
        r0 = (RO if i % 2 == 0 else RI) + 0.014
        n = int((x1 - x0) / 0.15)
        for k in range(n + 1):
            for da in (-2.9, 2.9):
                rv.rivet(cp(x0 + (x1 - x0) * k / n, strap_ang[i] + da, r0), cn(strap_ang[i] + da), r=0.022, segs=6)
    for xc in (-1.5, 1.45):
        for k in range(7):
            ang = 124 + k * 8.6
            for dx in (-0.27, 0.27):
                rv.rivet(cp(xc + dx, ang, RO + 0.018), cn(ang), r=0.022, segs=6)

    # ---------------- front end plate with the furnace mouth
    fp = P.part(IRON, atlas=1, col=BLK, rust=1.1, sharp=35)
    hw_, hb, hs = 0.36, 1.02, 1.36      # mouth half width, sill, spring line
    mouth = [(-hw_, hb), (hw_, hb)] + [(hw_ * cosd(a), hs + hw_ * sind(a)) for a in range(0, 181, 15)]
    outer = [fp.bm.verts.new((XF, CY + 1.275 * math.cos(2 * PI * k / 56), 1.275 * math.sin(2 * PI * k / 56))) for k in range(56)]
    inner = [fp.bm.verts.new((XF, y, z)) for z, y in mouth]
    fill_ring(fp, outer, inner, normal=(-1, 0, 0))
    fp.lathe([(1.275, XF), (1.300, XF - 0.006), (1.315, XF - 0.022), (1.319, -2.64)], segs=56, m=AX)
    frv = P.part(IRON, atlas=1, col=BLK, rust=1.3, sharp=80)
    for k in range(46):
        a = 2 * PI * (k + 0.5) / 46
        frv.rivet((XF, CY + 1.20 * math.cos(a), 1.20 * math.sin(a)), (-1, 0, 0), r=0.025, segs=8)
    for yy, n, half in ((2.60, 7, 0.78), (2.28, 9, 1.0)):      # gusset stay rivets
        for k in range(n):
            z = -half + 2 * half * k / (n - 1)
            if abs(z) < 0.3 and yy < 2.5:
                continue
            frv.rivet((XF, yy, z), (-1, 0, 0), r=0.028, segs=8)
    # furnace tube (soot-black interior)
    fur = P.part(SOOT, atlas=1, col=[0.05, 0.04, 0.035])
    loop3 = [V(XF, y, z) for z, y in mouth]
    A, B = loop_wall(fur, loop3, (1.15, 0, 0), inward=True)
    f = fur.bm.faces.new(B)
    f.normal_update()
    if f.normal.x > 0:
        f.normal_flip()
    # cast door frame
    fr = P.part(IRON, atlas=1, col=[0.8, 0.8, 0.8], rust=0.9, sharp=42)
    path = round_path([V(XF, hs, hw_), V(XF, hb, hw_), V(XF, hb, -hw_), V(XF, hs, -hw_)], 0.05, 3)[1:-1]
    path = [V(XF, hs + hw_ * sind(a), hw_ * cosd(a)) for a in range(180, -1, -15)] + path
    sec = [(-0.004, -0.008), (0.085, -0.008), (0.09, 0.0), (0.09, 0.075), (0.074, 0.092), (-0.004, 0.092)]
    t0 = (path[1] - path[-1]).normalized()
    w0 = t0.cross(V(-1, 0, 0))
    if w0.dot(path[0] - V(XF, 1.36, 0)) < 0:
        sec = [(a, -b) for a, b in reversed(sec)]
    fr.sweep(path, sec, closed=True, up=V(-1, 0, 0))
    fb = P.part(STEEL, atlas=1, rust=1.4)
    for k, (y, z) in enumerate([(hb - 0.045, -0.2), (hb - 0.045, 0.2), (1.2, -0.405), (1.2, 0.405), (1.5, 0.39),
                                 (1.5, -0.39), (1.71, 0.19), (1.71, -0.19), (1.765, 0.0)]):
        fb.hexbolt((XF - 0.09, y, z), (-1, 0, 0), r=0.017, h=0.014, spin=k * 0.5, washer=False)
    # dead plate + fire bars under the door
    bars = P.part(IRON, atlas=1, col=[0.7, 0.7, 0.7], rust=1.2)
    for k in range(9):
        bars.box(0.34, 0.035, 0.03, m=T(XF + 0.16, 1.135, -0.30 + k * 0.075), bevel=0.005)
    bars.box(0.05, 0.05, 0.70, m=T(XF + 0.01, 1.125, 0), bevel=0.006)
    # coal bed (emissive at runtime)
    P.node("FireGlow", T(XF + 0.50, 1.19, 0.0))
    coal = P.part(COAL, atlas=1, node="FireGlow", sharp=70)
    rng = random.Random(5)
    hts = [[rng.random() for _ in range(9)] for _ in range(11)]

    def coal_fn(u, v):
        i, j = int(round(u * 10)), int(round(v * 8))
        edge = 1.0 - abs(2 * v - 1) ** 3
        return (XF + 0.30 + 0.80 * u, 1.15 + 0.07 * hts[i][j] * edge + 0.06 * edge + 0.03 * u, -0.345 + 0.69 * v)
    coal.grid(10, 8, coal_fn)

    # ---------------- fire door (hinged at -Z, ajar)
    xd = XF - 0.092
    piv = (xd - 0.03, 1.36, -0.475)
    AJ = hinge_node(P, "FireDoor", piv, 'Y', -14.0)
    DM = T(xd - 0.021, 0, 0) @ FACE_NX
    dh, db, ds = 0.415, 0.965, 1.36
    dpoly = [(-dh, db + 0.03), (-dh + 0.03, db), (dh - 0.03, db), (dh, db + 0.03)] + \
            [(dh * cosd(a), ds + dh * sind(a)) for a in range(0, 181, 12)]
    door = P.part(IRON, atlas=1, node="FireDoor", col=[0.85, 0.85, 0.85], rust=1.0, sharp=42)
    door.extrude(dpoly, 0.042, m=DM, bevel=0.006)
    rim = [V(xd - 0.042, ds + (dh - 0.045) * sind(a), (dh - 0.045) * cosd(a)) for a in range(180, -1, -12)]
    rim += round_path([V(xd - 0.042, ds, dh - 0.045), V(xd - 0.042, db + 0.045, dh - 0.045),
                       V(xd - 0.042, db + 0.045, -dh + 0.045), V(xd - 0.042, ds, -dh + 0.045)], 0.04, 3)[1:-1]
    door.tube(rim, 0.013, segs=6, closed=True, up=V(-1, 0, 0))
    door.lathe([(0.135, 0.0), (0.135, 0.012), (0.120, 0.02), (0.05, 0.024), (0.04, 0.045), (0.0, 0.048)], segs=18,
               m=orient((xd - 0.042, 1.27, 0.0), (-1, 0, 0)))                       # spinner air regulator
    slots = P.part(SOOT, atlas=1, node="FireDoor")
    for k in range(6):
        a = k * PI / 3
        door.box(0.012, 0.022, 0.07, m=T(xd - 0.064, 1.27, 0) @ R('X', math.degrees(a)) @ T(0, 0.085, 0), bevel=0.004)
        b = (k + 0.5) * PI / 3
        slots.lathe([(0.017, 0.0), (0.0, 0.0)], segs=6, m=orient((xd - 0.0648, 1.27 + 0.085 * math.cos(b), 0.085 * math.sin(b)), (-1, 0, 0)))
    door.box(0.012, 0.045, 0.44, m=T(xd - 0.046, 1.52, 0.0), bevel=0.005)
    dhw = P.part(STEEL, atlas=1, node="FireDoor", rust=1.1, sharp=50)
    dhw.box(0.014, 0.036, 0.36, m=T(xd - 0.062, 1.40, 0.30), bevel=0.004)
    dhw.tube(round_path([V(xd - 0.066, 1.40, 0.40), V(xd - 0.13, 1.40, 0.40), V(xd - 0.13, 1.22, 0.40)], 0.03, 3), 0.012, segs=7)
    dhw.lathe([(0.012, 0.0), (0.021, 0.02), (0.021, 0.09), (0.014, 0.105), (0.0, 0.108)], segs=8, m=orient((xd - 0.13, 1.23, 0.40), (0, -1, 0)))
    dhw.hexbolt((xd - 0.069, 1.40, 0.14), (-1, 0, 0), r=0.014, h=0.012)
    for hy in (1.13, 1.60):
        dhw.box(0.012, 0.055, 0.52, m=T(xd - 0.048, hy, -0.215), bevel=0.004)
        for zz in (-0.36, -0.2, -0.03):
            dhw.rivet((xd - 0.054, hy, zz), (-1, 0, 0), r=0.013)
        dhw.lathe([(0.0, -0.045), (0.022, -0.045), (0.022, 0.045), (0.0, 0.045)], segs=8, m=T(piv[0], hy, piv[2]))
    for part in (door, slots, dhw):
        part.xf(AJ)
    st = P.part(IRON, atlas=1, col=[0.8, 0.8, 0.8], rust=1.2, sharp=50)   # static pintles + latch keeper
    for hy in (1.13, 1.60):
        st.lathe([(0.0, -0.075), (0.019, -0.075), (0.019, -0.05), (0.01, -0.047), (0.01, 0.06), (0.0, 0.062)], segs=8, m=T(piv[0], hy, piv[2]))
        st.box(0.11, 0.035, 0.05, m=T(piv[0] + 0.065, hy - 0.063, piv[2] - 0.012), bevel=0.006)
    st.box(0.07, 0.07, 0.03, m=T(xd - 0.03, 1.40, 0.49), bevel=0.006)
    st.box(0.03, 0.02, 0.05, m=T(xd - 0.06, 1.425, 0.47), bevel=0.004)

    # ---------------- fittings on the front plate
    mp = P.part(DECAL, atlas=1, img="plate_boiler", kind="brass", w=0.44, h=0.29, uvscale=2.2)
    mp.lathe([(1.0, 0.0), (1.0, 0.008), (0.94, 0.012), (0.0, 0.012)], segs=24, m=R('X', 90) @ Matrix.Diagonal((0.22, 1.0, 0.145, 1.0)))
    mp.xf(T(XF, 2.02, 0.0) @ FACE_NX)
    mh = P.part(IRON, atlas=1, col=[0.8, 0.8, 0.8], rust=1.1, sharp=40)     # manhole with bridge bars
    mh.lathe([(1.0, 0.0), (1.0, 0.03), (0.9, 0.05), (0.55, 0.075), (0.0, 0.082)], segs=22,
             m=T(XF, 2.76, 0.0) @ FACE_NX @ R('X', 90) @ Matrix.Diagonal((0.23, 1.0, 0.17, 1.0)))
    for zz in (-0.1, 0.1):
        mh.box(0.03, 0.42, 0.05, m=T(XF - 0.095, 2.76, zz), bevel=0.008)
        mh.hexbolt((XF - 0.11, 2.76, zz), (-1, 0, 0), r=0.03, h=0.03, spin=zz * 9)
        mh.lathe([(0.016, 0.0), (0.016, 0.03), (0.0, 0.032)], segs=8, m=orient((XF - 0.14, 2.76, zz), (-1, 0, 0)))
    wg = P.part(BRASS, atlas=1, sharp=50, uvscale=1.4)                       # water gauge
    gz = 0.78
    for gy in (2.20, 2.74):
        valve(wg, (XF, gy, gz), (-1, 0, 0), r=0.024, L=0.15, wheel_axis=(0, 0, 1))
        wg.box(0.012, 0.014, 0.085, m=T(XF - 0.078, gy, gz + 0.115), bevel=0.003)
        up = 1 if gy < 2.4 else -1
        wg.lathe([(0.024, 0.0), (0.024, 0.03), (0.016, 0.034), (0.016, 0.05), (0.0, 0.05)], segs=8,
                 m=orient((XF - 0.115, gy + 0.02 * up, gz), (0, up, 0)))
    wg.tube([V(XF - 0.115, 2.14, gz), V(XF - 0.115, 2.02, gz), V(XF - 0.115, 1.98, gz + 0.03)], 0.011, segs=6)
    for dz in (-0.05, 0.05):
        wg.tube([V(XF - 0.10, 2.2, gz + dz), V(XF - 0.10, 2.74, gz + dz)], 0.005, segs=5)
    gl = P.part(LAMP, atlas=1, col=[0.30, 0.33, 0.30], sharp=60, uvscale=1.4)
    gl.lathe([(0.0125, 2.25), (0.0125, 2.69)], segs=8, m=T(XF - 0.115, 0, gz))
    for gy in (2.33, 2.58):
        valve(wg, (XF, gy, gz + 0.22), (-1, 0, 0), r=0.016, L=0.10)
    pg = P.part(BRASS, atlas=1, sharp=50, uvscale=1.5)                       # pressure gauge on a syphon loop
    gyc, gzc = 3.03, -0.62
    sy = [V(XF, 2.62, gzc), V(XF - 0.07, 2.62, gzc), V(XF - 0.07, 2.68, gzc)]
    sy += [V(XF - 0.07, 2.735 - 0.055 * math.cos(k * PI / 6), gzc + 0.055 * math.sin(k * PI / 6)) for k in range(1, 12)]
    sy += [V(XF - 0.07, 2.70, gzc), V(XF - 0.07, 2.92, gzc)]
    pg.tube(sy, 0.010, segs=6)
    pg.lathe([(0.0, 0.0), (0.125, 0.0), (0.125, 0.062), (0.132, 0.068), (0.132, 0.082), (0.118, 0.088), (0.112, 0.076)], segs=22,
             m=orient((XF - 0.07, gyc, gzc), (-1, 0, 0)))
    pg.lathe([(0.018, 2.88), (0.018, 2.915)], segs=8, m=T(XF - 0.07, 0, gzc))
    dial = P.part(DECAL, atlas=1, img="dial_steam", kind="dial", w=0.226, h=0.226, uvscale=2.6)
    dial.lathe([(0.113, 0.0), (0.0, 0.0)], segs=22, m=R('X', 90))
    dial.xf(T(XF - 0.07 - 0.074, gyc, gzc) @ FACE_NX)
    bd = P.part(IRON, atlas=1, col=[0.8, 0.8, 0.8], rust=1.4, sharp=50)      # blow-down pipe into the floor
    bd.tube(round_path([V(XF, 0.80, 0.0), V(XF - 0.2, 0.80, 0.0), V(XF - 0.2, 0.0, 0.0)], 0.07, 4), 0.042, segs=10)
    bd.lathe([(0.085, 0.0), (0.085, 0.022), (0.045, 0.026)], segs=12, m=T(XF - 0.2, 0.0, 0.0))
    bd.lathe([(0.085, 0.0), (0.085, 0.024), (0.045, 0.028)], segs=12, m=orient((XF, 0.80, 0), (-1, 0, 0)))
    for k in range(5):
        a = k * 2 * PI / 5
        bd.hexbolt((XF - 0.024, 0.80 + 0.065 * math.cos(a), 0.065 * math.sin(a)), (-1, 0, 0), r=0.011, h=0.01, washer=False)
    bdv = P.part(BRASS, atlas=1, sharp=50)
    bdv.lathe([(0.06, 0.38), (0.06, 0.40), (0.05, 0.41), (0.05, 0.50), (0.06, 0.51), (0.06, 0.53)], segs=12, m=T(XF - 0.2, 0, 0))
    bdv.lathe([(0.03, 0.0), (0.03, 0.06), (0.02, 0.07), (0.0, 0.07)], segs=8, m=orient((XF - 0.25, 0.455, 0), (-1, 0, 0)))
    bdv.box(0.02, 0.03, 0.30, m=T(XF - 0.31, 0.455, 0.11), bevel=0.006)

    # ---------------- steam dome, lever safety valve, stop valve (top)
    dome_x = -0.55
    ytop = CY + RO
    dm = P.part(IRON, atlas=1, col=BLK, rust=1.0, sharp=35)
    dm.lathe([(0.52, ytop - 0.115), (0.52, ytop - 0.085), (0.41, ytop - 0.02), (0.40, ytop + 0.0), (0.40, ytop + 0.40),
              (0.415, ytop + 0.40), (0.415, ytop + 0.46), (0.40, ytop + 0.47), (0.36, ytop + 0.53), (0.24, ytop + 0.585),
              (0.10, ytop + 0.605), (0.0, ytop + 0.607)], segs=26, m=T(dome_x, 0, 0))
    drv = P.part(IRON, atlas=1, col=BLK, rust=1.3, sharp=80)
    for k in range(16):
        a = 2 * PI * k / 16
        drv.rivet((dome_x + 0.415 * math.cos(a), ytop + 0.43, 0.415 * math.sin(a)), (math.cos(a), 0, math.sin(a)), r=0.02, segs=6)
        x_, z_ = dome_x + 0.47 * math.cos(a), 0.47 * math.sin(a)
        drv.rivet((x_, CY + math.sqrt(RO * RO - z_ * z_) + 0.004, z_), (0.3 * math.cos(a), 0.9, 0.5 * math.sin(a)), r=0.022, segs=6)
    sv = P.part(BRASS, atlas=1, sharp=45, uvscale=1.3)
    yv = ytop + 0.60
    sv.lathe([(0.10, yv - 0.01), (0.10, yv + 0.02), (0.06, yv + 0.03), (0.055, yv + 0.12), (0.085, yv + 0.14), (0.085, yv + 0.17),
              (0.05, yv + 0.19), (0.02, yv + 0.20), (0.02, yv + 0.25), (0.0, yv + 0.25)], segs=14, m=T(dome_x, 0, 0))
    svi = P.part(IRON, atlas=1, col=[0.8, 0.8, 0.8], rust=1.1, sharp=45)
    svi.box(0.03, 0.26, 0.03, m=T(dome_x - 0.14, yv + 0.13, 0), bevel=0.006)
    svi.box(0.92, 0.035, 0.022, m=T(dome_x + 0.30, yv + 0.262, 0) @ R('Z', -3), bevel=0.006)
    svi.lathe([(0.0, -0.10), (0.07, -0.10), (0.085, -0.06), (0.085, 0.06), (0.07, 0.10), (0.0, 0.10)], segs=12,
              m=T(dome_x + 0.66, yv + 0.105, 0))
    svi.tube([V(dome_x + 0.66, yv + 0.20, 0), V(dome_x + 0.66, yv + 0.235, 0)], 0.012, segs=6)
    svi.hexbolt((dome_x - 0.14, yv + 0.265, 0.016), (0, 0, 1), r=0.014, h=0.01)
    sx = 1.05
    spn = P.part(IRON, atlas=1, col=BLK, rust=1.1, sharp=40)
    spn.lathe([(0.22, ytop - 0.04), (0.22, ytop + 0.0), (0.12, ytop + 0.02), (0.11, ytop + 0.16), (0.18, ytop + 0.165),
               (0.18, ytop + 0.20), (0.11, ytop + 0.205), (0.11, ytop + 0.24), (0.16, ytop + 0.29), (0.16, ytop + 0.40),
               (0.11, ytop + 0.45), (0.11, ytop + 0.47), (0.17, ytop + 0.475), (0.17, ytop + 0.505), (0.05, ytop + 0.51),
               (0.035, ytop + 0.70), (0.0, ytop + 0.70)], segs=16, m=T(sx, 0, 0))
    for k in range(8):
        a = 2 * PI * (k + 0.5) / 8
        spn.hexbolt((sx + 0.15 * math.cos(a), ytop + 0.20, 0.15 * math.sin(a)), (0, 1, 0), r=0.014, h=0.012, washer=False)
        spn.hexbolt((sx + 0.145 * math.cos(a), ytop + 0.505, 0.145 * math.sin(a)), (0, 1, 0), r=0.013, h=0.012, washer=False)
    spn.ring((sx, ytop + 0.69, 0), (0, 1, 0), 0.19, 0.016, segs=20, tsegs=6)
    for k in range(5):
        a = 2 * PI * k / 5
        spn.tube([V(sx, ytop + 0.69, 0), V(sx + 0.19 * math.cos(a), ytop + 0.69, 0.19 * math.sin(a))], 0.012, segs=5, caps=False)
    spn.tube([V(sx, ytop + 0.345, -0.12), V(sx, ytop + 0.345, -0.62)], 0.085, segs=12, caps=False)
    spn.lathe([(0.085, -0.03), (0.15, -0.03), (0.15, 0.0), (0.0, 0.0)], segs=12, m=orient((sx, ytop + 0.345, -0.65), (0, 0, -1)))
    for k in range(6):
        a = 2 * PI * k / 6
        spn.hexbolt((sx + 0.118 * math.cos(a), ytop + 0.345 + 0.118 * math.sin(a), -0.62), (0, 0, 1), r=0.014, h=0.012, washer=False)
    fd = P.part(IRON, atlas=1, col=BLK, rust=1.3, sharp=45)                  # feed check valve on the front flank
    fa = 48.0
    p0 = cp(-1.95, fa, RO - 0.01)
    fd.lathe([(0.12, 0.0), (0.12, 0.03), (0.06, 0.035), (0.06, 0.10)], segs=12, m=orient(p0, cn(fa)))
    p1 = p0 + cn(fa) * 0.10
    pend = p1 + cn(fa) * 0.08 + V(0, 1.15, 0)
    fd.tube(round_path([p1, p1 + cn(fa) * 0.08, pend], 0.07, 4), 0.045, segs=10, caps=False)
    fd.lathe([(0.045, -0.03), (0.10, -0.028), (0.10, 0.0), (0.0, 0.0)], segs=12, m=orient(pend, (0, 1, 0)))
    for k in range(5):
        a = 2 * PI * k / 5
        fd.hexbolt(pend + V(0.075 * math.cos(a), -0.028, 0.075 * math.sin(a)), (0, -1, 0), r=0.011, h=0.01, washer=False)
    fdv = P.part(BRASS, atlas=1, sharp=45)
    vc = p1 + cn(fa) * 0.08 + V(0, 0.42, 0)
    fdv.lathe([(0.075, -0.09), (0.075, -0.07), (0.06, -0.06), (0.06, 0.06), (0.075, 0.07), (0.075, 0.09)], segs=12, m=T(*vc))
    valve(fdv, vc, (-1, 0, 0), r=0.03, L=0.13, wheel=0.075, wheel_axis=(-1, 0, 0))

    # ---------------- smokebox door (rear, +X)
    sb = P.part(IRON, atlas=1, col=BLK, rust=1.2, sharp=35)
    sb.lathe([(RS - 0.02, XR + 0.02), (1.20, XR + 0.02), (0.92, XR + 0.02), (0.90, XR + 0.035), (0.86, XR + 0.045),
              (0.55, XR + 0.085), (0.20, XR + 0.10), (0.0, XR + 0.102)], segs=40, m=AX)
    sbr = P.part(IRON, atlas=1, col=BLK, rust=1.4, sharp=80)
    for k in range(36):
        a = 2 * PI * k / 36
        sbr.rivet((XR + 0.02, CY + 1.26 * math.cos(a), 1.26 * math.sin(a)), (1, 0, 0), r=0.024, segs=6)
    sbf = P.part(STEEL, atlas=1, rust=1.3, sharp=45)
    sbf.lathe([(0.06, 0.0), (0.06, 0.03), (0.03, 0.04), (0.03, 0.08), (0.0, 0.08)], segs=10, m=orient((XR + 0.10, CY, 0), (1, 0, 0)))
    sbf.tube([V(XR + 0.155, CY - 0.17, 0.05), V(XR + 0.155, CY + 0.17, -0.05)], 0.014, segs=6)
    sbf.tube([V(XR + 0.185, CY - 0.05, -0.16), V(XR + 0.185, CY + 0.05, 0.16)], 0.014, segs=6)
    for hy in (CY - 0.42, CY + 0.42):
        sbf.box(0.014, 0.07, 0.72, m=T(XR + 0.075, hy, -0.56) @ R('Y', -5.0), bevel=0.004)
        sbf.lathe([(0.0, -0.06), (0.024, -0.06), (0.024, 0.06), (0.0, 0.06)], segs=8, m=T(XR + 0.045, hy, -0.95))

    # ---------------- flue stack to 5.2 m
    stx = (XS - 0.05 + XR + 0.02) / 2
    stk = P.part(IRON, atlas=2, col=[0.66, 0.66, 0.68], rust=1.5, sharp=35)
    ys = CY + RS
    prof = [(0.36, ys - 0.085), (0.36, ys - 0.045), (0.325, ys + 0.03), (0.30, ys + 0.24), (0.285, ys + 0.26)]
    bands = []
    y = ys + 0.26
    while y < 4.9:
        y2 = min(y + 0.62, 5.13)
        prof += [(0.285, y2 - 0.035), (0.297, y2 - 0.035), (0.297, y2 + 0.035), (0.285, y2 + 0.035)]
        bands.append(y2)
        y = y2 + 0.035
    prof = prof[:-1] + [(0.297, 5.2), (0.268, 5.2), (0.268, 4.7)]
    stk.lathe(prof, segs=22, m=T(stx, 0, 0))
    cap = P.part(SOOT, atlas=2)
    cap.lathe([(0.268, 4.72), (0.0, 4.72)], segs=22, m=T(stx, 0, 0))
    srv = P.part(IRON, atlas=2, col=[0.66, 0.66, 0.68], rust=1.6, sharp=80)
    for y_ in bands:
        for k in range(8):
            a = 2 * PI * (k + 0.25) / 8
            srv.rivet((stx + 0.297 * math.cos(a), y_, 0.297 * math.sin(a)), (math.cos(a), 0, math.sin(a)), r=0.014)
    dmp = P.part(STEEL, atlas=2, rust=1.4, sharp=50)
    dmp.tube([V(stx, ys + 0.75, -0.32), V(stx, ys + 0.75, 0.40)], 0.012, segs=6)
    dmp.box(0.02, 0.24, 0.035, m=T(stx, ys + 0.66, 0.40) @ R('Z', 25), bevel=0.005)
    dmp.lathe([(0.03, 0.0), (0.03, 0.02), (0.0, 0.02)], segs=8, m=orient((stx, ys + 0.75, 0.283), (0, 0, 1)))

    # ---------------- masonry saddle cradles (front half modelled, mirrored)
    for xc in (-1.5, 1.45):
        cr = P.part(BRICK, atlas=2, mirror=True, sharp=30)
        arc = []
        for k in range(13):
            z = 1.09 * k / 12
            arc.append((z, CY - math.sqrt((RO + 0.018) ** 2 - z * z)))
        poly = [(0.0, 0.14), (1.27, 0.14), (1.27, 1.0), (arc[-1][0], 1.0)] + list(reversed(arc[:-1]))
        cr.extrude(poly, 0.58, m=T(xc, 0, 0) @ FACE_NX, bevel=0.012)
        cr.extrude([(0.0, 0.0), (1.33, 0.0), (1.33, 0.125), (1.315, 0.14), (0.0, 0.14)], 0.70, m=T(xc, 0, 0) @ FACE_NX, bevel=0.01)

    def hook(tx, a):
        Pp, N = tx.P, tx.N
        n1 = tx.fbm(2.0, 3, 401)
        n2 = tx.fbm(0.8, 3, 402, stretch=(6.0, 1.0, 6.0))
        r = np.hypot(Pp[:, 1] - CY, Pp[:, 2])
        low = ss(0.0, -1.2, Pp[:, 1] - CY)
        front = ss(XF + 0.25, XF - 0.05, Pp[:, 0])
        dz = np.abs(Pp[:, 2])
        n3 = tx.fbm(1.0, 3, 404, stretch=(1.0, 2.0, 14.0))
        plume = front * ss(0.85, 0.1, dz - 0.16 * np.clip(Pp[:, 1] - 1.7, 0, 2) + (n3 - 0.5) * 0.5) * ss(1.3, 1.78, Pp[:, 1]) * ss(3.4, 1.9, Pp[:, 1])
        soot = plume * (0.55 + 0.9 * n3)
        soot += ss(XS - 0.2, XR, Pp[:, 0]) * (0.25 + 0.5 * n1) * 0.8
        soot += ss(4.2, 5.2, Pp[:, 1]) * 0.9
        soot += ((Pp[:, 0] > XF + 0.02) & (r < 0.9) & (Pp[:, 1] < 1.8) & (Pp[:, 0] < XF + 1.3) & (np.abs(Pp[:, 2]) < 0.37)) * 0.5
        tx.F["soot"] = np.clip(soot, 0, 1).astype(np.float32)
        tx.F["rust"] = (low * 0.35 + ss(3.4, 5.0, Pp[:, 1]) * 0.25 + (n2 - 0.5) * 0.5).astype(np.float32)
        srcm = ((tx.surf == BRASS) & (tx.cav > 0.25)).astype(np.float32)       # lime scale weeping from fittings/seams
        seam = (np.abs(Pp[:, 0] - edges[2]) < 0.03) & (Pp[:, 2] > 0.6) & (Pp[:, 1] < 2.6) & (n1 > 0.52)
        seam |= (np.abs(Pp[:, 0] - edges[3]) < 0.03) & (Pp[:, 2] > 0.9) & (n1 > 0.6)
        lime = K.flow(Pp, np.maximum(srcm, seam.astype(np.float32)), 0.02, 0.5, seed=9)
        lime = lime * (1 - np.abs(N[:, 1])) * ss(0.35, 0.7, tx.fbm(1.0, 3, 403, stretch=(60.0, 3.0, 60.0)))
        tx.F["lime"] = (np.clip(lime, 0, 1) * (tx.surf != BRASS) * 0.9).astype(np.float32)
        tx.F["dirt"] = (ss(0.5, 0.0, Pp[:, 1]) * 0.5).astype(np.float32)
    P.hook = hook
    return P


def ticks(a, b, edges, step):
    """Grid coordinates from a to b with extra lines `edges` inside both ends and ~step spacing between."""
    xs = [a] + [a + e for e in edges]
    inner_a, inner_b = a + edges[-1], b - edges[-1]
    n = max(1, int(round((inner_b - inner_a) / step)))
    xs += [inner_a + (inner_b - inner_a) * k / n for k in range(1, n)]
    xs += [b - e for e in reversed(edges)] + [b]
    return xs


def grid_xy(part, xs, ys, fn, m=None, aux=0.0):
    """Heightfield over explicit x / y coordinate lists; fn(x, y) -> z. Faces point toward +Z."""
    nx, ny = len(xs) - 1, len(ys) - 1
    return part.grid(ny, nx, lambda u, v: (xs[int(round(v * nx))], ys[int(round(u * ny))],
                                             fn(xs[int(round(v * nx))], ys[int(round(u * ny))])), m=m, aux=aux)


def panel_door(part, w, h, t, edge=0.03, dents=(), field=True, m=None, step=0.06):
    """Pillowed sheet-metal door in local XY (+Z out, back at z=0) with real dents in the front skin."""
    mm = (m if m is not None else Matrix.Identity(4))
    part.rrloft(w, h, edge, [(0.0, 0.0), (0.0, t * 0.70), (edge * 0.2, t * 0.90), (edge * 0.55, t * 0.985), (edge, t)],
                n=3, caps=(True, False), m=mm @ R('X', 90))
    x0, x1, y0, y1 = -w / 2 + edge, w / 2 - edge, -h / 2 + edge, h / 2 - edge

    def fn(x, y):
        d = min(x - x0, x1 - x, y - y0, y1 - y)
        z = t - 0.007 * float(ss(0.012, 0.03, d))
        if field:
            z += 0.0055 * float(ss(0.05, 0.068, d))
        for (dx, dy, rad, dep) in dents:
            q = ((x - dx) ** 2 + (y - dy) ** 2) / (rad * rad)
            z -= dep * math.exp(-q) * float(ss(0.0, 0.05, d))
        return z
    e = [0.012, 0.03, 0.05, 0.068] if field else [0.012, 0.03]
    grid_xy(part, ticks(x0, x1, e, step), ticks(y0, y1, e, step), fn, m=mm)


def strap_hinge(part, knuckle, length, width, m, bolts=3, barrel_r=0.016, barrel_h=0.09, thick=0.008):
    """Strap hinge in local XY: barrel axis along Y at the origin, strap running toward +X on the z=0 face."""
    part.lathe([(0.0, -barrel_h / 2), (barrel_r, -barrel_h / 2), (barrel_r, barrel_h / 2), (0.0, barrel_h / 2)], segs=8, m=m)
    part.lathe([(0.0, barrel_h / 2), (barrel_r * 0.55, barrel_h / 2), (barrel_r * 0.55, barrel_h / 2 + 0.012), (0.0, barrel_h / 2 + 0.014)],
               segs=6, m=m)
    poly = [(0.0, -width / 2), (length * 0.9, -width * 0.28), (length, 0.0), (length * 0.9, width * 0.28), (0.0, width / 2)]
    part.extrude(poly, thick, m=m @ T(knuckle, 0, thick / 2), bevel=thick * 0.3)
    for k in range(bolts):
        x = knuckle + length * (0.14 + 0.64 * k / max(bolts - 1, 1))
        part.rivet((m @ V(x, 0, thick)), (m.to_3x3() @ V(0, 0, 1)), r=width * 0.16, segs=6)


def chain(part, pts, link=0.052, wire=0.0055, width=0.019, closed=True, seed=0):
    rng = random.Random(seed)
    P_ = [Vector(p) for p in pts]
    if closed:
        P_.append(P_[0])
    seg = [(P_[i + 1] - P_[i]).length for i in range(len(P_) - 1)]
    total = sum(seg)
    pitch = link - wire * 3.4
    n = max(2, int(round(total / pitch)))
    if closed and n % 2:
        n += 1
    rw = width / 2
    s = link / 2 - rw
    stad = [(rw * cosd(a), s + rw * sind(a), 0.0) for a in (0, 45, 90, 135, 180)] + \
           [(rw * cosd(a), -s + rw * sind(a), 0.0) for a in (180, 225, 270, 315, 360)]
    for k in range(n if closed else n + 1):
        d = total * k / n
        i = 0
        while i < len(seg) - 1 and d > seg[i]:
            d -= seg[i]
            i += 1
        t = (P_[i + 1] - P_[i]).normalized()
        p = P_[i] + t * d
        roll = (PI / 2 if k % 2 else 0.0) + rng.uniform(-0.25, 0.25)
        part.tube(stad, wire, segs=5, closed=True, up=(0, 0, 1), m=orient(p, t, roll))


def broken_board(part, L, w, t, br0=0.0, br1=0.0, rng=None, nw=3, nt=2):
    """Board along local X with jagged splintered ends (aux=1 marks the fresh fracture)."""
    rng = rng or random
    bm = part.bm
    ends = []
    for sgn, br in ((-1, br0), (1, br1)):
        g = [[bm.verts.new((sgn * (L / 2 - (rng.uniform(0.0, br) if br > 0 else 0.0)), -t / 2 + t * j / nt, -w / 2 + w * i / nw))
              for j in range(nt + 1)] for i in range(nw + 1)]
        for row in g:
            for v in row:
                v[part.aux] = 1.0 if br > 0 else 0.0
        ends.append(g)
        for i in range(nw):
            for j in range(nt):
                q = [g[i][j], g[i][j + 1], g[i + 1][j + 1], g[i + 1][j]]
                bm.faces.new(q if sgn > 0 else list(reversed(q)))

    def perim(g):
        out = [g[i][0] for i in range(nw + 1)] + [g[nw][j] for j in range(1, nt + 1)] + \
              [g[i][nt] for i in range(nw - 1, -1, -1)] + [g[0][j] for j in range(nt - 1, 0, -1)]
        return out
    p0, p1 = perim(ends[0]), perim(ends[1])
    rings = [p0]
    for sgn, br, src in ((-1, br0, p0), (1, br1, p1)):
        if br > 0:
            ring = [bm.verts.new((sgn * (L / 2 - br - 0.06), v.co.y, v.co.z)) for v in src]
            if sgn < 0:
                rings.append(ring)
            else:
                rings.append(ring)
    rings.append(p1)
    for a in range(len(rings) - 1):
        A, B = rings[a], rings[a + 1]
        for k in range(len(A)):
            k2 = (k + 1) % len(A)
            bm.faces.new([A[k], A[k2], B[k2], B[k]])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])


# =============================================================================================
# 3. Mortuary cold-storage bank
# =============================================================================================
def build_morgue_drawers():
    P = K.Prop("prop_morgue_drawers", ["front", "case"], edge_r=0.012, cav_dist=0.04, voxel=0.014, streak_len=0.4,
               dust=0.3, seed=3, streak=1.25)
    CREAM = [0.80, 0.80, 0.71]
    rng = random.Random(33)
    ZF = 0.385          # carcass / face-frame front plane
    cols = [-0.965, 0.0, 0.965]
    rows = [0.57, 1.55]
    OW, OH = 0.80, 0.86
    # --- carcass panels (sides stay planar at x = +-1.45 so banks butt cleanly)
    case = P.part(PAINT, atlas=1, col=CREAM, wear=0.9, rust=1.1, gloss=0.4, uvscale=0.6)
    for sx in (-1, 1):
        case.box(0.03, 2.2, 0.885, m=T(sx * 1.435, 1.1, -0.0575))
    case.box(2.84, 0.03, 0.885, m=T(0, 2.185, -0.0575))
    case.box(2.84, 0.03, 0.885, m=T(0, 0.015, -0.0575))
    case.box(2.84, 2.14, 0.02, m=T(0, 1.1, -0.49))
    # --- face frame: stiles full height, rails between
    fr = P.part(PAINT, atlas=0, col=CREAM, wear=1.0, rust=1.2, gloss=0.4)
    stiles = [(-1.4075, 0.085), (-0.4825, 0.165), (0.4825, 0.165), (1.4075, 0.085)]
    for x, w in stiles:
        fr.box(w, 2.2, 0.06, m=T(x, 1.1, ZF - 0.03), bevel=0.0 if abs(x) > 1.3 else 0.004)
    for cx in cols:
        fr.box(OW, 0.14, 0.055, m=T(cx, 0.07, ZF - 0.0325))
        fr.box(OW, 0.12, 0.055, m=T(cx, 1.06, ZF - 0.0325))
        fr.box(OW, 0.22, 0.055, m=T(cx, 2.09, ZF - 0.0325))
    scr = P.part(STEEL, atlas=0, rust=1.2, sharp=80)
    for x, w in stiles:
        for k in range(9):
            y = 0.1 + k * 0.25
            if abs(x) < 1.3:
                for dx in (-0.055, 0.055):
                    scr.rivet((x + dx, y, ZF), (0, 0, 1), r=0.008, segs=6)
            else:
                scr.rivet((x, y, ZF), (0, 0, 1), r=0.008, segs=6)
    # --- doors
    open_cell = (1, 0)
    OPEN_DEG = 30.0
    num = 0
    for ri in (1, 0):
        for ci in range(3):
            num += 1
            cx, cy = cols[ci], rows[ri]
            is_open = (ci, ri) == open_cell
            node = "DrawerDoorOpen" if is_open else None
            dents = [(rng.uniform(-0.3, 0.3), rng.uniform(-0.33, 0.33), rng.uniform(0.05, 0.13), rng.uniform(0.004, 0.011))
                     for _ in range(rng.randint(1, 3))]
            if ri == 0:
                dents.append((rng.uniform(-0.25, 0.25), -0.3, 0.12, 0.012))
            DW, DH, DT = 0.86, 0.92, 0.058
            M = T(cx, cy, ZF + 0.009)
            door = P.part(PAINT, atlas=0, node=node, col=CREAM, wear=1.1 + 0.3 * rng.random(), rust=1.1, gloss=0.38, sharp=42)
            panel_door(door, DW, DH, DT, edge=0.03, dents=dents, m=M)
            gk = P.part(RUBBER, atlas=0, node=node, col=[0.55, 0.52, 0.48])
            gk.rrloft(DW - 0.03, DH - 0.03, 0.02, [(0.0, -0.009), (0.0, 0.002)], n=3, caps=(False, False), m=M @ R('X', 90))
            hw = P.part(STEEL, atlas=0, node=node, col=[1.15, 1.15, 1.1], rust=0.95, sharp=45)
            hx = -DW / 2 - 0.012
            for hy in (-0.30, 0.30):
                strap_hinge(hw, 0.012, 0.26, 0.055, M @ T(hx, hy, DT - 0.004), bolts=3, barrel_r=0.017, barrel_h=0.10)
            # lever latch: base plate, pivot boss, lever bar with grip
            lx = DW / 2 - 0.085
            hw.rrloft(0.075, 0.17, 0.012, [(0.0, 0.0), (0.0, 0.008), (0.004, 0.011)], n=2, caps=(False, True),
                      m=M @ T(lx, 0, DT - 0.002) @ R('X', 90))
            hw.lathe([(0.026, 0.0), (0.026, 0.016), (0.016, 0.022), (0.016, 0.034), (0.0, 0.036)], segs=10,
                     m=M @ T(lx, 0.0, DT + 0.008) @ R('X', 90))
            lev = [V(lx, 0, DT + 0.03), V(lx + 0.10, 0, DT + 0.03), V(lx + 0.118, 0, DT + 0.045), V(lx + 0.118, -0.07, DT + 0.062),
                   V(lx + 0.118, -0.20, DT + 0.062)]
            hw.sweep(round_path(lev, 0.03, 3), [(-0.007, -0.015), (0.007, -0.015), (0.007, 0.015), (-0.007, 0.015)], m=M,
                     ups=None, up=(0, 0, 1))
            hw.lathe([(0.012, -0.05), (0.017, -0.035), (0.017, 0.035), (0.012, 0.05), (0.0, 0.052)], segs=8,
                     m=M @ T(lx + 0.118, -0.17, DT + 0.066))
            for sy in (-0.065, 0.065):
                hw.rivet(M @ V(lx, sy, DT + 0.009), (0, 0, 1), r=0.007, segs=6)
            # numbered enamel plate + brass card frame
            pl = P.part(DECAL, atlas=0, node=node, img="num_%d" % num, kind="enamel", w=0.150, h=0.112, uvscale=1.7)
            pl.lathe([(1.0, 0.0), (1.0, 0.003), (0.93, 0.005), (0.0, 0.0055)], segs=20,
                     m=R('X', 90) @ Matrix.Diagonal((0.075, 1.0, 0.056, 1.0)))
            pl.xf(M @ T(-0.02, 0.27, DT + 0.004))
            cf = P.part(BRASS, atlas=0, node=node, sharp=45)
            for (bx, by, bw, bh) in ((0, 0.036, 0.13, 0.008), (0, -0.036, 0.13, 0.008), (-0.061, 0, 0.008, 0.064), (0.061, 0, 0.008, 0.064)):
                cf.box(bw, bh, 0.006, m=M @ T(-0.02 + bx, 0.12 + by, DT + 0.0075), bevel=0.002)
            card = P.part(DECAL, atlas=0, node=node, img="label_blank", kind="paper", w=0.114, h=0.064, rim=[0.7, 0.66, 0.52])
            card.box(0.114, 0.064, 0.002)
            card.xf(M @ T(-0.02, 0.12, DT + 0.0052))
            kp = P.part(STEEL, atlas=0, col=[1.15, 1.15, 1.1], rust=1.0, sharp=45)        # keeper on the stile (static)
            kxw = cx + DW / 2 + 0.026
            kp.box(0.036, 0.11, 0.03, m=T(kxw, cy, ZF + 0.015), bevel=0.005)
            kp.box(0.03, 0.03, 0.06, m=T(kxw - 0.004, cy + 0.03, ZF + 0.045), bevel=0.005)
            kp.lathe([(0.0, -0.014), (0.011, -0.014), (0.011, 0.014), (0.0, 0.014)], segs=8, m=T(kxw - 0.018, cy + 0.006, ZF + 0.06) @ R('Z', 90))
            if is_open:
                piv = (cx + hx, cy, ZF + 0.009 + DT - 0.004)
                AJ = hinge_node(P, "DrawerDoorOpen", piv, 'Y', -OPEN_DEG)
                for part in (door, gk, hw, pl, cf, card):
                    part.xf(AJ)
            else:
                for hy in (-0.30, 0.30):                                                   # frame-side hinge leaf
                    kp.box(0.03, 0.10, 0.01, m=T(cx + hx - 0.022, cy + hy, ZF + 0.005), bevel=0.003)
    # --- the open cell: liner, roller rails, sliding tray
    cx, cy = cols[open_cell[0]], rows[open_cell[1]]
    lin = P.part(GALV, atlas=1, col=[0.55, 0.56, 0.56])
    loop = [V(cx - OW / 2, cy - OH / 2, ZF - 0.058), V(cx + OW / 2, cy - OH / 2, ZF - 0.058), V(cx + OW / 2, cy + OH / 2, ZF - 0.058),
            V(cx - OW / 2, cy + OH / 2, ZF - 0.058)]
    A, B = loop_wall(lin, loop, (0, 0, -0.80), inward=True)
    f = lin.bm.faces.new(B)
    f.normal_update()
    if f.normal.z < 0:
        f.normal_flip()
    rails = P.part(GALV, atlas=1, sharp=45)
    ty = cy - OH / 2 + 0.16
    for sx in (-1, 1):
        rails.box(0.035, 0.035, 0.80, m=T(cx + sx * (OW / 2 - 0.02), ty - 0.04, ZF - 0.46), bevel=0.004)
        for kz in range(5):
            rails.lathe([(0.0, -0.012), (0.02, -0.012), (0.022, 0.0), (0.02, 0.012), (0.0, 0.012)], segs=8,
                        m=T(cx + sx * (OW / 2 - 0.052), ty - 0.035, ZF - 0.12 - kz * 0.17) @ R('Z', 90))
    tray = P.part(GALV, atlas=1, sharp=45)
    TW, TL = 0.64, 0.86
    tray.rrloft(TW, TL, 0.05, [(0.012, 0.0), (0.0, 0.006), (0.0, 0.058), (0.004, 0.064), (0.010, 0.064), (0.014, 0.058),
                               (0.016, 0.012), (0.03, 0.008)], n=4, caps=(True, True), m=T(cx, ty - 0.012, ZF - 0.40))
    tray.tube(round_path([V(cx - 0.11, ty + 0.02, ZF + 0.03), V(cx - 0.11, ty + 0.02, ZF + 0.075), V(cx + 0.11, ty + 0.02, ZF + 0.075),
                          V(cx + 0.11, ty + 0.02, ZF + 0.03)], 0.02, 3), 0.007, segs=6)
    # --- top rail: maker's plate + cold-room thermometer
    mp = P.part(DECAL, atlas=0, img="plate_cold", kind="brass", w=0.40, h=0.20, uvscale=1.6)
    mp.rrloft(0.40, 0.20, 0.012, [(0.0, 0.0), (0.0, 0.004), (0.004, 0.006)], n=2, caps=(False, True), m=R('X', 90))
    mp.xf(T(0.0, 2.09, ZF))
    th = P.part(BRASS, atlas=0, sharp=45)
    th.lathe([(0.075, 0.0), (0.075, 0.03), (0.08, 0.034), (0.08, 0.044), (0.07, 0.048), (0.066, 0.04)], segs=20,
             m=T(cols[2], 2.09, ZF) @ R('X', 90))
    dial = P.part(DECAL, atlas=0, img="dial_thermo", kind="dial", w=0.134, h=0.134, uvscale=2.2)
    dial.lathe([(0.067, 0.0), (0.0, 0.0)], segs=20, m=R('X', 90))
    dial.xf(T(cols[2], 2.09, ZF + 0.038))
    # --- plinth vents
    vent = P.part(SOOT, atlas=0, col=[0.03, 0.03, 0.03])
    lou = P.part(PAINT, atlas=0, col=CREAM, wear=1.3, rust=1.6)
    for cxv in (cols[0], cols[2]):
        vent.box(0.40, 0.07, 0.002, m=T(cxv, 0.07, ZF - 0.004))
        for k in range(5):
            lou.box(0.42, 0.006, 0.02, m=T(cxv, 0.042 + k * 0.014, ZF + 0.004) @ R('X', 35))

    def hook(tx, a):
        Pp = tx.P
        n1 = tx.fbm(1.3, 3, 501)
        n2 = tx.fbm(4.0, 3, 502)
        tx.F["rust"] = (ss(0.5, 0.0, Pp[:, 1]) * 0.5 + (n1 - 0.5) * 0.4).astype(np.float32)
        tx.F["dirt"] = (ss(0.35, 0.0, Pp[:, 1]) * 0.5 + ss(0.6, 0.8, n2) * 0.2).astype(np.float32)
        inside = (Pp[:, 2] < ZF - 0.05) & (np.abs(Pp[:, 0] - cx) < OW / 2 + 0.01) & (np.abs(Pp[:, 1] - cy) < OH / 2 + 0.01)
        tx.F["stain"] = (inside * ss(0.42, 0.7, n2) * 0.9).astype(np.float32)
    P.hook = hook
    return P


# =============================================================================================
# 4. Breach gate (security door leaf)
# =============================================================================================
def build_breach_gate():
    P = K.Prop("prop_breach_gate", ["plate", "bars"], edge_r=0.012, cav_dist=0.04, voxel=0.014, streak_len=0.5,
               dust=0.3, seed=4, streak=1.3)
    GREEN = [0.17, 0.21, 0.18]
    rng = random.Random(44)
    W, H = 2.6, 3.1
    XL, XR_, YB, YM, YT = 0.05, 2.55, 0.07, 1.54, 3.04      # stile / rail centre lines
    FW, FT = 0.075, 0.055
    fr = P.part(PAINT, atlas=0, col=GREEN, wear=1.4, rust=1.3, gloss=0.45)
    fr.box(FW, H - 0.04, FT, m=T(XL, H / 2, 0), bevel=0.005)
    fr.box(FW, H - 0.04, FT, m=T(XR_, H / 2, 0), bevel=0.005)
    for y in (YB, YM, YT):
        fr.box(XR_ - XL - FW, FW, FT - 0.004, m=T((XL + XR_) / 2, y, 0), bevel=0.005)
    # --- riveted plate (dented by boots and rams)
    px0, px1, py0, py1 = XL + FW / 2, XR_ - FW / 2, YB + FW / 2, YM - FW / 2
    dents = [(rng.uniform(0.5, 2.1), rng.uniform(0.25, 1.2), rng.uniform(0.10, 0.22), rng.uniform(0.008, 0.022)) for _ in range(7)]

    def pz(x, y):
        z = 0.0
        for (dx, dy, rad, dep) in dents:
            z -= dep * math.exp(-((x - dx) ** 2 + (y - dy) ** 2) / (rad * rad))
        e = min(x - px0, px1 - x, y - py0, py1 - y)
        return z * float(ss(0.0, 0.12, e))
    plate = P.part(PAINT, atlas=0, col=GREEN, wear=1.2, rust=1.25, gloss=0.45)
    xs = [px0 + (px1 - px0) * k / 30 for k in range(31)]
    ys = [py0 + (py1 - py0) * k / 18 for k in range(19)]
    grid_xy(plate, xs, ys, lambda x, y: pz(x, y) + 0.004)
    grid_xy(plate, xs, ys, lambda x, y: -(pz(px0 + px1 - x, y) - 0.004), m=R('Y', 180) @ T(-(px0 + px1), 0, 0))
    # flat-bar stiffeners on both faces
    bands = P.part(PAINT, atlas=0, col=GREEN, wear=1.5, rust=1.35, gloss=0.45)
    riv = P.part(PAINT, atlas=0, col=GREEN, wear=1.9, rust=1.5, sharp=80)
    xm = (px0 + px1) / 2
    for sz in (1, -1):
        z = sz * 0.010
        specs = [((xm, py0 + 0.035), (px1 - px0, 0.06)), ((xm, py1 - 0.035), (px1 - px0, 0.06)),
                 ((px0 + 0.035, (py0 + py1) / 2), (0.06, py1 - py0 - 0.14)), ((px1 - 0.035, (py0 + py1) / 2), (0.06, py1 - py0 - 0.14)),
                 ((xm, (py0 + py1) / 2), (0.07, py1 - py0 - 0.14)), ((xm, 0.82), (px1 - px0 - 0.14, 0.06))]
        for k, ((bx, by), (bw, bh)) in enumerate(specs):
            bands.box(bw, bh, 0.012 if k < 5 else 0.011, m=T(bx, by, z), bevel=0.003)
            if bw > bh:
                n = int(bw / 0.14)
                for i in range(n):
                    xx = bx - bw / 2 + bw * (i + 0.5) / n
                    riv.rivet((xx, by, z + sz * 0.006), (0, 0, sz), r=0.013, segs=6)
            else:
                n = int(bh / 0.14)
                for i in range(n):
                    yy = by - bh / 2 + bh * (i + 0.5) / n
                    riv.rivet((bx, yy, z + sz * 0.006), (0, 0, sz), r=0.013, segs=6)
    # --- barred upper half
    bars = P.part(PAINT, atlas=1, col=GREEN, wear=1.7, rust=1.5, gloss=0.45, sharp=50)
    nb = 17
    bx0, bx1 = XL + FW / 2, XR_ - FW / 2
    yb0, yb1 = YM + FW / 2, YT - FW / 2
    bar_x = [bx0 + (bx1 - bx0) * (k + 1) / (nb + 1) for k in range(nb)]
    weld = P.part(PAINT, atlas=1, col=GREEN, wear=2.0, rust=1.7, gloss=0.45, sharp=80)
    for k, x in enumerate(bar_x):
        bend = 0.0
        pts = [V(x, yb0 - 0.01, 0), V(x, yb1 + 0.01, 0)]
        if k in (6, 7):      # two bars bowed apart by a pry attempt
            s = -1 if k == 6 else 1
            pts = [V(x, yb0 - 0.01, 0)] + [V(x + s * 0.028 * math.sin(PI * t), yb0 + (yb1 - yb0) * (0.08 + 0.5 * t), 0.012 * math.sin(PI * t))
                                           for t in [i / 8 for i in range(9)]] + [V(x, yb1 + 0.01, 0)]
        bars.tube(pts, 0.014, segs=8, caps=False)
        for yy, d in ((yb0, 1), (yb1, -1)):
            weld.lathe([(0.027, 0.0), (0.024, 0.006), (0.017, 0.011), (0.0142, 0.012)], segs=8, m=orient((x, yy, 0), (0, d, 0)))
    for yy in (2.03, 2.53):
        bars.box(bx1 - bx0, 0.05, 0.014, m=T((bx0 + bx1) / 2, yy, 0), bevel=0.003)
    # --- strap hinges on the +Z face (barrels on the x = 0 hinge line)
    hg = P.part(IRON, atlas=1, col=[0.8, 0.82, 0.8], rust=1.2, sharp=45)
    for hy in (0.42, 1.54, 2.72):
        strap_hinge(hg, 0.012, 0.74, 0.085, T(0.0, hy, 0.0) @ T(0, 0, FT / 2 - 0.002), bolts=4, barrel_r=0.024, barrel_h=0.13, thick=0.012)
        hg.box(0.05, 0.085, FT / 2 + 0.012, m=T(0.022, hy, (FT / 2 + 0.012) / 2 - 0.002), bevel=0.004)
    # --- rim lock box
    lk = P.part(IRON, atlas=1, col=[0.75, 0.78, 0.76], rust=1.2, sharp=42)
    lcx, lcy, lz = 2.33, 1.36, FT / 2
    lk.rrloft(0.36, 0.25, 0.018, [(0.0, 0.0), (0.0, 0.066), (0.006, 0.074), (0.014, 0.078)], n=3, caps=(False, True),
              m=T(lcx, lcy, lz) @ R('X', 90))
    lk.box(0.05, 0.07, 0.03, m=T(2.555, lcy + 0.02, lz + 0.045), bevel=0.006)          # bolt throw
    for sx in (-1, 1):
        for sy in (-1, 1):
            lk.hexbolt((lcx + sx * 0.15, lcy + sy * 0.095, lz + 0.078), (0, 0, 1), r=0.012, h=0.008, washer=False, spin=sx + sy)
    lb = P.part(BRASS, atlas=1, sharp=45)
    lb.lathe([(1.0, 0.0), (1.0, 0.004), (0.85, 0.006), (0.0, 0.006)], segs=14,
             m=T(lcx - 0.03, lcy - 0.02, lz + 0.078) @ R('X', 90) @ Matrix.Diagonal((0.026, 1.0, 0.042, 1.0)))
    kh = P.part(SOOT, atlas=1)
    kh.lathe([(0.008, 0.0), (0.0, 0.0)], segs=8, m=T(lcx - 0.03, lcy - 0.008, lz + 0.0845) @ R('X', 90))
    kh.box(0.006, 0.022, 0.0005, m=T(lcx - 0.03, lcy - 0.026, lz + 0.0845))
    # ring pull
    lk.lathe([(0.02, 0.0), (0.02, 0.012), (0.012, 0.02), (0.0, 0.021)], segs=10, m=T(lcx + 0.09, lcy + 0.03, lz + 0.078) @ R('X', 90))
    lk.ring((lcx + 0.09, lcy - 0.022, lz + 0.094), (0, 0.25, 1), 0.05, 0.007, segs=18, tsegs=6)
    # --- heavy chain wrapped twice around the last two bars, padlocked where it hangs in front
    ch = P.part(STEEL, atlas=1, rust=1.35, sharp=70, uvscale=1.2)
    zo = 0.038
    xa, xb = bar_x[-3] + 0.05, bar_x[-1] + 0.05
    xmid = (xa + xb) / 2
    loop = [V(xa, 1.99, -zo), V(xmid, 1.975, -zo - 0.004), V(xb, 1.99, -zo), V(xb + 0.012, 1.97, 0.0), V(xb, 1.93, zo), V(xb - 0.03, 1.80, zo + 0.012),
            V(xmid + 0.035, 1.715, zo + 0.02), V(xmid, 1.695, zo + 0.022), V(xmid - 0.035, 1.715, zo + 0.02), V(xa + 0.03, 1.80, zo + 0.012),
            V(xa, 1.93, zo), V(xa - 0.012, 1.97, 0.0)]
    chain(ch, loop, link=0.07, wire=0.0075, width=0.027, seed=4)
    loop2 = [V(xa, 2.10, -zo), V(xmid, 2.085, -zo - 0.004), V(xb, 2.10, -zo), V(xb + 0.012, 2.09, 0.0), V(xb, 2.07, zo), V(xb - 0.04, 1.99, zo + 0.03),
             V(xmid, 1.945, zo + 0.036), V(xa + 0.04, 1.99, zo + 0.03), V(xa, 2.07, zo), V(xa - 0.012, 2.09, 0.0)]
    chain(ch, loop2, link=0.07, wire=0.0075, width=0.027, seed=5)
    py_, pz_ = 1.575, zo + 0.026
    pd = P.part(BRASS, atlas=1, col=[0.9, 0.85, 0.75], sharp=42, uvscale=1.3)
    pd.rrloft(0.092, 0.036, 0.012, [(0.006, 0.0), (0.0, 0.006), (0.0, 0.092), (0.006, 0.098)], n=3, caps=(True, True),
              m=T(xmid, py_, pz_) @ R('Z', 5))
    pds = P.part(STEEL, atlas=1, rust=0.9, sharp=60, uvscale=1.3)
    pds.tube([V(xmid - 0.027, py_ + 0.09, pz_), V(xmid - 0.027, py_ + 0.125, pz_)] +
             [V(xmid - 0.027 * cosd(a_), py_ + 0.125 + 0.027 * sind(a_), pz_) for a_ in range(20, 161, 20)] +
             [V(xmid + 0.027, py_ + 0.125, pz_), V(xmid + 0.027, py_ + 0.09, pz_)], 0.008, segs=7)
    pk = P.part(SOOT, atlas=1)
    pk.lathe([(0.008, 0.0), (0.0, 0.0)], segs=8, m=T(xmid, py_ + 0.04, pz_ + 0.0185) @ R('X', 90))
    pk.box(0.005, 0.02, 0.0005, m=T(xmid, py_ + 0.026, pz_ + 0.0185))

    def hook(tx, a):
        Pp = tx.P
        n1 = tx.fbm(1.1, 3, 601)
        tx.F["rust"] = (ss(0.6, 0.0, Pp[:, 1]) * 0.55 + (n1 - 0.5) * 0.5).astype(np.float32)
        tx.F["chip"] = (ss(0.9, 0.2, Pp[:, 1]) * 0.12).astype(np.float32)
        tx.F["dirt"] = (ss(0.4, 0.0, Pp[:, 1]) * 0.6).astype(np.float32)
    P.hook = hook
    return P


# =============================================================================================
# 5. Dispensary (perk) cabinet
# =============================================================================================
def bottle(P, x, y, z, r, h, colr, label="", rng=None, atlas=1, cork=True):
    b = P.part(BOTTLE, atlas=atlas, col=colr, label=label, l0=h * 0.16, l1=h * 0.50, lr=r, fill=h * rng.uniform(0.1, 0.5),
               sharp=50, uvscale=1.25)
    nk = r * 0.36
    b.lathe([(0.0, 0.0), (r * 0.92, 0.0), (r, r * 0.12), (r, h * 0.62), (r * 0.9, h * 0.70), (nk * 1.1, h * 0.80), (nk, h * 0.84),
             (nk, h * 0.94), (nk * 1.3, h * 0.95), (nk * 1.3, h * 0.985), (nk, h)], segs=10)
    b.xf(T(x, y, z) @ R('Y', rng.uniform(-25, 25)))
    if cork:
        c = P.part(PAINT, atlas=atlas, col=[0.42, 0.30, 0.18], wear=0.0, rust=0.0, gloss=0.8)
        c.lathe([(nk * 0.95, h * 0.99), (nk * 1.05, h * 1.05), (0.0, h * 1.055)], segs=8, m=T(x, y, z))
    return (x, y, h, r, [colr[0] * 0.9 + 0.03, colr[1] * 0.9 + 0.03, colr[2] * 0.9 + 0.03])


def tin(P, x, y, z, r, h, colr, rng, atlas=1):
    t = P.part(PAINT, atlas=atlas, col=colr, wear=1.2, rust=1.3, gloss=0.4, sharp=50, uvscale=1.2)
    t.lathe([(0.0, 0.0), (r, 0.0), (r, h * 0.8), (r * 1.03, h * 0.8), (r * 1.03, h), (0.0, h)], segs=12, m=T(x, y, z))
    return (x, y, h, r * 1.03, colr)


def build_perk_cabinet():
    P = K.Prop("prop_perk_cabinet", ["body", "inner"], edge_r=0.008, ao_dist=0.35, cav_dist=0.03, voxel=0.01,
               streak_len=0.3, dust=0.45, seed=5)
    WH = [0.80, 0.81, 0.74]
    rng = random.Random(55)
    ZFc = 0.205         # carcass front plane; doors sit proud of it up to z = 0.225
    # --- legs + carcass panels
    leg = P.part(PAINT, atlas=0, col=WH, wear=1.6, rust=1.6, gloss=0.38)
    for sx in (-1, 1):
        for sz in (-1, 1):
            leg.rrloft(0.045, 0.045, 0.006, [(0.009, 0.0), (0.005, 0.004), (0.0, 0.125)], n=2, caps=(True, False),
                       m=T(sx * 0.44, 0, sz * 0.19 - 0.01))
    body = P.part(PAINT, atlas=0, col=WH, wear=1.0, rust=1.1, gloss=0.36)
    for sx in (-1, 1):
        body.box(0.014, 1.64, 0.43, m=T(sx * 0.468, 0.94, -0.01), bevel=0.003)
    body.box(0.95, 0.014, 0.43, m=T(0, 0.127, -0.01), bevel=0.003)
    body.box(0.95, 0.014, 0.43, m=T(0, 1.753, -0.01), bevel=0.003)
    body.box(0.93, 1.62, 0.010, m=T(0, 0.94, -0.22))
    body.rrloft(0.975, 0.455, 0.006, [(0.012, 1.758), (0.0, 1.770), (0.0, 1.786), (0.004, 1.79)], n=2, caps=(False, True),
                m=T(0, 0, 0.0025))                                                    # cornice cap
    body.rrloft(0.965, 0.445, 0.005, [(0.006, 0.962), (0.0, 0.968), (0.0, 0.984), (0.006, 0.990)], n=2, caps=(True, True),
                m=T(0, 0, -0.0025))                                                   # counter ledge
    # --- lower cupboard doors
    for sx in (-1, 1):
        d = P.part(PAINT, atlas=0, col=WH, wear=1.1 + 0.3 * rng.random(), rust=1.1, gloss=0.36, sharp=42)
        dents = [(rng.uniform(-0.12, 0.12), rng.uniform(-0.2, 0.2), rng.uniform(0.04, 0.08), rng.uniform(0.002, 0.006))]
        panel_door(d, 0.458, 0.655, 0.02, edge=0.014, dents=dents, m=T(sx * 0.232, 0.468, ZFc), step=0.07)
        kn = P.part(BRASS, atlas=0, sharp=45)
        kn.lathe([(0.016, 0.0), (0.016, 0.004), (0.007, 0.008), (0.007, 0.018), (0.015, 0.026), (0.015, 0.034), (0.0, 0.038)], segs=10,
                 m=T(sx * 0.045, 0.60, ZFc + 0.019) @ R('X', 90))
        hgp = P.part(STEEL, atlas=0, rust=1.0, sharp=50)
        for hy in (0.23, 0.70):
            hgp.lathe([(0.0, -0.03), (0.007, -0.03), (0.007, 0.03), (0.0, 0.03)], segs=6, m=T(sx * 0.463, hy, ZFc + 0.02))
    # --- drawer band with the brass dispensing drawer
    band = P.part(PAINT, atlas=0, col=WH, wear=1.0, rust=1.1, gloss=0.36)
    DWd, DHd = 0.50, 0.112
    yb = 0.878
    band.box((0.922 - DWd) / 2, 0.158, 0.016, m=T(-(DWd / 2 + (0.922 - DWd) / 4), yb, ZFc + 0.008), bevel=0.003)
    band.box((0.922 - DWd) / 2, 0.158, 0.016, m=T((DWd / 2 + (0.922 - DWd) / 4), yb, ZFc + 0.008), bevel=0.003)
    band.box(DWd, (0.158 - DHd) / 2, 0.016, m=T(0, yb + DHd / 2 + (0.158 - DHd) / 4, ZFc + 0.008))
    band.box(DWd, (0.158 - DHd) / 2, 0.016, m=T(0, yb - DHd / 2 - (0.158 - DHd) / 4, ZFc + 0.008))
    tun = P.part(SOOT, atlas=1, col=[0.05, 0.05, 0.045])
    loop = [V(-DWd / 2, yb - DHd / 2, ZFc + 0.014), V(DWd / 2, yb - DHd / 2, ZFc + 0.014), V(DWd / 2, yb + DHd / 2, ZFc + 0.014),
            V(-DWd / 2, yb + DHd / 2, ZFc + 0.014)]
    A, B = loop_wall(tun, loop, (0, 0, -0.36), inward=True)
    f = tun.bm.faces.new(B)
    f.normal_update()
    if f.normal.z < 0:
        f.normal_flip()
    DL = 0.33
    zfront = ZFc + 0.016
    P.node("DispenseDrawer", T(0, yb, zfront - DL))
    dr = P.part(BRASS, atlas=0, node="DispenseDrawer", col=[1.0, 0.97, 0.9], sharp=42)
    dr.rrloft(DWd - 0.012, DL, 0.006, [(0.004, 0.0), (0.0, 0.004), (0.0, DHd - 0.016), (0.003, DHd - 0.012), (0.006, DHd - 0.016),
                                       (0.007, 0.01), (0.014, 0.006)], n=2, caps=(True, True), m=T(0, yb - DHd / 2 + 0.004, zfront - DL / 2))
    dr.rrloft(DWd + 0.022, DHd + 0.02, 0.006, [(0.0, 0.0), (0.0, 0.007), (0.004, 0.011), (0.010, 0.012)], n=2, caps=(True, True),
              m=T(0, yb, zfront) @ R('X', 90))
    # bar pull on two turned posts
    for sx in (-1, 1):
        dr.lathe([(0.011, 0.0), (0.011, 0.004), (0.006, 0.008), (0.006, 0.026), (0.009, 0.030)], segs=8,
                 m=T(sx * 0.07, yb - 0.022, zfront + 0.012) @ R('X', 90))
    dr.tube([V(-0.095, yb - 0.022, zfront + 0.044), V(0.095, yb - 0.022, zfront + 0.044)], 0.0075, segs=8)
    dpl = P.part(DECAL, atlas=0, node="DispenseDrawer", img="plate_dispense", kind="brass", w=0.20, h=0.05, uvscale=2.0)
    dpl.box(0.20, 0.05, 0.003)
    dpl.xf(T(0, yb + 0.03, zfront + 0.0125))
    drs = P.part(STEEL, atlas=0, node="DispenseDrawer", rust=0.8, sharp=80)
    for sx in (-1, 1):
        drs.rivet((sx * 0.235, yb, zfront + 0.012), (0, 0, 1), r=0.006, segs=6)
    # --- glazed upper doors
    y0g, y1g = 0.996, 1.596
    gl_specs = []
    for sx in (-1, 1):
        d = P.part(PAINT, atlas=0, col=WH, wear=1.2, rust=1.2, gloss=0.36, sharp=42)
        cxd = sx * 0.232
        dw, dhh, st = 0.458, y1g - y0g, 0.044
        for ex in (-1, 1):
            d.box(st, dhh, 0.022, m=T(cxd + ex * (dw / 2 - st / 2), (y0g + y1g) / 2, ZFc + 0.011), bevel=0.004)
        for ey in (-1, 1):
            d.box(dw - 2 * st, st, 0.020, m=T(cxd, (y0g + y1g) / 2 + ey * (dhh / 2 - st / 2), ZFc + 0.010), bevel=0.004)
        gl_specs.append((cxd - dw / 2 + st, cxd + dw / 2 - st, y0g + st, y1g - st))
        hgp = P.part(STEEL, atlas=0, rust=1.0, sharp=50)
        for hy in (y0g + 0.09, y1g - 0.09):
            hgp.lathe([(0.0, -0.03), (0.007, -0.03), (0.007, 0.03), (0.0, 0.03)], segs=6, m=T(sx * 0.463, hy, ZFc + 0.022))
    latch = P.part(BRASS, atlas=0, sharp=45)
    latch.lathe([(0.014, 0.0), (0.014, 0.004), (0.006, 0.008), (0.006, 0.016), (0.0, 0.017)], segs=10, m=T(0.022, 1.28, ZFc + 0.022) @ R('X', 90))
    latch.box(0.05, 0.014, 0.006, m=T(0.006, 1.28, ZFc + 0.04) @ R('Z', 12), bevel=0.002)
    zg = ZFc + 0.008
    glass = P.part(GLASS, atlas=1, sharp=30)
    gx0, gx1, gy0, gy1 = gl_specs[0]
    grid_xy(glass, [gx0, gx1], [gy0, gy1], lambda x, y: zg)
    gx0, gx1, gy0, gy1 = gl_specs[1]
    hc = ((gx0 + gx1) / 2 + 0.03, gy0 + 0.17)
    angs = sorted([2 * PI * k / 30 for k in range(30)] +
                  [math.atan2(cy_ - hc[1], cx_ - hc[0]) % (2 * PI) for cx_ in (gx0, gx1) for cy_ in (gy0, gy1)])
    rr = random.Random(7)
    outer, inner, crack_angles = [], [], []
    for a in angs:
        dx, dy = math.cos(a), math.sin(a)
        tx_ = min(((gx1 if dx > 0 else gx0) - hc[0]) / dx if abs(dx) > 1e-9 else 1e9,
                  ((gy1 if dy > 0 else gy0) - hc[1]) / dy if abs(dy) > 1e-9 else 1e9)
        rad = min(rr.uniform(0.075, 0.15) * (1.25 if dy < 0 else 0.9), tx_ * 0.93)
        outer.append(glass.bm.verts.new((hc[0] + dx * tx_, hc[1] + dy * tx_, zg)))
        inner.append(glass.bm.verts.new((hc[0] + dx * rad, hc[1] + dy * rad, zg)))
    for i in range(len(angs)):
        j = (i + 1) % len(angs)
        glass.bm.faces.new([outer[i], outer[j], inner[j], inner[i]])
    P.opts["cracks"] = (hc[0], hc[1], [angs[i] for i in range(0, len(angs), 4)])
    # --- frieze with the red-cross enamel plate
    frz = P.part(PAINT, atlas=0, col=WH, wear=1.0, rust=1.1, gloss=0.36)
    frz.box(0.922, 0.158, 0.016, m=T(0, 1.678, ZFc + 0.008), bevel=0.003)
    rc = P.part(DECAL, atlas=0, img="redcross", kind="enamel", w=0.142, h=0.142, uvscale=2.0)
    rc.rrloft(0.142, 0.142, 0.012, [(0.0, 0.0), (0.0, 0.003), (0.003, 0.005)], n=2, caps=(False, True), m=R('X', 90))
    rc.xf(T(0, 1.678, ZFc + 0.016))
    rcs = P.part(STEEL, atlas=0, rust=1.2, sharp=80)
    for sx in (-1, 1):
        for sy in (-1, 1):
            rcs.rivet((sx * 0.06, 1.678 + sy * 0.06, ZFc + 0.021), (0, 0, 1), r=0.0045, segs=6)
    # --- status lamp in a wire cage on top
    lx, lz_, ly = 0.0, 0.03, 1.79
    lb = P.part(IRON, atlas=0, col=[0.8, 0.8, 0.8], rust=1.0, sharp=42)
    lb.lathe([(0.062, 0.0), (0.062, 0.008), (0.05, 0.014), (0.044, 0.024), (0.036, 0.026)], segs=16, m=T(lx, ly, lz_))
    P.node("StatusLamp", T(lx, ly + 0.024, lz_))
    lamp = P.part(LAMP, atlas=0, node="StatusLamp", col=[0.50, 0.05, 0.04], sharp=60, uvscale=1.6)
    prof = [(0.036, 0.0)]
    for k in range(5):
        yy = 0.006 + k * 0.009
        prof += [(0.0345 - k * 0.002, yy), (0.037 - k * 0.0022, yy + 0.0045)]
    prof += [(0.024, 0.056), (0.012, 0.064), (0.0, 0.066)]
    lamp.lathe(prof, segs=14, m=T(lx, ly + 0.024, lz_))
    cage = P.part(STEEL, atlas=0, rust=1.2, sharp=70)
    for k in range(4):
        a = k * PI / 2 + PI / 4
        pts = [V(lx + 0.05 * math.cos(a), ly + 0.012, lz_ + 0.05 * math.sin(a)), V(lx + 0.05 * math.cos(a), ly + 0.06, lz_ + 0.05 * math.sin(a))]
        pts += [V(lx + 0.05 * math.cos(a) * cosd(t), ly + 0.06 + 0.042 * sind(t), lz_ + 0.05 * math.sin(a) * cosd(t)) for t in (25, 50, 75, 90)]
        cage.tube(pts, 0.0028, segs=5, caps=False)
    cage.ring((lx, ly + 0.05, lz_), (0, 1, 0), 0.05, 0.0028, segs=16, tsegs=5)
    cage.lathe([(0.008, 0.098), (0.008, 0.106), (0.0, 0.108)], segs=6, m=T(lx, ly, lz_))
    # --- interior: shelves, bottles, tins
    inn = P.part(PAINT, atlas=1, col=WH, wear=0.7, rust=0.9, gloss=0.4, uvscale=0.8)
    shelf_y = [0.992, 1.195, 1.395]
    for sy in shelf_y[1:]:
        inn.box(0.92, 0.008, 0.36, m=T(0, sy - 0.004, -0.02), bevel=0.002)
    inn.box(0.92, 0.008, 0.40, m=T(0, shelf_y[0] - 0.004, -0.01))
    ghosts = []
    AMB, GRN, BLU, CLR = [0.20, 0.10, 0.035], [0.06, 0.16, 0.08], [0.05, 0.08, 0.20], [0.30, 0.33, 0.30]
    labels = ["label_a", "label_b", "label_c", "label_d"]
    items = [  # (x, shelf, kind, r, h, colour)
        (0.07, 0, 'b', 0.036, 0.15, AMB), (0.16, 0, 'b', 0.030, 0.12, GRN), (0.245, 0, 't', 0.04, 0.085, [0.50, 0.12, 0.10]),
        (0.34, 0, 'b', 0.034, 0.16, AMB), (0.42, 0, 'b', 0.024, 0.10, CLR),
        (0.08, 1, 'b', 0.028, 0.13, BLU), (0.15, 1, 'b', 0.028, 0.13, AMB), (0.25, 1, 't', 0.045, 0.07, [0.16, 0.24, 0.20]),
        (0.36, 1, 'b', 0.038, 0.165, GRN), (0.43, 1, 'b', 0.022, 0.09, AMB),
        (0.09, 2, 't', 0.05, 0.06, [0.58, 0.50, 0.28]), (0.20, 2, 'b', 0.032, 0.14, CLR), (0.29, 2, 'b', 0.030, 0.12, AMB),
        (0.39, 2, 'b', 0.034, 0.15, BLU),
    ]
    k = 0
    for (x, si, kind, r, h, colr) in items:
        z = rng.uniform(0.03, 0.10)
        if kind == 'b':
            ghosts.append(bottle(P, x, shelf_y[si], z, r, h, colr, labels[k % 4], rng))
            k += 1
        else:
            ghosts.append(tin(P, x, shelf_y[si], z, r, h, colr, rng))
    for (x, si, kind, r, h, colr) in items:      # left side: seen only as silhouettes through the dusty pane
        if rng.random() < 0.8:
            ghosts.append((-x - rng.uniform(-0.02, 0.02), shelf_y[si], h * rng.uniform(0.8, 1.1), r, [c * 0.9 + 0.03 for c in colr]))
    P.opts["ghosts"] = ghosts
    P.opts["ghost_shelves"] = shelf_y[1:]

    def hook(tx, a):
        Pp = tx.P
        n1 = tx.fbm(1.6, 3, 701)
        tx.F["rust"] = (ss(0.35, 0.1, Pp[:, 1]) * 0.45 + (n1 - 0.5) * 0.35).astype(np.float32)
        tx.F["dirt"] = (ss(0.3, 0.1, Pp[:, 1]) * 0.4).astype(np.float32)
        hx, hy, _ = P.opts["cracks"]
        d = np.hypot(Pp[:, 0] - hx, Pp[:, 1] - hy)
        tx.F["wipe"] = (ss(0.30, 0.10, d) * 0.5).astype(np.float32)
    P.hook = hook
    return P


# =============================================================================================
# 7. Gurney
# =============================================================================================
def build_gurney():
    P = K.Prop("prop_gurney", ["frame", "bed"], edge_r=0.007, ao_dist=0.3, cav_dist=0.025, voxel=0.01, streak_len=0.18,
               dust=0.3, seed=7, uv_angle=66.0)
    ENA = [0.78, 0.79, 0.74]
    rng = random.Random(77)
    TR = 0.0155
    YF = 0.705
    fr = P.part(PAINT, atlas=0, col=ENA, wear=2.3, rust=2.5, gloss=0.4, sharp=50)
    hx, hz = 0.92, 0.305
    loop = [V(x, YF, z) for x, z in K.rr_points(2 * hx, 2 * hz, 0.07, 4)]
    fr.tube(loop, TR, segs=8, closed=True, up=(0, 1, 0))
    legs = []
    for sx in (-1, 1):
        for sz in (-1, 1):
            top = V(sx * 0.70, YF - 0.005, sz * hz)
            bot = V(sx * 0.76, 0.150, sz * hz)
            fr.tube([top, bot], TR, segs=8, caps=False)
            legs.append(bot)
            fr.lathe([(TR * 1.35, 0.0), (TR * 1.35, 0.03), (TR, 0.036)], segs=8, m=T(bot.x, 0.150, bot.z))
        # low cross stretchers
        fr.tube([V(sx * 0.742, 0.30, -hz), V(sx * 0.742, 0.30, hz)], TR * 0.85, segs=7, caps=False)
    for sz in (-1, 1):
        fr.tube([V(-0.742, 0.30, sz * hz), V(0.742, 0.30, sz * hz)], TR * 0.85, segs=7, caps=False)
    fr.tube([V(-0.742, 0.30, 0), V(0.742, 0.30, 0)], TR * 0.8, segs=7, caps=False)
    # push hoop at the head end
    hoop = round_path([V(-0.84, YF, -0.24), V(-1.0, YF + 0.20, -0.24), V(-1.0, YF + 0.20, 0.24), V(-0.84, YF, 0.24)], 0.07, 4)
    fr.tube(hoop, TR * 0.9, segs=8, caps=False)
    # foot rail
    fr.tube(round_path([V(0.86, YF, -0.22), V(0.93, YF + 0.10, -0.22), V(0.93, YF + 0.10, 0.22), V(0.86, YF, 0.22)], 0.05, 4), TR * 0.8, segs=7, caps=False)
    # deck pan with cross slats
    deck = P.part(PAINT, atlas=0, col=ENA, wear=1.9, rust=2.2, gloss=0.4, sharp=45)
    deck.rrloft(1.80, 0.585, 0.05, [(0.006, YF - 0.012), (0.0, YF - 0.006), (0.0, YF + 0.012), (0.004, YF + 0.016)], n=3, caps=(True, True))
    for k in range(6):
        deck.box(0.03, 0.02, 0.60, m=T(-0.75 + k * 0.30, YF - 0.022, 0), bevel=0.004)
    # --- castors
    for i, bot in enumerate(legs):
        ang = [20, -65, 140, 75][i]
        M = T(bot.x, 0, bot.z) @ R('Y', ang)
        cs = P.part(STEEL, atlas=0, rust=1.5, sharp=45)
        cs.lathe([(0.0, 0.150), (0.02, 0.150), (0.02, 0.132), (0.03, 0.130), (0.03, 0.120), (0.0, 0.120)], segs=10, m=M)
        cs.box(0.05, 0.006, 0.05, m=M @ T(0.012, 0.118, 0), bevel=0.002)
        for sz in (-1, 1):
            cs.extrude([(-0.012, 0.0), (0.036, 0.0), (0.045, -0.055), (0.030, -0.072), (0.016, -0.072), (0.004, -0.050)], 0.004,
                       m=M @ T(0, 0.118, sz * 0.021), bevel=0.0)
        cs.lathe([(0.0, -0.027), (0.006, -0.027), (0.006, 0.027), (0.0, 0.027)], segs=6, m=M @ T(0.024, 0.062, 0) @ R('X', 90))
        wh = P.part(RUBBER, atlas=0, col=[0.75, 0.74, 0.72], sharp=50)
        wh.lathe([(0.012, -0.015), (0.052, -0.015), (0.060, -0.010), (0.0625, 0.0), (0.060, 0.010), (0.052, 0.015), (0.012, 0.015)], segs=16,
                 m=M @ T(0.024, 0.0625, 0) @ R('X', 90))
        hub = P.part(STEEL, atlas=0, rust=1.3, sharp=50)
        hub.lathe([(0.0, -0.017), (0.03, -0.017), (0.034, -0.0152), (0.034, 0.0152), (0.03, 0.017), (0.0, 0.017)], segs=12,
                  m=M @ T(0.024, 0.0625, 0) @ R('X', 90))
    # --- mattress (ticking canvas, tufted, sagging where a body lay)
    mat = P.part(CANVAS, atlas=1, sharp=60)
    MW, MD, MB, MT = 1.76, 0.56, YF + 0.016, 0.80
    mat.rrloft(MW, MD, 0.045, [(0.02, MB), (0.004, MB + 0.008), (0.0, MB + 0.022), (0.0, MT - 0.028), (0.004, MT - 0.014),
                               (0.014, MT - 0.004), (0.028, MT - 0.001), (0.045, MT)], n=4, caps=(True, False))
    tuft = [(-0.66 + 0.33 * i, sz * 0.13) for i in range(5) for sz in (-1, 1)]
    x0, x1, z0, z1 = -MW / 2 + 0.045, MW / 2 - 0.045, -MD / 2 + 0.045, MD / 2 - 0.045

    def mfn(u, v):
        x, z = x0 + (x1 - x0) * u, z0 + (z1 - z0) * v
        e = min(x - x0, x1 - x, z - z0, z1 - z)
        y = MT + 0.012 * float(ss(0.0, 0.10, e))
        for (tx_, tz_) in tuft:
            y -= 0.017 * math.exp(-((x - tx_) ** 2 + (z - tz_) ** 2) / (0.045 ** 2))
        y -= 0.014 * math.exp(-((x + 0.1) ** 2 / 0.5 ** 2 + z ** 2 / 0.2 ** 2)) * float(ss(0.0, 0.08, e))
        return (x, y, z)
    mat.grid(44, 16, mfn)
    btn = P.part(LEATHER, atlas=1, col=[0.8, 0.7, 0.6], sharp=70)
    for (tx_, tz_) in tuft:
        p = mfn((tx_ - x0) / (x1 - x0), (tz_ - z0) / (z1 - z0))
        btn.lathe([(0.011, 0.0), (0.009, 0.004), (0.0, 0.0055)], segs=8, m=T(p[0], p[1] - 0.001, p[2]))
    # --- restraint straps: one buckled across the mattress, one hanging loose
    sx_ = 0.28
    yt = MT + 0.011
    path = [V(sx_, YF - 0.02, -hz - 0.004), V(sx_, YF, -hz - 0.02), V(sx_, YF + 0.03, -hz - 0.012), V(sx_, MT - 0.02, -MD / 2 - 0.004),
            V(sx_, yt - 0.004, -MD / 2 + 0.04), V(sx_, yt + 0.002, -0.12), V(sx_, yt + 0.003, 0.0), V(sx_, yt + 0.002, 0.12),
            V(sx_, yt - 0.004, MD / 2 - 0.04), V(sx_, MT - 0.02, MD / 2 + 0.004), V(sx_, YF + 0.03, hz + 0.012), V(sx_, YF, hz + 0.02),
            V(sx_, YF - 0.02, hz + 0.004)]
    ups = [V(0, -0.3, -1), V(0, 0, -1), V(0, 0.3, -1), V(0, 0.4, -1), V(0, 1, -0.4), V(0, 1, 0), V(0, 1, 0), V(0, 1, 0),
           V(0, 1, 0.4), V(0, 0.4, 1), V(0, 0.3, 1), V(0, 0, 1), V(0, -0.3, 1)]
    rp, ru = [], []
    for i in range(len(path) - 1):
        for k in range(4):
            t = k / 4
            rp.append(path[i].lerp(path[i + 1], t))
            ru.append(ups[i].lerp(ups[i + 1], t))
    rp.append(path[-1])
    ru.append(ups[-1])
    st = P.part(LEATHER, atlas=1, sharp=50)
    st.strap(rp, 0.052, 0.005, ups=ru)
    st.frame = T(sx_, MT, 0) @ R('Y', 90)
    # tail of the buckled strap overlapping past the buckle
    st2 = P.part(LEATHER, atlas=1, sharp=50)
    st2.strap([V(sx_, yt + 0.008, 0.02), V(sx_, yt + 0.010, 0.08), V(sx_, yt + 0.011, 0.16), V(sx_ + 0.004, yt + 0.022, 0.215)], 0.05, 0.005,
              ups=[V(0, 1, 0)] * 4)
    st2.frame = T(sx_, MT, 0) @ R('Y', 90)
    bk = P.part(STEEL, atlas=1, rust=0.9, sharp=60, uvscale=1.4)
    bk.tube([V(sx_ + a, yt + 0.008, b) for a, b in K.rr_points(0.072, 0.052, 0.01, 2)], 0.0035, segs=5, closed=True, up=(0, 1, 0), m=T(0, 0, 0.03))
    bk.tube([V(sx_, yt + 0.009, 0.006), V(sx_, yt + 0.012, 0.058)], 0.0028, segs=5)
    # loose strap pair at the chest, dangling
    for sz, ln in ((-1, 0.42), (1, 0.30)):
        s3 = P.part(LEATHER, atlas=1, sharp=50)
        xx = -0.42
        pp = [V(xx, YF + 0.02, sz * (hz - 0.012)), V(xx, YF + 0.022, sz * (hz + 0.012)), V(xx, YF, sz * (hz + 0.024)),
              V(xx + 0.01, YF - ln * 0.5, sz * (hz + 0.022)), V(xx + 0.025, YF - ln, sz * (hz + 0.03))]
        s3.strap(round_path(pp, 0.012, 2), 0.05, 0.005, ups=None, up=(0, 0.2, sz))
        s3.frame = T(xx, YF, sz * hz) @ R('Z', 90)
        if sz < 0:
            b3 = P.part(STEEL, atlas=1, rust=1.0, sharp=60, uvscale=1.4)
            e = pp[-1]
            b3.tube([V(e.x + a, e.y - 0.03 + b, e.z + 0.002) for a, b in [(-0.036, -0.026), (0.036, -0.026), (0.036, 0.026), (-0.036, 0.026)]],
                    0.0035, segs=5, closed=True, up=(0, 0, 1))
            b3.tube([V(e.x, e.y - 0.004, e.z + 0.004), V(e.x, e.y - 0.056, e.z + 0.004)], 0.0028, segs=5)

    def hook(tx, a):
        Pp = tx.P
        n1 = tx.fbm(2.2, 4, 801)
        n2 = tx.fbm(7.0, 3, 802)
        mid = np.exp(-(((Pp[:, 0] + 0.05) / 0.38) ** 2 + (Pp[:, 2] / 0.17) ** 2))
        tx.F["stain"] = (mid * (0.35 + 0.9 * n1) * 0.9 + ss(0.55, 0.75, n1) * 0.3).astype(np.float32)
        tx.F["blood"] = (ss(0.52, 0.72, n2 * 0.5 + np.exp(-(((Pp[:, 0] - 0.34) / 0.16) ** 2 + ((Pp[:, 2] + 0.05) / 0.12) ** 2)) * 0.75)).astype(np.float32)
        tx.F["rust"] = (0.10 + ss(0.45, 0.05, Pp[:, 1]) * 0.3 + (n1 - 0.5) * 0.5).astype(np.float32)
    P.hook = hook
    return P


# =============================================================================================
# 6. Stair collapse barricade (settled with a rigid-body drop)
# =============================================================================================
def settle(bodies, frames=260):
    """bodies: dicts with parts (in body-local coords), m0 (start pose), static. Poses the parts where they come to rest."""
    sc = bpy.context.scene
    sc.gravity = (0.0, -9.81, 0.0)          # the props are modelled Y-up
    if sc.rigidbody_world is None:
        bpy.ops.rigidbody.world_add()
    rw = sc.rigidbody_world
    rw.substeps_per_frame = 12
    rw.solver_iterations = 30
    rw.point_cache.frame_start = 1
    rw.point_cache.frame_end = frames
    sc.frame_start, sc.frame_end = 1, frames
    objs = []
    for b in bodies:
        bm = bmesh.new()
        allv = [v.co for p in b["parts"] for v in p.bm.verts]
        c = sum(allv, Vector()) / max(len(allv), 1)
        b["c"] = c
        for p in b["parts"]:
            p.bm.verts.index_update()
            vm = [bm.verts.new(v.co - c) for v in p.bm.verts]
            for f in p.bm.faces:
                try:
                    bm.faces.new([vm[v.index] for v in f.verts])
                except ValueError:
                    pass
        me = bpy.data.meshes.new("rb")
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("rb", me)
        sc.collection.objects.link(ob)
        ob.matrix_world = b["m0"] @ T(*c)
        objs.append(ob)
    bpy.context.view_layer.update()
    for b, ob in zip(bodies, objs):
        for o in sc.objects:
            o.select_set(o is ob)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.rigidbody.object_add(type='PASSIVE' if b.get("static") else 'ACTIVE')
        rb = ob.rigid_body
        rb.collision_shape = b.get("shape", 'CONVEX_HULL')
        rb.friction = b.get("friction", 0.85)
        rb.restitution = 0.0
        rb.use_margin = True
        rb.collision_margin = 0.002
        rb.linear_damping = 0.35
        rb.angular_damping = 0.6
        if not b.get("static"):
            rb.mass = b.get("mass", 5.0)
    for f in range(1, frames + 1):
        sc.frame_set(f)
    bpy.context.view_layer.update()
    for b, ob in zip(bodies, objs):
        M = ob.matrix_world.copy() @ T(*(-b["c"]))
        for p in b["parts"]:
            p.xf(M)
        b["m1"] = M
        b["m0"] = Matrix.Identity(4)      # parts now hold world coordinates
    for ob in objs:
        bpy.data.objects.remove(ob, do_unlink=True)
    bpy.ops.rigidbody.world_remove()


def build_stair_collapse():
    P = K.Prop("prop_stair_collapse", ["wardrobe", "timber", "plaster"], edge_r=0.012, ao_dist=0.5, cav_dist=0.05, voxel=0.02,
               streak_len=0.2, dust=0.62, dust_col=(0.66, 0.64, 0.58), seed=6, wood_size=0.8, streak=0.0, samples=16,
               uv_pack='AABB')
    rng = random.Random(66)
    bodies = []
    # --- static rubble mound: a wedge under the wardrobe's foot end and a spill toward the front
    mound = P.part(RUBBLE, atlas=2, sharp=70, uvscale=0.9)
    nrm = np.random.RandomState(6).rand(41, 29)

    def mh(x, z):
        e = min(1.2 - abs(x), 0.75 - abs(z))
        base = (0.20 * math.exp(-((x - 0.62) / 0.34) ** 2 - ((z + 0.22) / 0.30) ** 2) +
                0.30 * math.exp(-((x + 0.20) / 0.70) ** 2 - ((z - 0.42) / 0.26) ** 2) +
                0.22 * math.exp(-((x - 0.70) / 0.30) ** 2 - ((z - 0.30) / 0.24) ** 2) +
                0.16 * math.exp(-((x + 0.85) / 0.22) ** 2 - ((z - 0.10) / 0.30) ** 2))
        i, j = int(round((x + 1.2) / 2.4 * 44)), int(round((z + 0.75) / 1.5 * 30))
        wob = 0.05 * math.sin(x * 9.0 + z * 4.0) + 0.04 * math.sin(z * 13.0 - x * 5.0)
        h = (base - 0.04 + wob * 0.4 + 0.04 * (nrm[i % 41, j % 29] - 0.3) * (0.3 + base * 3)) * float(ss(0.0, 0.16, e))
        return max(0.0, h)
    mound.grid(44, 30, lambda u, v: (-1.2 + 2.4 * u, mh(-1.2 + 2.4 * u, -0.75 + 1.5 * v), -0.75 + 1.5 * v))
    bmesh.ops.delete(mound.bm, geom=[f for f in mound.bm.faces if all(v.co.y < 1e-4 for v in f.verts)], context='FACES')
    for v in mound.bm.verts:
        if v.co.y < 1e-4:
            v.co.y = -0.004
    bodies.append(dict(parts=[mound], m0=Matrix.Identity(4), static=True, shape='MESH'))
    fl = K.Part(K.Prop("tmp", ["a"]), SOOT)
    fl.box(12, 1, 12)
    bodies.append(dict(parts=[fl], m0=T(0, -0.5, 0), static=True, shape='BOX'))
    n_static = len(bodies)

    # --- wardrobe (dark oak): built upright around its centre; every board runs along its own local X
    OAK = dict(tex="oak_dark", col=[0.86, 0.74, 0.62], varnish=0.7)
    WW, WHt, WD = 0.92, 1.80, 0.50
    wparts = []

    def board(L, w, t, M, bevel=0.004, **kw):
        prm = dict(OAK)
        prm.update(kw)
        bd = P.part(WOOD, atlas=0, sharp=42, **prm)
        bd.box(L, t, w, bevel=bevel)
        bd.xf(M)
        wparts.append(bd)
        return bd
    UPR = R('Z', 90)                     # board length along Y
    for sx in (-1, 1):
        board(WHt, WD, 0.022, T(sx * (WW / 2 - 0.011), 0, 0) @ UPR)
    board(WW - 0.044, WD, 0.022, T(0, WHt / 2 - 0.011, 0))
    board(WW - 0.044, WD, 0.022, T(0, -WHt / 2 + 0.10, 0))
    board(WHt - 0.02, WW - 0.02, 0.010, T(0, 0, -WD / 2 + 0.008) @ UPR @ R('X', 90), bevel=0.0, varnish=0.1, col=[0.6, 0.55, 0.5])
    board(WW - 0.044, WD - 0.06, 0.018, T(0, 0.45, -0.01))
    crn = P.part(WOOD, atlas=0, sharp=42, **OAK)
    crn.rrloft(WW + 0.07, WD + 0.05, 0.006, [(0.03, 0.0), (0.02, 0.012), (0.004, 0.03), (0.0, 0.045), (0.0, 0.058), (0.006, 0.064)], n=2,
               caps=(True, True), m=T(0, WHt / 2 - 0.004, 0.01))
    wparts.append(crn)
    pl = P.part(WOOD, atlas=0, sharp=42, **OAK)
    pl.rrloft(WW + 0.03, WD + 0.02, 0.006, [(0.006, 0.0), (0.0, 0.006), (0.0, 0.075), (0.012, 0.092)], n=2, caps=(True, False),
              m=T(0, -WHt / 2, 0.005))
    wparts.append(pl)
    DWp, DHp = WW / 2 - 0.006, WHt - 0.20

    def door_boards(M):
        out = []
        for sx in (-1, 1):
            out.append(board(DHp, 0.075, 0.022, M @ T(sx * (DWp / 2 - 0.0375), 0, 0) @ UPR @ R('X', 90)))
        for sy in (-1, 0, 1):
            out.append(board(DWp - 0.15, 0.08, 0.022, M @ T(0, sy * (DHp / 2 - 0.04), 0) @ R('X', 90)))
        for sy in (-1, 1):
            out.append(board(DHp / 2 - 0.085, DWp - 0.14, 0.010, M @ T(0, sy * (DHp / 4), -0.003) @ UPR @ R('X', 90), bevel=0.0))
        return out
    hingeM = T(-WW / 2 + 0.004, 0, WD / 2) @ R('Y', -9) @ T(WW / 2 - 0.004, 0, -WD / 2)     # the remaining door hangs ajar
    for bd in door_boards(T(-WW / 4, 0.03, WD / 2 + 0.011)):
        bd.xf(hingeM)
    kn = P.part(BRASS, atlas=0, sharp=45)
    kn.lathe([(0.014, 0.0), (0.014, 0.004), (0.006, 0.008), (0.006, 0.02), (0.016, 0.03), (0.012, 0.042), (0.0, 0.045)], segs=10,
             m=hingeM @ T(-0.045, 0.0, WD / 2 + 0.022) @ R('X', 90))
    wparts.append(kn)
    rail = P.part(BRASS, atlas=0, sharp=45)
    rail.tube([V(-WW / 2 + 0.022, 0.72, 0.0), V(WW / 2 - 0.022, 0.72, 0.0)], 0.011, segs=8, caps=False)
    wparts.append(rail)
    # toppled onto its side across the flight, foot end riding up on the rubble wedge
    bodies.append(dict(parts=wparts, m0=T(-0.08, 0.66, -0.11) @ R('Y', 5) @ R('Z', 90), mass=70.0, friction=0.95))
    ward = bodies[n_static]
    settle(bodies, frames=170)                       # the wardrobe comes to rest first; the rest is staged around it
    # 70 kg of oak is not shifted by lath and plaster: from here on it is a fixed (hollow, mesh-accurate) obstacle
    ward["static"], ward["shape"] = True, 'MESH'
    wv = [v.co for p in wparts for v in p.bm.verts]
    WTOP, WFRONT = max(v.y for v in wv), max(v.z for v in wv)
    WBACK, WX0, WX1 = min(v.z for v in wv), min(v.x for v in wv), max(v.x for v in wv)
    print("  [settle] wardrobe rests x %.2f..%.2f  z %.2f..%.2f  top %.2f" % (WX0, WX1, WBACK, WFRONT, WTOP))

    def lean(foot, yaw, pitch, L):
        """Pose for a board (length along local X, centred) leaning back toward -Z from `foot`."""
        c_, s_ = cosd(pitch), sind(pitch)
        M = Matrix(((0, 0, 1, 0), (s_, c_, 0, 0), (-c_, s_, 0, 0), (0, 0, 0, 1)))
        return T(*foot) @ R('Y', yaw) @ M @ T(L / 2, 0, 0)

    from mathutils.bvhtree import BVHTree

    def surface(bods):
        vs, polys = [], []
        for b_ in bods:
            for p_ in b_["parts"]:
                p_.bm.verts.index_update()
                off = len(vs)
                vs += [v.co.copy() for v in p_.bm.verts]
                polys += [[off + v.index for v in f.verts] for f in p_.bm.faces]
        return BVHTree.FromPolygons(vs, polys)

    def lean_on(x, zf, L, half_t, yaw=0.0):
        """Pose a board so it bears on the ground at z=zf and on the wardrobe's upper front edge.
        At these pitches (50-60 deg) that is a stable ladder contact (needs friction > 0.35), so these few heavy
        members are posed in closed form and kept fixed while the loose debris settles around them."""
        tree = surface(bodies)
        ze, ye, zz = WFRONT, WTOP, WFRONT + 0.05
        while zz > WBACK:                 # walk back from the front until a ray lands on the wardrobe's upper side
            hit = tree.ray_cast(Vector((x, 6.0, zz)), Vector((0, -1, 0)))
            if hit[0] is not None and hit[0].y > WTOP - 0.30:
                ze, ye = zz + 0.01, hit[0].y
                break
            zz -= 0.01
        hit = tree.ray_cast(Vector((x, 6.0, zf)), Vector((0, -1, 0)))
        g = hit[0].y if hit[0] is not None else 0.0
        best = None
        for k in range(300, 880, 5):
            th = k / 10.0
            c_, s_ = cosd(th), sind(th)
            yf = g + half_t * c_ - 0.012                                                      # foot bedded into the rubble
            d = (ze - (zf - half_t * s_)) * s_ + (ye + 0.002 - (yf - half_t * c_)) * c_      # edge's distance to the underside
            if best is None or abs(d) < best[0]:
                best = (abs(d), th, yf)
        print("  [settle] lean at x=%.2f: pitch %.1f deg onto edge y=%.2f z=%.2f" % (x, best[1], ye, ze))
        # a small yaw about the foot lengthens the run to the edge by 1/cos(yaw): move the foot in by that much
        run = (zf - ze) * (1.0 / math.cos(math.radians(yaw)) - 1.0)
        return lean((x, best[2], zf - run), yaw, best[1], L)

    # the wardrobe's other door, torn off and propped against its front
    d2 = door_boards(Matrix.Identity(4))
    for bd in d2:
        wparts.remove(bd)
        bd.xf(R('X', 90) @ R('Z', 90))               # length along X, thickness along Y
    bodies.append(dict(parts=d2, m0=lean_on(-0.74, WFRONT + 0.44, DHp, 0.016, yaw=-5), static=True, friction=0.98))

    # --- collapsed ceiling joists (old softwood, splintered where they snapped)
    TIM = dict(tex="timber_weathered_albedo", col=[0.98, 0.84, 0.66], varnish=0.0)
    LTH = dict(tex="timber_weathered_albedo", col=[1.25, 1.08, 0.84], varnish=0.0)
    pending = []

    def queue(part, zone, rot, mass, radius, half_h, first=False):
        d_ = dict(parts=part if isinstance(part, list) else [part], zone=zone, rot=rot, mass=mass, r=radius, hh=half_h, friction=0.98)
        if first:
            heavy.append(d_)
        else:
            pending.append(d_)
    heavy = []
    for k, (L, spec) in enumerate([(1.74, (0.40, 0.52, -9)), (1.46, (-0.16, 0.36, 7)), (1.45, 'top'), (1.20, 'front'), (1.00, 'front')]):
        j = P.part(WOOD, atlas=1, sharp=50, **TIM)
        broken_board(j, L, 0.19, 0.07, br0=rng.uniform(0.08, 0.2) if k != 1 else 0.0, br1=rng.uniform(0.08, 0.22), rng=rng)
        if isinstance(spec, tuple):      # two joists lean from the floor onto the wardrobe, standing on edge
            j.xf(R('X', 90))
            bodies.append(dict(parts=[j], m0=lean_on(spec[0], WFRONT + spec[1], L, 0.095, yaw=spec[2]), static=True, friction=0.98))
        else:                            # the others lie flat: along the top of the wardrobe and on the spill in front
            queue(j, spec, R('Y', rng.uniform(-14, 14)), 14.0, L * 0.5, 0.05, first=True)
    # --- lath: one section still nailed to its battens, the rest loose
    panel = []
    for i in range(9):
        l = P.part(WOOD, atlas=1, sharp=50, uvscale=0.85, **LTH)
        broken_board(l, rng.uniform(0.7, 0.95), 0.032, 0.008, br0=0.04, br1=0.05, rng=rng, nw=2, nt=1)
        l.xf(T(rng.uniform(-0.04, 0.04), 0, -0.2 + i * 0.045))
        panel.append(l)
    for sx in (-0.25, 0.22):
        cl = P.part(WOOD, atlas=1, sharp=50, **TIM)
        broken_board(cl, 0.5, 0.05, 0.04, br0=0.05, br1=0.06, rng=rng, nw=2, nt=1)
        cl.xf(T(sx, -0.024, -0.02) @ R('Y', 90))
        panel.append(cl)
    queue(panel, 'front', R('Y', rng.uniform(-20, 20)), 3.0, 0.50, 0.06, first=True)

    # --- everything else is laid onto the heap in small batches: each piece is ray-cast onto the current surface
    #     (never overlapping another piece), dropped a few centimetres, and the heap is settled before the next batch.
    ZA, ZB = WBACK + 0.14, WFRONT - 0.32          # strip on the wardrobe's upper side
    ZC, ZD = WFRONT + 0.10, 0.60                  # strip in front of it
    for i in range(44):
        l = P.part(WOOD, atlas=1, sharp=50, uvscale=0.85, **LTH)
        L_ = rng.uniform(0.28, 0.72)
        broken_board(l, L_, 0.032, 0.008, br0=0.04, br1=0.05, rng=rng, nw=2, nt=1)
        queue(l, 'top' if i % 3 == 0 else 'front', R('Y', rng.uniform(-60, 60)) @ R('Z', rng.uniform(-6, 6)), 0.3, L_ * 0.5, 0.04)
    for k in range(4):                            # broken stair treads (oak)
        t = P.part(WOOD, atlas=0, sharp=50, tex="oak_dark", col=[0.95, 0.85, 0.72], varnish=0.35)
        L_ = rng.uniform(0.55, 0.9)
        broken_board(t, L_, 0.27, 0.038, br0=rng.uniform(0.06, 0.16), br1=rng.uniform(0.0, 0.14) if k % 2 else 0.0, rng=rng, nw=4)
        queue(t, 'front', R('Y', rng.uniform(-40, 40)) @ R('X', rng.uniform(-8, 8)), 4.0, L_ * 0.5, 0.06)
    for k in range(40):                           # plaster slabs: painted skin is part-local +Y, lath keys on the back
        sl = P.part(PLASTER, atlas=2, sharp=45, col=[0.66, 0.65, 0.57] if k % 3 else [0.50, 0.56, 0.49])
        rad = rng.uniform(0.09, 0.25)
        n = rng.randint(13, 18)
        lobes = [rng.uniform(0.0, 6.28) for _ in range(3)]
        poly = []
        for i in range(n):
            a_ = 2 * PI * i / n + rng.uniform(-0.12, 0.12)
            r_ = rad * (0.82 + 0.16 * math.sin(2 * a_ + lobes[0]) + 0.10 * math.sin(3 * a_ + lobes[1]) + 0.07 * math.sin(5 * a_ + lobes[2])) * rng.uniform(0.86, 1.08)
            poly.append((r_ * math.cos(a_) * 1.3, r_ * math.sin(a_)))
        for v in sl.extrude(poly, 0.032, bevel=0.0):
            if v.co.z < 0:
                v.co.x *= rng.uniform(0.9, 1.0)
                v.co.y *= rng.uniform(0.9, 1.0)
        sl.bm.transform(R('X', -90))
        flip = 180 if k % 5 == 1 else 0           # some land face down, showing the lath keys
        queue(sl, 'top' if k % 3 == 0 else 'front', R('Y', rng.uniform(0, 360)) @ R('X', rng.uniform(-9, 9) + flip), 2.5, rad * 1.3, 0.06)
    for k in range(80):                           # loose chunks
        c = P.part(PLASTER, atlas=2, sharp=62, col=[0.66, 0.64, 0.57], uvscale=0.8)
        tb = bmesh.new()
        bmesh.ops.create_icosphere(tb, subdivisions=2, radius=1.0)
        r0 = rng.uniform(0.03, 0.085)
        sc_ = [r0 * f for f in (1.0, rng.uniform(0.5, 0.8), rng.uniform(0.7, 1.0))]
        ph = [rng.uniform(0, 6.28) for _ in range(3)]
        for v in tb.verts:
            lump = 1.0 + 0.16 * math.sin(v.co.x * 3.1 + ph[0]) + 0.13 * math.sin(v.co.y * 4.3 + ph[1]) + 0.12 * math.sin(v.co.z * 3.7 + ph[2])
            v.co = Vector((v.co.x * sc_[0], v.co.y * sc_[1], v.co.z * sc_[2])) * lump * rng.uniform(0.93, 1.07)
        c._absorb(tb)
        queue(c, 'top' if k % 4 == 0 else 'front', R('Y', rng.uniform(0, 360)), 0.6, r0 * 1.2, r0 * 1.2)
    rng.shuffle(pending)
    pending = heavy + pending

    def trim(bods):
        n = 0
        for b_ in list(bods[n_static + 1:]):
            xs = [v.co.x for p_ in b_["parts"] for v in p_.bm.verts]
            ys = [v.co.y for p_ in b_["parts"] for v in p_.bm.verts]
            zs = [v.co.z for p_ in b_["parts"] for v in p_.bm.verts]
            if min(ys) < -0.03 or min(zs) < -0.80 or max(zs) > 0.80 or min(xs) < -1.2 or max(xs) > 1.2:
                for p_ in b_["parts"]:
                    p_.bm.clear()
                bods.remove(b_)
                n += 1
        return n

    BATCH = 16
    for start in range(0, len(pending), BATCH):
        tree = surface(bodies)
        laid = []
        for b_ in pending[start:start + BATCH]:
            for attempt in range(40):
                if b_["zone"] == 'top':
                    half = max(0.04, (WX1 - WX0) / 2 - 0.2 - b_["r"])
                    x, z = (WX0 + WX1) / 2 + rng.uniform(-half, half), rng.uniform(ZA, ZB)
                else:
                    half = max(0.05, 1.10 - b_["r"])
                    x, z = rng.uniform(-half, half), rng.uniform(ZC, ZD)
                if all((x - lx) ** 2 + (z - lz) ** 2 > (b_["r"] + lr) ** 2 * 0.8 for lx, lz, lr, lt in laid):
                    break
            base = 0.0
            for dx, dz in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7)):
                hit = tree.ray_cast(Vector((x + dx * b_["r"], 6.0, z + dz * b_["r"])), Vector((0, -1, 0)))
                if hit[0] is not None:
                    base = max(base, hit[0].y)
            for lx, lz, lr, lt in laid:
                if (x - lx) ** 2 + (z - lz) ** 2 < (b_["r"] + lr) ** 2:
                    base = max(base, lt)
            y = base + b_["hh"] + 0.03
            laid.append((x, z, b_["r"], y + b_["hh"]))
            b_["m0"] = T(x, y, z) @ b_["rot"]
            bodies.append(b_)
        settle(bodies, frames=70)
        trimmed = trim(bodies)
        print("  [settle] batch %d: %d pieces in the heap (%d trimmed outside the footprint)" % (start // BATCH, len(bodies) - n_static, trimmed))
    settle(bodies, frames=160)
    for rnd in range(3):
        if not trim(bodies):
            break
        settle(bodies, frames=100)
    print("  [settle] final: %d pieces rest in the heap" % (len(bodies) - n_static))
    wv = [v.co for p in ward["parts"] for v in p.bm.verts]
    P.info["wardrobe_centre"] = [round(v, 2) for v in (sum(wv, Vector()) / len(wv))]
    P.info["wardrobe_y_range"] = [round(min(v.y for v in wv), 2), round(max(v.y for v in wv), 2)]

    def hook(tx, a):
        n1 = tx.fbm(3.0, 3, 901)
        tx.F["dust"] = (tx.up * (0.25 + 0.5 * n1) * 0.35 + ss(0.5, 0.0, tx.P[:, 1]) * 0.25 * n1).astype(np.float32)
    P.hook = hook
    return P


BUILDERS = {
    "boiler": build_boiler,
    "morgue_drawers": build_morgue_drawers,
    "breach_gate": build_breach_gate,
    "perk_cabinet": build_perk_cabinet,
    "stair_collapse": build_stair_collapse,
    "gurney": build_gurney,
    "morgue_table": build_morgue_table,
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = os.path.join(K.REPO, "assets", "models")
    names, use_cache, samples = [], True, None
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--out":
            out_dir = argv[i + 1]
            i += 1
        elif a == "--nocache":
            use_cache = False
        elif a == "--samples":
            samples = int(argv[i + 1])
            i += 1
        else:
            names.append(a.replace("prop_", ""))
        i += 1
    names = names or list(BUILDERS)
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass
    tex_dir = os.path.join(SCRATCH, "tex")
    cache_dir = os.path.join(SCRATCH, "cache")
    for d in (out_dir, tex_dir, cache_dir):
        os.makedirs(d, exist_ok=True)
    print("=== build_env_props ->", out_dir)
    summary = []
    for n in names:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        random.seed(1234)
        prop = BUILDERS[n]()
        if samples:
            prop.opts["samples"] = samples
        prop.finish(out_dir, tex_dir, cache_dir, use_cache)
        summary.append((prop.name, prop.info))
    for nm, info in summary:
        print("SUMMARY", nm, info)
    print("=== ALL ENV PROPS BUILT ===")


if __name__ == "__main__":
    main()
