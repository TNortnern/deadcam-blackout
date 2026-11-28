"""Shared helpers for tools/build_zombie_kits.py (Blender 5.3, run headless).
Everything here works in the game's CHARACTER SPACE (metres, +Y up, character faces +Z,
character's left is +X).  Kit objects keep their mesh data in character space while they are
being built and carry the same +90deg X object rotation Blender's OBJ importer gives the
reference bodies, so `matrix_world` puts both in Blender's Z-up world.  `freeze()` bakes that
rotation into the mesh right before export, and the glTF exporter (+Y up) turns it back into
character space with identity node transforms.
"""

import bpy, bmesh, math, os, json, random
import numpy as np
from mathutils import Vector, Matrix, noise
from mathutils.bvhtree import BVHTree

SCRATCH = os.environ.get("DEADCAM_KIT_SCRATCH", r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache\polish")
REFS = os.path.join(SCRATCH, "zombie_refs")
KITDIR = os.path.join(SCRATCH, "zombie_kits")
TEX = os.path.join(KITDIR, "tex")
TEX_OUT = os.path.join(KITDIR, "tex", "baked")
RENDERS = os.path.join(KITDIR, "renders")
ROT = (math.pi / 2.0, 0.0, 0.0)
V = Vector



# --------------------------------------------------------------------------- scene / body
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for d in (TEX_OUT, RENDERS):
        os.makedirs(d, exist_ok=True)



def node_tree(idblock):
    try:
        idblock.use_nodes = True
    except Exception:
        pass
    return idblock.node_tree



class Body:
    """Reference body: Blender objects for rendering/AO plus a character-space BVH."""
    def __init__(self, variant, fit_skip=()):
        """fit_skip: object-name prefixes left out of the fitting BVH (still rendered)."""
        self.variant = variant
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(REFS, f"zombie_{variant}_rest.obj"),
                              forward_axis='NEGATIVE_Z', up_axis='Y')
        self.objects = [o for o in bpy.data.objects if o not in before]
        clay = bpy.data.materials.new("REF_clay")
        nt = node_tree(clay)
        b = nt.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (0.115, 0.090, 0.080, 1)
        b.inputs["Roughness"].default_value = 0.9
        b.inputs["Specular IOR Level"].default_value = 0.1
        verts, polys = [], []
        for o in self.objects:
            o.name = "REF_" + o.name
            o.data.materials.clear()
            o.data.materials.append(clay)
            o.data.polygons.foreach_set("use_smooth", [True] * len(o.data.polygons))
            if any(o.name[4:].startswith(pre) for pre in fit_skip):
                continue
            base = len(verts)
            verts += [v.co.copy() for v in o.data.vertices]      # mesh-local == character space
            polys += [[base + i for i in p.vertices] for p in o.data.polygons]
        self.bvh = BVHTree.FromPolygons(verts, polys)
        sk = json.load(open(os.path.join(REFS, "skeleton_info.json")))[variant]["bones"]
        self.bones = {}
        for k, p in sk.items():
            if k.startswith("mixamorig_"):
                self.bones[k[len("mixamorig_"):].rsplit("_", 1)[0]] = V(p)

    def bone(self, key):
        return self.bones[key].copy()

    def ray(self, o, d, dist=3.0):
        r = self.bvh.ray_cast(V(o), V(d).normalized(), dist)
        return r[0]

    def near(self, p):
        loc, nrm, _i, dist = self.bvh.find_nearest(V(p))
        return loc, nrm, dist

    def sdist(self, p):
        """Approximate signed distance (negative inside the body)."""
        p = V(p)
        loc, nrm, _i, dist = self.bvh.find_nearest(p)
        if loc is None:
            return 9.0
        return dist if (p - loc).dot(nrm) >= 0.0 else -dist

    def outer(self, p, n, reach=0.25):
        """Outermost body surface point along the line through p with outward direction n."""
        n = V(n).normalized()
        h = self.ray(V(p) + n * reach, -n, reach * 2.0)
        return h



def smoothstep(a, b, x):
    if a == b:
        return 0.0 if x < a else 1.0
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)



def lerp(a, b, t):
    return a + (b - a) * t



def smooth_list(vals, iters=2, closed=False, k=0.5):
    vals = list(vals)
    n = len(vals)
    for _ in range(iters):
        out = list(vals)
        for i in range(n):
            if not closed and (i == 0 or i == n - 1):
                continue
            a, b = vals[(i - 1) % n], vals[(i + 1) % n]
            out[i] = vals[i] * (1 - k) + (a + b) * 0.5 * k
        vals = out
    return vals



def fill_none(vals, closed=False, default=0.1):
    n = len(vals)
    known = [i for i, v in enumerate(vals) if v is not None]
    if not known:
        return [default] * n
    out = list(vals)
    for i in range(n):
        if out[i] is not None:
            continue
        prev = [k for k in known if k < i]
        nxt = [k for k in known if k > i]
        if closed:
            a = prev[-1] if prev else known[-1] - n
            b = nxt[0] if nxt else known[0] + n
        else:
            a = prev[-1] if prev else None
            b = nxt[0] if nxt else None
        if a is None:
            out[i] = vals[b % n]
        elif b is None:
            out[i] = vals[a % n]
        else:
            t = (i - a) / (b - a)
            out[i] = lerp(vals[a % n], vals[b % n], t)
    return out



def polar_radii(body, c, e1, e2, angles, R=0.5, rmax=None):
    """Outer body radius seen from directions d = e1*cos(a) + e2*sin(a) around point c."""
    c = V(c)
    out = []
    for a in angles:
        d = (V(e1) * math.cos(a) + V(e2) * math.sin(a)).normalized()
        h = body.ray(c + d * R, -d, R)
        r = (h - c).length if h is not None else None
        if r is not None and rmax is not None and r > rmax:
            r = None
        out.append(r)
    return out



def catmull(pts, t):
    """Catmull-Rom through pts, t in [0,1]."""
    n = len(pts) - 1
    x = min(max(t, 0.0), 1.0) * n
    i = min(int(x), n - 1)
    f = x - i
    p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, n)]
    return 0.5 * ((2 * p1) + (-p0 + p2) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f + (-p0 + 3 * p1 - 3 * p2 + p3) * f ** 3)



def catmull_f(vals, t):
    n = len(vals) - 1
    x = min(max(t, 0.0), 1.0) * n
    i = min(int(x), n - 1)
    f = x - i
    p0, p1, p2, p3 = vals[max(i - 1, 0)], vals[i], vals[i + 1], vals[min(i + 2, n)]
    return 0.5 * ((2 * p1) + (-p0 + p2) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f + (-p0 + 3 * p1 - 3 * p2 + p3) * f ** 3)



