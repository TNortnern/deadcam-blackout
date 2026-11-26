#!/usr/bin/env python3
"""Generate detailed sculpted .obj 3D meshes with proper normals and UVs for DEADCAM: BLACKOUT.
Avoids primitive box/sphere look by building organic displaced geometry, architectural arches,
rubble mounds, turned balusters, curved reception desks, oak barrels, detailed pine trees,
sculpted zombie anatomy/helmets, and detailed tactical weapons.
"""
import math
from pathlib import Path
import numpy as np

OUT = Path(__file__).resolve().parents[1] / "assets" / "meshes"
OUT.mkdir(parents=True, exist_ok=True)


class MeshBuilder:
    def __init__(self):
        self.verts = []
        self.uvs = []
        self.faces = []  # list of ((v0,vt0), (v1,vt1), (v2,vt2))

    def add_v(self, x, y, z):
        self.verts.append((float(x), float(y), float(z)))
        return len(self.verts)

    def add_uv(self, u, v):
        self.uvs.append((float(u), float(v)))
        return len(self.uvs)

    def add_tri(self, a, b, c):
        self.faces.append((a, b, c))

    def add_quad(self, a, b, c, d):
        self.faces.append((a, b, c))
        self.faces.append((a, c, d))

    def add_lathe(self, profile, segs=20, noise_amp=0.0, seed=1, y_offset=0.0, x_offset=0.0, z_offset=0.0):
        """profile: list of (radius, y, v_coord)"""
        rng = np.random.default_rng(seed)
        rings = []
        for ri, (rad, y, vc) in enumerate(profile):
            ring = []
            for si in range(segs + 1):
                ang = (si / segs) * math.tau
                n = 1.0 + (rng.uniform(-1, 1) * noise_amp if (noise_amp > 0 and 0 < ri < len(profile) - 1 and si < segs) else 0.0)
                if si == segs and ring:
                    v_idx = ring[0][0]
                else:
                    v_idx = self.add_v(
                        x_offset + math.cos(ang) * rad * n,
                        y_offset + y,
                        z_offset + math.sin(ang) * rad * n,
                    )
                uv_idx = self.add_uv(si / segs, vc)
                ring.append((v_idx, uv_idx))
            rings.append(ring)
        for ri in range(len(rings) - 1):
            r0, r1 = rings[ri], rings[ri + 1]
            for si in range(segs):
                self.add_quad(r0[si], r0[si + 1], r1[si + 1], r1[si])

    def add_box(self, cx, cy, cz, sx, sy, sz, bevel=0.0, rx=0.0, ry=0.0, rz=0.0, uv_scale=1.0):
        """Oriented box with optional clean chamfer feel via subdivisions."""
        hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
        # Rotation matrix
        crx, srx = math.cos(rx), math.sin(rx)
        cry, sry = math.cos(ry), math.sin(ry)
        crz, srz = math.cos(rz), math.sin(rz)

        def xform(x, y, z):
            # Rx
            y, z = y * crx - z * srx, y * srx + z * crx
            # Ry
            x, z = x * cry + z * sry, -x * sry + z * cry
            # Rz
            x, y = x * crz - y * srz, x * srz + y * crz
            return cx + x, cy + y, cz + z

        faces_spec = [
            # +Z front
            ((-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz), sx, sy),
            # -Z back
            ((hx, -hy, -hz), (-hx, -hy, -hz), (-hx, hy, -hz), (hx, hy, -hz), sx, sy),
            # +X right
            ((hx, -hy, hz), (hx, -hy, -hz), (hx, hy, -hz), (hx, hy, hz), sz, sy),
            # -X left
            ((-hx, -hy, -hz), (-hx, -hy, hz), (-hx, hy, hz), (-hx, hy, -hz), sz, sy),
            # +Y top
            ((-hx, hy, hz), (hx, hy, hz), (hx, hy, -hz), (-hx, hy, -hz), sx, sz),
            # -Y bottom
            ((-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), sx, sz),
        ]
        for p0, p1, p2, p3, uw, vh in faces_spec:
            vs = [self.add_v(*xform(*p)) for p in (p0, p1, p2, p3)]
            us = [
                self.add_uv(0, 0),
                self.add_uv(uw * uv_scale, 0),
                self.add_uv(uw * uv_scale, vh * uv_scale),
                self.add_uv(0, vh * uv_scale),
            ]
            self.add_quad((vs[0], us[0]), (vs[1], us[1]), (vs[2], us[2]), (vs[3], us[3]))

    def write_obj(self, name: str, smooth: bool = True):
        verts = np.array(self.verts, dtype=np.float64)
        normals = np.zeros_like(verts)
        if smooth:
            for (a, _), (b, _), (c, _) in self.faces:
                v0, v1, v2 = verts[a - 1], verts[b - 1], verts[c - 1]
                n = np.cross(v1 - v0, v2 - v0)
                normals[a - 1] += n
                normals[b - 1] += n
                normals[c - 1] += n
            lens = np.linalg.norm(normals, axis=1, keepdims=True)
            normals = np.divide(normals, np.maximum(lens, 1e-9))

        lines = [f"# DEADCAM procedural mesh: {name}"]
        for x, y, z in self.verts:
            lines.append(f"v {x:.5f} {y:.5f} {z:.5f}")
        for u, v in self.uvs:
            lines.append(f"vt {u:.5f} {v:.5f}")
        if smooth:
            for nx, ny, nz in normals:
                lines.append(f"vn {nx:.5f} {ny:.5f} {nz:.5f}")
            for (v0, t0), (v1, t1), (v2, t2) in self.faces:
                lines.append(f"f {v0}/{t0}/{v0} {v1}/{t1}/{v1} {v2}/{t2}/{v2}")
        else:
            for fi, ((v0, t0), (v1, t1), (v2, t2)) in enumerate(self.faces, 1):
                p0, p1, p2 = verts[v0 - 1], verts[v1 - 1], verts[v2 - 1]
                n = np.cross(p1 - p0, p2 - p0)
                nl = np.linalg.norm(n)
                n = n / max(nl, 1e-9)
                lines.append(f"vn {n[0]:.5f} {n[1]:.5f} {n[2]:.5f}")
                lines.append(f"f {v0}/{t0}/{fi} {v1}/{t1}/{fi} {v2}/{t2}/{fi}")
        path = OUT / f"{name}.obj"
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"  saved mesh: {name}.obj ({len(self.verts)}v, {len(self.faces)}t)")


