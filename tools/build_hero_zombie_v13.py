#!/usr/bin/env python3
"""Blender 5.3 AAA Hero Zombie Builder (v13):
- Uses DARK bruised wet necrotic LeePerrySmith face (lps_zombie_diff_v13.jpg, mean=25, max=72 — ZERO pale glowing mask!)
- ZERO button-eye spheres (deep 3D carved orbital sockets cast genuine dark hollow shadows!)
- Irregular broken dark-stained teeth tucked naturally inside snarling dark bloody jaw
- Sleek low-profile dark tactical combat helmet + compact dark curved ski goggles hugged snugly to helmet brow!
"""
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler, Matrix

CACHE = r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache"
RAW_MOD = os.path.join(CACHE, "raw", "models")
HERO_Z = os.path.join(RAW_MOD, "hero_z")
BUILT_MOD = os.path.join(CACHE, "built_models")
BUILT_TEX = os.path.join(CACHE, "built_textures")
os.makedirs(BUILT_MOD, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_pbr_mat(name: str, rough=0.78, metal=0.0, uv_scale=1.0,
                 direct_albedo=None, direct_normal=None, normal_str=1.5, spec=0.22):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = spec

    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (uv_scale, uv_scale, uv_scale)
    nt.links.new(tc.outputs["UV"], mp.inputs["Vector"])

    def load_img(path, colorspace='sRGB'):
        if not path or not os.path.isfile(path):
            return None
        im = bpy.data.images.load(path, check_existing=False)
        try:
            im.colorspace_settings.name = colorspace
        except Exception:
            pass
        im.pack()
        return im

    im_a = load_img(direct_albedo, 'sRGB')
    if im_a:
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = im_a
        nt.links.new(mp.outputs["Vector"], tn.inputs["Vector"])
        nt.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])

    im_n = load_img(direct_normal, 'Non-Color')
    if im_n:
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = im_n
        nt.links.new(mp.outputs["Vector"], tn.inputs["Vector"])
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = normal_str
        nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])

    return mat


def make_solid_mat(name: str, color, rough=0.88, metal=0.0, spec=0.12):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = spec
    return mat


def add_box(bm, center, size, rot=(0, 0, 0), bevel_amt=0.0):
    mat_rot = Euler(rot, 'XYZ').to_matrix().to_4x4()
    mat_scl = Matrix.Diagonal((size[0], size[1], size[2], 1.0))
    mat_tr = Matrix.Translation(center)
    res = bmesh.ops.create_cube(bm, size=1.0, matrix=mat_tr @ mat_rot @ mat_scl)
    verts = res["verts"]
    if bevel_amt > 0.0:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel_amt, segments=1, affect='EDGES', clamp_overlap=True)
    return verts


def box_project_uvs(mesh_obj, scale=1.0):
    bm = bmesh.new()
    bm.from_mesh(mesh_obj.data)
    uv_layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for loop in f.loops:
            co = loop.vert.co
            if az >= ax and az >= ay:
                loop[uv_layer].uv = (co.x * scale, co.y * scale)
            elif ax >= ay:
                loop[uv_layer].uv = (co.y * scale, co.z * scale)
            else:
                loop[uv_layer].uv = (co.x * scale, co.z * scale)
    bm.to_mesh(mesh_obj.data)
    bm.free()


def finish_mesh(name, bm, mat, uv_scale=1.0, smooth=True):
    mesh = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    box_project_uvs(obj, uv_scale)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    return obj