def resample(pts, step):
    """Evenly re-space a polyline."""
    pts = [V(p) for p in pts]
    d = [0.0]
    for a, b in zip(pts, pts[1:]):
        d.append(d[-1] + (b - a).length)
    total = d[-1]
    n = max(2, int(round(total / step)) + 1)
    out = []
    j = 0
    for i in range(n):
        s = total * i / (n - 1)
        while j < len(d) - 2 and d[j + 1] < s:
            j += 1
        seg = d[j + 1] - d[j]
        f = 0.0 if seg < 1e-9 else (s - d[j]) / seg
        out.append(pts[j].lerp(pts[j + 1], f))
    return out



# --------------------------------------------------------------------------- mesh creation

_SRC = {}
SRC_SPECS = {}



def link(ob):
    bpy.context.scene.collection.objects.link(ob)
    ob.rotation_euler = ROT
    return ob



def new_obj(name, verts, faces, mat=None, proj=None):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], [tuple(f) for f in faces])
    me.update()
    ob = link(bpy.data.objects.new(name, me))
    if mat:
        me.materials.append(src_material(mat))
    if proj is not None:
        uvl = me.uv_layers.new(name="proj")
        for lp in me.loops:
            uvl.data[lp.index].uv = proj[lp.vertex_index]
    return ob



def activate(ob):
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob



def mod(ob, kind, **props):
    activate(ob)
    m = ob.modifiers.new(kind, kind)
    for k, v in props.items():
        setattr(m, k, v)
    bpy.ops.object.modifier_apply(modifier=m.name)
    return ob



def join(obs, name):
    obs = [o for o in obs if o is not None]
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    if len(obs) > 1:
        bpy.ops.object.join()
    obs[0].name = name
    obs[0].data.name = name
    return obs[0]



def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)



def shade(ob, sharp_deg=None):
    me = ob.data
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    if sharp_deg is not None:
        me.set_sharp_from_angle(angle=math.radians(sharp_deg))
    me.update()
    return ob



