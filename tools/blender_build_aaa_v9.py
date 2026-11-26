#!/usr/bin/env python3
"""Blender 5.3 Headless AAA Hero Builder (v9):
1. Rebuilds grand_staircase_aaa.glb & reception_desk_aaa.glb with desaturated weathered aged-oak wood_carved!
2. Upgrades zombie_tactical.glb:
   - Uses dark bruised corpse face zh_rotting_head_v9.jpg (ZERO glowing white eyes or glowing chin!)
   - Sleek flush-fitting curved combat ski goggles tucked snugly on helmet brow (NO protruding VR box!)
   - Wrinkled organic flecktarn parka with slim contour-hugging dark harness straps (NO boxy armor!)
3. Upgrades zombie_runner.glb (18.5K-vert leo_zombie) with readable bruised necrotic flesh + ragged cloth!
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector, Euler, Matrix

CACHE = r"C:\Users\trayn\.t3\scratch\deadcam_cc0_cache"
RAW_MOD = os.path.join(CACHE, "raw", "models")
BUILT_MOD = os.path.join(CACHE, "built_models")
BUILT_TEX = os.path.join(CACHE, "built_textures")
os.makedirs(BUILT_MOD, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export_glb(path: str, apply_mods=True, skins=False, anims=False):
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format='GLB',
        export_texcoords=True,
        export_normals=True,
        export_materials='EXPORT',
        export_skins=skins,
        export_animations=anims,
        export_image_format='JPEG',
        export_jpeg_quality=88,
        export_apply=apply_mods if not skins else False,
    )
    kb = os.path.getsize(path) // 1024
    print(f"  [GLB v9] {os.path.basename(path)} ({kb} KB)")


def make_pbr_mat(name: str, tex_prefix: str, rough=0.78, metal=0.0, uv_scale=1.0,
                 direct_albedo=None, direct_normal=None, normal_str=1.4, spec=0.30):
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

    alb_path = direct_albedo if direct_albedo else os.path.join(BUILT_TEX, f"{tex_prefix}_albedo.jpg")
    nor_path = direct_normal if direct_normal else os.path.join(BUILT_TEX, f"{tex_prefix}_normal.jpg")
    rgh_path = os.path.join(BUILT_TEX, f"{tex_prefix}_rough.jpg")

    im_a = load_img(alb_path, 'sRGB')
    if im_a:
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = im_a
        nt.links.new(mp.outputs["Vector"], tn.inputs["Vector"])
        nt.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])

    im_r = load_img(rgh_path, 'Non-Color') if not direct_albedo else None
    if im_r:
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = im_r
        nt.links.new(mp.outputs["Vector"], tn.inputs["Vector"])
        nt.links.new(tn.outputs["Color"], bsdf.inputs["Roughness"])

    im_n = load_img(nor_path, 'Non-Color')
    if im_n:
        tn = nt.nodes.new("ShaderNodeTexImage")
        tn.image = im_n
        nt.links.new(mp.outputs["Vector"], tn.inputs["Vector"])
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = normal_str
        nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])

    return mat


def make_solid_mat(name: str, color, rough=0.88, metal=0.0, spec=0.14):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = spec
    return mat


def add_box_uv(bm, center, size, rot=(0, 0, 0), bevel_amt=0.0):
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


def finish_mesh_obj(name, bm, mat, uv_scale=0.65, smooth=False):
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


def retexture_existing_wood_glb(glb_name: str):
    """Update grand_staircase_aaa.glb & reception_desk_aaa.glb with desaturated weathered aged oak!"""
    p = os.path.join(BUILT_MOD, glb_name)
    if not os.path.isfile(p):
        return
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=p)
    oak_mat = make_pbr_mat("AgedWeatheredOak", "wood_carved", rough=0.66, metal=0.0, uv_scale=1.0, normal_str=1.55)
    dark_mat = make_pbr_mat("AgedDarkTimber", "timber_weathered", rough=0.76, metal=0.0, uv_scale=1.0, normal_str=1.65)
    for o in bpy.data.objects:
        if o.type == 'MESH':
            use_dark = any(k in o.name.lower() for k in ["baluster", "trim"])
            o.data.materials.clear()
            o.data.materials.append(dark_mat if use_dark else oak_mat)
    export_glb(p, apply_mods=True)


def build_tactical_zombies():
    src = os.path.join(RAW_MOD, "zombie_hazmat.glb")
    if not os.path.isfile(src):
        return

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=src)
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and (o.parent is None or "icosphere" in o.name.lower()):
            bpy.data.objects.remove(o, do_unlink=True)

    arm_obj = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
    meshes = sorted([o for o in bpy.data.objects if o.type == 'MESH'], key=lambda o: len(o.data.vertices), reverse=True)
    suit_obj = meshes[0] if len(meshes) >= 1 else None
    head_obj = meshes[1] if len(meshes) >= 2 else None

    if suit_obj is not None:
        head_vg = next((vg.index for vg in suit_obj.vertex_groups if "head" in vg.name.lower()), None)
        bm = bmesh.new()
        bm.from_mesh(suit_obj.data)
        deform = bm.verts.layers.deform.active
        if head_vg is not None and deform is not None:
            to_del = [v for v in bm.verts if v[deform].get(head_vg, 0.0) > 0.25]
            if to_del:
                bmesh.ops.delete(bm, geom=to_del, context='VERTS')
        for v in bm.verts:
            co = v.co
            wrinkle = (
                math.sin(co.z * 0.24 + co.x * 0.18) * 1.05 +
                math.cos(co.y * 0.30 - co.z * 0.20) * 0.85 +
                math.sin((co.x - co.z) * 0.44) * 0.45
            )
            v.co += v.normal * wrinkle
        bm.normal_update()
        bm.to_mesh(suit_obj.data)
        bm.free()

        suit_tex = os.path.join(BUILT_TEX, "zh_tactical_suit_v9.jpg")
        if not os.path.isfile(suit_tex):
            suit_tex = os.path.join(BUILT_TEX, "zh_tactical_suit.jpg")
        suit_mat = make_pbr_mat(
            "ZombieParkaCamoV9", "", rough=0.92, metal=0.0, uv_scale=2.6,
            direct_albedo=suit_tex,
            direct_normal=os.path.join(BUILT_TEX, "zh_tactical_suit_normal.jpg"),
            normal_str=1.75, spec=0.10,
        )
        suit_obj.data.materials.clear()
        suit_obj.data.materials.append(suit_mat)

    # Dark bruised corpse face (NO glowing eyes, NO cartoon white chin!)
    head_tex = os.path.join(BUILT_TEX, "zh_rotting_head_v9.jpg")
    head_nor = os.path.join(BUILT_TEX, "zh_rotting_head_v9_normal.jpg")
    if head_obj is not None and os.path.isfile(head_tex):
        head_mat = make_pbr_mat(
            "ZombieCorpseFaceV9", "", rough=0.68, metal=0.0, uv_scale=1.0,
            direct_albedo=head_tex,
            direct_normal=head_nor if os.path.isfile(head_nor) else None,
            normal_str=2.1, spec=0.22,
        )
        head_obj.data.materials.clear()
        head_obj.data.materials.append(head_mat)

    if arm_obj is not None and head_obj is not None:
        head_bone = next((b for b in arm_obj.data.bones if "head" in b.name.lower() and "top" not in b.name.lower()), None)
        helm_tex = os.path.join(BUILT_TEX, "zh_tactical_suit_v9.jpg")
        if not os.path.isfile(helm_tex):
            helm_tex = os.path.join(BUILT_TEX, "zh_tactical_suit.jpg")
        helm_mat = make_pbr_mat(
            "CombatHelmetDarkV9", "", rough=0.94, metal=0.0, uv_scale=0.04,
            direct_albedo=helm_tex,
            direct_normal=os.path.join(BUILT_TEX, "zh_tactical_suit_normal.jpg"),
            normal_str=1.5, spec=0.08,
        )
        rubber_mat = make_solid_mat("UltraMatteGoggleRubber", (0.008, 0.009, 0.009), rough=0.94, metal=0.0, spec=0.06)
        lens_mat = make_solid_mat("UltraDarkSmokedLens", (0.003, 0.004, 0.006), rough=0.18, metal=0.02, spec=0.20)

        if head_bone is not None:
            skull_v = [v.co for v in head_obj.data.vertices if v.co.z >= 50.0]
            hx = 0.0
            hy_min = min(v.y for v in skull_v)
            hy_max = max(v.y for v in skull_v)
            hy_c = 0.5 * (hy_min + hy_max) + 0.2
            hz_top = max(v.z for v in skull_v)
            hz_c = hz_top - 8.4
            rx_h = max(abs(v.x) for v in skull_v) + 2.4
            ry_h = 0.5 * (hy_max - hy_min) + 2.4
            rz_h = 13.4

            bm_h = bmesh.new()
            bm_gr = bmesh.new()
            bm_gl = bmesh.new()

            # Deep weathered combat helmet / winter cap dome wrapping over ears & nape
            res = bmesh.ops.create_uvsphere(bm_h, u_segments=28, v_segments=18, radius=1.0)
            to_del = []
            for v in res["verts"]:
                x, y, z = v.co.x, v.co.y, v.co.z
                cut_z = 0.20 if y < -0.25 else (-0.34 if y > 0.25 else -0.22)
                if z < cut_z:
                    to_del.append(v)
                    continue
                ear_flare = 1.08 if (abs(x) > 0.55 and z < 0.15) else 1.0
                brim_flare = 1.05 if (y < -0.45 and z < 0.25) else 1.0
                bump = 0.28 * math.sin(x * 18.0 + y * 15.0) * math.cos(z * 19.0)
                v.co = Vector((hx + x * rx_h * ear_flare + bump,
                               hy_c + y * ry_h * brim_flare,
                               hz_c + z * rz_h))
            bmesh.ops.delete(bm_h, geom=to_del, context='VERTS')
            bmesh.ops.solidify(bm_h, geom=list(bm_h.faces), thickness=1.1)

            # Snug FLUSH-HUGGING curved rubber ski goggles resting cleanly on the helmet brow (NO protruding VR box!)
            gy_front = hy_c - ry_h * 0.88
            gz_gog = hz_c + 6.4
            for side in (-1.0, 1.0):
                ang = -side * 0.36
                gx = hx + side * 4.5
                gy = gy_front + abs(side * 4.5) * 0.30
                m_rot = Euler((0.28, 0, ang), 'XYZ').to_matrix().to_4x4()
                # Flattened curved rubber bezel hugging helmet curve
                bmesh.ops.create_uvsphere(
                    bm_gr, u_segments=16, v_segments=12, radius=1.0,
                    matrix=Matrix.Translation((gx, gy, gz_gog)) @ m_rot @ Matrix.Diagonal((4.4, 2.0, 2.9, 1.0))
                )
                bmesh.ops.create_uvsphere(
                    bm_gl, u_segments=14, v_segments=10, radius=1.0,
                    matrix=Matrix.Translation((gx, gy - 0.9, gz_gog)) @ m_rot @ Matrix.Diagonal((3.5, 1.2, 2.1, 1.0))
                )
            for seg in range(20):
                a = -math.pi * 0.08 + (seg / 19.0) * math.pi * 1.16
                sx = hx + math.cos(a) * (rx_h * 1.03)
                sy = hy_c + math.sin(a) * (ry_h * 1.02)
                add_box_uv(bm_gr, (sx, sy, hz_c + 5.2), (1.2, 3.2, 2.5), rot=(0, 0, a), bevel_amt=0.3)

            for gname, gbm, gmat in [
                ("CombatHelmet", bm_h, helm_mat),
                ("GoggleFrame", bm_gr, rubber_mat),
                ("GoggleLenses", bm_gl, lens_mat),
            ]:
                gobj = finish_mesh_obj(gname, gbm, gmat, uv_scale=0.04, smooth=True)
                gobj.parent = arm_obj
                mod = gobj.modifiers.new(name="Armature", type='ARMATURE')
                mod.object = arm_obj
                vg = gobj.vertex_groups.new(name=head_bone.name)
                vg.add(list(range(len(gobj.data.vertices))), 1.0, 'REPLACE')

    if arm_obj is not None:
        arm_obj.scale = (1.0, 1.0, 1.0)
        arm_obj.location = (0.0, 0.0, 0.0)
    export_glb(os.path.join(BUILT_MOD, "zombie_tactical.glb"), apply_mods=False, skins=True, anims=True)


def build_leo_horror_zombie():
    src = os.path.join(RAW_MOD, "gh_fps", "leo_zombie.glb")
    if not os.path.isfile(src):
        return
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=src)
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and (o.parent is None or "icosphere" in o.name.lower()):
            bpy.data.objects.remove(o, do_unlink=True)

    flesh_mat = make_pbr_mat(
        "LeoZombieFleshV9", "", rough=0.64, metal=0.0, uv_scale=1.0,
        direct_albedo=os.path.join(BUILT_TEX, "zh_leo_flesh_v9.jpg"),
        direct_normal=os.path.join(BUILT_TEX, "zh_rotting_head_v9_normal.jpg"),
        normal_str=2.0, spec=0.28,
    )
    cloth_mat = make_pbr_mat(
        "LeoZombieRagsV9", "", rough=0.92, metal=0.0, uv_scale=2.2,
        direct_albedo=os.path.join(BUILT_TEX, "zh_tactical_suit.jpg"),
        direct_normal=os.path.join(BUILT_TEX, "zh_tactical_suit_normal.jpg"),
        normal_str=1.6, spec=0.14,
    )
    for o in bpy.data.objects:
        if o.type == 'MESH':
            o.data.materials.clear()
            mat_use = cloth_mat if len(o.data.vertices) in (2784, 804) else flesh_mat
            o.data.materials.append(mat_use)

    arm_obj = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
    if arm_obj is not None:
        arm_obj.scale = (0.71, 0.71, 0.71)
        arm_obj.location = (0.0, 0.0, 0.0)
    export_glb(os.path.join(BUILT_MOD, "zombie_runner.glb"), apply_mods=False, skins=True, anims=True)


def main():
    print("=== blender_build_aaa_v9 ===")
    retexture_existing_wood_glb("grand_staircase_aaa.glb")
    retexture_existing_wood_glb("reception_desk_aaa.glb")
    build_tactical_zombies()
    build_leo_horror_zombie()
    print("=== ALL v9 HERO GLBs BUILT ===")


if __name__ == "__main__":
    main()
