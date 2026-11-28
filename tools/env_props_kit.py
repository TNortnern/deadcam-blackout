"""Shared toolkit for tools/build_env_props.py (Blender 5.3, headless).

Pipeline per prop
  1. Parts are modelled with bmesh primitives in GAME coordinates (metres, +Y up, +Z front).
  2. All parts are merged into one work mesh, smart-unwrapped into one 1024px atlas per material.
  3. Cycles bakes DATA maps only (surface id / part id, world position, object normal, wide AO,
     tight cavity AO, bevel-edge convexity).
  4. numpy composites albedo / roughness / metallic / height per texel from those maps: tiling
     source photos are sampled tri-planar in world or part-local space, and wear (chips on convex
     edges, rust in crevices, drip streaks flowing down from crevices, dust on up-facing faces)
     is computed in 3D so it follows the geometry and never shows UV seams.
  5. The mesh is split into the named nodes, rotated to Blender Z-up and exported as GLB.
"""
import bpy
import bmesh
import math
import os
import time
import hashlib
import numpy as np
from mathutils import Vector, Matrix

SCRATCH = r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache\polish\env_props"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEX_DIRS = [os.path.join(SCRATCH, "src", "tile"), os.path.join(SCRATCH, "src", "decal"),
            os.path.join(REPO, "assets", "textures")]
RES = 1024
PI = math.pi

# ----------------------------------------------------------------------------- surface ids
IRON, PAINT, ENAMEL, BRASS, STEEL, BRICK, WOOD, PLASTER, GLASS, BOTTLE, CANVAS, LEATHER, RUBBER, \
    COAL, DECAL, GALV, RUBBLE, SOOT, LAMP = range(1, 20)


# ----------------------------------------------------------------------------- small math helpers
def V(*a):
    return Vector(a)


def T(x, y, z):
    return Matrix.Translation((x, y, z))


def R(axis, deg):
    return Matrix.Rotation(math.radians(deg), 4, axis)


def orient(pos, normal, spin=0.0):
    """Matrix taking local +Y to `normal`, located at `pos` (right handed)."""
    n = Vector(normal).normalized()
    a = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))
    x = a.cross(n).normalized()
    z = x.cross(n).normalized()
    m = Matrix(((x.x, n.x, z.x, pos[0]), (x.y, n.y, z.y, pos[1]), (x.z, n.z, z.z, pos[2]), (0, 0, 0, 1)))
    if spin:
        m = m @ Matrix.Rotation(spin, 4, 'Y')
    return m


def rr_points(w, d, r, n):
    """Rounded rectangle outline in the XZ plane, 4*(n+1) points, angle from +X toward +Z."""
    r = max(min(r, w / 2 - 1e-5, d / 2 - 1e-5), 1e-5)
    pts = []
    for k, (sx, sz) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        cx, cz = sx * (w / 2 - r), sz * (d / 2 - r)
        for i in range(n + 1):
            a = (k + i / n) * PI / 2
            pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts


def round_path(pts, radius, n=4):
    """Replace the interior corners of a polyline with small arcs."""
    pts = [Vector(p) for p in pts]
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = pts[i - 1], pts[i], pts[i + 1]
        u1, u2 = (a - b), (c - b)
        d = min(radius, u1.length * 0.49, u2.length * 0.49)
        p0, p1 = b + u1.normalized() * d, b + u2.normalized() * d
        for k in range(n + 1):
            t = k / n
            out.append(p0 * (1 - t) ** 2 + b * 2 * t * (1 - t) + p1 * t * t)
    out.append(pts[-1])
    return out


def arc_pts(c, r, a0, a1, n, plane='xy'):
    out = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        if plane == 'xy':
            out.append(Vector((c[0] + r * math.cos(a), c[1] + r * math.sin(a), c[2])))
        elif plane == 'zy':
            out.append(Vector((c[0], c[1] + r * math.sin(a), c[2] + r * math.cos(a))))
        else:
            out.append(Vector((c[0] + r * math.cos(a), c[1], c[2] + r * math.sin(a))))
    return out


# ----------------------------------------------------------------------------- parts
class Part:
    """One logical piece: a bmesh plus the surface recipe id / atlas / node it belongs to."""

    def __init__(self, prop, surf, atlas=0, node=None, sharp=40.0, mirror=False, uvscale=1.0, **params):
        self.prop, self.surf, self.atlas, self.node = prop, surf, atlas, node
        self.sharp, self.mirror, self.uvscale, self.params = sharp, mirror, uvscale, params
        self.bm = bmesh.new()
        self.aux = self.bm.verts.layers.float.new("aux")
        self.frame = Matrix.Identity(4)
        self.index = len(prop.parts)
        prop.parts.append(self)

    # -- internals
    def _done(self, verts, m, aux):
        if m is not None:
            for v in verts:
                v.co = m @ v.co
        if aux:
            for v in verts:
                v[self.aux] = aux
        return verts

    def _absorb(self, tb, m=None, aux=0.0):
        tb.verts.index_update()
        vm = [self.bm.verts.new(v.co) for v in tb.verts]
        for f in tb.faces:
            try:
                self.bm.faces.new([vm[v.index] for v in f.verts])
            except ValueError:
                pass
        tb.free()
        return self._done(vm, m, aux)

    # -- primitives
    def lathe(self, prof, segs=16, m=None, arc=None, aux=0.0):
        """Revolve (r, h) profile about local +Y. Outward = right-hand side of profile travel."""
        bm = self.bm
        closed = arc is None
        a0, a1 = (0.0, 2 * PI) if closed else (math.radians(arc[0]), math.radians(arc[1]))
        n = segs if closed else segs + 1
        angs = [a0 + (a1 - a0) * j / segs for j in range(n)]
        rings, new = [], []
        for r, h in prof:
            if r < 1e-7:
                ring = [bm.verts.new((0.0, h, 0.0))]
            else:
                ring = [bm.verts.new((r * math.cos(a), h, r * math.sin(a))) for a in angs]
            rings.append(ring)
            new += ring
        for i in range(len(prof) - 1):
            A, B = rings[i], rings[i + 1]
            for j in range(segs):
                j2 = (j + 1) % n if closed else j + 1
                if len(A) == 1 and len(B) == 1:
                    continue
                if len(A) == 1:
                    bm.faces.new([A[0], B[j], B[j2]])
                elif len(B) == 1:
                    bm.faces.new([A[j], B[0], A[j2]])
                else:
                    bm.faces.new([A[j], B[j], B[j2], A[j2]])
        return self._done(new, m, aux)

    def rrloft(self, w, d, r, prof, n=3, m=None, caps=(True, True), aux=0.0):
        """Stack of rounded rectangles (XZ plane). prof = [(inset, y)] bottom to top."""
        bm = self.bm
        rings, new = [], []
        for ent in prof:
            ins, y = ent[0], ent[1]
            pts = rr_points(w - 2 * ins, d - 2 * ins, ent[2] if len(ent) > 2 else max(r - ins, 0.0015), n)
            ring = [bm.verts.new((x, y, z)) for x, z in pts]
            rings.append(ring)
            new += ring
        cnt = len(rings[0])
        for i in range(len(rings) - 1):
            A, B = rings[i], rings[i + 1]
            for j in range(cnt):
                j2 = (j + 1) % cnt
                bm.faces.new([A[j], B[j], B[j2], A[j2]])
        if caps[0]:
            bm.faces.new(rings[0])
        if caps[1]:
            bm.faces.new(list(reversed(rings[-1])))
        return self._done(new, m, aux)

    def box(self, sx, sy, sz, m=None, bevel=0.0, segs=1, aux=0.0):
        tb = bmesh.new()
        bmesh.ops.create_cube(tb, size=1.0, matrix=Matrix.Diagonal((sx, sy, sz, 1.0)))
        if bevel > 0:
            bmesh.ops.bevel(tb, geom=list(tb.edges), offset=min(bevel, min(sx, sy, sz) * 0.45), segments=segs,
                            profile=0.5, affect='EDGES', clamp_overlap=True)
        return self._absorb(tb, m, aux)

    def extrude(self, poly, depth, m=None, bevel=0.0, segs=1, aux=0.0):
        """CCW (x, y) polygon extruded along Z, centred on z=0."""
        area = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))
        if area < 0:
            poly = list(reversed(poly))
        tb = bmesh.new()
        f = [tb.verts.new((x, y, depth / 2)) for x, y in poly]
        b = [tb.verts.new((x, y, -depth / 2)) for x, y in poly]
        n = len(poly)
        tb.faces.new(f)
        tb.faces.new(list(reversed(b)))
        for i in range(n):
            j = (i + 1) % n
            tb.faces.new([f[i], b[i], b[j], f[j]])
        if bevel > 0:
            bmesh.ops.bevel(tb, geom=list(tb.edges), offset=bevel, segments=segs, profile=0.5, affect='EDGES',
                            clamp_overlap=True)
        return self._absorb(tb, m, aux)

    def sweep(self, path, section, closed=False, up=None, ups=None, caps=True, m=None, scales=None, aux=0.0):
        """Sweep a CCW (a, b) section along a path. a runs along the frame 'up', b along tangent x up."""
        bm = self.bm
        P = [Vector(p) for p in path]
        n = len(P)
        tans = []
        for i in range(n):
            if closed:
                t = P[(i + 1) % n] - P[i - 1]
            else:
                t = P[min(i + 1, n - 1)] - P[max(i - 1, 0)]
            tans.append(t.normalized())
        U = []
        if ups is not None:
            for i in range(n):
                u = Vector(ups[i]) if not isinstance(ups, Vector) else ups
                u = u - tans[i] * u.dot(tans[i])
                U.append(u.normalized())
        else:
            u = Vector(up) if up is not None else Vector((0, 1, 0))
            if abs(u.normalized().dot(tans[0])) > 0.95:
                u = Vector((1, 0, 0)) if abs(tans[0].x) < 0.9 else Vector((0, 0, 1))
            for i in range(n):
                u = u - tans[i] * u.dot(tans[i])
                u = u.normalized()
                U.append(u.copy())
        rings, new = [], []
        for i in range(n):
            w = tans[i].cross(U[i])
            s = scales[i] if scales is not None else 1.0
            ring = [bm.verts.new(P[i] + U[i] * (a * s) + w * (b * s)) for a, b in section]
            rings.append(ring)
            new += ring
        k = len(section)
        for i in range(n if closed else n - 1):
            A, B = rings[i], rings[(i + 1) % n]
            for j in range(k):
                j2 = (j + 1) % k
                bm.faces.new([A[j], A[j2], B[j2], B[j]])
        if caps and not closed and k > 2:
            bm.faces.new(list(reversed(rings[0])))
            bm.faces.new(rings[-1])
        return self._done(new, m, aux)

    def tube(self, path, r, segs=8, **kw):
        sec = [(r * math.cos(2 * PI * j / segs), r * math.sin(2 * PI * j / segs)) for j in range(segs)]
        return self.sweep(path, sec, **kw)

    def strap(self, path, width, thick, **kw):
        t, w = thick / 2, width / 2
        return self.sweep(path, [(-t, -w), (t, -w), (t, w), (-t, w)], **kw)

    def grid(self, nu, nv, fn, m=None, aux=0.0):
        """fn(u, v) -> (x, y, z) for u, v in 0..1. Normal = dP/dv x dP/du."""
        bm = self.bm
        vs = [[bm.verts.new(fn(i / nu, j / nv)) for j in range(nv + 1)] for i in range(nu + 1)]
        for i in range(nu):
            for j in range(nv):
                bm.faces.new([vs[i][j], vs[i][j + 1], vs[i + 1][j + 1], vs[i + 1][j]])
        return self._done([v for row in vs for v in row], m, aux)

    def rivet(self, pos, normal, r=0.02, h=None, segs=5, sink=0.003):
        h = h if h is not None else r * 0.62
        return self.lathe([(r, -sink), (r * 0.76, h * 0.6), (0, h)], segs=segs, m=orient(pos, normal))

    def hexbolt(self, pos, normal, r=0.018, h=0.012, spin=0.0, washer=True):
        m = orient(pos, normal, spin)
        if washer:
            self.lathe([(r * 1.55, -0.002), (r * 1.55, h * 0.22), (r * 1.0, h * 0.22)], segs=10, m=m)
        return self.lathe([(r, 0), (r, h * 0.82), (r * 0.82, h), (0, h)], segs=6, m=m)

    def ring(self, c, normal, R_, r, segs=14, tsegs=6):
        """Torus around `normal` at centre c."""
        prof = [(R_ + r * math.cos(2 * PI * k / tsegs), r * math.sin(2 * PI * k / tsegs)) for k in range(tsegs + 1)]
        return self.lathe(prof, segs=segs, m=orient(c, normal))

    # -- transforms
    def xf(self, m):
        self.bm.transform(m)
        self.frame = m @ self.frame
        return self

    def verts(self):
        return list(self.bm.verts)