def fix_normals(ob, away_from=None, toward_dir=None):
    """Make face normals consistent; optionally make them point away from a point / along a dir."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    if away_from is not None or toward_dir is not None:
        s = 0.0
        for f in bm.faces:
            ref = (f.calc_center_median() - V(away_from)) if away_from is not None else V(toward_dir)
            s += f.normal.dot(ref) * f.calc_area()
        if s < 0.0:
            bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    me.update()
    return ob



def grid(fn, us, vs, close_u=False):
    """Vertex grid from fn(u, v) -> Vector.  Returns verts, quad faces and per-vertex (u, v)."""
    nu, nv = len(us), len(vs)
    verts = [fn(u, v) for v in vs for u in us]
    faces = []
    for j in range(nv - 1):
        for i in range(nu if close_u else nu - 1):
            a = j * nu + i
            b = j * nu + (i + 1) % nu
            faces.append((a, b, b + nu, a + nu))
    u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
    proj = [((u - u0) / max(u1 - u0, 1e-9), (v - v0) / max(v1 - v0, 1e-9)) for v in vs for u in us]
    return verts, faces, proj



def linspace(a, b, n):
    return [a + (b - a) * i / (n - 1) for i in range(n)]



def frame_from(t, hint):
    t = V(t).normalized()
    u = V(hint) - t * V(hint).dot(t)
    if u.length < 1e-6:
        u = t.orthogonal()
    u.normalize()
    return t, u, t.cross(u)



def loft(spine, radii, nth=40, nv=22, ncap=7, cap_len=1.0, squash=(1.0, 1.0), up_hint=(0, 1, 0), shape=None):
    """Organic lofted blob: rings follow a Catmull-Rom spine, then a rounded cap closes the end.
    shape(theta, v, point_on_axis) -> radius multiplier; v is 0 at the open root, 1 at the cap pole."""
    spine = [V(p) for p in spine]
    total_rows = nv + ncap
    verts, faces = [], []
    t_prev, u_prev = None, V(up_hint)
    rows = []
    for j in range(nv):
        s = j / (nv - 1)
        c = catmull(spine, s)
        tan = (catmull(spine, min(s + 0.01, 1.0)) - catmull(spine, max(s - 0.01, 0.0)))
        t, u, w = frame_from(tan, u_prev)
        u_prev = u
        rows.append((c, t, u, w, catmull_f(radii, s), j / (total_rows - 1)))
    c_end, t, u, w, r_end, _ = rows[-1]
    for k in range(1, ncap):
        phi = (math.pi / 2.0) * k / ncap
        rows.append((c_end + t * (r_end * cap_len * math.sin(phi)), t, u, w, r_end * math.cos(phi), (nv - 1 + k) / (total_rows - 1)))
    for (c, t, u, w, r, vv) in rows:
        for i in range(nth):
            th = 2 * math.pi * i / nth
            m = shape(th, vv, c) if shape else 1.0
            verts.append(c + (u * (math.cos(th) * squash[1]) + w * (math.sin(th) * squash[0])) * (r * m))
    nrows = len(rows)
    for j in range(nrows - 1):
        for i in range(nth):
            a = j * nth + i
            b = j * nth + (i + 1) % nth
            faces.append((a, b, b + nth, a + nth))
    m = shape(0.0, 1.0, c_end) if shape else 1.0
    pole = len(verts)
    verts.append(c_end + t * (r_end * cap_len * m))
    base = (nrows - 1) * nth
    for i in range(nth):
        faces.append((base + i, base + (i + 1) % nth, pole))
    return verts, faces



def sweep(pts, nrms, profile, closed=False, cap=True):
    """Sweep a closed 2D profile [(across, out), ...] along pts; 'out' follows nrms."""
    n = len(pts)
    m = len(profile)
    verts, faces = [], []
    for i in range(n):
        if closed:
            tan = pts[(i + 1) % n] - pts[(i - 1) % n]
        else:
            tan = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        tan.normalize()
        nn = V(nrms[i]) - tan * V(nrms[i]).dot(tan)
        nn.normalize()
        b = tan.cross(nn)
        for (x, y) in profile:
            verts.append(pts[i] + b * x + nn * y)
    for i in range(n if closed else n - 1):
        for k in range(m):
            a = i * m + k
            b_ = i * m + (k + 1) % m
            c = ((i + 1) % n) * m + (k + 1) % m
            d = ((i + 1) % n) * m + k
            faces.append((a, b_, c, d))
    if cap and not closed:
        faces.append(tuple(range(m - 1, -1, -1)))
        faces.append(tuple((n - 1) * m + k for k in range(m)))
    return verts, faces



def strap_profile(width, thick, lift=0.0, chamfer=0.3):
    hw, c = width * 0.5, thick * chamfer
    return [(-hw, lift), (hw, lift), (hw, lift + thick - c), (hw - c, lift + thick), (-hw + c, lift + thick), (-hw, lift + thick - c)]



def drape(body, pts, nrms, clearance=0.002, iters=3, reach=0.12):
    """Push a path out so it rests on the outermost body surface along each normal, then smooth."""
    pts = [V(p) for p in pts]
    for it in range(iters + 1):
        for i, p in enumerate(pts):
            n = V(nrms[i]).normalized()
            h = body.ray(p + n * reach, -n, reach * 2.0)
            if h is not None:
                d = (h - p).dot(n) + clearance
                if d > 0.0 or it == 0:
                    pts[i] = p + n * d
        if it < iters:
            sm = list(pts)
            for i in range(1, len(pts) - 1):
                sm[i] = pts[i] * 0.5 + (pts[i - 1] + pts[i + 1]) * 0.25
            pts = sm
    return pts



def dome(center, normal, r, h=None, seg=8, rings=2, hex_head=False):
    """Rivet / bolt head sitting on a surface."""
    center, n = V(center), V(normal).normalized()
    h = r * 0.6 if h is None else h
    u = n.orthogonal().normalized()
    w = n.cross(u)
    verts, faces = [], []
    if hex_head:
        seg = 6
        for z in (-h * 0.3, h):
            for i in range(seg):
                a = 2 * math.pi * i / seg
                verts.append(center + (u * math.cos(a) + w * math.sin(a)) * r + n * z)
        for i in range(seg):
            faces.append((i, (i + 1) % seg, seg + (i + 1) % seg, seg + i))
        top = len(verts)
        verts.append(center + n * (h * 1.12))
        for i in range(seg):
            faces.append((seg + i, seg + (i + 1) % seg, top))
        return verts, faces
    for k in range(rings + 1):
        phi = (math.pi / 2.0) * k / (rings + 1)
        for i in range(seg):
            a = 2 * math.pi * i / seg
            verts.append(center + (u * math.cos(a) + w * math.sin(a)) * (r * math.cos(phi)) + n * (h * math.sin(phi) - (0.001 if k == 0 else 0.0)))
    for k in range(rings):
        for i in range(seg):
            a = k * seg + i
            b = k * seg + (i + 1) % seg
            faces.append((a, b, b + seg, a + seg))
    top = len(verts)
    verts.append(center + n * h)
    for i in range(seg):
        faces.append((rings * seg + i, rings * seg + (i + 1) % seg, top))
    return verts, faces



def tube(pts, r, sides=6, closed=False, up=(0, 1, 0)):
    pts = [V(p) for p in pts]
    n = len(pts)
    verts, faces = [], []
    u_prev = V(up)
    for i in range(n):
        tan = (pts[(i + 1) % n] - pts[(i - 1) % n]) if closed else (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)])
        t, u, w = frame_from(tan, u_prev)
        u_prev = u
        for k in range(sides):
            a = 2 * math.pi * k / sides
            verts.append(pts[i] + (u * math.cos(a) + w * math.sin(a)) * r)
    for i in range(n if closed else n - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            c = ((i + 1) % n) * sides + (k + 1) % sides
            d = ((i + 1) % n) * sides + k
            faces.append((a, b, c, d))
    if not closed:
        faces.append(tuple(range(sides - 1, -1, -1)))
        faces.append(tuple((n - 1) * sides + k for k in range(sides)))
    return verts, faces



def buckle(center, normal, along, w=0.040, h=0.030, bar=0.0045, lift=0.004):
    """Roller buckle frame + prong.  `along` is the strap direction, w is measured across the strap."""
    c, n = V(center), V(normal).normalized()
    a = V(along) - n * V(along).dot(n)
    a.normalize()
    x = n.cross(a)
    c = c + n * lift
    hw, hh, rc = w * 0.5, h * 0.5, 0.006
    path = []
    for (sx, sy, a0) in ((1, 1, 0.0), (-1, 1, 90.0), (-1, -1, 180.0), (1, -1, 270.0)):
        for k in range(3):
            ang = math.radians(a0 + 45.0 * k)
            path.append(c + x * (sx * (hw - rc) + rc * math.cos(ang)) + a * (sy * (hh - rc) + rc * math.sin(ang)))
    parts = [tube(path, bar * 0.5, 6, closed=True, up=n)]
    parts.append(tube([c - x * hw, c + x * hw], bar * 0.42, 6, up=n))
    parts.append(tube([c + n * (bar * 0.4), c + a * (hh * 0.55) + n * (bar * 0.9), c + a * (hh + bar * 0.6) + n * (bar * 0.55)], bar * 0.36, 5, up=n))
    return parts



class Buf:
    """Accumulates raw geometry for one source material, then becomes an object."""
    def __init__(self):
        self.verts, self.faces = [], []

    def add(self, vf):
        v, f = vf[0], vf[1]
        base = len(self.verts)
        self.verts += list(v)
        self.faces += [tuple(base + i for i in face) for face in f]
        return self

    def add_all(self, lst):
        for vf in lst:
            self.add(vf)
        return self

    def obj(self, name, mat, sharp=35.0, away_from=None):
        if not self.verts:
            return None
        ob = new_obj(name, self.verts, self.faces, mat)
        fix_normals(ob, away_from=away_from)
        shade(ob, sharp)
        return ob



# --------------------------------------------------------------------------- body-fitted paths and shells
def ang(c, e1, e2, p):
    """Angle of point p around c in the (e1, e2) plane."""
    d = V(p) - V(c)
    return math.atan2(d.dot(V(e2).normalized()), d.dot(V(e1).normalized()))


def arc_path(body, c, e1, e2, a0, a1, n, R=0.4, clearance=0.002, smooth=2, rmax=None, closed=False, default=0.1, lift=None, rmin=None):
    """Path hugging the outermost body surface inside the plane (e1, e2) through c.
    Returns points, outward normals (perpendicular to the path, in the plane) and the sample angles."""
    c, e1, e2 = V(c), V(e1).normalized(), V(e2).normalized()
    angles = [a0 + 2 * math.pi * i / n for i in range(n)] if closed else linspace(a0, a1, n)
    raw = fill_none(polar_radii(body, c, e1, e2, angles, R, rmax), closed, default)
    if rmin is not None:
        raw = [max(r, rmin) for r in raw]
    sm = smooth_list(raw, smooth, closed)
    rr = smooth_list([max(a, b) for a, b in zip(raw, sm)], 1, closed, k=0.3)
    dirs = [e1 * math.cos(a) + e2 * math.sin(a) for a in angles]
    base = [c + d * r for d, r in zip(dirs, rr)]
    pn = e1.cross(e2)
    pts, nrms = [], []
    for i in range(n):
        if closed:
            tan = base[(i + 1) % n] - base[(i - 1) % n]
        else:
            tan = base[min(i + 1, n - 1)] - base[max(i - 1, 0)]
        nn = tan.cross(pn)
        if nn.length < 1e-9:
            nn = dirs[i].copy()
        nn.normalize()
        if nn.dot(dirs[i]) < 0.0:
            nn = -nn
        extra = lift(base[i]) if lift else 0.0
        pts.append(base[i] + nn * (clearance + extra))
        nrms.append(nn)
    return pts, nrms, angles


def strap(pts, nrms, width, thick, closed=False, chamfer=0.3):
    return sweep(pts, nrms, strap_profile(width, thick, 0.0, chamfer), closed=closed)


def circle_fit(p2):
    """Kasa least-squares circle through 2D points -> (cx, cy, r)."""
    a = np.array([[2 * x, 2 * y, 1.0] for x, y in p2])
    b = np.array([x * x + y * y for x, y in p2])
    sol, *_ = np.linalg.lstsq(a, b, rcond=None)
    cx, cy = sol[0], sol[1]
    return cx, cy, math.sqrt(max(sol[2] + cx * cx + cy * cy, 1e-9))


def fit_limb(body, p0, p1, svals, up_ref, a_lo, a_hi, na=11, R=0.3, rmax=0.19, rlim=(0.05, 0.14), default_r=0.09, max_off=0.09):
    """Fit a tapering cylinder to the visible side of a limb (angles a_lo..a_hi from up_ref around
    the bone axis p0->p1).  Returns (centre_fn(s), radius_fn(s), axis, u, w); s is metres along the axis."""
    p0, p1 = V(p0), V(p1)
    a, u, w = frame_from(p1 - p0, up_ref)
    rows = []
    angles = linspace(a_lo, a_hi, na)
    for s in svals:
        c = p0 + a * s
        rad = polar_radii(body, c, u, w, angles, R, rmax)
        p2 = [(r * math.cos(t), r * math.sin(t)) for r, t in zip(rad, angles) if r is not None]
        if len(p2) < 5:
            continue
        cx, cy, r = circle_fit(p2)
        if rlim[0] <= r <= rlim[1] and math.hypot(cx, cy) <= max_off:
            rows.append((s, cx, cy, r))
    if len(rows) >= 3:
        ss = np.array([r_[0] for r_ in rows])
        fits = [np.polyfit(ss, np.array([r_[k] for r_ in rows]), 1) for k in (1, 2, 3)]
    elif rows:
        fits = [np.array([0.0, sum(r_[k] for r_ in rows) / len(rows)]) for k in (1, 2, 3)]
    else:
        fits = [np.array([0.0, 0.0]), np.array([0.0, 0.0]), np.array([0.0, default_r])]
    print(f"[fit] rows={len(rows)} cu={fits[0].round(4)} cw={fits[1].round(4)} r={fits[2].round(4)}")

    def centre(s):
        return p0 + a * s + u * float(np.polyval(fits[0], s)) + w * float(np.polyval(fits[1], s))

    def radius(s):
        return float(min(max(np.polyval(fits[2], s), rlim[0]), rlim[1]))

    return centre, radius, a, u, w


def squircle(p, q, n=5.0):
    """Map the square [-1,1]^2 onto a rounded-corner shape (keeps grid lines smooth)."""
    m = max(abs(p), abs(q))
    if m < 1e-9:
        return 0.0, 0.0
    k = m / (abs(p) ** n + abs(q) ** n) ** (1.0 / n)
    return p * k, q * k


def plate(ob, thick, bevel=0.002, rim_only=False, offset=1.0, sharp=40.0, segments=2):
    """Give a single-sided shell thickness and rounded edges."""
    mod(ob, 'SOLIDIFY', thickness=thick, offset=offset, use_rim_only=rim_only, use_even_offset=True)
    if bevel:
        mod(ob, 'BEVEL', width=bevel, segments=segments, limit_method='ANGLE', angle_limit=math.radians(50))
    shade(ob, sharp)
    return ob


# --------------------------------------------------------------------------- organic blobs
def blob_union(name, blobs, mat, voxel=0.004, smooth=3, tris=8000, seed=1):
    """Union of lumpy ellipsoids -> voxel remesh -> smooth -> decimate.
    blob = dict(c=Vector, r=float, scale=(sx,sy,sz), frame=(ex,ey,ez), lump=0.08, freq=7.0)"""
    bm = bmesh.new()
    rnd = random.Random(seed)
    for bl in blobs:
        off = V((rnd.uniform(-50, 50), rnd.uniform(-50, 50), rnd.uniform(-50, 50)))
        r = bl["r"]
        sc = bl.get("scale", (1, 1, 1))
        ex, ey, ez = bl.get("frame", (V((1, 0, 0)), V((0, 1, 0)), V((0, 0, 1))))
        lump, freq = bl.get("lump", 0.08), bl.get("freq", 6.0)
        res = bmesh.ops.create_icosphere(bm, subdivisions=3 if r > 0.03 else 2, radius=1.0)
        for v in res["verts"]:
            d = v.co.normalized()
            m = 1.0 + lump * noise.noise(d * (freq * 0.35) + off) + lump * 0.45 * noise.noise(d * freq * 0.9 + off * 1.7)
            v.co = V(bl["c"]) + (ex * (d.x * sc[0]) + ey * (d.y * sc[1]) + ez * (d.z * sc[2])) * (r * m)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = link(bpy.data.objects.new(name, me))
    mod(ob, 'REMESH', mode='VOXEL', voxel_size=voxel, adaptivity=0.0, use_smooth_shade=True)
    if smooth:
        mod(ob, 'SMOOTH', factor=0.55, iterations=smooth)
    n = tri_count(ob)
    if n > tris:
        mod(ob, 'DECIMATE', ratio=tris / n)
    ob.data.materials.append(src_material(mat))
    shade(ob)
    return ob



def cull_inside(ob, body, depth=0.012):
    """Delete faces that are entirely buried deeper than `depth` inside the reference body."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    sd = {v: body.sdist(v.co) for v in bm.verts}
    dead = [f for f in bm.faces if all(sd[v] < -depth for v in f.verts)]
    bmesh.ops.delete(bm, geom=dead, context='FACES')
    bm.to_mesh(me)
    bm.free()
    me.update()
    return ob