def gen_vaulted_tunnel_bay():
    """Arched brick tunnel segment (4.2m wide, 3.6m tall, 4.0m deep) with recessed masonry ribs."""
    mb = MeshBuilder()
    segs = 20
    length = 4.0
    z_steps = 6
    wall_h = 1.45
    half_w = 2.05
    arch_r = half_w

    def arch_point(t):
        """t in [0, 1]: left wall up -> semicircular vault -> right wall down."""
        if t < 0.2:
            f = t / 0.2
            return -half_w, f * wall_h
        elif t > 0.8:
            f = (1.0 - t) / 0.2
            return half_w, f * wall_h
        else:
            ang = math.pi * (1.0 - (t - 0.2) / 0.6)
            return math.cos(ang) * arch_r, wall_h + math.sin(ang) * (arch_r * 0.92)

    rings = []
    rng = np.random.default_rng(42)
    for zi in range(z_steps + 1):
        z = -length * 0.5 + (zi / z_steps) * length
        ring = []
        for si in range(segs + 1):
            t = si / segs
            x, y = arch_point(t)
            # Subtle masonry unevenness so flashlight raking light looks ultra-real!
            bump = (math.sin(t * 24.0 + z * 3.1) * 0.025 + math.cos(t * 47.0 - z * 5.2) * 0.015)
            # Rib inset at ends
            rib = -0.14 if (zi == 0 or zi == z_steps) else 0.0
            nx = -x / max(math.hypot(x, y - wall_h), 0.1)
            ny = -(y - wall_h) / max(math.hypot(x, y - wall_h), 0.1) if y > wall_h else 0.0
            px = x + nx * (bump + rib)
            py = y + ny * (bump + rib)
            v = mb.add_v(px, py, z)
            uv = mb.add_uv(t * 4.5, (zi / z_steps) * 2.0)
            ring.append((v, uv))
        rings.append(ring)

    # Winding faces inward so interior of tunnel is rendered!
    for zi in range(z_steps):
        r0, r1 = rings[zi], rings[zi + 1]
        for si in range(segs):
            mb.add_quad(r0[si], r1[si], r1[si + 1], r0[si + 1])

    # Thick structural arch rib ring at z = 0
    for si in range(segs):
        t0, t1 = si / segs, (si + 1) / segs
        x0, y0 = arch_point(t0)
        x1, y1 = arch_point(t1)
        mx, my = (x0 + x1) * 0.5, (y0 + y1) * 0.5
        ang = math.atan2(y1 - y0, x1 - x0)
        seg_len = math.hypot(x1 - x0, y1 - y0)
        mb.add_box(mx * 0.96, my * 0.97 + 0.03, 0.0, seg_len + 0.05, 0.20, 0.36, rz=ang, uv_scale=0.6)

    mb.write_obj("tunnel_vault_bay", smooth=True)