# ----------------------------------------------------------------------------- numpy helpers
def ss(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def mix(a, b, t):
    if isinstance(t, np.ndarray) and t.ndim == 1 and (getattr(a, "ndim", 1) == 2 or getattr(b, "ndim", 1) == 2):
        t = t[:, None]
    return a + (b - a) * t


def C(r, g, b):
    return np.array([r, g, b], np.float32)


def lum(c):
    return c[:, 0] * 0.3 + c[:, 1] * 0.59 + c[:, 2] * 0.11


def _hash(ix, iy, iz, seed):
    h = (ix & 0xFFFFFFFF).astype(np.uint32) * np.uint32(374761393)
    h ^= (iy & 0xFFFFFFFF).astype(np.uint32) * np.uint32(668265263)
    h ^= (iz & 0xFFFFFFFF).astype(np.uint32) * np.uint32(1440662683)
    h ^= np.uint32((seed * 2654435761) & 0xFFFFFFFF)
    h ^= h >> np.uint32(13)
    h *= np.uint32(1274126177)
    h ^= h >> np.uint32(16)
    return (h & np.uint32(0xFFFFFF)).astype(np.float32) * np.float32(1.0 / 16777215.0)


_LATTICE = {}


def vnoise(P, seed=0):
    """Tri-linear value noise on a wrapping 32^3 random lattice."""
    L = _LATTICE.get(seed)
    if L is None:
        L = _LATTICE[seed] = np.random.RandomState(seed * 7919 + 13).rand(32 * 32 * 32).astype(np.float32)
    F = np.floor(P)
    f = (P - F).astype(np.float32)
    f = f * f * (3 - 2 * f)
    I = F.astype(np.int64)
    x0, y0, z0 = I[:, 0] & 31, I[:, 1] & 31, I[:, 2] & 31
    x1, y1, z1 = (x0 + 1) & 31, (y0 + 1) & 31, (z0 + 1) & 31
    fx, fy, fz = f[:, 0], f[:, 1], f[:, 2]
    a0, a1 = (x0 << 10), (x1 << 10)
    b0, b1 = (y0 << 5), (y1 << 5)
    c00 = L[a0 + b0 + z0] * (1 - fx) + L[a1 + b0 + z0] * fx
    c10 = L[a0 + b1 + z0] * (1 - fx) + L[a1 + b1 + z0] * fx
    c01 = L[a0 + b0 + z1] * (1 - fx) + L[a1 + b0 + z1] * fx
    c11 = L[a0 + b1 + z1] * (1 - fx) + L[a1 + b1 + z1] * fx
    return (c00 * (1 - fy) + c10 * fy) * (1 - fz) + (c01 * (1 - fy) + c11 * fy) * fz


def fbm(P, octaves=4, seed=0, gain=0.5):
    out, amp, tot = 0.0, 1.0, 0.0
    Q = np.asarray(P, np.float64)
    for o in range(octaves):
        out = out + vnoise(Q, seed + o * 17) * amp
        tot += amp
        amp *= gain
        Q = Q * 2.03 + 11.7
    return (out / tot).astype(np.float32)


def flow(coords, src, voxel, decay_len, axis=1, seed=3):
    """Smear `src` downward (toward decreasing coords[axis]) through a voxel grid. Returns per-point value."""
    lo = coords.min(0)
    c = np.floor((coords - lo) / voxel).astype(np.int32)
    dims = c.max(0) + 1
    G = np.zeros(dims, np.float32)
    np.maximum.at(G, (c[:, 0], c[:, 1], c[:, 2]), src.astype(np.float32))
    G = np.moveaxis(G, axis, 0)
    decay = math.exp(-voxel / decay_len)
    ii, jj = np.meshgrid(np.arange(G.shape[1]), np.arange(G.shape[2]), indexing='ij')
    jit = 0.86 + 0.14 * _hash(ii.ravel(), jj.ravel(), np.zeros(ii.size, np.int64), seed).reshape(ii.shape)
    for k in range(G.shape[0] - 2, -1, -1):
        np.maximum(G[k], G[k + 1] * decay * jit, out=G[k])
    G = np.moveaxis(G, 0, axis)
    return G[c[:, 0], c[:, 1], c[:, 2]]


class Tex:
    _cache = {}

    @classmethod
    def get(cls, name):
        if name not in cls._cache:
            cls._cache[name] = Tex(name)
        return cls._cache[name]

    def __init__(self, name):
        path = None
        for d in TEX_DIRS:
            for ext in (".jpg", ".png"):
                p = os.path.join(d, name + ext)
                if os.path.isfile(p):
                    path = p
                    break
            if path:
                break
        if path is None:
            raise FileNotFoundError("texture source missing: " + name + " (run tools/gen_env_prop_sources.py)")
        im = bpy.data.images.load(path, check_existing=False)
        w, h = im.size
        a = np.empty(w * h * 4, np.float32)
        im.pixels.foreach_get(a)
        bpy.data.images.remove(im)
        a = a.reshape(h, w, 4)[..., :3].copy()
        self.w, self.h = w, h
        self.mips = [a]
        while min(self.mips[-1].shape[:2]) > 16 and self.mips[-1].shape[0] % 2 == 0 and self.mips[-1].shape[1] % 2 == 0:
            b = self.mips[-1]
            self.mips.append((b[0::2, 0::2] + b[1::2, 0::2] + b[0::2, 1::2] + b[1::2, 1::2]) * 0.25)
        self.mean = a.mean((0, 1))
        self.lmean = float(self.mean[0] * 0.3 + self.mean[1] * 0.59 + self.mean[2] * 0.11)

    def sample(self, u, v, lvl=0, clamp=False):
        a = self.mips[int(min(max(lvl, 0), len(self.mips) - 1))]
        h, w = a.shape[:2]
        x = np.asarray(u, np.float64) * w - 0.5
        y = np.asarray(v, np.float64) * h - 0.5
        x0 = np.floor(x)
        y0 = np.floor(y)
        fx = (x - x0).astype(np.float32)[:, None]
        fy = (y - y0).astype(np.float32)[:, None]
        x0 = x0.astype(np.int64)
        y0 = y0.astype(np.int64)
        if clamp:
            xa, xb = np.clip(x0, 0, w - 1), np.clip(x0 + 1, 0, w - 1)
            ya, yb = np.clip(y0, 0, h - 1), np.clip(y0 + 1, 0, h - 1)
        else:
            xa, xb, ya, yb = x0 % w, (x0 + 1) % w, y0 % h, (y0 + 1) % h
        return (a[ya, xa] * (1 - fx) + a[ya, xb] * fx) * (1 - fy) + (a[yb, xa] * (1 - fx) + a[yb, xb] * fx) * fy


class Tx:
    """Per-texel working set (1D arrays over the covered texels of one atlas, or a subset)."""
    FIELDS = ("P", "N", "ao", "cav", "edge", "conv", "surf", "part", "aux", "gnd", "up")

    def __init__(self, prop, ppm, **arr):
        self.prop, self.ppm = prop, ppm
        for k in self.FIELDS:
            setattr(self, k, arr[k])
        self.F = arr.get("F", {})
        self._loc = None

    def sub(self, mask):
        arr = {k: getattr(self, k)[mask] for k in self.FIELDS}
        arr["F"] = {k: (v[mask] if isinstance(v, np.ndarray) else v) for k, v in self.F.items()}
        return Tx(self.prop, self.ppm, **arr)

    def f(self, name):
        return self.F.get(name, 0.0)

    def fbm(self, freq, octaves=4, seed=0, stretch=None, P=None):
        Q = (self.P if P is None else P) * freq
        if stretch is not None:
            Q = Q * np.asarray(stretch, np.float64)
        return fbm(Q, octaves, seed + self.prop.seed)

    def pp(self, key, default):
        tab = np.array([p.params.get(key, default) for p in self.prop.parts], np.float32)
        return tab[self.part]

    def phash(self, seed=0):
        z = np.zeros(len(self.part), np.int64)
        return _hash(self.part.astype(np.int64), z, z, seed + 77)

    def local(self):
        if self._loc is None:
            inv = np.array([np.array(p.frame.inverted()) for p in self.prop.parts], np.float64)
            Mi = inv[self.part]
            L = np.einsum('nij,nj->ni', Mi[:, :3, :3], self.P) + Mi[:, :3, 3]
            LN = np.einsum('nij,nj->ni', Mi[:, :3, :3], self.N)
            self._loc = (L, LN.astype(np.float32))
        return self._loc

    def _lvl(self, tex, size):
        return int(round(math.log2(max((tex.w / size) / self.ppm, 1.0))))

    def tri(self, name, size, P=None, N=None, sharp=4.0, off=None):
        """Tri-planar sample; `size` = metres covered by one tile."""
        tex = Tex.get(name)
        P = self.P if P is None else P
        N = self.N if N is None else N
        if off is not None:
            P = P + off
        w = np.abs(N) ** sharp + 1e-6
        w = w / w.sum(1, keepdims=True)
        lv = self._lvl(tex, size)
        s = 1.0 / size
        cx = tex.sample(P[:, 2] * s, P[:, 1] * s, lv)
        cy = tex.sample(P[:, 0] * s, P[:, 2] * s, lv)
        cz = tex.sample(P[:, 0] * s, P[:, 1] * s, lv)
        return cx * w[:, 0:1] + cy * w[:, 1:2] + cz * w[:, 2:3]

    def grain(self, name, size, off=None):
        """Part-local sample with texture U along the part's local X (wood grain, straps, ticking)."""
        tex = Tex.get(name)
        L, LN = self.local()
        if off is not None:
            L = L + off
        a = np.abs(LN)
        lv = self._lvl(tex, size)
        s = 1.0 / size
        cy = tex.sample(L[:, 0] * s, L[:, 2] * s, lv)          # faces whose normal is local Y
        cz = tex.sample(L[:, 0] * s, L[:, 1] * s, lv)          # faces whose normal is local Z
        cx = tex.sample(L[:, 2] * s * 2.2, L[:, 1] * s * 2.2, lv)  # end grain
        w = a ** 6 + 1e-6
        w = w / w.sum(1, keepdims=True)
        return cx * w[:, 0:1] + cy * w[:, 1:2] + cz * w[:, 2:3]


# ----------------------------------------------------------------------------- surface recipes
# Each returns (albedo sRGB (n,3), roughness, metallic, height in metres).
GRIME = C(0.36, 0.31, 0.25)
SOOTC = C(0.035, 0.033, 0.032)
DUSTC = C(0.62, 0.59, 0.53)


def _rustcol(t):
    a = t.tri("rust_heavy", 0.75)
    b = t.tri("rust_light", 0.6)
    n = t.fbm(5.0, 3, 31)
    c = mix(a * 0.80, b * 0.72, ss(0.35, 0.7, n))
    return c * (0.62 + 0.5 * t.fbm(2.1, 2, 32)[:, None])


def _common(t, alb, rough, metal, h, dust=1.0):
    """Soot, lime scale, dust and contact dirt shared by every recipe."""
    soot = np.clip(t.f("soot") + 0.0, 0, 1)
    if isinstance(soot, np.ndarray):
        alb = mix(alb, SOOTC * (0.8 + 0.5 * t.fbm(30, 2, 41)[:, None]), soot * 0.93)
        rough = mix(rough, 0.96, soot)
        metal = metal * (1 - soot)
    lime = t.f("lime")
    if isinstance(lime, np.ndarray):
        lime = np.clip(lime, 0, 1)
        alb = mix(alb, C(0.78, 0.77, 0.70) * (0.8 + 0.3 * t.fbm(60, 2, 42)[:, None]), lime * 0.85)
        rough = mix(rough, 0.9, lime)
        metal = metal * (1 - lime)
        h = h + lime * 0.0004
    d = t.up * (0.35 + 0.65 * t.fbm(6.0, 3, 43)) * t.prop.dust * dust + t.f("dust")
    d = np.clip(d, 0, 1) * 0.8
    dc = t.prop.dust_col * (0.85 + 0.3 * t.fbm(90, 2, 44)[:, None])
    alb = mix(alb, dc, d)
    rough = mix(rough, 0.95, d)
    metal = metal * (1 - d)
    return np.clip(alb, 0, 1), np.clip(rough, 0.04, 1), np.clip(metal, 0, 1), h


def r_paint(t):
    colr = t.pp("col", [0.80, 0.78, 0.70])
    wear, rustp, gloss = t.pp("wear", 1.0), t.pp("rust", 1.0), t.pp("gloss", 0.42)
    nlo, nmid, nhi = t.fbm(1.4, 3, 11), t.fbm(8.0, 4, 12), t.fbm(44.0, 3, 13)
    ptex = t.tri("paint_cream", 1.1) / Tex.get("paint_cream").mean
    paint = colr * ptex * (0.90 + 0.2 * nlo[:, None])
    grime = np.clip(t.ao * 0.9 + t.cav * 0.9 + t.f("dirt") + t.gnd * 0.5, 0, 1.3) * (0.3 + 1.0 * nmid)
    grime = np.clip(grime, 0, 1)
    paint = mix(paint, paint * GRIME, grime * 0.82)
    big = ss(0.56, 0.80, t.fbm(3.1, 3, 14))
    chipd = t.conv * 1.25 * wear + (nhi - 0.5) * 0.7 + (nmid - 0.5) * 0.9 + t.f("chip") + 0.45 * wear * big
    chip = ss(0.60, 0.67, chipd)
    streak = t.f("streak")
    rd = chipd * 0.55 + (t.cav * 0.85 + t.f("rust") + (nlo - 0.5) * 0.7 + t.gnd * 0.4 + streak * 0.45) * rustp
    rust = ss(0.56, 0.80, rd + (nhi - 0.5) * 0.4)
    wash = np.clip(ss(0.22, 0.62, rd + (nmid - 0.5) * 0.5) * 0.55 + streak * 0.8 * rustp, 0, 0.9)
    rc = _rustcol(t)
    alb = mix(paint, paint * C(0.74, 0.45, 0.24) * 0.9 + rc * 0.12, wash)
    alb = mix(alb, rc, rust)
    bare = chip * (1 - rust)
    primer = mix(t.tri("steel_worn", 0.5) * 0.40, rc * 0.50, ss(0.3, 0.6, nmid) * 0.5 + 0.35)   # old chips are oxidised
    alb = mix(alb, primer, bare)
    rough = mix(gloss + grime * 0.4 + wash * 0.25, 0.9, rust)
    rough = mix(rough, 0.62, bare)
    metal = bare * 0.35
    h = (1 - np.maximum(chip, rust)) * 0.00045 + rust * (lum(rc) - 0.3) * 0.0022 + (lum(ptex) - 1.0) * 0.0004
    return _common(t, alb, rough, metal, h)


def r_iron(t):
    tint = t.pp("col", [1.0, 1.0, 1.0])
    rustp = t.pp("rust", 1.0)
    nlo, nmid, nhi = t.fbm(0.9, 3, 21), t.fbm(6.0, 4, 22), t.fbm(40.0, 3, 23)
    base = t.tri("cast_iron", 0.6) * tint * (0.80 + 0.5 * nlo[:, None])
    ox = ss(0.42, 0.72, t.fbm(1.7, 4, 24))
    base = mix(base, base * C(1.35, 1.02, 0.78), ox * 0.7)                  # brown oxide bloom
    runs = t.fbm(1.0, 3, 25, stretch=(26.0, 1.6, 26.0))
    base = base * (0.78 + 0.44 * runs[:, None] * (1 - np.abs(t.N[:, 1:2])) + 0.22 * np.abs(t.N[:, 1:2]))
    streak = t.f("streak")
    rd = (t.cav * 0.9 + t.f("rust") + (nlo - 0.5) * 0.9 + (nmid - 0.5) * 0.7 + streak * 0.75 + t.gnd * 0.3) * rustp
    rust = ss(0.42, 0.78, rd + (nhi - 0.5) * 0.35)
    wash = np.clip(ss(0.12, 0.55, rd) * 0.5 + streak * 0.6 * rustp, 0, 0.85)
    rc = _rustcol(t)
    alb = mix(base, base * 0.5 + rc * 0.45, wash)
    alb = mix(alb, rc, rust)
    worn = t.conv * (1 - rust) * ss(0.35, 0.7, nmid + t.conv * 0.4)
    alb = mix(alb, C(0.34, 0.33, 0.32), worn * 0.7)
    grime = np.clip(t.ao * 0.6 + t.cav * 0.5, 0, 1)
    alb = alb * (1 - 0.45 * grime[:, None])
    rough = mix(0.58 + nmid * 0.14, 0.92, np.maximum(rust, wash * 0.6))
    rough = mix(rough, 0.36, worn)
    metal = mix(0.45, 0.0, np.maximum(rust, wash * 0.7))
    metal = mix(metal, 0.9, worn)
    h = (lum(t.tri("cast_iron", 0.6)) - 0.2) * 0.003 + rust * (lum(rc) - 0.3) * 0.003
    return _common(t, alb, rough, metal, h)


def r_enamel(t):
    colr = t.pp("col", [0.90, 0.89, 0.84])
    wear, rustp = t.pp("wear", 1.0), t.pp("rust", 1.0)
    nlo, nmid, nhi = t.fbm(1.7, 3, 51), t.fbm(9.0, 4, 52), t.fbm(48.0, 3, 53)
    etex = t.tri("enamel_white", 0.9) / Tex.get("enamel_white").mean
    en = colr * (etex ** 1.6) * (0.95 + 0.08 * nlo[:, None])
    stain = np.clip(ss(0.5, 0.85, nlo) * 0.35 + t.f("stain") + t.cav * 0.5 + t.ao * 0.35, 0, 1)
    en = mix(en, en * C(0.66, 0.52, 0.34), stain * 0.8)
    blood = np.clip(t.f("blood"), 0, 1) if isinstance(t.f("blood"), np.ndarray) else 0.0
    en = mix(en, C(0.17, 0.045, 0.035) * (0.7 + 0.6 * nmid[:, None]), blood * 0.92) if isinstance(blood, np.ndarray) else en
    big = ss(0.60, 0.82, t.fbm(4.3, 3, 54))
    chipd = t.conv * 1.15 * wear + (nhi - 0.5) * 0.45 + (nmid - 0.5) * 0.8 + 0.5 * wear * big + t.f("chip")
    chip = ss(0.60, 0.64, chipd)
    streak = t.f("streak")
    halo = np.clip(ss(0.40, 0.60, chipd) * 0.75 * rustp + streak * 0.9 * rustp, 0, 0.92)
    rc = _rustcol(t)
    alb = mix(en, en * C(0.78, 0.50, 0.28), halo)
    core = mix(C(0.07, 0.065, 0.07) * (0.7 + 0.8 * nhi[:, None]), rc, ss(0.35, 0.75, nmid + (rustp - 1) * 0.3))
    alb = mix(alb, core, chip)
    rough = mix(0.16 + stain * 0.35 + halo * 0.3, 0.86, chip)
    if isinstance(blood, np.ndarray):
        rough = mix(rough, 0.42, blood * (1 - chip))
    metal = chip * 0.0
    h = (1 - chip) * 0.0007 + chip * (nhi - 0.5) * 0.0005
    return _common(t, alb, rough, metal, h, dust=0.6)


def r_brass(t):
    tint = t.pp("col", [1.0, 1.0, 1.0])
    nlo, nmid = t.fbm(3.0, 3, 61), t.fbm(22.0, 3, 62)
    b = t.tri("brass_old", 0.45) * tint * 1.05
    tarn = np.clip(t.cav * 1.1 + t.ao * 0.7 + ss(0.45, 0.8, nlo) * 0.5 + t.f("dirt"), 0, 1)
    alb = mix(b, b * C(0.36, 0.28, 0.20), tarn * 0.85)
    verd = ss(0.62, 0.86, t.cav * 0.9 + nmid * 0.55 + nlo * 0.3 + t.f("streak") * 0.4)
    alb = mix(alb, C(0.30, 0.47, 0.40) * (0.8 + 0.4 * nmid[:, None]), verd * 0.85)
    pol = t.conv * ss(0.3, 0.7, nmid + 0.2) * (1 - verd)
    alb = mix(alb, C(0.86, 0.69, 0.36), pol * 0.75)
    rough = mix(0.36 + tarn * 0.3, 0.85, verd)
    rough = mix(rough, 0.22, pol)
    metal = np.clip(1.0 - verd * 0.95 - tarn * 0.25, 0, 1)
    h = (lum(b) - 0.5) * 0.0004 + verd * 0.0003
    return _common(t, alb, rough, metal, h, dust=0.7)


def r_steel(t):
    tint = t.pp("col", [1.0, 1.0, 1.0])
    rustp = t.pp("rust", 1.0)
    nlo, nmid, nhi = t.fbm(1.9, 3, 71), t.fbm(11.0, 4, 72), t.fbm(52.0, 3, 73)
    b = t.tri("steel_worn", 0.5) * tint * 0.66
    streak = t.f("streak")
    rd = (t.cav * 0.9 + t.ao * 0.3 + t.f("rust") + (nlo - 0.5) * 1.0 + (nmid - 0.5) * 0.9 + streak * 0.6 + t.gnd * 0.3) * rustp
    rust = ss(0.34, 0.66, rd + (nhi - 0.5) * 0.4)
    rc = _rustcol(t)
    alb = mix(b, rc, rust)
    pol = t.conv * (1 - rust) * 0.6
    alb = mix(alb, C(0.50, 0.50, 0.48), pol)
    grime = np.clip(t.ao * 0.7 + t.cav * 0.6, 0, 1)
    alb = alb * (1 - 0.4 * grime[:, None])
    rough = mix(0.50 + nmid * 0.15, 0.9, rust)
    rough = mix(rough, 0.34, pol)
    metal = (1 - rust) * 0.85
    h = rust * (lum(rc) - 0.3) * 0.0022 + (lum(b) - 0.45) * 0.0006
    return _common(t, alb, rough, metal, h)


def r_galv(t):
    nlo, nmid, nhi = t.fbm(1.6, 3, 81), t.fbm(9.0, 4, 82), t.fbm(50.0, 3, 83)
    b = t.tri("galvanized", 0.7) * t.pp("col", [1.0, 1.0, 1.0])
    rd = t.cav * 0.8 + t.conv * 0.7 + (nlo - 0.5) * 0.8 + (nmid - 0.5) * 0.7 + t.f("rust") + t.f("streak") * 0.6
    rust = ss(0.5, 0.8, rd + (nhi - 0.5) * 0.3)
    rc = _rustcol(t)
    grime = np.clip(t.ao * 0.8 + t.cav * 0.6, 0, 1)
    alb = mix(b * (1 - 0.5 * grime[:, None]), rc, rust)
    stain = np.clip(t.f("stain"), 0, 1) if isinstance(t.f("stain"), np.ndarray) else None
    if stain is not None:
        alb = mix(alb, alb * C(0.45, 0.30, 0.22), stain * 0.8)
    rough = mix(0.48 + nmid * 0.12, 0.9, rust)
    metal = (1 - rust) * 0.7
    h = rust * (lum(rc) - 0.3) * 0.002
    return _common(t, alb, rough, metal, h)


def r_brick(t):
    size = 0.72
    b = t.tri("soot_brick", size)
    l = lum(b)
    sat = b.max(1) - b.min(1)
    mortar = ss(0.36, 0.50, l) * ss(0.10, 0.03, sat)
    nlo = t.fbm(1.2, 3, 91)
    warm = t.pp("col", [1.25, 1.0, 0.86])
    alb = mix(b * warm * (0.95 + 0.5 * nlo[:, None]), b * 1.05, mortar)
    damp = np.clip(t.gnd * 0.8 + t.ao * 0.5, 0, 1)
    alb = alb * (1 - 0.4 * damp[:, None])
    rough = mix(0.88, 0.95, mortar)
    h = -mortar * 0.004 + (l - 0.25) * 0.004 * (1 - mortar) - t.conv * 0.002 * ss(0.4, 0.7, t.fbm(18, 3, 92))
    return _common(t, alb, rough, np.zeros_like(l), h)


def r_wood(t):
    """params: tex, col (tint), varnish 0..1, dustm. aux > 0.5 marks freshly splintered ends."""
    parts = t.prop.parts
    names = sorted({p.params.get("tex", "oak_dark") for p in parts if p.surf == WOOD})
    tid = np.array([names.index(p.params.get("tex", "oak_dark")) if p.surf == WOOD else 0 for p in parts])[t.part]
    off = np.stack([t.phash(1) * 3.0, t.phash(2) * 3.0, t.phash(3) * 3.0], 1)
    w = np.zeros((len(t.part), 3), np.float32)
    for i, nm in enumerate(names):
        m = tid == i
        if m.any():
            s = t.sub(m)
            w[m] = s.grain(nm, s.prop.opts.get("wood_size", 0.9), off=off[m])
    tint = t.pp("col", [1.0, 1.0, 1.0])
    varn = t.pp("varnish", 0.6)
    nlo, nmid = t.fbm(2.2, 3, 101), t.fbm(14.0, 3, 102)
    L, LN = t.local()
    lgrain = fbm(L * np.array([6.0, 70.0, 70.0]), 3, 105)
    lfig = fbm(L * np.array([1.6, 26.0, 26.0]) + off, 3, 106)        # broad figure running along the board
    wl = np.maximum(lum(w), 1e-3)
    w = w * ((wl / wl.mean()) ** 0.9)[:, None]                         # deepen the photographed grain contrast
    base = w * tint * (0.80 + 0.3 * nlo[:, None]) * (0.72 + 0.56 * lfig[:, None]) * (0.86 + 0.28 * lgrain[:, None])
    wornm = np.clip(t.conv * 1.3 + (nmid - 0.5) * 0.6, 0, 1) * varn[:]
    worn = ss(0.35, 0.75, wornm)
    alb = mix(base, base * 1.5 + 0.06, worn * 0.6)
    fresh = ss(0.35, 0.65, t.aux + (lgrain - 0.5) * 0.5)
    alb = mix(alb, C(0.60, 0.47, 0.30) * (0.62 + 0.7 * lgrain[:, None]), fresh)
    grime = np.clip(t.ao * 0.9 + t.cav * 0.6 + t.gnd * 0.3, 0, 1)
    alb = alb * (1 - 0.5 * grime[:, None])
    rough = mix(mix(0.82, 0.50, varn) + worn * 0.25, 0.9, fresh)
    h = (lum(w) / np.maximum(lum(w).mean(), 1e-3) - 1.0) * 0.0009 + (lgrain - 0.5) * 0.0012 * (0.3 + fresh)
    return _common(t, alb, rough, np.zeros_like(nlo), h, dust=1.0)


def r_plaster(t):
    """Local +Y face is the finished painted wall/ceiling skin, everything else is raw lime core."""
    L, LN = t.local()
    tint = t.pp("col", [0.86, 0.85, 0.78])
    nlo, nmid, nhi = t.fbm(2.5, 3, 111), t.fbm(13.0, 3, 112), t.fbm(60.0, 2, 113)
    skin = t.tri("plaster_smooth_albedo", 1.6, P=L, N=LN)
    skin = skin / Tex.get("plaster_smooth_albedo").mean * tint * (0.9 + 0.2 * nlo[:, None])
    core = t.tri("lime_plaster_core", 0.45, P=L, N=LN) * C(0.92, 0.90, 0.84)
    face = ss(0.5, 0.8, LN[:, 1])
    chipped = np.clip(t.conv * 1.3 + (nmid - 0.5) * 0.9 + (nlo - 0.5) * 0.5, 0, 1)
    face = face * (1 - ss(0.5, 0.62, chipped))
    off = np.stack([t.phash(8), t.phash(9), t.phash(10)], 1) * 5.0
    crk = np.abs(fbm((L + off) * 7.0, 4, 114) - 0.5)
    crack = ss(0.016, 0.004, crk) * (0.5 + 0.5 * ss(0.3, 0.6, fbm((L + off) * 2.0, 2, 115)))      # hairline crazing
    blot = ss(0.42, 0.75, fbm((L + off) * 3.0, 4, 116))
    skin = skin * (1 - 0.30 * blot[:, None]) * C(1.0, 0.97, 0.90)                                 # damp / smoke staining
    skin = mix(skin, skin * C(0.42, 0.38, 0.33), crack * 0.85)
    back = ss(0.5, 0.8, -LN[:, 1])
    keys = ss(0.25, 0.05, np.abs(((L[:, 0] / 0.042) % 1.0) - 0.5)) * back   # lath key ridges
    core = core * (1 - 0.35 * keys[:, None]) * (0.86 + 0.25 * nmid[:, None])
    alb = mix(core, skin, face)
    grime = np.clip(t.ao * 0.7 + t.cav * 0.5, 0, 1)
    alb = alb * (1 - 0.45 * grime[:, None])
    rough = mix(0.94, 0.80, face)
    h = face * (0.0012 - crack * 0.0012) + (1 - face) * (lum(core) - 0.6) * 0.004 + keys * 0.004 + (nhi - 0.5) * 0.0004
    return _common(t, alb, rough, np.zeros_like(nlo), h, dust=0.7)


def r_rubble(t):
    b = t.tri("rubble_plaster", 0.85)
    l = lum(b)
    nlo = t.fbm(1.8, 3, 121)
    alb = b * C(0.90, 0.88, 0.82) * (0.78 + 0.35 * nlo[:, None])
    alb = alb * (1 - 0.5 * np.clip(t.ao * 1.1 + t.cav * 0.5, 0, 1)[:, None])
    h = (l - 0.55) * 0.011
    return _common(t, alb, 0.95 + 0 * l, np.zeros_like(l), h, dust=0.2)


def r_glass(t):
    """Opaque dusty wire-reinforced glass. params: ghosts = prop.opts['ghosts'] list (cx, y0, h, r, colour)."""
    P = t.P
    nlo, nmid, nhi = t.fbm(2.3, 3, 131), t.fbm(15.0, 3, 132), t.fbm(70.0, 2, 133)
    alb = np.tile(C(0.105, 0.125, 0.115), (len(nlo), 1)) * (0.8 + 0.5 * nlo[:, None])
    # things on the shelves behind the pane, seen dimly
    for (cx, y0, hh, r, colr) in t.prop.opts.get("ghosts", []):
        dx = np.abs(P[:, 0] - cx)
        ty = (P[:, 1] - y0) / hh
        prof = r * np.where(ty < 0.62, 1.0, np.clip(1.0 - (ty - 0.62) / 0.2, 0.34, 1.0))
        m = ss(prof + 0.008, prof - 0.004, dx) * ss(-0.01, 0.01, ty) * ss(1.02, 0.98, ty)
        alb = mix(alb, np.asarray(colr, np.float32) * (0.75 + 0.4 * nmid[:, None]), m * 0.8)
    for ys in t.prop.opts.get("ghost_shelves", []):
        m = ss(0.016, 0.008, np.abs(P[:, 1] - ys))
        alb = mix(alb, C(0.30, 0.31, 0.28), m * 0.7)
    # wire mesh (diamond chicken wire) embedded in the glass
    pitch = 0.026
    a = (P[:, 0] + P[:, 1]) / pitch
    b = (P[:, 0] - P[:, 1]) / pitch
    lw = 1.1 / (t.ppm * pitch)
    wire = np.maximum(ss(lw, lw * 0.4, np.abs((a % 1.0) - 0.5)), ss(lw, lw * 0.4, np.abs((b % 1.0) - 0.5)))
    alb = mix(alb, C(0.05, 0.045, 0.04), wire * 0.75)
    dust = np.clip(0.30 + (nlo - 0.5) * 0.9 + t.cav * 1.2 + t.ao * 0.8 + ss(0.4, 0.75, nmid) * 0.25 + t.f("dust"), 0, 1)
    wipe = t.f("wipe")
    if isinstance(wipe, np.ndarray):
        dust = dust * (1 - 0.85 * np.clip(wipe, 0, 1))
    alb = mix(alb, C(0.50, 0.49, 0.43) * (0.85 + 0.3 * nhi[:, None]), dust * 0.62)
    rough = mix(0.10, 0.72, dust)
    h = wire * 0.0002 + dust * (nhi - 0.5) * 0.0003
    return np.clip(alb, 0, 1), rough, np.zeros_like(nlo), h


def r_bottle(t):
    """params: col, label (decal name or ''), l0, l1 (label height range, local y), lr (bottle radius)."""
    L, LN = t.local()
    colr = t.pp("col", [0.20, 0.11, 0.04])
    nlo, nhi = t.fbm(9.0, 3, 141), t.fbm(80.0, 2, 143)
    alb = colr * (0.75 + 0.5 * nlo[:, None])
    fill = t.pp("fill", 0.5)
    alb = alb * np.where(L[:, 1] < fill, 0.55, 1.0)[:, None]
    dust = np.clip(ss(0.1, 0.8, t.N[:, 1]) * 0.9 + 0.22 + t.cav * 0.5 + (nlo - 0.5) * 0.5, 0, 1)
    rough = mix(0.10, 0.75, dust)
    names = sorted({p.params.get("label", "") for p in t.prop.parts if p.surf == BOTTLE} - {""})
    lid = np.array([(names.index(p.params["label"]) if p.params.get("label") else -1) if p.surf == BOTTLE else -1
                    for p in t.prop.parts])[t.part]
    l0, l1, lr = t.pp("l0", 0.03), t.pp("l1", 0.09), t.pp("lr", 0.03)
    ang = np.arctan2(L[:, 0], L[:, 2])   # 0 at local +Z (front)
    half = 1.05
    u = ang / (2 * half) + 0.5
    v = (L[:, 1] - l0) / np.maximum(l1 - l0, 1e-4)
    inlab = (u > 0) & (u < 1) & (v > 0) & (v < 1) & (np.hypot(L[:, 0], L[:, 2]) > lr * 0.8)
    for i, nm in enumerate(names):
        m = inlab & (lid == i)
        if m.any():
            lab = Tex.get(nm).sample(u[m], v[m], 0, clamp=True)
            lab = lab * C(0.92, 0.86, 0.70) * (0.72 + 0.45 * nlo[m][:, None])
            alb[m] = lab
            rough[m] = 0.88
            dust[m] *= 0.5
    alb = mix(alb, C(0.50, 0.48, 0.42), dust * 0.6)
    return np.clip(alb, 0, 1), rough, np.zeros_like(nlo), (nhi - 0.5) * 0.0001


def r_canvas(t):
    L, LN = t.local()
    tex = Tex.get("ticking_canvas")
    lv = t._lvl(tex, 0.55)
    off = t.phash(4)[:, None] * 2.0
    top = np.abs(LN[:, 1]) > 0.55
    u = np.where(top, L[:, 2], np.where(np.abs(LN[:, 0]) > np.abs(LN[:, 2]), L[:, 1], L[:, 1])) / 0.55
    v = np.where(top, L[:, 0], np.where(np.abs(LN[:, 0]) > np.abs(LN[:, 2]), L[:, 2], L[:, 0])) / 0.55
    b = tex.sample(u + off[:, 0], v, lv)
    nlo, nmid, nhi = t.fbm(2.6, 4, 151), t.fbm(11.0, 3, 152), t.fbm(140.0, 2, 153)
    alb = b * C(0.86, 0.82, 0.72) * (0.86 + 0.25 * nlo[:, None])
    stain = np.clip(ss(0.46, 0.72, nlo) * 0.7 + t.f("stain"), 0, 1)
    ring = ss(0.05, 0.0, np.abs(nlo - 0.6)) * 0.35
    alb = mix(alb, alb * C(0.60, 0.44, 0.26), np.clip(stain * 0.85 + ring, 0, 1))
    blood = t.f("blood")
    if isinstance(blood, np.ndarray):
        alb = mix(alb, alb * C(0.33, 0.12, 0.09), np.clip(blood, 0, 1) * 0.9)
    grime = np.clip(t.ao * 1.0 + t.cav * 0.9 + t.conv * 0.25 + (nmid - 0.5) * 0.4, 0, 1)
    alb = mix(alb, alb * C(0.40, 0.35, 0.29), grime * 0.75)
    h = (lum(b) - tex.lmean) * 0.0012 + (nhi - 0.5) * 0.0005
    return np.clip(alb, 0, 1), np.full(len(nlo), 0.94, np.float32), np.zeros_like(nlo), h


def r_leather(t):
    b = t.grain("leather_strap", 0.32, off=np.stack([t.phash(5), t.phash(6), t.phash(7)], 1))
    nmid, nhi = t.fbm(16.0, 3, 161), t.fbm(90.0, 2, 162)
    tint = t.pp("col", [1.0, 0.95, 0.9])
    alb = b * tint * 1.15
    L, LN = t.local()
    worn = np.clip(t.conv * 1.2 + (nmid - 0.5) * 0.7, 0, 1)
    alb = mix(alb, alb * 1.8 + 0.05, ss(0.4, 0.8, worn) * 0.6)
    alb = alb * (1 - 0.5 * np.clip(t.ao * 0.9 + t.cav * 0.6, 0, 1)[:, None])
    rough = 0.58 + 0.25 * nmid
    h = (lum(b) - 0.2) * 0.002 + (nhi - 0.5) * 0.0003
    return _common(t, alb, rough, np.zeros_like(nmid), h, dust=0.6)


def r_rubber(t):
    b = t.tri("rubber_old", 0.4) * t.pp("col", [0.8, 0.8, 0.8])
    nmid = t.fbm(20.0, 3, 171)
    alb = b * (1 - 0.4 * np.clip(t.ao + t.cav, 0, 1)[:, None])
    alb = mix(alb, DUSTC * 0.7, np.clip(t.gnd * 0.5 + (nmid - 0.5) * 0.6 + t.conv * 0.3, 0, 1) * 0.5)
    return _common(t, alb, 0.86 + 0 * nmid, np.zeros_like(nmid), (lum(b) - 0.2) * 0.0015, dust=0.5)


def r_coal(t):
    b = t.tri("coal_bed", 0.55)
    l = lum(b)
    alb = b * (1 - 0.4 * np.clip(t.ao, 0, 1)[:, None])
    return np.clip(alb, 0, 1), 0.85 + 0 * l, np.zeros_like(l), (l - 0.3) * 0.02


def r_soot(t):
    n = t.fbm(25.0, 3, 181)
    base = t.pp("col", [0.035, 0.033, 0.032])
    alb = base * (0.6 + 0.9 * n[:, None])
    return np.clip(alb, 0, 1), 0.96 + 0 * n, np.zeros_like(n), (n - 0.5) * 0.001


def r_lamp(t):
    colr = t.pp("col", [0.55, 0.05, 0.04])
    n = t.fbm(14.0, 3, 191)
    dust = np.clip(ss(0.2, 0.9, t.N[:, 1]) * 0.8 + t.cav * 0.8 + (n - 0.5) * 0.5 + 0.1, 0, 1)
    alb = mix(colr * (0.8 + 0.4 * n[:, None]), C(0.45, 0.40, 0.36), dust * 0.55)
    return np.clip(alb, 0, 1), mix(0.12, 0.7, dust), np.zeros_like(n), (n - 0.5) * 0.0001


def r_decal(t):
    """A plate whose local XY plane (+Z out) carries an image. params: img, w, h, kind, rim."""
    L, LN = t.local()
    parts = t.prop.parts
    n = len(t.part)
    alb = np.zeros((n, 3), np.float32)
    rough = np.full(n, 0.3, np.float32)
    metal = np.zeros(n, np.float32)
    h = np.zeros(n, np.float32)
    nmid, nhi, nlo = t.fbm(12.0, 3, 201), t.fbm(55.0, 3, 202), t.fbm(2.5, 3, 203)
    for pi in np.unique(t.part):
        p = parts[pi]
        m = t.part == pi
        kind = p.params.get("kind", "enamel")
        tex = Tex.get(p.params["img"])
        w_, h_ = p.params["w"], p.params["h"]
        u = L[m, 0] / w_ + 0.5
        v = L[m, 1] / h_ + 0.5
        face = (LN[m, 2] > 0.5) & (u > 0) & (u < 1) & (v > 0) & (v < 1)
        img = tex.sample(u, v, 0, clamp=True)
        rim = np.asarray(p.params.get("rim", [0.85, 0.84, 0.78]), np.float32)
        a = np.where(face[:, None], img, rim[None, :])
        l = lum(img)
        if kind == "brass":      # cast/engraved plate: image luminance = raised polished lettering
            br = t.sub(m).tri("brass_old", 0.3)
            raised = np.where(face, ss(0.25, 0.5, l), 1.0)
            a = mix(br * 0.22, br * 1.15, raised)
            metal[m] = mix(0.4, 1.0, raised)
            rough[m] = mix(0.75, 0.36, raised) + t.cav[m] * 0.2
            h[m] = raised * 0.0015
            a = mix(a, C(0.30, 0.46, 0.40), ss(0.6, 0.85, nmid[m] * 0.6 + t.cav[m] * 0.8 + nlo[m] * 0.3)[:, None] * 0.6)
        elif kind == "paper":
            a = a * C(0.95, 0.90, 0.76) * (0.8 + 0.3 * nlo[m][:, None])
            rough[m] = 0.9
        elif kind == "dial":     # card dial under a glass
            a = a * C(0.93, 0.88, 0.74) * (0.78 + 0.3 * nlo[m][:, None])
            grime = np.clip((nmid[m] - 0.45) * 1.4 + t.cav[m] + t.ao[m] * 0.6, 0, 1)
            a = mix(a, a * C(0.45, 0.38, 0.28), grime * 0.7)
            rough[m] = 0.14 + grime * 0.4
        else:                    # vitreous enamel sign
            a = a * (0.90 + 0.12 * nlo[m][:, None])
            conv = t.conv[m]
            chipd = conv * 1.1 + (nhi[m] - 0.5) * 0.5 + (nmid[m] - 0.5) * 0.85 + 0.5 * ss(0.58, 0.8, fbm(t.P[m] * 9.0, 3, 207))
            chip = ss(0.60, 0.64, chipd)
            halo = ss(0.42, 0.60, chipd) * 0.7
            rc = _rustcol(t.sub(m))
            grime = np.clip(t.cav[m] * 0.8 + t.ao[m] * 0.5 + ss(0.5, 0.8, nlo[m]) * 0.4, 0, 1)
            a = mix(a, a * C(0.62, 0.50, 0.36), grime * 0.7)
            a = mix(a, a * C(0.78, 0.5, 0.28), halo)
            a = mix(a, mix(C(0.07, 0.065, 0.07), rc, ss(0.3, 0.7, nmid[m])), chip)
            rough[m] = mix(0.18 + grime * 0.3, 0.86, chip)
            h[m] = (1 - chip) * 0.0006
        alb[m] = a
    return np.clip(alb, 0, 1), rough, metal, h


RECIPES = {IRON: r_iron, PAINT: r_paint, ENAMEL: r_enamel, BRASS: r_brass, STEEL: r_steel, BRICK: r_brick,
           WOOD: r_wood, PLASTER: r_plaster, GLASS: r_glass, BOTTLE: r_bottle, CANVAS: r_canvas,
           LEATHER: r_leather, RUBBER: r_rubber, COAL: r_coal, DECAL: r_decal, GALV: r_galv, RUBBLE: r_rubble,
           SOOT: r_soot, LAMP: r_lamp}
RUSTABLE = (IRON, PAINT, ENAMEL, STEEL, GALV, BRASS)


# ----------------------------------------------------------------------------- image utilities
def _dilate(img, valid, iters=16):
    img = img.copy()
    valid = valid.copy()
    for _ in range(iters):
        if valid.all():
            break
        acc = np.zeros_like(img)
        cnt = np.zeros(valid.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            v = np.roll(valid, (dy, dx), (0, 1))
            acc += np.roll(img, (dy, dx), (0, 1)) * (v[..., None] if img.ndim == 3 else v)
            cnt += v
        fill = (~valid) & (cnt > 0)
        if img.ndim == 3:
            img[fill] = acc[fill] / cnt[fill][:, None]
        else:
            img[fill] = acc[fill] / cnt[fill]
        valid = valid | fill
    return img


def _mblur(img, valid, iters=1):
    """Small masked blur (normalised 3x3 box)."""
    v = valid.astype(np.float32)
    for _ in range(iters):
        acc = np.zeros_like(img)
        cnt = np.zeros_like(v)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                vv = np.roll(v, (dy, dx), (0, 1))
                acc += np.roll(img, (dy, dx), (0, 1)) * (vv[..., None] if img.ndim == 3 else vv)
                cnt += vv
        img = np.where((cnt > 0)[..., None] if img.ndim == 3 else (cnt > 0), acc / np.maximum(cnt, 1e-6)[..., None] if img.ndim == 3 else acc / np.maximum(cnt, 1e-6), img)
    return img


def _save_png(name, arr, srgb, folder):
    h, w = arr.shape[:2]
    rgba = np.ones((h, w, 4), np.float32)
    rgba[..., :3] = np.clip(arr, 0, 1)
    old = bpy.data.images.get(name)
    if old:
        bpy.data.images.remove(old)
    im = bpy.data.images.new(name, w, h, alpha=False)
    im.colorspace_settings.name = 'sRGB' if srgb else 'Non-Color'
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = os.path.join(folder, name + ".png")
    im.file_format = 'PNG'
    im.save()
    return im


def _strip_jpeg(raw):
    """Drop COM / APP1..APP15 segments. Blender 5.3 writes OIIO comment + ICC blocks that Godot 4.7's
    libjpeg-turbo loader rejects (ERR_PARSE_ERROR); the pixel data is untouched."""
    import struct
    if raw[:2] != b"\xff\xd8":
        return raw
    out = bytearray(raw[:2])
    i = 2
    while i + 4 <= len(raw) and raw[i] == 0xFF:
        m = raw[i + 1]
        ln = struct.unpack(">H", raw[i + 2:i + 4])[0]
        if m == 0xDA:
            out += raw[i:]
            return bytes(out)
        if not (m == 0xFE or 0xE1 <= m <= 0xEF):
            out += raw[i:i + 2 + ln]
        i += 2 + ln
    return raw


def clean_glb(path):
    """Rewrite the GLB with metadata-free JPEGs (see _strip_jpeg)."""
    import json
    import struct
    d = open(path, "rb").read()
    jl = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + jl])
    b0 = 20 + jl + 8
    img_views = {im["bufferView"] for im in j.get("images", []) if "bufferView" in im}
    out = bytearray()
    for i, bv in enumerate(j["bufferViews"]):
        off = bv.get("byteOffset", 0)
        raw = d[b0 + off:b0 + off + bv["byteLength"]]
        if i in img_views:
            raw = _strip_jpeg(raw)
        while len(out) % 4:
            out += b"\x00"
        bv["byteOffset"] = len(out)
        bv["byteLength"] = len(raw)
        out += raw
    while len(out) % 4:
        out += b"\x00"
    j["buffers"][0]["byteLength"] = len(out)
    js = json.dumps(j, separators=(",", ":")).encode("utf-8")
    while len(js) % 4:
        js += b" "
    total = 12 + 8 + len(js) + 8 + len(out)
    with open(path, "wb") as f:
        f.write(b"glTF" + struct.pack("<II", 2, total))
        f.write(struct.pack("<I", len(js)) + b"JSON" + js)
        f.write(struct.pack("<I", len(out)) + b"BIN\x00" + bytes(out))