class MeshField:
    """Signed-distance helper for a kit object (mesh data already in character space)."""
    def __init__(self, ob):
        me = ob.data
        self.bvh = BVHTree.FromPolygons([v.co.copy() for v in me.vertices], [list(p.vertices) for p in me.polygons])

    def sdist(self, p):
        p = V(p)
        loc, nrm, _i, dist = self.bvh.find_nearest(p)
        if loc is None:
            return 9.0
        return dist if (p - loc).dot(nrm) >= 0.0 else -dist



def set_prox(ob, body, d0=0.0, d1=0.03, power=1.0):
    """Point colour attribute 'prox': 1 where the surface touches/enters the body, 0 beyond d1."""
    me = ob.data
    attr = me.color_attributes.get("prox") or me.color_attributes.new("prox", 'FLOAT_COLOR', 'POINT')
    vals = []
    for v in me.vertices:
        p = (1.0 - smoothstep(d0, d1, body.sdist(v.co))) ** power
        vals += [p, p, p, 1.0]
    attr.data.foreach_set("color", vals)
    return ob



def ensure_prox(ob):
    me = ob.data
    if me.color_attributes.get("prox") is None:
        attr = me.color_attributes.new("prox", 'FLOAT_COLOR', 'POINT')
        attr.data.foreach_set("color", [0.0, 0.0, 0.0, 1.0] * len(me.vertices))