def gen_rubble_mound():
    """Organic jagged concrete/brick rubble pile for tunnel floors & collapsed corners."""
    mb = MeshBuilder()
    rng = np.random.default_rng(77)
    # Irregular mound base
    rings = 8
    segs = 18
    grid = []
    for ri in range(rings + 1):
        f = ri / rings
        rad = f * 1.5
        ring = []
        for si in range(segs + 1):
            ang = (si / segs) * math.tau
            if si == segs and ring:
                v = ring[0][0]
            else:
                h = (1.0 - f * f) * 0.52
                n = (math.sin(ang * 3 + f * 7) * 0.08 + math.cos(ang * 5 - f * 9) * 0.06 + rng.uniform(-0.05, 0.05))
                y = max(0.0, h + n * (1.0 - f * 0.6))
                r = rad * (1.0 + math.sin(ang * 2.0) * 0.18 + rng.uniform(-0.06, 0.06))
                v = mb.add_v(math.cos(ang) * r, y, math.sin(ang) * r)
            uv = mb.add_uv((math.cos(ang) * f * 0.5 + 0.5) * 2.0, (math.sin(ang) * f * 0.5 + 0.5) * 2.0)
            ring.append((v, uv))
        grid.append(ring)
    for ri in range(rings):
        for si in range(segs):
            mb.add_quad(grid[ri][si], grid[ri + 1][si], grid[ri + 1][si + 1], grid[ri][si + 1])

    # Scatter jagged broken concrete chunks & bricks protruding from the mound
    for _ in range(18):
        ang = rng.uniform(0, math.tau)
        dist = rng.uniform(0.1, 1.25)
        sx = rng.uniform(0.14, 0.38)
        sy = rng.uniform(0.08, 0.24)
        sz = rng.uniform(0.12, 0.34)
        y = max(0.04, (1.0 - (dist / 1.5) ** 2) * 0.44)
        mb.add_box(math.cos(ang) * dist, y, math.sin(ang) * dist, sx, sy, sz,
                   rx=rng.uniform(-0.7, 0.7), ry=rng.uniform(0, math.tau), rz=rng.uniform(-0.7, 0.7), uv_scale=1.5)
    mb.write_obj("rubble_mound", smooth=False)


def gen_oak_barrel():
    """Bulged oak barrel with recessed top/bottom heads (ref #18)."""
    mb = MeshBuilder()
    prof = [
        (0.0, 0.02, 0.0),
        (0.27, 0.02, 0.04),
        (0.28, 0.0, 0.06),
        (0.31, 0.14, 0.18),
        (0.35, 0.44, 0.50),
        (0.31, 0.74, 0.82),
        (0.28, 0.88, 0.94),
        (0.27, 0.85, 0.96),
        (0.0, 0.85, 1.0),
    ]
    mb.add_lathe(prof, segs=20, noise_amp=0.008, seed=18)
    mb.write_obj("oak_barrel", smooth=True)


def gen_vintage_lamp():
    """Ornate turned wooden Asylum reception desk lamp (base + shade, ref #16)."""
    mb = MeshBuilder()
    base_prof = [
        (0.0, 0.0, 0.0),
        (0.12, 0.0, 0.05),
        (0.11, 0.03, 0.10),
        (0.045, 0.07, 0.18),
        (0.075, 0.16, 0.34),
        (0.082, 0.22, 0.44),
        (0.038, 0.30, 0.58),
        (0.048, 0.35, 0.66),
        (0.028, 0.40, 0.74),
        (0.0, 0.40, 0.76),
    ]
    mb.add_lathe(base_prof, segs=18)
    mb.write_obj("lamp_base", smooth=True)

    ms = MeshBuilder()
    shade_prof = [
        (0.22, 0.36, 0.0),
        (0.12, 0.58, 1.0),
        (0.115, 0.58, 1.0),
        (0.215, 0.36, 0.0),
    ]
    ms.add_lathe(shade_prof, segs=22)
    ms.write_obj("lamp_shade", smooth=True)


def gen_reception_desk():
    """Curved paneled Asylum lobby reception desk with molding & counter overhang (ref #16)."""
    mb = MeshBuilder()
    segs = 18
    r_inner = 1.65
    r_outer = 2.25
    h = 1.08
    start_a = -math.pi * 0.58
    end_a = math.pi * 0.48

    # Build curved front & back walls + counter lip + recessed decorative panels
    for i in range(segs):
        a0 = start_a + (i / segs) * (end_a - start_a)
        a1 = start_a + ((i + 1) / segs) * (end_a - start_a)
        am = (a0 + a1) * 0.5
        seg_w_out = (r_outer * (a1 - a0)) + 0.02
        # Main carcass segment
        cx = math.cos(am) * ((r_inner + r_outer) * 0.5)
        cz = math.sin(am) * ((r_inner + r_outer) * 0.5)
        mb.add_box(cx, h * 0.5, cz, r_outer - r_inner, h, seg_w_out, ry=-am, uv_scale=0.8)
        # Overhanging thick counter top
        cx_top = math.cos(am) * ((r_inner + r_outer) * 0.5 + 0.04)
        cz_top = math.sin(am) * ((r_inner + r_outer) * 0.5 + 0.04)
        mb.add_box(cx_top, h + 0.035, cz_top, (r_outer - r_inner) + 0.18, 0.07, seg_w_out + 0.04, ry=-am, uv_scale=0.8)
        # Baseboard plinth
        mb.add_box(math.cos(am) * (r_outer + 0.03), 0.08, math.sin(am) * (r_outer + 0.03), 0.06, 0.16, seg_w_out, ry=-am, uv_scale=0.8)
        # Raised molding stiles every 2 segments
        if i % 2 == 0:
            mb.add_box(math.cos(a0) * (r_outer + 0.025), h * 0.5, math.sin(a0) * (r_outer + 0.025), 0.05, h - 0.14, 0.09, ry=-a0, uv_scale=0.8)
    mb.write_obj("reception_desk", smooth=False)