def build_zombie_tactical_v13():
    src = os.path.join(RAW_MOD, "zombie_hazmat.glb")
    lps_path = os.path.join(HERO_Z, "LeePerrySmith.glb")
    lps_diff = os.path.join(BUILT_TEX, "lps_zombie_diff_v13.jpg")
    lps_norm = os.path.join(HERO_Z, "LeePerrySmith_norm.jpg")
    suit_tex = os.path.join(BUILT_TEX, "zh_tactical_suit_v10.jpg")
    suit_nor = os.path.join(BUILT_TEX, "zh_tactical_suit_v10_normal.jpg")

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=src)
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and (o.parent is None or "icosphere" in o.name.lower()):
            bpy.data.objects.remove(o, do_unlink=True)

    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    meshes = sorted([o for o in bpy.data.objects if o.type == 'MESH'], key=lambda o: len(o.data.vertices), reverse=True)
    suit_obj = meshes[0]
    old_head_obj = meshes[1]

    skull_v = [v.co for v in old_head_obj.data.vertices if v.co.z >= 50.0]
    hx_c = 0.0
    hy_c = 0.5 * (min(v.y for v in skull_v) + max(v.y for v in skull_v))
    hz_top = max(v.z for v in skull_v)
    hz_min = min(v.z for v in skull_v)
    hz_mid = 0.5 * (hz_min + hz_top)
    bpy.data.objects.remove(old_head_obj, do_unlink=True)

    head_vg = next((vg.index for vg in suit_obj.vertex_groups if "head" in vg.name.lower()), None)
    bm_s = bmesh.new()
    bm_s.from_mesh(suit_obj.data)
    deform = bm_s.verts.layers.deform.active
    if head_vg is not None and deform is not None:
        to_del = [v for v in bm_s.verts if v[deform].get(head_vg, 0.0) > 0.25]
        if to_del:
            bmesh.ops.delete(bm_s, geom=to_del, context='VERTS')
    for v in bm_s.verts:
        co = v.co
        wrinkle = (
            math.sin(co.z * 0.28 + co.x * 0.22) * 1.65 +
            math.cos(co.y * 0.34 - co.z * 0.24) * 1.25 +
            math.sin((co.x - co.z) * 0.46) * 0.65
        )
        v.co += v.normal * wrinkle
    bm_s.normal_update()
    bm_s.to_mesh(suit_obj.data)
    bm_s.free()

    suit_mat = make_pbr_mat(
        "ZombieWinterParkaV13", rough=0.90, metal=0.0, uv_scale=3.6,
        direct_albedo=suit_tex, direct_normal=suit_nor, normal_str=2.3, spec=0.14
    )
    suit_obj.data.materials.clear()
    suit_obj.data.materials.append(suit_mat)

    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=lps_path)
    lps_obj = next(o for o in bpy.data.objects if o not in before_objs and o.type == 'MESH')

    bm_h = bmesh.new()
    bm_h.from_mesh(lps_obj.data)
    bm_h.transform(lps_obj.matrix_world)
    lps_obj.matrix_world = Matrix.Identity(4)

    del_bust = [v for v in bm_h.verts if v.co.z < -1.42 or (v.co.z < -0.55 and abs(v.co.x) > 1.55)]
    if del_bust:
        bmesh.ops.delete(bm_h, geom=del_bust, context='VERTS')

    # 3D ANATOMICAL HORROR SCULPTING (deep sunken orbital hollows, jutting cheekbones, gaunt cheeks, snarling jaw!)
    for v in bm_h.verts:
        x, y, z = v.co.x, v.co.y, v.co.z
        for sx in (-0.72, 0.72):
            de = math.sqrt(((x - sx) / 0.44) ** 2 + ((z - 1.95) / 0.34) ** 2)
            if de < 1.3 and y < -1.2:
                v.co.y += math.exp(-(de ** 2.2)) * 0.62
        db = math.sqrt((abs(x) / 1.35) ** 2 + ((z - 2.38) / 0.25) ** 2)
        if db < 1.3 and y < -1.4:
            v.co.y -= math.exp(-(db ** 2.0)) * 0.20
        for sx in (-1.18, 1.18):
            dz = math.sqrt(((x - sx) / 0.48) ** 2 + ((z - 1.32) / 0.34) ** 2)
            if dz < 1.4 and y < -0.6:
                v.co.y -= math.exp(-(dz ** 2.0)) * 0.20
                v.co.x += math.copysign(math.exp(-(dz ** 2.0)) * 0.09, sx)
            dh = math.sqrt(((x - sx * 0.92) / 0.55) ** 2 + ((z - 0.42) / 0.52) ** 2)
            if dh < 1.4 and y < -0.4:
                v.co.y += math.exp(-(dh ** 2.0)) * 0.48
                v.co.x -= math.copysign(math.exp(-(dh ** 2.0)) * 0.24, sx)
        if z < 0.26 and y < -0.55:
            jaw_w = math.exp(-((abs(x) / 1.15) ** 2.4)) * min(1.0, (0.26 - z) / 0.45)
            v.co.z -= jaw_w * 0.46
            v.co.y += jaw_w * 0.14
        if 0.24 <= z <= 0.65 and y < -1.5:
            snarl = math.exp(-((abs(x) / 0.68) ** 2.2)) * math.exp(-(((z - 0.36) / 0.20) ** 2.0))
            v.co.z += snarl * 0.22
            v.co.y -= snarl * 0.14
        dm = math.sqrt(((abs(x) / 0.64) ** 2) + (((z - 0.12) / 0.36) ** 2))
        if dm < 1.05 and y < -1.65:
            v.co.y += math.exp(-(dm ** 2.6)) * 0.98

    bm_h.normal_update()
    bm_h.to_mesh(lps_obj.data)
    bm_h.free()
    for p in lps_obj.data.polygons:
        p.use_smooth = True

    # Matte dry rotting dark corpse skin with deep pore/blood normal relief (ZERO metallic silver sheen!)
    face_mat = make_pbr_mat(
        "LPSCorpseFaceV13", rough=0.82, metal=0.0, uv_scale=1.0,
        direct_albedo=lps_diff, direct_normal=lps_norm, normal_str=2.7, spec=0.12
    )
    lps_obj.data.materials.clear()
    lps_obj.data.materials.append(face_mat)

    teeth_mat = make_solid_mat("StainedBoneTeethV13", (0.042, 0.032, 0.022), rough=0.58, metal=0.0, spec=0.18)
    gum_mat = make_solid_mat("BloodyGumsV13", (0.032, 0.004, 0.004), rough=0.36, metal=0.0, spec=0.26)
    helm_mat = make_pbr_mat("WinterHelmetDarkV13", rough=0.94, metal=0.0, uv_scale=0.35,
                            direct_albedo=suit_tex, direct_normal=suit_nor, normal_str=2.0, spec=0.08)
    gframe_mat = make_solid_mat("SkiGoggleFrameV13", (0.008, 0.009, 0.010), rough=0.90, metal=0.0, spec=0.08)
    glens_mat = make_solid_mat("SkiGoggleLensV13", (0.005, 0.007, 0.010), rough=0.42, metal=0.08, spec=0.16)

    bm_teeth = bmesh.new()
    bm_gums = bmesh.new()
    bm_helm = bmesh.new()
    bm_gfr = bmesh.new()
    bm_gln = bmesh.new()

    rng = random.Random(1305)
    # Dark stained irregular broken rotting teeth recessed naturally inside the snarling mouth (ZERO button eyes!)
    for z_base, dir_z, n_t, r_y, skip_idx in [(0.34, -1.0, 10, -1.91, {2, 7}), (-0.08, 1.0, 9, -1.85, {4, 6})]:
        for i in range(n_t):
            if i in skip_idx:
                continue
            t = (i / float(n_t - 1)) * 2.0 - 1.0
            ang = t * 0.84
            tx = math.sin(ang) * 0.50 + rng.uniform(-0.02, 0.02)
            ty = r_y + (1.0 - math.cos(ang)) * 0.38
            th = rng.uniform(0.10, 0.18)
            tw = rng.uniform(0.050, 0.068)
            add_box(bm_teeth, (tx, ty, z_base + dir_z * th * 0.44), (tw, 0.060, th),
                    rot=(rng.uniform(-0.24, 0.24), rng.uniform(-0.20, 0.20), -ang + rng.uniform(-0.20, 0.20)), bevel_amt=0.012)
        for i in range(10):
            t = (i / 9.0) * 2.0 - 1.0
            ang = t * 0.88
            add_box(bm_gums, (math.sin(ang) * 0.52, r_y + 0.07 + (1.0 - math.cos(ang)) * 0.38, z_base - dir_z * 0.05),
                    (0.13, 0.13, 0.11), rot=(0, 0, -ang), bevel_amt=0.02)

    # Rugged low-profile dark tactical combat helmet sitting snugly above brow
    res = bmesh.ops.create_uvsphere(bm_helm, u_segments=32, v_segments=20, radius=1.0)
    to_del = []
    for v in res["verts"]:
        x, y, z = v.co.x, v.co.y, v.co.z
        cut_z = 0.10 if y < -0.20 else (-0.42 if y > 0.25 else -0.30)
        if z < cut_z:
            to_del.append(v)
            continue
        ear_flare = 1.11 if (abs(x) > 0.52 and z < 0.18) else 1.0
        bump = 0.09 * math.sin(x * 14.0 + y * 11.0) * math.cos(z * 16.0)
        v.co = Vector((x * 2.10 * ear_flare + bump,
                       -0.06 + y * 2.24 + bump * 0.5,
                       2.26 + z * 1.92))
    bmesh.ops.delete(bm_helm, geom=to_del, context='VERTS')
    bmesh.ops.solidify(bm_helm, geom=list(bm_helm.faces), thickness=0.18)

    # Sleek compact dark ski goggles tucked flush against helmet forehead (NO frog-eye protrusion!)
    gz_g = 3.12
    for side in (-1.0, 1.0):
        ang = -side * 0.38
        gx = side * 0.78
        gy = -1.96 + abs(gx) * 0.32
        m_rot = Euler((0.30, 0, ang), 'XYZ').to_matrix().to_4x4()
        bmesh.ops.create_uvsphere(
            bm_gfr, u_segments=20, v_segments=14, radius=1.0,
            matrix=Matrix.Translation((gx, gy, gz_g)) @ m_rot @ Matrix.Diagonal((0.68, 0.32, 0.46, 1.0))
        )
        bmesh.ops.create_uvsphere(
            bm_gln, u_segments=18, v_segments=12, radius=1.0,
            matrix=Matrix.Translation((gx, gy - 0.12, gz_g)) @ m_rot @ Matrix.Diagonal((0.54, 0.18, 0.34, 1.0))
        )
    bmesh.ops.create_uvsphere(
        bm_gfr, u_segments=12, v_segments=8, radius=1.0,
        matrix=Matrix.Translation((0.0, -1.94, gz_g + 0.04)) @ Matrix.Diagonal((0.32, 0.24, 0.22, 1.0))
    )
    for s_i in range(24):
        a = -0.08 + (s_i / 23.0) * (math.pi + 0.16)
        add_box(bm_gfr, (math.cos(a) * 2.16, -0.06 + math.sin(a) * 2.30, 2.94),
                (0.14, 0.42, 0.34), rot=(0, 0, a), bevel_amt=0.03)

    head_parts = [lps_obj]
    for pname, pbm, pmat in [
        ("CorpseTeethV13", bm_teeth, teeth_mat),
        ("CorpseGumsV13", bm_gums, gum_mat),
        ("WinterHelmetV13", bm_helm, helm_mat),
        ("SkiGoggleFrameV13", bm_gfr, gframe_mat),
        ("SkiGoggleLensesV13", bm_gln, glens_mat),
    ]:
        head_parts.append(finish_mesh(pname, pbm, pmat, uv_scale=0.6, smooth=True))

    m_to_hz = (
        Matrix.Translation((hx_c, hy_c - 1.2, hz_mid - 1.0))
        @ Matrix.Diagonal((5.75, 5.75, 5.75, 1.0))
        @ Matrix.Translation((0.0, 0.0, -1.25))
    )
    head_bone = next(b for b in arm.data.bones if "head" in b.name.lower() and "top" not in b.name.lower())

    for hp in head_parts:
        bm_t = bmesh.new()
        bm_t.from_mesh(hp.data)
        bm_t.transform(m_to_hz)
        bm_t.normal_update()
        bm_t.to_mesh(hp.data)
        bm_t.free()
        hp.parent = arm
        hp.matrix_parent_inverse = Matrix.Identity(4)
        hp.matrix_local = Matrix.Identity(4)
        mod = hp.modifiers.new(name="Armature", type='ARMATURE')
        mod.object = arm
        vg = hp.vertex_groups.new(name=head_bone.name)
        vg.add(list(range(len(hp.data.vertices))), 1.0, 'REPLACE')

    arm.scale = (1.0, 1.0, 1.0)
    arm.location = (0.0, 0.0, 0.0)

    out_path = os.path.join(BUILT_MOD, "zombie_tactical.glb")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        export_texcoords=True,
        export_normals=True,
        export_materials='EXPORT',
        export_skins=True,
        export_animations=True,
        export_image_format='JPEG',
        export_jpeg_quality=90,
        export_apply=False,
    )
    print(f"  [GLB v13] zombie_tactical.glb ({os.path.getsize(out_path) // 1024} KB)")


if __name__ == "__main__":
    print("=== build_hero_zombie_v13 ===")
    build_zombie_tactical_v13()
    print("=== ALL v13 DONE ===")