# --------------------------------------------------------------------------- source (bake) materials
def _img(path, colorspace='sRGB'):
    im = bpy.data.images.load(path, check_existing=True)
    im.colorspace_settings.name = colorspace
    return im



def _mix(nt, fac, a, b, blend='MIX'):
    n = nt.nodes.new("ShaderNodeMix")
    n.data_type = 'RGBA'
    n.blend_type = blend
    n.clamp_factor = True
    for sock, val in ((n.inputs[0], fac), (n.inputs[6], a), (n.inputs[7], b)):
        if hasattr(val, "links") or hasattr(val, "is_linked"):
            nt.links.new(val, sock)
        elif isinstance(val, (int, float)):
            sock.default_value = val if sock.type == 'VALUE' else (val, val, val, 1.0)
        else:
            sock.default_value = (*val[:3], 1.0)
    return n.outputs[2]



def _math(nt, op, a, b=None, c=None, clamp=False):
    n = nt.nodes.new("ShaderNodeMath")
    n.operation = op
    n.use_clamp = clamp
    for sock, val in zip(n.inputs, (a, b, c)):
        if val is None:
            continue
        if hasattr(val, "is_linked"):
            nt.links.new(val, sock)
        else:
            sock.default_value = val
    return n.outputs[0]



def _ramp(nt, val, lo, hi, out_lo=0.0, out_hi=1.0):
    n = nt.nodes.new("ShaderNodeMapRange")
    n.clamp = True
    n.interpolation_type = 'SMOOTHSTEP'
    nt.links.new(val, n.inputs[0])
    n.inputs[1].default_value, n.inputs[2].default_value = lo, hi
    n.inputs[3].default_value, n.inputs[4].default_value = out_lo, out_hi
    return n.outputs[0]



def _noise(nt, vec, scale, detail=4.0, rough=0.55, offset=0.0):
    n = nt.nodes.new("ShaderNodeTexNoise")
    n.inputs["Scale"].default_value = scale
    n.inputs["Detail"].default_value = detail
    n.inputs["Roughness"].default_value = rough
    if offset:
        mp = nt.nodes.new("ShaderNodeMapping")
        mp.inputs["Location"].default_value = (offset, offset * 0.7, -offset * 1.3)
        nt.links.new(vec, mp.inputs["Vector"])
        vec = mp.outputs["Vector"]
    nt.links.new(vec, n.inputs["Vector"])
    return n.outputs[0], n.outputs[1]



def _box_tex(nt, vec, file, scale, colorspace='sRGB', blend=0.25, offset=(0, 0, 0)):
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (scale, scale, scale)
    mp.inputs["Location"].default_value = offset
    nt.links.new(vec, mp.inputs["Vector"])
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = _img(os.path.join(TEX, file), colorspace)
    t.projection = 'BOX'
    t.projection_blend = blend
    t.extension = 'MIRROR'
    nt.links.new(mp.outputs["Vector"], t.inputs["Vector"])
    return t.outputs["Color"]



def _lum(nt, col):
    n = nt.nodes.new("ShaderNodeRGBToBW")
    nt.links.new(col, n.inputs[0])
    return n.outputs[0]



def _hsv(nt, col, h=0.5, s=1.0, v=1.0):
    n = nt.nodes.new("ShaderNodeHueSaturation")
    n.inputs["Hue"].default_value, n.inputs["Saturation"].default_value, n.inputs["Value"].default_value = h, s, v
    nt.links.new(col, n.inputs["Color"])
    return n.outputs["Color"]