def gen_baluster():
    """Carved wooden grand staircase baluster & newel post (ref #3)."""
    mb = MeshBuilder()
    prof = [
        (0.035, 0.0, 0.0),
        (0.035, 0.10, 0.12),
        (0.022, 0.16, 0.20),
        (0.034, 0.28, 0.35),
        (0.026, 0.42, 0.52),
        (0.018, 0.56, 0.70),
        (0.030, 0.68, 0.85),
        (0.032, 0.82, 1.0),
    ]
    mb.add_lathe(prof, segs=10)
    mb.write_obj("stair_baluster", smooth=True)


def gen_pine_tree():
    """Tall dark silhouetted winter spruce/pine tree with tiered organic needle boughs (refs #7, #8, #10)."""
    # Trunk mesh
    mt = MeshBuilder()
    trunk_prof = [
        (0.28, 0.0, 0.0),
        (0.22, 1.5, 0.15),
        (0.17, 4.0, 0.40),
        (0.11, 7.5, 0.75),
        (0.05, 10.5, 0.95),
        (0.01, 11.8, 1.0),
    ]
    mt.add_lathe(trunk_prof, segs=10, noise_amp=0.10, seed=51)
    mt.write_obj("pine_trunk", smooth=True)

    # Tiered drooping needle fronds (many overlapping angled branch skirts)
    mf = MeshBuilder()
    rng = np.random.default_rng(52)
    tiers = 11
    for ti in range(tiers):
        f = ti / (tiers - 1)
        y_base = 2.0 + f * 9.0
        max_r = (1.0 - f * 0.78) * 2.6 + 0.35
        branches = 7 if ti < 7 else 5
        for bi in range(branches):
            ang = (bi / branches) * math.tau + ti * 0.65 + rng.uniform(-0.2, 0.2)
            blen = max_r * rng.uniform(0.82, 1.15)
            droop = -0.35 - (1.0 - f) * 0.32
            # Build tapered diamond bough frond
            ca, sa = math.cos(ang), math.sin(ang)
            pa, qa = -sa, ca
            w = blen * 0.34
            p0 = mf.add_v(ca * 0.08, y_base + 0.15, sa * 0.08)
            p1 = mf.add_v(ca * blen * 0.55 + pa * w, y_base + droop * 0.45, sa * blen * 0.55 + qa * w)
            p2 = mf.add_v(ca * blen, y_base + droop, sa * blen)
            p3 = mf.add_v(ca * blen * 0.55 - pa * w, y_base + droop * 0.45, sa * blen * 0.55 - qa * w)
            pm = mf.add_v(ca * blen * 0.52, y_base + droop * 0.25 + 0.18, sa * blen * 0.52)
            u0, u1, u2, u3, um = mf.add_uv(0.5, 0), mf.add_uv(0, 0.5), mf.add_uv(0.5, 1), mf.add_uv(1, 0.5), mf.add_uv(0.5, 0.5)
            # Top surfaces
            mf.add_tri((p0, u0), (p1, u1), (pm, um))
            mf.add_tri((p1, u1), (p2, u2), (pm, um))
            mf.add_tri((p2, u2), (p3, u3), (pm, um))
            mf.add_tri((p3, u3), (p0, u0), (pm, um))
            # Underside so flashlight looking upward catches needles too
            mf.add_tri((p0, u0), (pm, um), (p1, u1))
            mf.add_tri((p1, u1), (pm, um), (p2, u2))
            mf.add_tri((p2, u2), (pm, um), (p3, u3))
            mf.add_tri((p3, u3), (pm, um), (p0, u0))
    mf.write_obj("pine_foliage", smooth=False)


def _add_cylinder_z(mb: MeshBuilder, cx, cy, z0, z1, r0, r1=None, segs=16):
    if r1 is None:
        r1 = r0
    ring0, ring1 = [], []
    for i in range(segs + 1):
        ang = (i / segs) * math.tau
        ca, sa = math.cos(ang), math.sin(ang)
        if i == segs and ring0:
            v0, v1 = ring0[0][0], ring1[0][0]
        else:
            v0 = mb.add_v(cx + ca * r0, cy + sa * r0, z0)
            v1 = mb.add_v(cx + ca * r1, cy + sa * r1, z1)
        ring0.append((v0, mb.add_uv(i / segs, 0.0)))
        ring1.append((v1, mb.add_uv(i / segs, 1.0)))
    for i in range(segs):
        mb.add_quad(ring0[i], ring0[i + 1], ring1[i + 1], ring1[i])
    c0 = (mb.add_v(cx, cy, z0), mb.add_uv(0.5, 0.5))
    c1 = (mb.add_v(cx, cy, z1), mb.add_uv(0.5, 0.5))
    for i in range(segs):
        mb.add_tri(c0, ring0[i + 1], ring0[i])
        mb.add_tri(c1, ring1[i], ring1[i + 1])