# ----------------------------------------------------------------------------- the prop
class Prop:
    def __init__(self, name, atlases, edge_r=0.012, ao_dist=0.5, cav_dist=0.05, voxel=0.015, streak_len=0.3,
                 dust=0.5, dust_col=(0.62, 0.59, 0.53), seed=0, normal_strength=3.0, jpeg_q=86, **opts):
        self.name, self.atlases = name, list(atlases)
        self.edge_r, self.ao_dist, self.cav_dist = edge_r, ao_dist, cav_dist
        self.voxel, self.streak_len, self.dust, self.seed = voxel, streak_len, dust, seed
        self.dust_col = np.array(dust_col, np.float32)
        self.normal_strength, self.jpeg_q = normal_strength, jpeg_q
        self.opts = opts
        self.parts = []
        self.nodes = {}      # node name -> pivot Matrix (game coords)
        self.hook = None     # hook(tx) fills tx.F fields before the recipes run
        self.info = {}

    def part(self, surf, atlas=0, node=None, **kw):
        return Part(self, surf, atlas, node, **kw)

    def node(self, name, pivot):
        self.nodes[name] = pivot.copy()

    # ---- assemble all parts into one work mesh
    def _assemble(self):
        bm = bmesh.new()
        L_part = bm.faces.layers.int.new("part")
        L_mir = bm.faces.layers.int.new("mir")
        L_node = bm.faces.layers.int.new("node")
        L_atlas = bm.faces.layers.int.new("atlas")
        L_data = bm.loops.layers.float_color.new("data")
        self.node_names = [None] + list(self.nodes.keys())
        for p in self.parts:
            p.bm.verts.index_update()
            vm = [bm.verts.new(v.co) for v in p.bm.verts]
            ax = [v[p.aux] for v in p.bm.verts]
            ni = self.node_names.index(p.node)
            for f in p.bm.faces:
                try:
                    nf = bm.faces.new([vm[v.index] for v in f.verts])
                except ValueError:
                    continue
                nf.material_index = p.atlas
                nf.smooth = True
                nf[L_part] = p.index
                nf[L_mir] = 1 if p.mirror else 0
                nf[L_node] = ni
                nf[L_atlas] = p.atlas
                for l, v in zip(nf.loops, f.verts):
                    l[L_data] = (float(p.surf), float(p.index), ax[v.index], 1.0)
        bm.normal_update()
        for e in bm.edges:
            if len(e.link_faces) == 2:
                lim = math.radians(min(self.parts[e.link_faces[0][L_part]].sharp, self.parts[e.link_faces[1][L_part]].sharp))
                e.smooth = e.calc_face_angle(0.0) < lim
        me = bpy.data.meshes.new(self.name + "_work")
        bm.to_mesh(me)
        self.tris = sum(len(f.verts) - 2 for f in bm.faces) + sum(len(f.verts) - 2 for f in bm.faces if f[L_mir])
        bm.free()
        for an in self.atlases:     # placeholder slots so face material indices are preserved
            me.materials.append(bpy.data.materials.new("slot_" + an))
        ob = bpy.data.objects.new(self.name + "_work", me)
        bpy.context.scene.collection.objects.link(ob)
        return ob

    @staticmethod
    def _restore_slots(me):
        vals = np.empty(len(me.polygons), np.int32)
        me.attributes["atlas"].data.foreach_get("value", vals)
        me.polygons.foreach_set("material_index", vals)
        me.update()

    def _unwrap(self, ob, cache_dir=None, use_cache=True):
        me = ob.data
        # the unwrap is deterministic for a given mesh, and packing is slow: reuse it when geometry is unchanged
        co = np.empty(len(me.vertices) * 3, np.float32)
        me.vertices.foreach_get("co", co)
        lv = np.empty(len(me.loops), np.int32)
        me.loops.foreach_get("vertex_index", lv)
        key = hashlib.md5(co.tobytes() + lv.tobytes() + repr([(p.atlas, p.uvscale) for p in self.parts]).encode() +
                          repr((self.opts.get("uv_angle", 62.0), self.opts.get("uv_margin", 0.0035),
                                self.opts.get("uv_pack", 'CONVEX'))).encode()).hexdigest()
        upath = os.path.join(cache_dir, self.name + "_uv.npz") if cache_dir else None
        if use_cache and upath and os.path.isfile(upath):
            z = np.load(upath)
            if str(z["key"]) == key:
                if not me.uv_layers:
                    me.uv_layers.new(name="UVMap")
                me.uv_layers.active.data.foreach_set("uv", z["uv"])
                print("  [uv] cache hit")
                return
        bpy.context.view_layer.objects.active = ob
        for o in bpy.context.scene.objects:
            o.select_set(o is ob)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.context.tool_settings.mesh_select_mode = (False, False, True)
        for a in range(len(self.atlases)):
            # UV operators only see visible faces: hide every other atlas while this one is unwrapped + packed
            bm = bmesh.from_edit_mesh(me)
            for f in bm.faces:
                f.hide_set(f.material_index != a)
                f.select_set(f.material_index == a)
            bm.select_flush_mode()
            bmesh.update_edit_mesh(me)
            bpy.ops.uv.smart_project(angle_limit=math.radians(self.opts.get("uv_angle", 62.0)), island_margin=0.0,
                                     area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
            try:
                bpy.ops.uv.select_all(action='SELECT')
            except Exception:
                pass
            bpy.ops.uv.average_islands_scale()
            bm = bmesh.from_edit_mesh(me)
            uvl = bm.loops.layers.uv.verify()
            lp = bm.faces.layers.int["part"]
            for f in bm.faces:
                if f.material_index == a:
                    s = self.parts[f[lp]].uvscale
                    if s != 1.0:
                        for l in f.loops:
                            l[uvl].uv = l[uvl].uv * s
            bmesh.update_edit_mesh(me)
            t0 = time.time()
            try:
                bpy.ops.uv.pack_islands(rotate=True, margin_method='FRACTION', margin=self.opts.get("uv_margin", 0.0035),
                                        shape_method=self.opts.get("uv_pack", 'CONVEX'))
            except Exception as ex:  # older signature
                print("  pack fallback:", ex)
                bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
            print("  [uv] %s atlas %s packed in %.1fs" % (self.name, self.atlases[a], time.time() - t0))
        bpy.ops.mesh.reveal(select=False)
        bpy.ops.object.mode_set(mode='OBJECT')
        if upath:
            uv = np.empty(len(me.loops) * 2, np.float32)
            me.uv_layers.active.data.foreach_get("uv", uv)
            np.savez(upath, key=key, uv=uv)

    # ---- Cycles data bakes
    def _bake(self, ob):
        sc = bpy.context.scene
        sc.render.engine = 'CYCLES'
        sc.cycles.device = 'CPU'
        sc.cycles.use_denoising = False
        me = ob.data
        mats = []
        for a, an in enumerate(self.atlases):
            mat = bpy.data.materials.new("bake_" + an)
            mat.use_nodes = True
            nt = mat.node_tree
            nt.nodes.clear()
            out = nt.nodes.new("ShaderNodeOutputMaterial")
            em = nt.nodes.new("ShaderNodeEmission")
            nt.links.new(em.outputs[0], out.inputs["Surface"])
            att = nt.nodes.new("ShaderNodeAttribute")
            att.attribute_name = "data"
            geo = nt.nodes.new("ShaderNodeNewGeometry")
            ao1 = nt.nodes.new("ShaderNodeAmbientOcclusion")
            ao1.samples = 4
            ao1.inputs["Distance"].default_value = self.ao_dist
            ao2 = nt.nodes.new("ShaderNodeAmbientOcclusion")
            ao2.samples = 4
            ao2.inputs["Distance"].default_value = self.cav_dist
            bev = nt.nodes.new("ShaderNodeBevel")
            bev.samples = 4
            bev.inputs["Radius"].default_value = self.edge_r
            dot = nt.nodes.new("ShaderNodeVectorMath")
            dot.operation = 'DOT_PRODUCT'
            nt.links.new(bev.outputs[0], dot.inputs[0])
            nt.links.new(geo.outputs["Normal"], dot.inputs[1])
            comb = nt.nodes.new("ShaderNodeCombineXYZ")
            nt.links.new(ao1.outputs["AO"], comb.inputs[0])
            nt.links.new(ao2.outputs["AO"], comb.inputs[1])
            nt.links.new(dot.outputs["Value"], comb.inputs[2])
            tex = nt.nodes.new("ShaderNodeTexImage")
            img = bpy.data.images.new("bake_" + an, RES, RES, alpha=True, float_buffer=True)
            img.colorspace_settings.name = 'Non-Color'
            tex.image = img
            nt.nodes.active = tex
            me.materials[a] = mat
            mats.append(dict(nt=nt, em=em, img=img, data=att.outputs["Color"], pos=geo.outputs["Position"],
                             occ=comb.outputs[0]))
        self._restore_slots(me)
        # mirrored occluder so the half-built (mirrored) parts receive AO from their twin
        occl = None
        if any(p.mirror for p in self.parts):
            bm = bmesh.new()
            bm.from_mesh(me)
            lm = bm.faces.layers.int["mir"]
            bmesh.ops.delete(bm, geom=[f for f in bm.faces if not f[lm]], context='FACES')
            bmesh.ops.scale(bm, vec=(1, 1, -1), verts=bm.verts)
            bmesh.ops.reverse_faces(bm, faces=bm.faces)
            om = bpy.data.meshes.new("occl")
            bm.to_mesh(om)
            bm.free()
            occl = bpy.data.objects.new("occl", om)
            sc.collection.objects.link(occl)
        for o in sc.objects:
            o.select_set(o is ob)
        bpy.context.view_layer.objects.active = ob

        def run(key, samples, typ='EMIT', **kw):
            for m in mats:
                if key:
                    for l in list(m["em"].inputs[0].links):
                        m["nt"].links.remove(l)
                    m["nt"].links.new(m[key], m["em"].inputs[0])
            sc.cycles.samples = samples
            t0 = time.time()
            bpy.ops.object.bake(type=typ, margin=0, use_clear=True, **kw)
            res = []
            for m in mats:
                a = np.empty(RES * RES * 4, np.float32)
                m["img"].pixels.foreach_get(a)
                res.append(a.reshape(RES, RES, 4).copy())
            print("  [bake] %s %s spp=%d %.1fs" % (self.name, key or typ, samples, time.time() - t0))
            return res

        data = run("data", 1)
        pos = run("pos", 1)
        occ = run("occ", self.opts.get("samples", 20))
        nrm = run(None, 1, 'NORMAL', normal_space='OBJECT')
        if occl:
            bpy.data.objects.remove(occl, do_unlink=True)
        for m in mats:
            bpy.data.images.remove(m["img"])
        return [dict(data=data[a], pos=pos[a][..., :3], occ=occ[a][..., :3], nrm=nrm[a][..., :3])
                for a in range(len(self.atlases))]

    # ---- numpy composite of one atlas
    def _composite(self, a, bk, area):
        cov = bk["data"][..., 3] > 0.5
        n = int(cov.sum())
        ppm = math.sqrt(n / max(area, 1e-6))
        occ = _mblur(bk["occ"], cov, 1)
        P = bk["pos"][cov].astype(np.float64)
        N = bk["nrm"][cov] * 2.0 - 1.0
        N = N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-6)
        aoW, aoT, dot = occ[cov][:, 0], occ[cov][:, 1], occ[cov][:, 2]
        edge = np.clip((1.0 - dot) / 0.2, 0, 1)
        conv = edge * ss(0.6, 0.92, aoT)
        surf = np.rint(bk["data"][cov][:, 0]).astype(np.int32)
        part = np.clip(np.rint(bk["data"][cov][:, 1]).astype(np.int32), 0, len(self.parts) - 1)
        aux = bk["data"][cov][:, 2]
        tx = Tx(self, ppm, P=P, N=N.astype(np.float32), ao=1 - aoW, cav=1 - aoT, edge=edge, conv=conv, surf=surf,
                part=part, aux=aux, gnd=ss(0.30, 0.0, P[:, 1]).astype(np.float32),
                up=ss(0.35, 0.92, N[:, 1]).astype(np.float32), F={})
        # generic drip streaks: crevices on rustable metal leak downward
        rustable = np.isin(surf, RUSTABLE)
        col_act = _hash(np.floor(P[:, 0] / self.voxel).astype(np.int64), np.floor(P[:, 2] / self.voxel).astype(np.int64),
                        np.zeros(n, np.int64), 5 + self.seed) ** 1.6
        src = ss(0.22, 0.6, tx.cav) * rustable * col_act * (0.4 + 0.6 * tx.fbm(3.0, 2, 7))
        st = flow(P, src, self.voxel, self.streak_len)
        st = st * (1 - np.abs(N[:, 1])) * (0.45 + 0.9 * tx.fbm(1.0, 3, 8, stretch=(70.0, 4.0, 70.0)))
        tx.F["streak"] = np.clip(st * self.opts.get("streak", 1.0), 0, 1).astype(np.float32)
        if self.hook:
            self.hook(tx, a)
        alb = np.zeros((n, 3), np.float32)
        rough = np.full(n, 0.8, np.float32)
        metal = np.zeros(n, np.float32)
        hgt = np.zeros(n, np.float32)
        for sid in np.unique(surf):
            fn = RECIPES.get(int(sid))
            if fn is None:
                continue
            m = surf == sid
            ra, rr, rm, rh = fn(tx.sub(m))
            alb[m], rough[m], metal[m], hgt[m] = ra, rr, rm, rh
        # per-part normal intensity compensation for scaled islands
        uvs = np.array([p.uvscale for p in self.parts], np.float32)[part]
        hgt = hgt * uvs
        # to images
        A = np.zeros((RES, RES, 3), np.float32)
        A[cov] = alb
        ORM = np.zeros((RES, RES, 3), np.float32)
        aoc = np.clip(aoW, 0, 1) ** 1.25 * (1 - 0.35 * tx.cav)
        ORM[cov] = np.stack([np.clip(aoc, 0.12, 1), rough, metal], 1)
        H = np.zeros((RES, RES), np.float32)
        H[cov] = hgt
        A = _dilate(A, cov, 12)
        blur = (A + np.roll(A, 1, 0) + np.roll(A, -1, 0) + np.roll(A, 1, 1) + np.roll(A, -1, 1)) / 5.0
        A = np.clip(A + (A - blur) * 0.55, 0, 1)        # mild unsharp mask: the atlas is magnified in game
        ORM = _dilate(ORM, cov, 12)
        H = _dilate(H, cov, 12)
        Hs = (H + np.roll(H, 1, 0) + np.roll(H, -1, 0) + np.roll(H, 1, 1) + np.roll(H, -1, 1)) / 5.0
        Hs = 0.6 * H + 0.4 * Hs
        k = self.normal_strength * ppm * 0.5
        gx = (np.roll(Hs, -1, 1) - np.roll(Hs, 1, 1)) * k
        gy = (np.roll(Hs, -1, 0) - np.roll(Hs, 1, 0)) * k
        gx, gy = np.clip(gx, -2.5, 2.5), np.clip(gy, -2.5, 2.5)
        nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
        NM = np.stack([-gx * nz * 0.5 + 0.5, -gy * nz * 0.5 + 0.5, nz * 0.5 + 0.5], -1)
        print("  [tex] %s/%s cover=%.0f%% density=%.0f px/m albedo mean=%s rough=%.2f metal=%.2f up=%.2f" % (
            self.name, self.atlases[a], 100.0 * n / (RES * RES), ppm, np.round(alb.mean(0), 2), rough.mean(), metal.mean(),
            float(tx.up.mean())))
        self.info.setdefault("density", {})[self.atlases[a]] = round(ppm)
        return A, NM, ORM

    # ---- final materials
    def _final_mat(self, an, ia, inn, io):
        mat = bpy.data.materials.new(self.name.replace("prop_", "") + "_" + an)
        mat.use_nodes = True
        nt = mat.node_tree
        nt.nodes.clear()
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        b = nt.nodes.new("ShaderNodeBsdfPrincipled")
        nt.links.new(b.outputs[0], out.inputs[0])
        ta = nt.nodes.new("ShaderNodeTexImage")
        ta.image = ia
        nt.links.new(ta.outputs[0], b.inputs["Base Color"])
        to = nt.nodes.new("ShaderNodeTexImage")
        to.image = io
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(to.outputs[0], sep.inputs[0])
        nt.links.new(sep.outputs[1], b.inputs["Roughness"])
        nt.links.new(sep.outputs[2], b.inputs["Metallic"])
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = inn
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(tn.outputs[0], nm.inputs["Color"])
        nt.links.new(nm.outputs[0], b.inputs["Normal"])
        grp = bpy.data.node_groups.get("glTF Material Output")
        if grp is None:
            grp = bpy.data.node_groups.new("glTF Material Output", "ShaderNodeTree")
            grp.interface.new_socket("Occlusion", in_out='INPUT', socket_type='NodeSocketFloat')
        g = nt.nodes.new("ShaderNodeGroup")
        g.node_tree = grp
        nt.links.new(sep.outputs[0], g.inputs["Occlusion"])
        mat.use_backface_culling = True
        return mat

    # ---- whole pipeline
    def finish(self, out_dir, tex_dir, cache_dir, use_cache=True):
        t_all = time.time()
        ob = self._assemble()
        me = ob.data
        print("[%s] parts=%d tris=%d" % (self.name, len(self.parts), self.tris))
        self._unwrap(ob, cache_dir, use_cache)
        # geometry/uv fingerprint for the bake cache
        co = np.empty(len(me.vertices) * 3, np.float32)
        me.vertices.foreach_get("co", co)
        uv = np.empty(len(me.loops) * 2, np.float32)
        me.uv_layers.active.data.foreach_get("uv", uv)
        key = hashlib.md5(co.tobytes() + uv.tobytes() + repr((self.edge_r, self.ao_dist, self.cav_dist,
                          self.opts.get("samples", 20), [(p.surf, p.atlas) for p in self.parts])).encode()).hexdigest()
        cpath = os.path.join(cache_dir, self.name + "_bake.npz")
        bakes = None
        if use_cache and os.path.isfile(cpath):
            z = np.load(cpath)
            if str(z["key"]) == key:
                bakes = [dict(data=z["data%d" % a], pos=z["pos%d" % a], occ=z["occ%d" % a], nrm=z["nrm%d" % a])
                         for a in range(len(self.atlases))]
                print("  [bake] cache hit")
        if bakes is None:
            bakes = self._bake(ob)
            sv = {"key": key}
            for a, b in enumerate(bakes):
                for k2, v2 in b.items():
                    sv["%s%d" % (k2, a)] = v2.astype(np.float16) if k2 in ("occ", "nrm") else v2
            np.savez(cpath, **sv)
        # per-atlas surface area (single copy, mirrored twins share texels)
        areas = [0.0] * len(self.atlases)
        for poly in me.polygons:
            areas[poly.material_index] += poly.area * self.parts[me.attributes["part"].data[poly.index].value].uvscale ** 2
        for a, an in enumerate(self.atlases):
            t0 = time.time()
            A, NM, ORM = self._composite(a, bakes[a], areas[a])
            base = self.name.replace("prop_", "") + "_" + an
            ia = _save_png(base + "_albedo", A, True, tex_dir)
            inn = _save_png(base + "_normal", NM, False, tex_dir)
            io = _save_png(base + "_orm", ORM, False, tex_dir)
            me.materials[a] = self._final_mat(an, ia, inn, io)
            print("  [composite] %s %.1fs" % (an, time.time() - t0))
        self._restore_slots(me)
        self._export(ob, out_dir)
        print("[%s] done in %.0fs" % (self.name, time.time() - t_all))

    def _export(self, ob, out_dir):
        me = ob.data
        bm = bmesh.new()
        bm.from_mesh(me)
        lm = bm.faces.layers.int["mir"]
        mf = [f for f in bm.faces if f[lm]]
        if mf:
            geom = bmesh.ops.duplicate(bm, geom=mf)["geom"]
            nv = [g for g in geom if isinstance(g, bmesh.types.BMVert)]
            nf = [g for g in geom if isinstance(g, bmesh.types.BMFace)]
            bmesh.ops.scale(bm, vec=(1, 1, -1), verts=nv)
            bmesh.ops.reverse_faces(bm, faces=nf)
        ln = bm.faces.layers.int["node"]
        Cm = Matrix.Rotation(PI / 2, 4, 'X')   # game (x, y, z) -> Blender (x, -z, y)
        objs = []
        for ni, nn in enumerate(self.node_names):
            b2 = bm.copy()
            l2 = b2.faces.layers.int["node"]
            bmesh.ops.delete(b2, geom=[f for f in b2.faces if f[l2] != ni], context='FACES')
            if not b2.faces:
                b2.free()
                continue
            name = nn or "Body"
            m2 = bpy.data.meshes.new(self.name + "_" + name)
            b2.to_mesh(m2)
            b2.free()
            for mat in me.materials:
                m2.materials.append(mat)
            for an in ("part", "mir", "node", "data", "atlas"):
                at = m2.attributes.get(an)
                if at:
                    m2.attributes.remove(at)
            piv = self.nodes.get(nn, Matrix.Identity(4)) if nn else Matrix.Identity(4)
            m2.transform(Cm @ piv.inverted())
            m2.update()
            o2 = bpy.data.objects.new(name, m2)
            bpy.context.scene.collection.objects.link(o2)
            o2.matrix_world = Cm @ piv @ Cm.inverted()
            objs.append(o2)
        bm.free()
        bpy.data.objects.remove(ob, do_unlink=True)
        bpy.context.view_layer.update()
        for o in bpy.context.scene.objects:
            o.select_set(o in objs)
        bpy.context.view_layer.objects.active = objs[0]
        path = os.path.join(out_dir, self.name + ".glb")
        q = self.jpeg_q
        while True:
            bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_yup=True,
                                      export_apply=True, export_texcoords=True, export_normals=True,
                                      export_tangents=False, export_materials='EXPORT', export_image_format='JPEG',
                                      export_jpeg_quality=q, export_cameras=False, export_lights=False,
                                      export_animations=False, export_skins=False, export_morph=False,
                                      export_extras=False, export_attributes=False)
            clean_glb(path)
            mb = os.path.getsize(path) / 1048576.0
            if mb <= 4.4 or q <= 60:
                break
            q -= 6
        self.info.update(file_mb=round(mb, 2), jpeg_q=q, tris=self.tris)
        print("  [glb] %s %.2f MB (jpeg q%d)" % (path, mb, q))
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