def src_material(key):
    """Procedural + photo-texture source shader that gets baked into the kit atlas."""
    if key in _SRC:
        return _SRC[key]
    sp = SRC_SPECS[key]
    mat = bpy.data.materials.new("SRC_" + key)
    nt = node_tree(mat)
    nt.nodes.clear()
    L = nt.links
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    obj = tc.outputs["Object"]
    if sp.get("proj"):                       # decal-style texture through the 'proj' UV map
        uvn = nt.nodes.new("ShaderNodeUVMap")
        uvn.uv_map = "proj"
        mp = nt.nodes.new("ShaderNodeMapping")
        crop = sp.get("crop", (0.0, 0.0, 1.0, 1.0))
        mp.inputs["Location"].default_value = (crop[0], crop[1], 0)
        mp.inputs["Scale"].default_value = (crop[2] - crop[0], crop[3] - crop[1], 1)
        L.new(uvn.outputs["UV"], mp.inputs["Vector"])
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = _img(os.path.join(TEX, sp["tex"]))
        t.extension = 'MIRROR'
        L.new(mp.outputs["Vector"], t.inputs["Vector"])
        col = t.outputs["Color"]
    else:
        col = _box_tex(nt, obj, sp["tex"], sp.get("scale", 4.0), offset=sp.get("offset", (0, 0, 0)))
    if "hsv" in sp:
        col = _hsv(nt, col, *sp["hsv"])
    if "tint" in sp:
        col = _mix(nt, 1.0, col, sp["tint"], 'MULTIPLY')
    lum = _lum(nt, col)
    height = lum
    rough = _ramp(nt, lum, sp.get("lum_range", (0.05, 0.7))[0], sp.get("lum_range", (0.05, 0.7))[1], sp["rough"][0], sp["rough"][1])
    mt = sp.get("metal", 0.0)
    metal = _ramp(nt, lum, 0.0, 1.0, mt[0], mt[1]) if isinstance(mt, tuple) else _math(nt, 'ADD', mt, 0.0)
    if "veins" in sp:                         # distorted cell borders read as branching vessels
        vs = sp["veins"]
        _nf, ncol = _noise(nt, obj, vs.get("warp_scale", 5.0), 3.0)
        warp = nt.nodes.new("ShaderNodeVectorMath")
        warp.operation = 'MULTIPLY_ADD'
        L.new(ncol, warp.inputs[0])
        warp.inputs[1].default_value = (vs.get("warp", 0.09),) * 3
        L.new(obj, warp.inputs[2])
        vor = nt.nodes.new("ShaderNodeTexVoronoi")
        vor.feature = 'DISTANCE_TO_EDGE'
        vor.inputs["Scale"].default_value = vs.get("scale", 16.0)
        L.new(warp.outputs[0], vor.inputs["Vector"])
        line = _ramp(nt, vor.outputs["Distance"], 0.0, vs.get("width", 0.035), 1.0, 0.0)
        brk, _c = _noise(nt, obj, vs.get("break_scale", 4.0), 2.0, offset=3.1)
        line = _math(nt, 'MULTIPLY', line, _ramp(nt, brk, 0.42, 0.62), clamp=True)
        line = _math(nt, 'MULTIPLY', line, vs.get("amount", 0.8))
        col = _mix(nt, line, col, vs.get("color", (0.10, 0.02, 0.05)))
        height = _math(nt, 'ADD', height, _math(nt, 'MULTIPLY', line, vs.get("lift", 0.25)))
    if "prox" in sp:                          # blend into inflamed skin where the part meets the body
        ps = sp["prox"]
        at = nt.nodes.new("ShaderNodeAttribute")
        at.attribute_name = "prox"
        if "tex" in ps:
            col2 = _box_tex(nt, obj, ps["tex"], ps.get("scale", 3.0))
            if "hsv" in ps:
                col2 = _hsv(nt, col2, *ps["hsv"])
            if "tint" in ps:
                col2 = _mix(nt, 1.0, col2, ps["tint"], 'MULTIPLY')
        else:
            mot, _c = _noise(nt, obj, 30.0, 4.0, 0.6, offset=4.2)
            col2 = _mix(nt, mot, V(ps["color"]) * 0.75, V(ps["color"]) * 1.25)
        brk, _c = _noise(nt, obj, 22.0, 4.0, offset=7.7)
        pf = _math(nt, 'ADD', at.outputs["Fac"], _math(nt, 'MULTIPLY', _math(nt, 'SUBTRACT', brk, 0.5), ps.get("breakup", 0.35)))
        pf = _ramp(nt, pf, ps.get("lo", 0.25), ps.get("hi", 0.75))
        col = _mix(nt, pf, col, col2)
        rough = _mix(nt, pf, rough, ps.get("rough", 0.6))
        height = _mix(nt, pf, height, _lum(nt, col2))
    if "blood" in sp:                         # dried blood spatter + smears
        bs = sp["blood"]
        n1, _c = _noise(nt, obj, bs.get("scale", 9.0), 5.0, 0.6, offset=1.3)
        n2, _c = _noise(nt, obj, bs.get("scale", 9.0) * 0.28, 2.0, 0.5, offset=5.9)
        m = _math(nt, 'MULTIPLY', _ramp(nt, n1, bs.get("lo", 0.56), bs.get("lo", 0.56) + 0.05), _ramp(nt, n2, 0.5, 0.62), clamp=True)
        m = _math(nt, 'MULTIPLY', m, bs.get("amount", 0.9))
        col = _mix(nt, m, col, bs.get("color", (0.040, 0.005, 0.004)))
        rough = _mix(nt, m, rough, bs.get("rough", 0.5))
        metal = _mix(nt, m, metal, 0.0)
    if "wear" in sp:                          # bright scuffed edges on hard shells (Cycles bevel trick)
        ws = sp["wear"]
        bev = nt.nodes.new("ShaderNodeBevel")
        bev.samples = 6
        bev.inputs["Radius"].default_value = ws.get("radius", 0.004)
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        dot = nt.nodes.new("ShaderNodeVectorMath")
        dot.operation = 'DOT_PRODUCT'
        L.new(bev.outputs["Normal"], dot.inputs[0])
        L.new(geo.outputs["Normal"], dot.inputs[1])
        edge = _ramp(nt, dot.outputs["Value"], ws.get("lo", 0.90), 0.995, 1.0, 0.0)
        brk, _c = _noise(nt, obj, ws.get("noise", 60.0), 5.0, 0.7, offset=2.2)
        edge = _math(nt, 'MULTIPLY', edge, _ramp(nt, brk, 0.35, 0.65), clamp=True)
        edge = _math(nt, 'MULTIPLY', edge, ws.get("amount", 0.8))
        col = _mix(nt, edge, col, ws.get("color", (0.30, 0.30, 0.31)))
        rough = _mix(nt, edge, rough, ws.get("rough", 0.5))
        if "metal" in ws:
            metal = _mix(nt, edge, metal, ws["metal"])
    if "grime" in sp:                         # large soft dirt variation
        gs = sp["grime"]
        g, _c = _noise(nt, obj, gs.get("scale", 3.0), 5.0, 0.6, offset=9.4)
        gm = _math(nt, 'MULTIPLY', _ramp(nt, g, 0.45, 0.75), gs.get("amount", 0.5))
        col = _mix(nt, gm, col, gs.get("color", (0.05, 0.04, 0.03)), 'MIX')
        rough = _mix(nt, gm, rough, gs.get("rough", 0.9))
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = sp.get("bump", 0.5)
    bump.inputs["Distance"].default_value = sp.get("bump_dist", 0.001)
    L.new(height, bump.inputs["Height"])
    hold = {}
    for nm, sock in (("col", col), ("rough", rough), ("metal", metal)):
        m = nt.nodes.new("ShaderNodeMix")
        m.data_type = 'RGBA'
        m.inputs[0].default_value = 0.0
        if hasattr(sock, "is_linked"):
            L.new(sock, m.inputs[6])
        m.name = "HOLD_" + nm
        hold[nm] = m.outputs[2]
    L.new(hold["col"], bsdf.inputs["Base Color"])
    L.new(hold["rough"], bsdf.inputs["Roughness"])
    L.new(hold["metal"], bsdf.inputs["Metallic"])
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    em = nt.nodes.new("ShaderNodeEmission")
    em.name = "BAKE_EMIT"
    L.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    tgt = nt.nodes.new("ShaderNodeTexImage")
    tgt.name = "BAKE_TARGET"
    mat["final"] = sp["final"]
    _SRC[key] = mat
    return mat