def _add_tube(mb: MeshBuilder, points, radii, segs=14):
    rings = []
    for idx, (pt, rad) in enumerate(zip(points, radii)):
        p = np.array(pt, dtype=np.float64)
        if idx == 0:
            t = np.array(points[1]) - p
        elif idx == len(points) - 1:
            t = p - np.array(points[idx - 1])
        else:
            t = np.array(points[idx + 1]) - np.array(points[idx - 1])
        t = t / max(np.linalg.norm(t), 1e-8)
        up = np.array([0.0, 1.0, 0.0]) if abs(t[1]) < 0.92 else np.array([1.0, 0.0, 0.0])
        right = np.cross(up, t)
        right = right / max(np.linalg.norm(right), 1e-8)
        up2 = np.cross(t, right)
        ring = []
        vc = idx / max(1, len(points) - 1)
        for si in range(segs + 1):
            ang = (si / segs) * math.tau
            if si == segs and ring:
                v = ring[0][0]
            else:
                pos = p + (right * math.cos(ang) + up2 * math.sin(ang)) * rad
                v = mb.add_v(pos[0], pos[1], pos[2])
            ring.append((v, mb.add_uv(si / segs, vc)))
        rings.append(ring)
    for ri in range(len(rings) - 1):
        for si in range(segs):
            mb.add_quad(rings[ri][si], rings[ri][si + 1], rings[ri + 1][si + 1], rings[ri + 1][si])


def gen_zombie_parts():
    """High-detail sculpted anatomical & tactical gear zombie meshes matching ref #4."""
    # 1. Sculpted Zombie Head + Deep Sockets + Exposed Nose + Snarling Jaw + Teeth + Corded Neck
    mh = MeshBuilder()
    rings, segs = 30, 34
    grid = []
    for ri in range(rings + 1):
        v_frac = ri / rings
        if v_frac <= 0.82:
            phi = (v_frac / 0.82) * math.pi
            y = math.cos(phi) * 0.140
            base_r = math.sin(phi)
            is_neck = False
        else:
            nf = (v_frac - 0.82) / 0.18
            y = -0.115 - nf * 0.095
            base_r = 0.48 + nf * 0.16
            is_neck = True
        ring = []
        for si in range(segs + 1):
            th = (si / segs) * math.tau
            if si == segs and ring:
                v = ring[0][0]
            else:
                sx, cz = math.sin(th), math.cos(th)
                if is_neck:
                    cord = math.sin(th * 6.0) * 0.005
                    v = mh.add_v(sx * (base_r * 0.095 + cord), y, cz * (base_r * 0.105 + cord) - 0.015)
                else:
                    rx, rz = base_r * 0.096, base_r * 0.118
                    if y < -0.015:
                        jf = min(1.0, (-y - 0.015) / 0.125)
                        rx *= (1.0 - jf * 0.36)
                        if cz > 0.15:
                            rz *= (1.0 + jf * 0.14)
                        if -0.085 < y < -0.020 and cz > 0.10 and 0.32 < abs(sx) < 0.82:
                            rx -= 0.016 * (1.0 - abs(y + 0.052) / 0.035)
                    if 0.018 < y < 0.056 and cz > 0.42:
                        rz += 0.019 * math.cos((y - 0.036) / 0.020 * math.pi * 0.5) * cz
                    for ex in (-0.34, 0.34):
                        de = math.hypot((sx - ex) / 0.20, (y - 0.006) / 0.024)
                        if cz > 0.50 and de < 1.0:
                            rz -= 0.036 * (math.cos(de * math.pi * 0.5) ** 1.4)
                    if -0.030 < y < 0.024 and cz > 0.72 and abs(sx) < 0.18:
                        if y > -0.008:
                            rz += 0.016 * (1.0 - abs(sx) / 0.18)
                        else:
                            dn = math.hypot(sx / 0.13, (y + 0.018) / 0.014)
                            if dn < 1.0:
                                rz -= 0.024 * math.cos(dn * math.pi * 0.5)
                    if -0.024 < y < 0.010 and cz > 0.25 and 0.50 < abs(sx) < 0.88:
                        rx += 0.016
                        rz += 0.010
                    dm = math.hypot(sx / 0.36, (y + 0.072) / 0.030)
                    if cz > 0.55 and dm < 1.0:
                        rz -= 0.042 * (math.cos(dm * math.pi * 0.5) ** 1.3)
                    elif cz > 0.55 and 1.0 <= dm < 1.38:
                        rz += 0.010 * math.sin((dm - 1.0) / 0.38 * math.pi)
                    if -0.025 < y < 0.030 and abs(cz) < 0.25 and abs(sx) > 0.90:
                        rx += 0.015
                    wrinkle = (math.sin(th * 7.0 + y * 55.0) * 0.0028 + math.cos(th * 13.0 - y * 90.0) * 0.0018)
                    v = mh.add_v(sx * (rx + wrinkle), y, cz * (rz + wrinkle))
            ring.append((v, mh.add_uv(si / segs, v_frac)))
        grid.append(ring)
    for ri in range(rings):
        for si in range(segs):
            mh.add_quad(grid[ri][si], grid[ri + 1][si], grid[ri + 1][si + 1], grid[ri][si + 1])
    for row_y, tilt in ((-0.052, 0.08), (-0.088, -0.10)):
        for ti in range(-3, 4):
            ang = ti * 0.115
            mh.add_box(math.sin(ang) * 0.034, row_y, math.cos(ang) * 0.095, 0.0065, 0.014, 0.007, rx=tilt, ry=ang, uv_scale=4.0)
    mh.write_obj("zombie_head", smooth=True)

    # 2. Curved PASGT/MICH Combat Helmet + Cloth Cover + Contoured Dark Goggles (ref #4!)
    mhel = MeshBuilder()
    h_rings, h_segs = 16, 28
    hgrid = []
    for ri in range(h_rings + 1):
        f = ri / h_rings
        phi = f * (math.pi * 0.56)
        ring = []
        for si in range(h_segs + 1):
            th = (si / h_segs) * math.tau
            if si == h_segs and ring:
                v = ring[0][0]
            else:
                sx, cz = math.sin(th), math.cos(th)
                brow_lift = max(0.0, cz) * 0.026 * (f ** 1.6)
                ear_flare = (abs(sx) ** 2) * 0.016 * (f ** 2.0)
                nape_drop = max(0.0, -cz) * 0.028 * (f ** 1.8)
                rad_x = math.sin(phi) * 0.128 + ear_flare
                rad_z = math.sin(phi) * 0.146 + (0.008 if cz > 0 else 0.005) * (f ** 2)
                fold = math.sin(th * 7.0 + f * 9.0) * 0.0035 * f + math.cos(th * 11.0 - f * 6.0) * 0.0022
                y = 0.025 + math.cos(phi) * 0.132 + brow_lift - nape_drop
                v = mhel.add_v(sx * (rad_x + fold), y, cz * (rad_z + fold) - 0.008)
            ring.append((v, mhel.add_uv(si / h_segs, f)))
        hgrid.append(ring)
    for ri in range(h_rings):
        for si in range(h_segs):
            mhel.add_quad(hgrid[ri][si], hgrid[ri + 1][si], hgrid[ri + 1][si + 1], hgrid[ri][si + 1])
    mhel.write_obj("zombie_helmet", smooth=True)

    # Separate dark rubber Tactical Goggles + wraparound strap (so goggles use dark rubber material, NOT bright cloth!)
    mgog = MeshBuilder()
    for si in range(24):
        am = ((si + 0.5) / 24.0) * math.tau
        sx, cz = math.sin(am), math.cos(am)
        if cz < 0.62:
            mgog.add_box(sx * 0.134, 0.072, cz * 0.150 - 0.008, 0.044, 0.032, 0.014, ry=am, uv_scale=3.0)
    # Rounded oval-like goggle cups via swept ring tubes (no square white box rim!)
    for side in (-1.0, 1.0):
        pts, rads = [], []
        for gi in range(17):
            ga = (gi / 16.0) * math.tau
            gx = side * 0.048 + math.cos(ga) * 0.034
            gy = 0.082 + math.sin(ga) * 0.024
            gz = 0.150 - abs(gx) * 0.18
            pts.append((gx, gy, gz))
            rads.append(0.0105)
        _add_tube(mgog, pts, rads, 10)
    mgog.add_box(0.0, 0.086, 0.156, 0.026, 0.016, 0.018, uv_scale=4.0)
    mgog.write_obj("zombie_goggles", smooth=True)

    # 3. Seamless Tactical Torso + Collar + Plate Carrier + Pouches + Hips
    mtor = MeshBuilder()
    torso_prof = [
        (0.0, -0.10, 0.0), (0.165, -0.04, 0.08), (0.168, 0.06, 0.18),
        (0.185, 0.18, 0.34), (0.228, 0.36, 0.58), (0.252, 0.49, 0.76),
        (0.168, 0.58, 0.88), (0.132, 0.64, 0.96), (0.095, 0.61, 1.0),
    ]
    mtor.add_lathe(torso_prof, segs=22, noise_amp=0.055, seed=405)
    mtor.verts = [(x * 1.15, y, z * 0.74) for (x, y, z) in mtor.verts]
    mtor.add_box(0.0, 0.32, 0.172, 0.30, 0.36, 0.058, rx=0.05, uv_scale=2.2)
    mtor.add_box(0.0, 0.33, -0.168, 0.30, 0.36, 0.058, rx=-0.05, uv_scale=2.2)
    for my in (0.20, 0.27, 0.34, 0.41):
        mtor.add_box(0.0, my, 0.202, 0.28, 0.022, 0.016, uv_scale=3.0)
    for px in (-0.095, 0.0, 0.095):
        mtor.add_box(px, 0.18, 0.212, 0.072, 0.135, 0.052, uv_scale=3.0)
    mtor.add_box(-0.11, 0.40, 0.205, 0.068, 0.105, 0.048, uv_scale=3.0)
    for sx in (-1.0, 1.0):
        mtor.add_box(sx * 0.155, 0.51, 0.0, 0.11, 0.09, 0.28, rz=-sx * 0.22, uv_scale=2.5)
        mtor.add_box(sx * 0.245, 0.45, 0.01, 0.13, 0.15, 0.15, rz=-sx * 0.35, uv_scale=2.5)
    mtor.add_box(0.0, 0.06, 0.0, 0.40, 0.065, 0.29, uv_scale=2.5)
    mtor.write_obj("zombie_torso", smooth=True)

    # 4. Wrinkled Limb + Clawed Hand + Combat Boot
    ml = MeshBuilder()
    ml.add_lathe([
        (0.0, -0.04, 0.0), (0.052, -0.02, 0.05), (0.074, 0.04, 0.14),
        (0.068, 0.14, 0.32), (0.074, 0.22, 0.48), (0.058, 0.32, 0.72),
        (0.062, 0.40, 0.90), (0.042, 0.44, 0.97), (0.0, 0.45, 1.0),
    ], segs=14, noise_amp=0.08, seed=406)
    ml.write_obj("zombie_limb", smooth=True)

    mhd = MeshBuilder()
    mhd.add_box(0.0, -0.045, 0.0, 0.068, 0.09, 0.032, uv_scale=4.0)
    for fi, fx in enumerate((-0.026, -0.009, 0.009, 0.026)):
        mhd.add_box(fx, -0.105, 0.012, 0.014, 0.058, 0.016, rx=-0.38 - fi * 0.04, uv_scale=4.0)
        mhd.add_box(fx, -0.142, 0.032, 0.011, 0.042, 0.013, rx=-0.78, uv_scale=4.0)
    mhd.write_obj("zombie_hand", smooth=True)

    mbt = MeshBuilder()
    mbt.add_box(0.0, -0.06, 0.0, 0.095, 0.14, 0.11, uv_scale=3.0)
    mbt.add_box(0.0, -0.125, 0.065, 0.102, 0.075, 0.22, uv_scale=3.0)
    mbt.add_box(0.0, -0.168, 0.062, 0.108, 0.024, 0.23, uv_scale=3.0)
    mbt.write_obj("zombie_boot", smooth=False)