def _set_pass(mat, which):
    nt = mat.node_tree
    out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
    em, bsdf = nt.nodes["BAKE_EMIT"], next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    for l in list(out.inputs["Surface"].links):
        nt.links.remove(l)
    if which in ("col", "rough", "metal"):
        nt.links.new(nt.nodes["HOLD_" + which].outputs[2], em.inputs["Color"])
        nt.links.new(em.outputs[0], out.inputs["Surface"])
    else:
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])



# --------------------------------------------------------------------------- atlas, bake, final materials
def _gltf_ao_group():
    ng = bpy.data.node_groups.get("glTF Material Output")
    if ng is None:
        ng = bpy.data.node_groups.new("glTF Material Output", "ShaderNodeTree")
        ng.interface.new_socket(name="Occlusion", in_out='INPUT', socket_type='NodeSocketFloat')
        ng.nodes.new("NodeGroupInput")
    return ng



def final_material(name, base_path, normal_path, orm_path, normal_strength=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_backface_culling = False                   # glTF doubleSided: rim-only shells stay opaque from behind
    nt = node_tree(mat)
    nt.nodes.clear()
    L = nt.links
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    L.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    tb = nt.nodes.new("ShaderNodeTexImage")
    tb.image = bpy.data.images.load(base_path, check_existing=False)
    tb.image.name = name + "_base"                     # (the exporter still names glTF images after the baked file)
    L.new(tb.outputs["Color"], bsdf.inputs["Base Color"])
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = bpy.data.images.load(normal_path, check_existing=False)
    tn.image.colorspace_settings.name = 'Non-Color'
    tn.image.name = name + "_normal"
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = normal_strength
    L.new(tn.outputs["Color"], nm.inputs["Color"])
    L.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    to = nt.nodes.new("ShaderNodeTexImage")
    to.image = bpy.data.images.load(orm_path, check_existing=False)
    to.image.colorspace_settings.name = 'Non-Color'
    to.image.name = name + "_orm"
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    L.new(to.outputs["Color"], sep.inputs[0])
    L.new(sep.outputs[1], bsdf.inputs["Roughness"])
    L.new(sep.outputs[2], bsdf.inputs["Metallic"])
    grp = nt.nodes.new("ShaderNodeGroup")
    grp.node_tree = _gltf_ao_group()
    L.new(sep.outputs[0], grp.inputs["Occlusion"])
    return mat



def _pixels(img):
    a = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(img.size[1], img.size[0], 4)



def _save_jpg(arr, path, colorspace, quality=90):
    h, w = arr.shape[:2]
    img = bpy.data.images.new("tmp_save", w, h, alpha=False)
    img.colorspace_settings.name = colorspace
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(arr[..., :3], 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = path
    img.file_format = 'JPEG'
    img.save(quality=quality)
    bpy.data.images.remove(img)



def unwrap_atlases(ob, finals, angle=66.0, margin=0.006):
    """One UV atlas per final material (faces of several source materials can share an atlas)."""
    me = ob.data
    if "UVMap" not in me.uv_layers:
        me.uv_layers.new(name="UVMap")
    me.uv_layers.active = me.uv_layers["UVMap"]
    me.uv_layers["UVMap"].active_render = True
    slot_final = [m["final"] for m in me.materials]
    activate(ob)
    for fin in finals:
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_mode(type='FACE')
        bpy.ops.mesh.select_all(action='DESELECT')
        bpy.ops.object.mode_set(mode='OBJECT')
        sel = [slot_final[p.material_index] == fin for p in me.polygons]
        me.polygons.foreach_set("select", sel)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(angle), island_margin=margin, area_weight=0.0,
                                 correct_aspect=True, scale_to_bounds=False)
        bpy.ops.uv.pack_islands(margin=margin, rotate=True)
        bpy.ops.object.mode_set(mode='OBJECT')



def bake_atlases(kit, ob, finals, res=1024, ao_dist=0.12, ao_samples=48, ao_floor=0.35, ao_tint=0.55, quality=88, normal_strength=None):
    """Bake colour / roughness / metallic / tangent normal / AO of the source shaders into
    <kit>_<final>_{base,normal,orm}.jpg and return {final: material}."""
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 8
    sc.cycles.use_denoising = False
    sc.render.bake.margin = 10
    sc.render.bake.use_clear = False
    sc.render.bake.use_selected_to_active = False
    if sc.world is None:
        sc.world = bpy.data.worlds.new("w")
    sc.world.light_settings.distance = ao_dist
    me = ob.data
    imgs = {}
    for fin in finals:
        for p in ("col", "rough", "metal", "normal", "ao"):
            im = bpy.data.images.new(f"bake_{fin}_{p}", res, res, alpha=False, float_buffer=True)
            im.colorspace_settings.name = 'Non-Color' if p != "col" else 'Linear Rec.709'
            fill = {"normal": (0.5, 0.5, 1.0, 1.0), "ao": (1, 1, 1, 1)}.get(p, (0, 0, 0, 1))
            im.generated_color = fill
            imgs[(fin, p)] = im
    activate(ob)
    for p in ("col", "rough", "metal", "normal", "ao"):
        for m in me.materials:
            _set_pass(m, p)
            tgt = m.node_tree.nodes["BAKE_TARGET"]
            tgt.image = imgs[(m["final"], p)]
            for n in m.node_tree.nodes:
                n.select = False
            tgt.select = True
            m.node_tree.nodes.active = tgt
        sc.cycles.samples = ao_samples if p == "ao" else (16 if p == "normal" else 4)
        btype = {"col": 'EMIT', "rough": 'EMIT', "metal": 'EMIT', "normal": 'NORMAL', "ao": 'AO'}[p]
        bpy.ops.object.bake(type=btype, margin=10, use_clear=False)
        print(f"[bake] {kit} {p} done")
    result = {}
    for fin in finals:
        col = _pixels(imgs[(fin, "col")])[..., :3]
        ao = np.clip(_pixels(imgs[(fin, "ao")])[..., :1], 0.0, 1.0)
        rough = _pixels(imgs[(fin, "rough")])[..., :1]
        metal = _pixels(imgs[(fin, "metal")])[..., :1]
        nrm = _pixels(imgs[(fin, "normal")])[..., :3]
        ao_s = ao_floor + (1.0 - ao_floor) * ao                       # stored occlusion
        col = col * (1.0 - ao_tint * (1.0 - ao) ** 1.5)                # contact grime in the albedo
        srgb = np.where(col <= 0.0031308, col * 12.92, 1.055 * np.power(np.clip(col, 1e-6, None), 1 / 2.4) - 0.055)
        if normal_strength and fin in normal_strength:
            k = normal_strength[fin]
            v = nrm * 2.0 - 1.0
            v[..., :2] *= k
            v /= np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-6)
            nrm = v * 0.5 + 0.5
        orm = np.concatenate([ao_s, np.clip(rough, 0.04, 1.0), np.clip(metal, 0.0, 1.0)], axis=-1)
        paths = {s: os.path.join(TEX_OUT, f"{kit}_{fin}_{s}.jpg") for s in ("base", "normal", "orm")}
        _save_jpg(srgb, paths["base"], 'Non-Color', quality)
        _save_jpg(nrm, paths["normal"], 'Non-Color', quality)
        _save_jpg(orm, paths["orm"], 'Non-Color', quality)
        result[fin] = final_material(fin, paths["base"], paths["normal"], paths["orm"])
    for im in imgs.values():
        bpy.data.images.remove(im)
    return result