def gen_weapons():
    """Sculpted detailed first-person tactical weapons + organic gloved hands/sleeves."""
    mp = MeshBuilder()
    mp.add_box(0.0, 0.030, -0.055, 0.026, 0.024, 0.190, uv_scale=4.0)
    mp.add_box(0.0, 0.043, -0.055, 0.020, 0.005, 0.188, uv_scale=4.0)
    for sz in (0.020, 0.012, 0.004, -0.004, -0.105, -0.113, -0.121):
        mp.add_box(0.0, 0.030, sz, 0.0275, 0.018, 0.0035)
    mp.add_box(0.0, 0.010, -0.052, 0.024, 0.018, 0.182, uv_scale=4.0)
    mp.add_box(0.0, -0.017, -0.018, 0.014, 0.0045, 0.052)
    mp.add_box(0.0, -0.006, -0.042, 0.014, 0.024, 0.005)
    mp.add_box(0.0, -0.048, 0.020, 0.025, 0.102, 0.042, rx=0.28, uv_scale=4.0)
    _add_cylinder_z(mp, 0.0, 0.031, -0.165, -0.145, 0.0075, 0.0075, 14)
    _add_cylinder_z(mp, 0.0, -0.014, -0.168, -0.088, 0.0135, 0.0125, 16)
    _add_cylinder_z(mp, 0.0, -0.014, -0.175, -0.165, 0.0150, 0.0140, 16)
    mp.add_box(-0.0075, 0.049, 0.032, 0.005, 0.0085, 0.010)
    mp.add_box(0.0075, 0.049, 0.032, 0.005, 0.0085, 0.010)
    mp.add_box(0.0, 0.049, -0.142, 0.0038, 0.0085, 0.009)
    mp.write_obj("weapon_pistol", smooth=True)

    mr = MeshBuilder()
    mr.add_box(0.0, 0.024, -0.055, 0.038, 0.058, 0.21, uv_scale=3.0)
    mr.add_box(0.0, 0.054, -0.055, 0.028, 0.010, 0.20, uv_scale=3.0)
    for ri in range(16):
        mr.add_box(0.0, 0.061, 0.03 - ri * 0.025, 0.020, 0.006, 0.011)
    _add_cylinder_z(mr, 0.0, 0.028, -0.39, -0.15, 0.024, 0.024, 8)
    _add_cylinder_z(mr, 0.0, 0.028, -0.59, -0.38, 0.017, 0.016, 16)
    _add_cylinder_z(mr, 0.034, 0.024, -0.41, -0.29, 0.012, 0.011, 14)
    mr.add_box(0.0, -0.052, -0.088, 0.023, 0.095, 0.056, rx=-0.10, uv_scale=3.0)
    mr.add_box(0.0, -0.125, -0.106, 0.023, 0.085, 0.054, rx=-0.28, uv_scale=3.0)
    mr.add_box(0.0, -0.052, 0.032, 0.028, 0.100, 0.040, rx=0.30, uv_scale=3.0)
    _add_tube(mr, [(0.0, 0.005, -0.29), (0.0, -0.088, -0.295)], [0.013, 0.014], 12)
    _add_cylinder_z(mr, 0.0, 0.030, 0.05, 0.22, 0.016, 0.016, 14)
    mr.add_box(0.0, 0.006, 0.21, 0.036, 0.115, 0.068, uv_scale=3.0)
    # Sleek rounded EOTech EXPS3 Holographic Sight Hood (clean beveled arch like ref #15 — NO giant oval blob!)
    mr.add_box(0.0, 0.068, -0.072, 0.036, 0.016, 0.074, uv_scale=4.0)
    mr.add_box(0.0, 0.075, -0.104, 0.032, 0.022, 0.024, uv_scale=4.0)  # front battery cap
    mr.add_box(0.022, 0.074, -0.075, 0.008, 0.012, 0.018, uv_scale=4.0)  # windage knob
    # Arched slim hood via swept tube around the optic window!
    _add_tube(mr, [
        (-0.020, 0.076, -0.068),
        (-0.021, 0.106, -0.068),
        (-0.015, 0.120, -0.068),
        (0.0, 0.124, -0.068),
        (0.015, 0.120, -0.068),
        (0.021, 0.106, -0.068),
        (0.020, 0.076, -0.068),
    ], [0.0042, 0.0042, 0.0042, 0.0045, 0.0042, 0.0042, 0.0042], 10)
    # Inner slim optic lens frame
    mr.add_box(-0.017, 0.098, -0.068, 0.003, 0.038, 0.024)
    mr.add_box(0.017, 0.098, -0.068, 0.003, 0.038, 0.024)
    mr.add_box(0.0, 0.118, -0.068, 0.034, 0.003, 0.024)
    # Charging handle latch & forward assist
    mr.add_box(0.0, 0.056, 0.048, 0.044, 0.009, 0.014)
    _add_cylinder_z(mr, 0.024, 0.040, 0.005, 0.032, 0.006, 0.007, 10)
    mr.write_obj("weapon_rifle", smooth=True)

    ms = MeshBuilder()
    ms.add_box(0.0, 0.022, -0.04, 0.038, 0.056, 0.20, uv_scale=3.0)
    _add_cylinder_z(ms, 0.0, 0.038, -0.56, -0.12, 0.012, 0.012, 14)
    _add_cylinder_z(ms, 0.0, 0.012, -0.52, -0.12, 0.012, 0.012, 14)
    _add_cylinder_z(ms, 0.0, 0.010, -0.39, -0.21, 0.021, 0.021, 14)
    ms.add_box(0.0, -0.020, 0.15, 0.036, 0.082, 0.21, rx=-0.18, uv_scale=3.0)
    _add_cylinder_z(ms, 0.028, 0.014, -0.48, -0.38, 0.011, 0.011, 12)
    ms.write_obj("weapon_shotgun", smooth=True)

    # Compact, tucked gloved hands wrapping cleanly around grip/handguard (matching Bodycam ref #16 & #15!)
    mhp = MeshBuilder()
    _add_tube(mhp, [(0.075, -0.16, 0.22), (0.032, -0.082, 0.09), (0.016, -0.046, 0.022)], [0.038, 0.029, 0.024], 14)
    _add_tube(mhp, [(-0.075, -0.16, 0.20), (-0.030, -0.078, 0.075), (-0.016, -0.042, 0.010)], [0.038, 0.028, 0.024], 14)
    for fi in range(3):
        fy = -0.030 - fi * 0.016
        _add_tube(mhp, [(-0.017, fy, 0.005), (0.0, fy - 0.002, -0.010), (0.017, fy, 0.005)], [0.0085, 0.009, 0.0085], 10)
    mhp.write_obj("fp_hands_pistol", smooth=True)

    mhr = MeshBuilder()
    _add_tube(mhr, [(0.085, -0.16, 0.22), (0.032, -0.078, 0.085), (0.016, -0.048, 0.028)], [0.038, 0.029, 0.024], 14)
    _add_tube(mhr, [(-0.095, -0.15, 0.04), (-0.052, -0.075, -0.14), (-0.022, -0.030, -0.26), (-0.008, -0.008, -0.29)], [0.038, 0.032, 0.026, 0.022], 14)
    mhr.write_obj("fp_hands_rifle", smooth=True)


if __name__ == "__main__":
    print("Generating sculpted 3D meshes...")
    gen_vaulted_tunnel_bay()
    gen_rubble_mound()
    gen_oak_barrel()
    gen_vintage_lamp()
    gen_reception_desk()
    gen_baluster()
    gen_pine_tree()
    gen_zombie_parts()
    gen_weapons()
    print("All 3D meshes generated!")