def assign_finals(ob, final_mats):
    """Replace source material slots with the baked final materials (merging duplicate slots)."""
    me = ob.data
    slot_final = [m["final"] for m in me.materials]
    order = []
    for f in slot_final:
        if f not in order:
            order.append(f)
    idx = [order.index(slot_final[p.material_index]) for p in me.polygons]
    me.materials.clear()
    for f in order:
        me.materials.append(final_mats[f])
    me.polygons.foreach_set("material_index", idx)
    me.update()



def split_parts(ob, names):
    """Split the baked kit mesh back into its named nodes using the face attribute 'part'."""
    out = []
    for i, nm in enumerate(names):
        me = ob.data.copy()
        bm = bmesh.new()
        bm.from_mesh(me)
        layer = bm.faces.layers.int["part"]
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] != i], context='FACES')
        bm.to_mesh(me)
        bm.free()
        o = link(bpy.data.objects.new(nm, me))
        me.name = nm
        used = sorted({p.material_index for p in me.polygons})
        mats = [me.materials[k] for k in used]
        remap = {k: j for j, k in enumerate(used)}
        idx = [remap[p.material_index] for p in me.polygons]
        me.materials.clear()
        for m in mats:
            me.materials.append(m)
        me.polygons.foreach_set("material_index", idx)
        for extra in ("proj",):
            if extra in me.uv_layers:
                me.uv_layers.remove(me.uv_layers[extra])
        for an in ("part", "prox"):
            a = me.attributes.get(an)
            if a is not None:
                me.attributes.remove(a)
        me.update()
        out.append(o)
    bpy.data.objects.remove(ob)
    return out



def tag_part(ob, index):
    me = ob.data
    a = me.attributes.get("part") or me.attributes.new("part", 'INT', 'FACE')
    a.data.foreach_set("value", [index] * len(me.polygons))



def freeze(ob):
    """Bake the +90deg X rotation into the mesh so the exported node transform is identity."""
    ob.data.transform(Matrix.Rotation(math.pi / 2.0, 4, 'X'))
    ob.rotation_euler = (0, 0, 0)
    ob.data.update()



def export_glb(path, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    want = dict(filepath=path, export_format='GLB', use_selection=True, export_yup=True, export_apply=False,
                export_image_format='JPEG', export_image_quality=86, export_jpeg_quality=86,
                export_tangents=True, export_normals=True, export_texcoords=True, export_materials='EXPORT',
                export_cameras=False, export_lights=False, export_animations=False, export_skins=False,
                export_extras=False, export_attributes=False, export_vertex_color='NONE',
                export_all_vertex_colors=False, export_active_vertex_color_when_no_material=False)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties
    bpy.ops.export_scene.gltf(**{k: v for k, v in want.items() if k in props})



# --------------------------------------------------------------------------- preview renders
def setup_studio(engine='BLENDER_EEVEE'):
    sc = bpy.context.scene
    sc.render.engine = engine
    if engine == 'CYCLES':
        sc.cycles.samples = 24
        sc.cycles.use_denoising = True
    w = sc.world or bpy.data.worlds.new("w")
    sc.world = w
    nt = node_tree(w)
    bg = next(n for n in nt.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.42, 0.42, 0.44, 1)
    bg.inputs[1].default_value = 0.8
    for rot, e in (((50, 0, 35), 3.2), ((62, 0, -120), 1.6), ((40, 0, 170), 1.4)):
        l = bpy.data.lights.new("studio", 'SUN')
        l.energy = e
        l.angle = math.radians(12)
        lo = bpy.data.objects.new("studio", l)
        sc.collection.objects.link(lo)
        lo.rotation_euler = [math.radians(a) for a in rot]
    cam = bpy.data.cameras.new("cam")
    cam.type = 'ORTHO'
    co = bpy.data.objects.new("cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    try:
        sc.view_settings.view_transform = 'Standard'
    except Exception:
        pass
    return co



def shot(cam, center_char, dir_char, scale, path, res=(900, 900)):
    """Orthographic render; centre and view direction are given in character space."""
    sc = bpy.context.scene
    c = V((center_char[0], -center_char[2], center_char[1]))
    d = V((dir_char[0], -dir_char[2], dir_char[1])).normalized()     # from centre toward camera
    cam.location = c + d * 6.0
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cam.data.ortho_scale = scale
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.filepath = path
    sc.render.image_settings.file_format = 'JPEG'
    sc.render.image_settings.quality = 88
    bpy.ops.render.render(write_still=True)
