extends Node3D
class_name WorldBuilder

var mats: Dictionary = {}
var meshes: Dictionary = {}
var glbs: Dictionary = {}
var asylum_power_lights: Array[Light3D] = []
var spawn_points: Array[Vector3] = []
var interactables: Array[InteractableObject] = []
var world_env: WorldEnvironment
var moon_light: DirectionalLight3D
var lightning_light: DirectionalLight3D
var _is_compat_cached: bool = false
var _opaque_mat_cache: Dictionary = {}
var _opaque_mesh_cache: Dictionary = {}
var snow_particles: GPUParticles3D
var lobby_group: Node3D
var staircase_group: Node3D
var alcove_group: Node3D
var tunnel_group: Node3D
var courtyard_group: Node3D
var cabin_group: Node3D
var reflection_probes: Array[ReflectionProbe] = []
var outdoor_fill_lights: Array[Light3D] = []
var bg_horde_group: Node3D
var _fog_noise_3d: NoiseTexture3D
var _last_indoor: int = -1
var _last_tunnel: int = -1
var _last_outdoor: int = -1
var _last_ssao_t: float = -1.0
var _last_out_fill_w: float = -1.0
var debug_lock_env: bool = false
var voxel_gis: Array[VoxelGI] = []
var quality_preset: int = 1
var _last_side_trees: int = -1
var _tree_bucket_left: Array[MultiMeshInstance3D] = []
var _tree_bucket_right: Array[MultiMeshInstance3D] = []

var user_ssr_enabled: bool = true
var user_ssao_enabled: bool = true
var user_vol_fog_enabled: bool = true
var user_voxel_gi_enabled: bool = true
var user_pom_level: float = 1.0
var daylight_mode: bool = false
var _pom_materials: Array[ShaderMaterial] = []

const TUNNEL_DOOR := AABB(Vector3(-2.45, -0.30, -8.60), Vector3(4.90, 4.05, 0.95))
const TUNNEL_EXIT := AABB(Vector3(-2.60, -0.40, -28.75), Vector3(5.20, 4.35, 1.05))

# Structural/furniture/rubble props never cast expensive dynamic shadows, but NEVER pop-disappear!
const NO_SHADOW_GLBS := {
	"plaster_fall": 0.90, "splinter_heap": 0.90, "pine_roots": 0.85,
	"rubble_boulder": 0.90, "fallen_spruce": 0.85, "books_set": 0.95,
	"binder_notebook": 0.95, "clipboard": 0.95, "picture_frame": 1.0,
	"trashbag": 0.95, "fallen_stone_bank": 0.92, "fractured_bricks": 0.92,
	"vault_brickfall": 0.92, "quarry_fall": 0.95, "spruce_snag": 0.88,
	"coast_rocks": 0.90, "upper_spindle": 0.95, "herringbone_blocks": 1.0,
	"broken_lime_plaster": 0.95, "broken_spandrel": 0.95, "stripped_plaster": 0.95,
	"oak_dado": 1.0, "admissions_gallery": 1.0, "arched_window": 1.0,
	"ornate_door": 1.0, "ward_door": 1.0, "folding_wooden_stool": 0.95,
	"drawer_cabinet": 0.98, "gothic_cabinet": 0.98, "vintage_cabinet": 0.98,
	"wooden_chair": 0.95, "wooden_table": 0.98, "wooden_bookshelf": 0.98,
	"wheelchair": 0.98, "vintage_lamp": 0.95, "hanging_industrial_lamp": 0.95,
	"chandelier": 1.0, "caged_sconce": 0.95, "wooden_lantern": 0.95,
	"lantern": 0.95, "wine_barrel": 0.98, "wooden_crate": 0.98,
	"military_crate": 0.98, "cardboard_box": 0.95, "ammo_box": 0.95,
	"medical_box": 0.95, "registration_machine": 0.98, "trash_can": 0.95,
	"vintage_crutches": 0.95, "modular_pipes": 0.95,
	"fallen_log": 0.88, "dead_quiver_branch_01": 0.85, "winter_grass": 0.85,
	"undergrowth_fern": 0.85, "threshold_lining": 0.95, "landing_portal": 0.95,
	"porch_steps": 0.95,
}

# Small interior floor/desk clutter smoothly dither-fades past 28m (never hero rooms/furniture!)
const SMALL_CLUTTER_GLBS := {
	"books_set": 0.95, "binder_notebook": 0.95, "clipboard": 0.95,
	"vintage_crutches": 0.95, "trash_can": 0.95, "trashbag": 0.95,
	"medical_box": 0.95, "ammo_box": 0.95, "cardboard_box": 0.95,
	"plaster_fall": 0.90, "splinter_heap": 0.90, "fractured_bricks": 0.92,
}

# Only tiny ankle-height outdoor ground scatter smoothly dither-fades well past 50m into night fog
const MICRO_DEBRIS_GLBS := {
	"winter_grass": 0.85, "undergrowth_fern": 0.85, "bark_debris": 0.85,
	"dry_windfall": 0.85, "dead_quiver_branch_01": 0.85,
}

const TREE_GLBS := {
	"fir_tree": 0.90, "dead_winter_tree": 0.90, "young_fir": 0.90, "winter_pine": 0.90,
}

const HERO_LOD_GLBS := {
	"split_siding": 1.0, "porch_steps": 1.0, "hewn_archway": 1.0, "cabin_facade": 1.0,
	"grand_staircase_aaa": 1.0, "zombie_tactical": 1.0,
	"winter_infected": 1.0, "zombie_runner": 1.0, "worn_oak_flight": 1.0,
}


func build_world() -> void:
	_is_compat_cached = (RenderingServer.get_current_rendering_method() == "gl_compatibility")
	if _is_compat_cached:
		user_pom_level = 0.0
	_opaque_mat_cache.clear()
	_opaque_mesh_cache.clear()
	_load_assets()
	_setup_environment()
	_build_asylum_lobby()
	_build_grand_staircase()
	_build_storage_alcove()
	_build_catacomb_tunnel()
	_build_snow_courtyard()
	_build_cabin()
	_build_occluders()
	_build_interactables()
	_build_snow_particles()
	_build_voxel_gi()
	_optimize_lights_recursive(self)
	apply_graphics_toggles()


func build_world_web_async(hud: BodycamHUD = null) -> void:
	_is_compat_cached = (RenderingServer.get_current_rendering_method() == "gl_compatibility")
	if _is_compat_cached:
		user_pom_level = 0.0
	_opaque_mat_cache.clear()
	_opaque_mesh_cache.clear()
	var tree := get_tree()
	await _load_assets_web_async(hud)
	if hud: hud.set_loading_status("BODYCAM-04 // BUILDING ASYLUM LOBBY...")
	_setup_environment()
	_build_asylum_lobby()
	await tree.process_frame
	if hud: hud.set_loading_status("BODYCAM-04 // BUILDING GRAND STAIRCASE...")
	_build_grand_staircase()
	_build_storage_alcove()
	await tree.process_frame
	if hud: hud.set_loading_status("BODYCAM-04 // BUILDING CATACOMB TUNNEL...")
	_build_catacomb_tunnel()
	await tree.process_frame
	if hud: hud.set_loading_status("BODYCAM-04 // BUILDING WINTER COURTYARD...")
	_build_snow_courtyard()
	await tree.process_frame
	if hud: hud.set_loading_status("BODYCAM-04 // BUILDING CABIN & INTERACTABLES...")
	_build_cabin()
	_build_occluders()
	_build_interactables()
	_build_snow_particles()
	_build_voxel_gi()
	_optimize_lights_recursive(self)
	apply_graphics_toggles()
	await tree.process_frame


func _optimize_lights_recursive(n: Node) -> void:
	if n is OmniLight3D or n is SpotLight3D:
		var l := n as Light3D
		var r := (l as OmniLight3D).omni_range if l is OmniLight3D else (l as SpotLight3D).spot_range
		l.distance_fade_enabled = true
		if r >= 7.0:
			# Hero room/courtyard lights stay lit across full courtyard<->lobby sightlines; shadows still cull early!
			l.distance_fade_shadow = 16.0
			l.distance_fade_begin = 64.0
			l.distance_fade_length = 16.0
		else:
			l.distance_fade_shadow = 12.0
			l.distance_fade_begin = 30.0
			l.distance_fade_length = 12.0
		if l is OmniLight3D and l.shadow_enabled:
			# Animated zombies in omni range invalidate dual-paraboloid omni caches (+425 shadow draws/frame); keep SpotLights + flashlight shadowing!
			l.shadow_enabled = false
		if l.shadow_enabled:
			# Static hero SpotLights only shadow Layer 1 architecture
			l.shadow_caster_mask = 1
			if _is_compat_renderer():
				l.shadow_bias = maxf(l.shadow_bias, 0.05)
				l.shadow_normal_bias = maxf(l.shadow_normal_bias, 1.25)
		elif not l.has_meta("keep_vol_fog"):
			l.light_volumetric_fog_energy = 0.0
		if l in outdoor_fill_lights or l.has_meta("dynamic_light"):
			l.light_bake_mode = Light3D.BAKE_DISABLED
		elif l.light_bake_mode == Light3D.BAKE_DYNAMIC:
			l.light_bake_mode = Light3D.BAKE_STATIC
	for c in n.get_children():
		_optimize_lights_recursive(c)


func _aabb_in_view(cam: Camera3D, box: AABB) -> bool:
	for pl: Plane in cam.get_frustum():
		var all_out := true
		for i in range(8):
			if not pl.is_point_over(box.get_endpoint(i)):
				all_out = false
				break
		if all_out:
			return false
	return true


func _is_compat_renderer() -> bool:
	return _is_compat_cached


func _make_opaque_if_fake_alpha(mat: Material) -> Material:
	if mat == null or not (mat is BaseMaterial3D):
		return mat
	var bm := mat as BaseMaterial3D
	if bm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		return mat
	var mname := str(bm.resource_name).to_lower()
	if "fir_tree_01_twig" in mname or "fir_sapling_medium_twigs" in mname or "grass_medium_01" in mname or "fern_02" in mname:
		var key := bm.get_instance_id()
		if _opaque_mat_cache.has(key):
			return _opaque_mat_cache[key]
		var dup := bm.duplicate() as BaseMaterial3D
		dup.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_opaque_mat_cache[key] = dup
		return dup
	return mat


func set_quality_preset(p: int) -> void:
	quality_preset = p
	_last_indoor = -1
	_last_tunnel = -1
	_last_outdoor = -1
	_last_side_trees = -1
	apply_graphics_toggles()


func apply_graphics_toggles() -> void:
	var is_compat := _is_compat_renderer()
	if world_env and world_env.environment:
		var env := world_env.environment
		if not is_compat:
			env.volumetric_fog_enabled = user_vol_fog_enabled
			env.ssr_max_steps = 12 if quality_preset <= 1 else 24
			if not user_ssr_enabled:
				env.ssr_enabled = false
			if not user_ssao_enabled:
				env.ssao_enabled = false
	for gi in voxel_gis:
		if is_instance_valid(gi):
			var gi_key := str(gi.get_meta("gi_key", ""))
			var allow_preset := (quality_preset >= 2) if gi_key == "tunnel" else true
			gi.visible = user_voxel_gi_enabled and not is_compat and allow_preset
	for pm in _pom_materials:
		if is_instance_valid(pm):
			pm.set_shader_parameter("pom_quality", user_pom_level)


func _is_portal_possibly_visible(cam: Camera3D, cam_pos: Vector3, portal: AABB) -> bool:
	if cam == null or portal.grow(1.5).has_point(cam_pos):
		return true
	var inv := cam.global_transform.affine_inverse()
	var vp := cam.get_viewport()
	var aspect := 1.85
	if vp:
		var sz := Vector2(vp.get_visible_rect().size)
		if sz.y > 0.0:
			aspect = maxf(sz.x / sz.y, 1.33)
	var ty := tan(deg_to_rad(clampf(cam.fov, 40.0, 120.0) * 0.5)) * 1.18
	var tx := ty * aspect * 1.15
	var any_in_front := false
	var any_behind := false
	var all_left := true
	var all_right := true
	var all_above := true
	var all_below := true
	for i in range(8):
		var c := portal.get_endpoint(i)
		var lp := inv * c
		var f := -lp.z
		if f > -0.25:
			any_in_front = true
		if f <= 0.25:
			any_behind = true
		else:
			if lp.x >= -tx * f:
				all_left = false
			if lp.x <= tx * f:
				all_right = false
			if lp.y >= -ty * f:
				all_below = false
			if lp.y <= ty * f:
				all_above = false
	if not any_in_front:
		return false
	if not any_behind and (all_left or all_right or all_above or all_below):
		return false
	return true


func _can_see_through_tunnel(cam: Camera3D, cam_pos: Vector3, near_portal: AABB, far_portal: AABB) -> bool:
	if cam == null:
		return true
	if not _is_portal_possibly_visible(cam, cam_pos, near_portal):
		return false
	if not _is_portal_possibly_visible(cam, cam_pos, far_portal):
		return false
	var nx0 := INF
	var nx1 := -INF
	var ny0 := INF
	var ny1 := -INF
	for i in range(8):
		var pt := near_portal.get_endpoint(i)
		var dz := maxf(absf(pt.z - cam_pos.z), 0.15)
		var qx := (pt.x - cam_pos.x) / dz
		var qy := (pt.y - cam_pos.y) / dz
		nx0 = minf(nx0, qx)
		nx1 = maxf(nx1, qx)
		ny0 = minf(ny0, qy)
		ny1 = maxf(ny1, qy)
	var fx0 := INF
	var fx1 := -INF
	var fy0 := INF
	var fy1 := -INF
	for i in range(8):
		var pt := far_portal.get_endpoint(i)
		var dz := maxf(absf(pt.z - cam_pos.z), 0.15)
		var qx := (pt.x - cam_pos.x) / dz
		var qy := (pt.y - cam_pos.y) / dz
		fx0 = minf(fx0, qx)
		fx1 = maxf(fx1, qx)
		fy0 = minf(fy0, qy)
		fy1 = maxf(fy1, qy)
	return not (nx1 < fx0 or nx0 > fx1 or ny1 < fy0 or ny0 > fy1)


func update_zone_culling(cam_or_pos) -> void:
	var cam: Camera3D = cam_or_pos if cam_or_pos is Camera3D else null
	var cam_pos: Vector3 = cam.global_position if cam != null else (cam_or_pos as Vector3)
	var z := cam_pos.z
	var is_compat := _is_compat_renderer()
	# Exact coaxial dual-portal sightline culling — ZERO distance cutoffs, ZERO room pop-in!
	var show_indoor := 1
	if z >= -8.60:
		show_indoor = 1
	elif z > -28.75:
		show_indoor = 1 if (cam == null or _is_portal_possibly_visible(cam, cam_pos, TUNNEL_DOOR)) else 0
	else:
		show_indoor = 1 if (cam == null or _can_see_through_tunnel(cam, cam_pos, TUNNEL_EXIT, TUNNEL_DOOR)) else 0

	var show_tunnel := 1
	if z >= -28.75 and z <= -7.65:
		show_tunnel = 1
	elif z > -7.65:
		show_tunnel = 1 if (cam == null or _is_portal_possibly_visible(cam, cam_pos, TUNNEL_DOOR)) else 0
	else:
		show_tunnel = 1 if (cam == null or _is_portal_possibly_visible(cam, cam_pos, TUNNEL_EXIT)) else 0

	var show_outdoor := 1
	if z <= -27.70:
		show_outdoor = 1
	elif z < -8.60:
		show_outdoor = 1 if (cam == null or _is_portal_possibly_visible(cam, cam_pos, TUNNEL_EXIT)) else 0
	else:
		show_outdoor = 1 if (cam == null or _can_see_through_tunnel(cam, cam_pos, TUNNEL_DOOR, TUNNEL_EXIT)) else 0

	var show_side_trees := show_outdoor
	if world_env and world_env.environment and not debug_lock_env and not is_compat:
		var env := world_env.environment
		var ssao_on := user_ssao_enabled and ((z > -28.0) if quality_preset >= 2 else (z > -10.5))
		var ssr_on := user_ssr_enabled and (z > -27.5) and (quality_preset >= 2 or z > -9.0)
		if env.ssao_enabled != ssao_on:
			env.ssao_enabled = ssao_on
		if env.ssr_enabled != ssr_on:
			env.ssr_enabled = ssr_on
		var want_ssr_steps := 12 if quality_preset <= 1 else 24
		if env.ssr_max_steps != want_ssr_steps:
			env.ssr_max_steps = want_ssr_steps
		if env.volumetric_fog_enabled != user_vol_fog_enabled:
			env.volumetric_fog_enabled = user_vol_fog_enabled
		if quality_preset >= 2:
			var ssao_t := smoothstep(-24.0, -28.0, z)
			if ssao_on and absf(ssao_t - _last_ssao_t) > 0.01:
				_last_ssao_t = ssao_t
				env.ssao_intensity = lerpf(2.05, 1.05, ssao_t)
		else:
			var ssao_t := smoothstep(-8.0, -10.5, z)
			if ssao_on and absf(ssao_t - _last_ssao_t) > 0.01:
				_last_ssao_t = ssao_t
				env.ssao_intensity = lerpf(2.05, 0.0, ssao_t)
	if not is_compat:
		var base_gi_on := user_voxel_gi_enabled
		for gi in voxel_gis:
			if is_instance_valid(gi):
				var gi_key := str(gi.get_meta("gi_key", ""))
				if gi_key == "lobby":
					gi.visible = base_gi_on and (show_indoor == 1)
				elif gi_key == "tunnel":
					gi.visible = base_gi_on and (quality_preset >= 2) and (show_tunnel == 1)
				elif gi_key == "cabin":
					gi.visible = base_gi_on and (quality_preset >= 2) and (show_outdoor == 1)
	var out_fill_w := smoothstep(-16.0, -24.0, z)
	if absf(out_fill_w - _last_out_fill_w) > 0.01:
		_last_out_fill_w = out_fill_w
		for l in outdoor_fill_lights:
			if is_instance_valid(l) and l.has_meta("base_energy"):
				l.light_energy = float(l.get_meta("base_energy")) * out_fill_w
	if show_indoor != _last_indoor:
		_last_indoor = show_indoor
		var b_in := show_indoor == 1
		if lobby_group: lobby_group.visible = b_in
		if staircase_group: staircase_group.visible = b_in
		if alcove_group: alcove_group.visible = b_in
	if show_tunnel != _last_tunnel:
		_last_tunnel = show_tunnel
		if tunnel_group: tunnel_group.visible = (show_tunnel == 1)
	if show_outdoor != _last_outdoor:
		_last_outdoor = show_outdoor
		var b_out := show_outdoor == 1
		if courtyard_group: courtyard_group.visible = b_out
		if cabin_group: cabin_group.visible = b_out
		if snow_particles: snow_particles.visible = b_out
		if bg_horde_group: bg_horde_group.visible = b_out
	if show_side_trees != _last_side_trees:
		_last_side_trees = show_side_trees
		var b_side := show_side_trees == 1
		for mmi in _tree_bucket_left:
			if is_instance_valid(mmi): mmi.visible = b_side
		for mmi in _tree_bucket_right:
			if is_instance_valid(mmi): mmi.visible = b_side


func set_all_zones_visible_for_bake(all_vis: bool) -> void:
	if lobby_group: lobby_group.visible = all_vis
	if staircase_group: staircase_group.visible = all_vis
	if alcove_group: alcove_group.visible = all_vis
	if tunnel_group: tunnel_group.visible = all_vis
	if courtyard_group: courtyard_group.visible = all_vis
	if cabin_group: cabin_group.visible = all_vis
	if bg_horde_group: bg_horde_group.visible = all_vis
	for mmi in _tree_bucket_left:
		if is_instance_valid(mmi): mmi.visible = all_vis
	for mmi in _tree_bucket_right:
		if is_instance_valid(mmi): mmi.visible = all_vis
	if not all_vis:
		_last_indoor = -1
		_last_tunnel = -1
		_last_outdoor = -1
		_last_side_trees = -1


func refresh_reflection_probes() -> void:
	for rp in reflection_probes:
		if is_instance_valid(rp):
			rp.visible = false
			rp.visible = true


const WORLD_GLB_LIST := [
	"grand_staircase_aaa", "reception_desk_aaa", "oak_dado", "fallen_stone_bank", "hewn_archway", "quarry_fall", "vault_brickfall", "splinter_heap", "admissions_gallery", "ward_door", "stripped_plaster", "cabin_facade", "arched_window",
	"folding_wooden_stool", "drawer_cabinet", "gothic_cabinet", "vintage_cabinet",
	"wooden_chair", "wooden_table", "wooden_bookshelf", "wheelchair",
	"hanging_industrial_lamp", "chandelier", "caged_sconce",
	"wooden_lantern", "lantern", "wine_barrel", "wooden_crate", "military_crate",
	"cardboard_box", "ammo_box", "medical_box", "books_set", "binder_notebook",
	"clipboard", "picture_frame", "trash_can", "trashbag", "vintage_crutches",
	"ornate_door", "rubble_boulder", "bark_debris",
	"tunnel_rubble_hero", "young_fir", "registration_machine", "winter_infected", "herringbone_blocks",
	"fir_tree", "dead_winter_tree", "fallen_spruce", "dry_windfall", "undergrowth_fern", "upper_spindle", "spruce_snag", "winter_pine", "fractured_bricks", "plaster_fall", "split_siding", "threshold_lining", "landing_portal", "porch_steps", "broken_spandrel", "broken_lime_plaster", "worn_oak_flight",
	"fallen_log", "dead_quiver_branch_01", "winter_grass",
	"zombie_tactical", "zombie_runner"
]


func _load_assets() -> void:
	for m in ["tunnel_vault_bay", "rubble_mound", "lamp_base", "lamp_shade", "pine_trunk", "pine_foliage"]:
		var p := "res://assets/meshes/%s.obj" % m
		if ResourceLoader.exists(p):
			meshes[m] = load(p)

	var is_web := OS.has_feature("web")
	for gname in WORLD_GLB_LIST:
		if is_web and (gname == "zombie_tactical" or gname == "zombie_runner") and ResourceLoader.exists("res://assets/baked/%s.scn" % gname):
			continue
		var gp := "res://assets/models/%s.glb" % gname
		if ResourceLoader.exists(gp):
			glbs[gname] = load(gp)

	_build_materials()


func _load_assets_web_async(hud: BodycamHUD = null) -> void:
	var tree := get_tree()
	for m in ["tunnel_vault_bay", "rubble_mound", "lamp_base", "lamp_shade", "pine_trunk", "pine_foliage"]:
		var p := "res://assets/meshes/%s.obj" % m
		if ResourceLoader.exists(p):
			meshes[m] = load(p)
	await tree.process_frame

	var total := WORLD_GLB_LIST.size()
	var t0 := Time.get_ticks_msec()
	for i in range(total):
		var gname: String = WORLD_GLB_LIST[i]
		if (gname == "zombie_tactical" or gname == "zombie_runner") and ResourceLoader.exists("res://assets/baked/%s.scn" % gname):
			continue
		var gp := "res://assets/models/%s.glb" % gname
		if ResourceLoader.exists(gp):
			glbs[gname] = load(gp)
		if Time.get_ticks_msec() - t0 >= 20:
			if hud:
				hud.set_loading_status("BODYCAM-04 // LOADING WORLD ASSETS (%d/%d)..." % [i + 1, total])
			await tree.process_frame
			t0 = Time.get_ticks_msec()

	if hud:
		hud.set_loading_status("BODYCAM-04 // LOADING MATERIALS & TEXTURES...")
	await tree.process_frame
	_build_materials()
	await tree.process_frame


func _build_materials() -> void:

	# PALE weathered plaster for Panel 6 stairwell so dark carved balusters & bold graffiti POP!
	mats["plaster"] = _make_weathered("plaster_peeling", Color(0.98, 0.96, 0.90), 0.30, 0.78, 2.05, 0.88, 0.36, 1.35, 0.30)
	mats["plaster_brick"] = _make_weathered("plaster_brick", Color(0.92, 0.90, 0.85), 0.34, 0.86, 2.35, 0.86, 0.44, 1.45, 0.36, 0.020, true)
	mats["parquet"] = _make_weathered("parquet_worn", Color(0.76, 0.70, 0.62), 0.27, 0.85, 1.55, 0.84, 0.36, 0.12, 0.14)
	mats["brick"] = _make_weathered("brick_vault", Color(0.84, 0.78, 0.72), 0.44, 1.02, 2.45, 0.78, 0.34, 1.15, 0.56, 0.026, true)
	var b_vault := (mats["brick"] as ShaderMaterial).duplicate() as ShaderMaterial
	b_vault.set_shader_parameter("use_mesh_uv", true)
	b_vault.set_shader_parameter("uv_scale", 0.46)
	b_vault.set_shader_parameter("detail_scale", 1.10)
	b_vault.set_shader_parameter("pom_depth", 0.028)
	b_vault.set_shader_parameter("is_brick", true)
	b_vault.set_meta(&"surface", "brick")
	mats["brick_vault"] = b_vault
	_pom_materials.append(b_vault)
	mats["tunnel_floor"] = _make_weathered("tunnel_rubble", Color(0.66, 0.63, 0.59), 0.52, 1.25, 2.50, 0.52, 0.28, 0.35, 0.75, 0.0, false)
	mats["concrete"] = _make_weathered("concrete_rubble", Color(0.94, 0.93, 0.90), 0.40, 0.98, 2.25, 0.68, 0.36, 0.65, 0.52, 0.014, false)
	mats["timber"] = _make_weathered("timber_weathered", Color(0.80, 0.77, 0.72), 0.40, 0.95, 2.05, 0.88, 0.42, 1.10, 0.32)
	mats["wood_carved"] = _make_pbr("wood_carved", 0.58, 0.0, Color(0.78, 0.75, 0.70), Vector3(1.0, 1.0, 1.0), 1.55, false)
	mats["tile"] = _make_pbr("tile_asylum", 0.66, 0.0, Color(0.55, 0.55, 0.52), Vector3(0.55, 0.55, 0.55), 1.5, true)
	mats["metal"] = _make_pbr("metal_tactical", 0.48, 0.78, Color(0.56, 0.58, 0.60), Vector3(1.0, 1.0, 1.0), 1.25, false)
	mats["bark"] = _make_pbr("bark_pine", 0.95, 0.0, Color(0.68, 0.65, 0.60), Vector3(1.0, 2.5, 1.0), 1.8, false)
	mats["barrel"] = _make_pbr("barrel_oak", 0.84, 0.12, Color(0.90, 0.86, 0.82), Vector3(1.0, 1.0, 1.0), 1.5, false)

	var smat := ShaderMaterial.new()
	smat.shader = load("res://shaders/wet_snow_ground.gdshader")
	smat.set_shader_parameter("snow_albedo", load("res://assets/textures/snow_clean_albedo.jpg"))
	smat.set_shader_parameter("snow_normal", load("res://assets/textures/snow_pure_normal.jpg"))
	smat.set_shader_parameter("snow_disp", load("res://assets/textures/snow_pure_disp.jpg"))
	smat.set_shader_parameter("tracks_albedo", load("res://assets/textures/powder_tracks.jpg"))
	smat.set_shader_parameter("tracks_normal", load("res://assets/textures/powder_microrelief.jpg"))
	smat.set_shader_parameter("tracks_height", load("res://assets/textures/powder_imprints.jpg"))
	smat.set_shader_parameter("mud_albedo", load("res://assets/textures/snow_mud_albedo.jpg"))
	smat.set_shader_parameter("mud_normal", load("res://assets/textures/snow_mud_normal.jpg"))
	smat.set_shader_parameter("mud_disp", load("res://assets/textures/snow_mud_disp.jpg"))
	smat.set_shader_parameter("mud_ao", load("res://assets/textures/snow_mud_ao.jpg"))
	smat.set_shader_parameter("mud_rough", load("res://assets/textures/snow_mud_rough.jpg"))
	smat.set_shader_parameter("churned_albedo", load("res://assets/textures/churned_snow.jpg"))
	smat.set_shader_parameter("churned_normal", load("res://assets/textures/churned_normal.jpg"))
	smat.set_shader_parameter("churned_height", load("res://assets/textures/churned_height.jpg"))
	mats["snow_ground"] = smat
	_pom_materials.append(smat)

	var lshade := ShaderMaterial.new()
	lshade.shader = preload("res://shaders/linen_shade.gdshader")
	mats["lamp_shade"] = lshade

	var bulb := StandardMaterial3D.new()
	bulb.albedo_color = Color(1.0, 0.94, 0.82)
	bulb.emission_enabled = true
	bulb.emission = Color(1.0, 0.88, 0.66)
	bulb.emission_energy_multiplier = 7.8
	mats["bulb_warm"] = bulb

	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.42, 0.40, 0.34)
	paper.roughness = 0.94
	mats["old_paper"] = paper

	mats["plaster"].set_meta(&"surface", "plaster")
	mats["plaster_brick"].set_meta(&"surface", "plaster")
	mats["parquet"].set_meta(&"surface", "wood")
	mats["brick"].set_meta(&"surface", "brick")
	mats["tunnel_floor"].set_meta(&"surface", "stone")
	mats["concrete"].set_meta(&"surface", "stone")
	mats["timber"].set_meta(&"surface", "wood")
	mats["wood_carved"].set_meta(&"surface", "wood")
	mats["tile"].set_meta(&"surface", "tile")
	mats["metal"].set_meta(&"surface", "metal")
	mats["bark"].set_meta(&"surface", "wood")
	mats["barrel"].set_meta(&"surface", "wood")
	mats["snow_ground"].set_meta(&"surface", "snow")
	mats["old_paper"].set_meta(&"surface", "wood")


func _make_weathered(prefix: String, tint := Color.WHITE, uv_sc := 0.32, det_sc := 0.85,
		n_depth := 1.95, r_mult := 0.86, grime := 0.46, damp_h := 1.25, wet := 0.38,
		pom_d := 0.0, brick_flag := false, mesh_uv := false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/arch_weathered.gdshader")
	mat.set_shader_parameter("albedo_tex", load("res://assets/textures/%s_albedo.jpg" % prefix))
	mat.set_shader_parameter("normal_tex", load("res://assets/textures/%s_normal.jpg" % prefix))
	mat.set_shader_parameter("rough_tex", load("res://assets/textures/%s_rough.jpg" % prefix))
	mat.set_shader_parameter("ao_tex", load("res://assets/textures/%s_ao.jpg" % prefix))
	var disp_p := "res://assets/textures/%s_disp.jpg" % prefix
	if ResourceLoader.exists(disp_p):
		mat.set_shader_parameter("disp_tex", load(disp_p))
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("uv_scale", uv_sc)
	mat.set_shader_parameter("detail_scale", det_sc)
	mat.set_shader_parameter("normal_depth", n_depth)
	mat.set_shader_parameter("roughness_mult", r_mult)
	mat.set_shader_parameter("grime_strength", grime)
	mat.set_shader_parameter("floor_damp_height", damp_h)
	mat.set_shader_parameter("wet_strength", wet)
	mat.set_shader_parameter("pom_depth", pom_d)
	mat.set_shader_parameter("is_brick", brick_flag)
	mat.set_shader_parameter("use_mesh_uv", mesh_uv)
	_pom_materials.append(mat)
	return mat


func _make_pbr(prefix: String, rough := 1.0, metal := 0.0, tint := Color.WHITE,
		uv := Vector3.ONE, n_scale := 1.3, triplanar := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/%s_albedo.jpg" % prefix)
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/%s_normal.jpg" % prefix)
	mat.normal_scale = n_scale
	mat.roughness_texture = load("res://assets/textures/%s_rough.jpg" % prefix)
	mat.roughness = rough
	mat.ao_enabled = true
	mat.ao_texture = load("res://assets/textures/%s_ao.jpg" % prefix)
	mat.ao_light_affect = 0.72
	mat.metallic = metal
	mat.albedo_color = tint
	mat.uv1_scale = uv
	mat.uv1_triplanar = triplanar
	mat.uv1_world_triplanar = triplanar
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func _add_graffiti_mural(parent: Node3D, pos: Vector3, size_xy: Vector2, rot_deg: Vector3,
		tex_name := "ward_inscriptions_0.png", alpha := 0.98) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size_xy
	mi.mesh = qm
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = load("res://assets/textures/%s" % tex_name)
	sm.albedo_color = Color(0.94, 0.92, 0.88, alpha)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.roughness = 0.94
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = sm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _infer_surface_from_key(key: String) -> String:
	var k := key.to_lower()
	if "metal" in k or "pipe" in k or "sconce" in k or "lamp" in k or "wheelchair" in k or "medical" in k or "ammo" in k or "machine" in k or "chandelier" in k or "lantern" in k or "can" in k:
		return "metal"
	if "brick" in k:
		return "brick"
	if "stone" in k or "rubble" in k or "rock" in k or "quarry" in k or "archway" in k:
		return "stone"
	if "wood" in k or "oak" in k or "desk" in k or "cabinet" in k or "chair" in k or "table" in k or "shelf" in k or "crate" in k or "door" in k or "stool" in k or "barrel" in k or "cabin" in k or "siding" in k or "porch" in k or "stair" in k or "spindle" in k or "log" in k or "tree" in k or "fir" in k or "spruce" in k or "bark" in k or "crutches" in k:
		return "wood"
	return "plaster"


func _tag_static_bodies(n: Node, surf: String) -> void:
	if n is CollisionObject3D:
		(n as CollisionObject3D).set_meta(&"surface", surf)
	for c in n.get_children():
		_tag_static_bodies(c, surf)


func _add_glb(parent: Node3D, key: String, pos: Vector3, rot := Vector3.ZERO,
		scl := Vector3.ONE, with_box_col := Vector3.ZERO, mat_override: Material = null) -> Node3D:
	if not glbs.has(key) or glbs[key] == null:
		return null
	var inst: Node3D = glbs[key].instantiate()
	inst.position = pos
	inst.rotation = rot
	inst.scale = scl
	if mat_override:
		_apply_mat_recursive(inst, mat_override)
	_optimize_glb_meshes(inst, key)
	var surf := _infer_surface_from_key(key)
	if mat_override and mat_override.has_meta(&"surface"):
		surf = str(mat_override.get_meta(&"surface"))
	_tag_static_bodies(inst, surf)
	parent.add_child(inst)
	if with_box_col != Vector3.ZERO:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.set_meta(&"surface", surf)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = with_box_col
		cs.shape = sh
		cs.position = Vector3(0, with_box_col.y * 0.5, 0)
		sb.add_child(cs)
		inst.add_child(sb)
	return inst


func _optimize_glb_meshes(root: Node, key: String) -> void:
	var no_shadow := NO_SHADOW_GLBS.has(key) or MICRO_DEBRIS_GLBS.has(key) or TREE_GLBS.has(key)
	var bias := 1.0
	var vis_end := 0.0
	var vis_margin := 0.0
	if MICRO_DEBRIS_GLBS.has(key):
		bias = MICRO_DEBRIS_GLBS[key]
		vis_end = 52.0
		vis_margin = 10.0
	elif SMALL_CLUTTER_GLBS.has(key):
		bias = SMALL_CLUTTER_GLBS[key]
		vis_end = 28.0
		vis_margin = 6.0
	elif NO_SHADOW_GLBS.has(key):
		bias = NO_SHADOW_GLBS[key]
	elif TREE_GLBS.has(key):
		bias = TREE_GLBS[key]
	elif HERO_LOD_GLBS.has(key):
		bias = HERO_LOD_GLBS[key]
	_apply_mesh_perf_recursive(root, no_shadow, bias, vis_end, vis_margin)


func _apply_mesh_perf_recursive(n: Node, no_shadow: bool, bias: float, vis_end: float, vis_margin := 0.0) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if no_shadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.lod_bias = bias
		if mi.material_override != null:
			var fixed_ov := _make_opaque_if_fake_alpha(mi.material_override)
			if fixed_ov != mi.material_override:
				mi.material_override = fixed_ov
		elif mi.mesh:
			for si in range(mi.mesh.get_surface_count()):
				var cur_m := mi.get_active_material(si)
				var fixed_m := _make_opaque_if_fake_alpha(cur_m)
				if fixed_m != cur_m:
					mi.set_surface_override_material(si, fixed_m)
		if vis_end > 0.0:
			mi.visibility_range_end = vis_end
			mi.visibility_range_end_margin = vis_margin
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		else:
			mi.visibility_range_end = 0.0
	for c in n.get_children():
		_apply_mesh_perf_recursive(c, no_shadow, bias, vis_end, vis_margin)


func _apply_mat_recursive(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		n.material_override = mat
	for c in n.get_children():
		_apply_mat_recursive(c, mat)


func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()

	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.002, 0.004, 0.008)
	sky_mat.sky_horizon_color = Color(0.018, 0.024, 0.036)
	sky_mat.ground_bottom_color = Color(0.001, 0.001, 0.002)
	sky_mat.ground_horizon_color = Color(0.004, 0.006, 0.009)
	sky_mat.sky_curve = 0.22
	sky_mat.energy_multiplier = 0.28
	sky_mat.sun_angle_max = 0.0
	sky.sky_material = sky_mat

	var is_compat := _is_compat_renderer()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.background_energy_multiplier = 0.14 if is_compat else 0.10
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.018, 0.022, 0.030) if is_compat else Color(0.008, 0.010, 0.014)
	env.ambient_light_energy = 0.055 if is_compat else 0.002
	env.ambient_light_sky_contribution = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.24 if is_compat else 1.06
	env.tonemap_agx_white = 10.5
	env.tonemap_agx_contrast = 1.28
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.94
	env.adjustment_brightness = 1.0
	env.sdfgi_enabled = false

	if is_compat:
		env.fog_enabled = true
		env.fog_light_color = Color(0.08, 0.10, 0.14)
		env.fog_density = 0.015
	else:
		env.ssao_enabled = true
		env.ssao_radius = 0.65
		env.ssao_intensity = 2.05
		env.ssao_power = 1.65
		env.ssao_horizon = 0.06
		env.ssao_light_affect = 0.42
		env.ssil_enabled = false
		env.ssil_radius = 2.5
		env.ssil_intensity = 0.88
		env.ssil_sharpness = 0.88
		env.ssil_normal_rejection = 0.90
		env.ssr_enabled = true
		env.ssr_max_steps = 12 if quality_preset <= 1 else 24
		env.ssr_fade_in = 0.18
		env.ssr_fade_out = 1.65
		env.ssr_depth_tolerance = 0.35

		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.012
		env.volumetric_fog_albedo = Color(0.26, 0.28, 0.32)
		env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
		env.volumetric_fog_emission_energy = 0.0
		env.volumetric_fog_anisotropy = 0.65
		env.volumetric_fog_length = 38.0
		env.volumetric_fog_detail_spread = 2.0

	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.48
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.75
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

	world_env.environment = env
	add_child(world_env)

	moon_light = DirectionalLight3D.new()
	moon_light.light_color = Color(0.46, 0.58, 0.82)
	moon_light.light_energy = 0.24
	moon_light.light_volumetric_fog_energy = 0.06
	moon_light.light_bake_mode = Light3D.BAKE_DISABLED
	moon_light.shadow_enabled = false
	moon_light.visible = false
	moon_light.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	add_child(moon_light)

	lightning_light = DirectionalLight3D.new()
	lightning_light.light_color = Color(0.72, 0.82, 1.0)
	lightning_light.light_energy = 0.0
	lightning_light.light_volumetric_fog_energy = 0.0
	lightning_light.light_bake_mode = Light3D.BAKE_DISABLED
	lightning_light.shadow_enabled = false
	lightning_light.visible = false
	lightning_light.rotation_degrees = Vector3(-42.0, 22.0, 0.0)
	add_child(lightning_light)


func set_daylight_mode(enabled: bool) -> void:
	daylight_mode = enabled
	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial if (env.sky != null) else null
	var is_compat := _is_compat_renderer()
	if daylight_mode:
		if sky_mat:
			sky_mat.sky_top_color = Color(0.18, 0.34, 0.58)
			sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.86)
			sky_mat.ground_bottom_color = Color(0.28, 0.32, 0.38)
			sky_mat.ground_horizon_color = Color(0.56, 0.62, 0.70)
			sky_mat.sky_curve = 0.16
			sky_mat.energy_multiplier = 1.15
			sky_mat.sun_angle_max = 18.0
		env.background_energy_multiplier = 1.05
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.78
		env.ambient_light_energy = 0.78
		env.tonemap_exposure = 0.80 if not is_compat else 0.94
		if is_compat:
			env.fog_enabled = true
			env.fog_light_color = Color(0.68, 0.75, 0.84)
			env.fog_density = 0.005
		else:
			env.volumetric_fog_density = 0.0032
			env.volumetric_fog_albedo = Color(0.76, 0.82, 0.90)
			env.volumetric_fog_length = 68.0
		if moon_light:
			moon_light.visible = true
			moon_light.light_color = Color(1.0, 0.94, 0.84)
			moon_light.light_energy = 2.45
			moon_light.light_volumetric_fog_energy = 0.35
			moon_light.shadow_enabled = not is_compat
			moon_light.shadow_blur = 1.4
			moon_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			moon_light.directional_shadow_max_distance = 75.0
			moon_light.rotation_degrees = Vector3(-34.0, 128.0, 0.0)
	else:
		if sky_mat:
			sky_mat.sky_top_color = Color(0.002, 0.004, 0.008)
			sky_mat.sky_horizon_color = Color(0.018, 0.024, 0.036)
			sky_mat.ground_bottom_color = Color(0.001, 0.001, 0.002)
			sky_mat.ground_horizon_color = Color(0.004, 0.006, 0.009)
			sky_mat.sky_curve = 0.22
			sky_mat.energy_multiplier = 0.28
			sky_mat.sun_angle_max = 0.0
		env.background_energy_multiplier = 0.14 if is_compat else 0.10
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.018, 0.022, 0.030) if is_compat else Color(0.008, 0.010, 0.014)
		env.ambient_light_energy = 0.055 if is_compat else 0.002
		env.ambient_light_sky_contribution = 0.0
		env.tonemap_exposure = 1.24 if is_compat else 1.06
		if is_compat:
			env.fog_enabled = true
			env.fog_light_color = Color(0.08, 0.10, 0.14)
			env.fog_density = 0.015
		else:
			env.volumetric_fog_density = 0.012
			env.volumetric_fog_albedo = Color(0.26, 0.28, 0.32)
			env.volumetric_fog_length = 38.0
		if moon_light:
			moon_light.visible = false
			moon_light.shadow_enabled = false


func _ensure_fog_noise() -> NoiseTexture3D:
	if _fog_noise_3d == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.055
		fn.fractal_octaves = 3
		var nt := NoiseTexture3D.new()
		nt.width = 48
		nt.height = 32
		nt.depth = 48
		nt.seamless = true
		nt.noise = fn
		_fog_noise_3d = nt
	return _fog_noise_3d


func _add_fog_volume(parent: Node3D, pos: Vector3, size: Vector3, albedo: Color, density: float) -> void:
	if _is_compat_renderer():
		return
	var fv := FogVolume.new()
	fv.size = size
	fv.position = pos
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/drifting_fog.gdshader")
	sm.set_shader_parameter("noise_tex", _ensure_fog_noise())
	sm.set_shader_parameter("fog_albedo", Vector3(albedo.r, albedo.g, albedo.b))
	sm.set_shader_parameter("base_density", density)
	sm.set_shader_parameter("floor_hug", 0.85)
	fv.material = sm
	parent.add_child(fv)


func _add_reflection_probe(parent: Node3D, pos: Vector3, size: Vector3, interior: bool, intensity := 1.15) -> ReflectionProbe:
	var rp := ReflectionProbe.new()
	var world_pos := pos
	var cur: Node3D = parent
	while cur != null and cur != self:
		world_pos = cur.transform * world_pos
		cur = cur.get_parent() as Node3D
	rp.position = world_pos
	rp.size = size
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.box_projection = true
	rp.enable_shadows = false
	rp.interior = interior
	rp.intensity = intensity
	rp.cull_mask = 1
	rp.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	rp.ambient_color = Color(0.14, 0.11, 0.08) if interior else Color(0.05, 0.07, 0.11)
	rp.ambient_color_energy = 0.07 if interior else 0.10
	add_child(rp)
	reflection_probes.append(rp)
	return rp


func _add_box_multimesh(parent: Node3D, transforms: Array[Transform3D], size: Vector3, mat: Material, cast_shadow := false) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.lod_bias = 0.95
	parent.add_child(mmi)
	return mmi


func _collect_glb_part_meshes(n: Node, rel_xf: Transform3D, out: Array[Dictionary]) -> void:
	var cur_xf := rel_xf * (n as Node3D).transform if (n is Node3D and n != null) else rel_xf
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			out.append({"mesh": mi.mesh, "xf": cur_xf, "mat": mi.material_override})
	for c in n.get_children():
		_collect_glb_part_meshes(c, cur_xf, out)


func _get_fixed_opaque_mesh(msh: Mesh) -> Mesh:
	if msh == null:
		return null
	var iid := msh.get_instance_id()
	if _opaque_mesh_cache.has(iid):
		return _opaque_mesh_cache[iid]
	var needs_fix := false
	for si in range(msh.get_surface_count()):
		var sm := msh.surface_get_material(si)
		if sm != null and _make_opaque_if_fake_alpha(sm) != sm:
			needs_fix = true
			break
	if not needs_fix:
		_opaque_mesh_cache[iid] = msh
		return msh
	var d_msh := msh.duplicate() as Mesh
	for si in range(d_msh.get_surface_count()):
		var sm := d_msh.surface_get_material(si)
		if sm != null:
			var fixed := _make_opaque_if_fake_alpha(sm)
			if fixed != sm:
				d_msh.surface_set_material(si, fixed)
	_opaque_mesh_cache[iid] = d_msh
	return d_msh


func _add_glb_multimesh(parent: Node3D, key: String, transforms: Array[Transform3D],
		mat_override: Material = null, lod_bias := 0.90, out_mmis: Array[MultiMeshInstance3D] = []) -> void:
	if transforms.is_empty() or not glbs.has(key) or glbs[key] == null:
		return
	var tmpl: Node3D = glbs[key].instantiate()
	var parts: Array[Dictionary] = []
	_collect_glb_part_meshes(tmpl, Transform3D.IDENTITY, parts)
	tmpl.free()
	for p in parts:
		var msh: Mesh = _get_fixed_opaque_mesh(p["mesh"])
		var local_xf: Transform3D = p["xf"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = msh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i] * local_xf)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.lod_bias = lod_bias
		if mat_override:
			mmi.material_override = _make_opaque_if_fake_alpha(mat_override)
		elif p["mat"] != null:
			mmi.material_override = _make_opaque_if_fake_alpha(p["mat"])
		parent.add_child(mmi)
		out_mmis.append(mmi)


func _add_glb_spatial_chunks(parent: Node3D, key: String, transforms: Array[Transform3D],
		mat_override: Material = null, lod_bias := 1.35) -> void:
	if transforms.is_empty():
		return
	var cell_sz := 14.0 if _is_compat_renderer() else 8.0
	var cells := {}
	for xf in transforms:
		var c := Vector2i(int(floor(xf.origin.x / cell_sz)), int(floor(xf.origin.z / cell_sz)))
		if not cells.has(c):
			var arr: Array[Transform3D] = []
			cells[c] = arr
		(cells[c] as Array[Transform3D]).append(xf)
	for c in cells.keys():
		var cell_xfs: Array[Transform3D] = cells[c]
		var min_x := INF
		var max_x := -INF
		var sum_x := 0.0
		var sum_z := 0.0
		for xf in cell_xfs:
			min_x = minf(min_x, xf.origin.x)
			max_x = maxf(max_x, xf.origin.x)
			sum_x += xf.origin.x
			sum_z += xf.origin.z
		var avg_x := sum_x / float(cell_xfs.size())
		var avg_z := sum_z / float(cell_xfs.size())
		var chunk_mmis: Array[MultiMeshInstance3D] = []
		_add_glb_multimesh(parent, key, cell_xfs, mat_override, lod_bias, chunk_mmis)
		if max_x < -6.0:
			_tree_bucket_left.append_array(chunk_mmis)
		elif min_x > 6.0:
			_tree_bucket_right.append_array(chunk_mmis)
		if avg_z < -56.0 or absf(avg_x) > 18.0:
			for mmi in chunk_mmis:
				mmi.visibility_range_end = 58.0
				mmi.visibility_range_end_margin = 10.0
				mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material,
		rot := Vector3.ZERO, with_collision := true, col_layer := 1) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if with_collision else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if with_collision:
		var sb := StaticBody3D.new()
		sb.collision_layer = col_layer
		var surf := "plaster"
		if mat != null and mat.has_meta(&"surface"):
			surf = str(mat.get_meta(&"surface"))
		sb.set_meta(&"surface", surf)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


func _add_mesh(parent: Node3D, mesh_key: String, pos: Vector3, mat: Material,
		rot := Vector3.ZERO, scl := Vector3.ONE, with_box_col := Vector3.ZERO) -> MeshInstance3D:
	if not meshes.has(mesh_key):
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[mesh_key]
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	if with_box_col != Vector3.ZERO:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		var surf := "plaster"
		if mat != null and mat.has_meta(&"surface"):
			surf = str(mat.get_meta(&"surface"))
		sb.set_meta(&"surface", surf)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = with_box_col
		cs.shape = sh
		cs.position = Vector3(0, with_box_col.y * 0.5, 0)
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


func _build_asylum_lobby() -> void:
	var g := Node3D.new()
	g.name = "AsylumLobby"
	lobby_group = g
	add_child(g)

	var parquet := ShaderMaterial.new()
	parquet.shader = preload("res://shaders/salvaged_parquet.gdshader")
	parquet.set_shader_parameter("oak", preload("res://assets/models/herringbone_blocks_SalvagedOakalbedo.jpg"))
	parquet.set_shader_parameter("grain", preload("res://assets/models/herringbone_blocks_SalvagedOaknormal.jpg"))
	parquet.set_shader_parameter("silt", preload("res://assets/textures/mud_rocks_albedo.jpg"))
	_add_glb(g, "herringbone_blocks", Vector3.ZERO, Vector3.ZERO, Vector3.ONE, Vector3.ZERO, parquet)
	var lobby_fl := _add_box(g, Vector3(0, -0.15, 0), Vector3(20.4, 0.3, 16.4), mats["parquet"])
	if lobby_fl:
		lobby_fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_add_box(g, Vector3(3.2, 7.15, 0.0), Vector3(14.0, 0.3, 16.4), mats["plaster"])
	_add_box(g, Vector3(-6.9, 7.15, 5.4), Vector3(6.6, 0.3, 5.6), mats["plaster"])
	# Pale dusty peeling plaster across the 3-story stairwell shaft so dark carved balusters & bold graffiti POP!
	_add_box(g, Vector3(-6.9, 11.15, -2.5), Vector3(7.4, 0.3, 11.4), mats["plaster"])
	_add_box(g, Vector3(-10.15, 9.1, -2.5), Vector3(0.35, 4.4, 11.4), mats["plaster"])
	_add_box(g, Vector3(-6.9, 9.1, -8.15), Vector3(7.4, 4.4, 0.35), mats["plaster"])
	_add_box(g, Vector3(-3.65, 9.1, -2.5), Vector3(0.35, 4.4, 11.4), mats["plaster"])
	_add_box(g, Vector3(-6.9, 9.1, 2.85), Vector3(7.4, 4.4, 0.35), mats["plaster"])

	_add_box(g, Vector3(0, 3.5, 8.15), Vector3(20.4, 7.2, 0.35), mats["plaster"])
	# West stairwell wall uses PALE peeling plaster so bold layered graffiti & water leaks stand out crisply (Ref #3!)
	_add_box(g, Vector3(-10.15, 3.5, 0), Vector3(0.35, 7.2, 16.4), mats["plaster"])

	_add_box(g, Vector3(10.15, 3.5, -6.2), Vector3(0.4, 7.2, 3.8), mats["plaster_brick"])
	_add_box(g, Vector3(10.15, 3.5, -1.6), Vector3(0.4, 7.2, 1.3), mats["plaster_brick"])
	_add_box(g, Vector3(10.15, 3.5, 4.8), Vector3(0.4, 7.2, 6.6), mats["plaster"])
	for wz: float in [-3.4, 0.25]:
		_add_box(g, Vector3(10.15, 0.9, wz), Vector3(0.4, 1.8, 2.5), mats["plaster"])
		_add_box(g, Vector3(10.15, 5.9, wz), Vector3(0.4, 2.4, 2.5), mats["plaster_brick"])
		_add_glb(g, "arched_window", Vector3(9.95, 1.80, wz), Vector3(0, -PI * 0.5, 0), Vector3(1.15, 1.15, 1.15))

	_add_glb(g, "ornate_door", Vector3(9.86, 0.0, 3.25), Vector3(0, -PI * 0.5, 0), Vector3(0.95, 1.02, 0.95))
	_add_box(g, Vector3(9.86, 1.65, 2.18), Vector3(0.24, 3.3, 0.22), mats["wood_carved"], Vector3.ZERO, false)
	_add_box(g, Vector3(9.86, 1.65, 4.32), Vector3(0.24, 3.3, 0.22), mats["wood_carved"], Vector3.ZERO, false)
	_add_box(g, Vector3(9.86, 3.38, 3.25), Vector3(0.26, 0.26, 2.42), mats["wood_carved"], Vector3.ZERO, false)

	_add_box(g, Vector3(-6.1, 3.5, -8.15), Vector3(8.0, 7.2, 0.4), mats["plaster"])
	_add_box(g, Vector3(6.1, 3.5, -8.15), Vector3(8.0, 7.2, 0.4), mats["plaster_brick"])
	_add_box(g, Vector3(0.0, 5.35, -8.15), Vector3(4.4, 3.5, 0.4), mats["plaster"])
	_add_box(g, Vector3(-2.15, 1.8, -7.95), Vector3(0.26, 3.6, 0.28), mats["wood_carved"])
	_add_box(g, Vector3(2.15, 1.8, -7.95), Vector3(0.26, 3.6, 0.28), mats["wood_carved"])
	_add_box(g, Vector3(0.0, 3.62, -7.95), Vector3(4.6, 0.28, 0.30), mats["wood_carved"])

	_add_box(g, Vector3(9.88, 0.72, 0.0), Vector3(0.14, 1.44, 15.8), mats["wood_carved"], Vector3.ZERO, false)
	_add_box(g, Vector3(9.82, 1.46, 0.0), Vector3(0.22, 0.11, 15.8), mats["wood_carved"], Vector3.ZERO, false)
	_add_box(g, Vector3(0.0, 0.72, 7.88), Vector3(19.8, 1.44, 0.14), mats["wood_carved"], Vector3.ZERO, false)
	for pz in [-7.2, -5.2, -1.6, 1.9, 5.5, 7.5]:
		_add_box(g, Vector3(9.82, 3.5, pz), Vector3(0.26, 7.0, 0.34), mats["wood_carved"], Vector3.ZERO, false)
	for cz in [-4.5, 0.0, 4.5]:
		_add_box(g, Vector3(3.1, 6.85, cz), Vector3(13.8, 0.34, 0.34), mats["wood_carved"], Vector3.ZERO, false)

	_add_graffiti_mural(g, Vector3(9.92, 4.65, -3.2), Vector2(4.2, 3.2), Vector3(0, -90, 0), "ward_inscriptions_0.png", 0.58)
	_add_graffiti_mural(g, Vector3(4.5, 4.2, -7.90), Vector2(6.4, 4.0), Vector3(0, 0, 0), "ward_inscriptions_1.png", 0.48)

	# Salvaged sash windows, raised dado and cracked plaster share one continuous wall.
	_add_glb(g, "admissions_gallery", Vector3(6.79,0,-2.20), Vector3.ZERO, Vector3(1.25,1.66,1.06))
	_add_box(g, Vector3(6.88,0.79,-2.20), Vector3(0.14,1.58,9.68), mats["wood_carved"]).visible = false
	_add_glb(g, "stripped_plaster", Vector3(2.50,0.1,-7.78), Vector3(0,PI/2,0), Vector3(0.64,0.87,0.76))
	# Missing plaster from the window bays exposes the brick and joists behind them.
	_add_box(g, Vector3(6.94,2.93,-1.36), Vector3(0.28,2.64,2.19), mats["plaster_brick"])
	_add_box(g, Vector3(6.94,5.65,-2.20), Vector3(0.28,2.90,9.68), mats["plaster"])
	_add_glb(g, "broken_lime_plaster", Vector3(6.77,2.91,-1.38), Vector3(0,-PI/2.0,-0.04), Vector3(0.51,0.79,1.25))
	_add_box(g, Vector3(6.91,4.20,-2.2), Vector3(0.32,0.22,9.68), mats["wood_carved"])
	_add_graffiti_mural(g, Vector3(6.69,2.97,-1.46), Vector2(1.87,2.34),Vector3(0,-90,0),"seeping_plaster.png",0.67)
	# A paneled return encloses the records passage full-height to the ceiling (zero movie-set cutout seam).
	for bay in range(4):
		_add_glb(g, "oak_dado", Vector3(3.39 + bay * 1.19,0,1.57), Vector3(0,PI/2,0))
	_add_box(g, Vector3(4.95,1.73,1.76), Vector3(4.45,3.46,0.20), mats["plaster"])
	_add_box(g, Vector3(4.95,5.25,1.76), Vector3(4.45,3.65,0.24), mats["plaster"])
	_add_box(g, Vector3(2.72,3.55,1.64), Vector3(0.28,7.10,0.30), mats["wood_carved"])
	_add_glb(g, "ward_door", Vector3(2.69,0,1.54), Vector3(0,-0.93,0), Vector3(0.92,1.39,1.0))
	for bay in range(6):
		_add_glb(g, "oak_dado", Vector3(2.84 + bay * 1.19, 0, -7.81), Vector3(0, -PI / 2.0, 0))
	var desk := _add_glb(g, "reception_desk_aaa", Vector3(4.25, 0.0, -2.53), Vector3(0, -2.52, 0), Vector3.ONE, Vector3(3.6, 1.12, 2.2))
	if desk:
		var lamp_idx := 0
		for ang_f: float in [-0.36 * PI, 0.24 * PI]:
			var lp := Vector3(cos(ang_f) * 1.80, 1.105, -sin(ang_f) * 1.80)
			var lb := _add_mesh(desk, "lamp_base", lp, mats["wood_carved"], Vector3.ZERO, Vector3(1.05, 1.05, 1.05))
			if lb:
				lb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var ls := _add_mesh(desk, "lamp_shade", lp, mats["lamp_shade"], Vector3.ZERO, Vector3(1.05, 1.05, 1.05))
			if ls:
				ls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var lgt := OmniLight3D.new()
			lgt.light_color = Color(1.0, 0.823, 0.61)
			lgt.light_energy = 10.7
			lgt.light_specular = 0.18
			lgt.light_indirect_energy = 1.45
			lgt.light_volumetric_fog_energy = 0.45
			lgt.set_meta("keep_vol_fog", true)
			lgt.omni_range = 12.8
			lgt.omni_attenuation = 1.92
			lgt.shadow_enabled = (lamp_idx == 0)
			lgt.light_bake_mode = Light3D.BAKE_STATIC
			lgt.shadow_bias = 0.025
			lgt.position = lp + Vector3(0, 0.44, 0)
			desk.add_child(lgt)
			lamp_idx += 1

		_add_glb(desk, "registration_machine", Vector3(1.34, 1.14, 1.15), Vector3(0, 1.74, 0), Vector3.ONE)
		_add_glb(desk, "books_set", Vector3(cos(-0.08 * PI) * 1.82, 1.11, -sin(-0.08 * PI) * 1.82), Vector3(0, 0.4, 0), Vector3(1.0, 1.0, 1.0))
		_add_glb(desk, "binder_notebook", Vector3(cos(0.06 * PI) * 1.82, 1.11, -sin(0.06 * PI) * 1.82), Vector3(0, -0.35, 0), Vector3(1.1, 1.1, 1.1))
		_add_glb(desk, "clipboard", Vector3(cos(-0.20 * PI) * 1.86, 1.11, -sin(-0.20 * PI) * 1.86), Vector3(0, 0.85, 0), Vector3(1.1, 1.1, 1.1))

	_add_reflection_probe(g, Vector3(1.5, 3.2, -1.0), Vector3(22.0, 8.0, 18.0), true, 1.15)
	_add_glb(g, "folding_wooden_stool", Vector3(2.63,0.32,-0.65), Vector3(1.27,0.64,0.60), Vector3.ONE * 1.55)
	_add_glb(g, "drawer_cabinet", Vector3(6.13,0.0,-2.08), Vector3(0,-1.31,0), Vector3.ONE * 1.17)
	_add_glb(g, "splinter_heap", Vector3(3.97,-0.067,0.24), Vector3(0,-0.68,0), Vector3(0.48,0.36,0.6))
	# Dense foreground debris around overturned stool & parquet floor (breaks up clean floor look!)
	_add_glb(g, "books_set", Vector3(1.45, 0.0, -0.45), Vector3(0.08, 0.82, -0.05), Vector3(1.1, 1.1, 1.1))
	_add_glb(g, "binder_notebook", Vector3(2.95, 0.0, 0.25), Vector3(0, -0.65, 0), Vector3(1.2, 1.2, 1.2))
	_add_glb(g, "bark_debris", Vector3(1.75, 0.01, -1.65), Vector3(0, 1.2, 0), Vector3(1.4, 1.1, 1.4))
	_add_glb(g, "bark_debris", Vector3(3.45, 0.01, 0.55), Vector3(0, 2.4, 0), Vector3(1.3, 1.1, 1.3))

	_add_glb(g, "folding_wooden_stool", Vector3(2.05, 0.24, -0.82), Vector3(1.48, 0.62, 0.18), Vector3(1.18, 1.18, 1.18))
	_add_glb(g, "wooden_chair", Vector3(4.95, 0.0, -3.55), Vector3(0, -2.4, 0), Vector3(1.05, 1.05, 1.05))
	_add_glb(g, "wooden_chair", Vector3(-1.45, 0.28, -4.25), Vector3(1.52, 0.75, 0.12), Vector3(1.04, 1.04, 1.04))

	_add_glb(g, "gothic_cabinet", Vector3(8.95, 0.0, -4.95), Vector3(0, -PI * 0.5, 0), Vector3(1.12, 1.12, 1.12), Vector3(1.4, 2.2, 0.7))
	_add_glb(g, "drawer_cabinet", Vector3(9.10, 0.0, -2.35), Vector3(0, -PI * 0.5, 0), Vector3(1.22, 1.22, 1.22), Vector3(1.2, 1.5, 0.6))
	_add_glb(g, "vintage_cabinet", Vector3(9.05, 0.0, 0.45), Vector3(0, -PI * 0.5, 0), Vector3(1.15, 1.15, 1.15), Vector3(1.2, 1.6, 0.6))
	_add_glb(g, "wooden_bookshelf", Vector3(7.10, 0.0, -7.45), Vector3(0, 0, 0), Vector3(1.12, 1.12, 1.12), Vector3(1.4, 2.1, 0.5))

	_add_glb(g, "wheelchair", Vector3(6.65, 0.0, -0.55), Vector3(0, -2.15, 0), Vector3(1.05, 1.05, 1.05))
	_add_glb(g, "medical_box", Vector3(5.65, 0.0, 0.85), Vector3(0, 0.42, 0), Vector3(1.25, 1.25, 1.25))
	_add_glb(g, "cardboard_box", Vector3(4.95, 0.0, 1.35), Vector3(0, -0.35, 0), Vector3(1.18, 1.18, 1.18))
	_add_glb(g, "cardboard_box", Vector3(7.45, 0.0, -2.15), Vector3(0, 0.25, 0), Vector3(1.15, 1.15, 1.15))
	_add_glb(g, "wooden_crate", Vector3(7.65, 0.0, 1.25), Vector3(0, 0.18, 0), Vector3(1.05, 1.05, 1.05))
	_add_glb(g, "trashbag", Vector3(-2.85, 0.0, -5.85), Vector3(0, 0.8, 0), Vector3(1.15, 1.15, 1.15))
	_add_glb(g, "trash_can", Vector3(5.85, 0.0, -4.45), Vector3(0, 0, 0), Vector3(1.1, 1.1, 1.1))
	_add_glb(g, "vintage_crutches", Vector3(8.55, 0.0, 2.15), Vector3(0.22, -1.2, 0.08), Vector3(1.1, 1.1, 1.1))
	_add_glb(g, "picture_frame", Vector3(9.88, 3.25, -5.55), Vector3(0, -PI * 0.5, 0.09), Vector3(1.45, 1.45, 1.45))
	_add_glb(g, "picture_frame", Vector3(6.25, 3.35, -7.88), Vector3(0, 0, -0.06), Vector3(1.35, 1.35, 1.35))
	_add_glb(g, "wooden_table", Vector3(6.8, 0.0, 4.9), Vector3(0, 0.08, 0), Vector3(1.25, 1.15, 1.25), Vector3(1.4, 0.8, 1.0))
	_add_glb(g, "chandelier", Vector3(1.6, 5.15, -1.5), Vector3.ZERO, Vector3(1.35, 1.35, 1.35))
	_add_glb(g, "hanging_industrial_lamp", Vector3(-2.4, 5.45, -3.5), Vector3.ZERO, Vector3(1.25, 1.25, 1.25))

	var rng := RandomNumberGenerator.new()
	rng.seed = 1609
	var wood_xforms: Array[Transform3D] = []
	var paper_xforms: Array[Transform3D] = []
	for _i in range(30):
		var px := rng.randf_range(-3.4, 8.2)
		var pz := rng.randf_range(-6.4, 5.2)
		if px > 2.2 and px < 5.6 and pz > -3.8 and pz < -0.5:
			continue
		if rng.randf() < 0.65:
			var sc := Vector3(rng.randf_range(0.09, 0.16), 0.022, rng.randf_range(0.36, 0.90))
			var b := Basis.from_euler(Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(0, TAU), rng.randf_range(-0.05, 0.05))).scaled(sc)
			wood_xforms.append(Transform3D(b, Vector3(px, 0.016, pz)))
		else:
			var sc := Vector3(rng.randf_range(0.18, 0.28), 0.005, rng.randf_range(0.24, 0.34))
			var b := Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), 0)).scaled(sc)
			paper_xforms.append(Transform3D(b, Vector3(px, 0.008, pz)))
	var mm_wood := _add_box_multimesh(g, wood_xforms, Vector3.ONE, mats["wood_carved"], false)
	var mm_paper := _add_box_multimesh(g, paper_xforms, Vector3.ONE, mats["old_paper"], false)
	for mm_clutter in [mm_wood, mm_paper]:
		if mm_clutter:
			mm_clutter.visibility_range_end = 24.0
			mm_clutter.visibility_range_end_margin = 5.0
			mm_clutter.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

	# Curled ledger leaves collect against the overturned stool and the foot of the counter.
	var leaf := PlaneMesh.new()
	leaf.size = Vector2(0.22, 0.31)
	leaf.subdivide_width = 6
	leaf.subdivide_depth = 8
	var paper_mesh := ArrayMesh.new()
	var arrays := leaf.get_mesh_arrays()
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for j in points.size():
		var v := points[j]
		v.y = pow(maxf(0, v.x * 6.0 + v.z * 2.6), 2.8) * 0.045
		points[j] = v
	arrays[Mesh.ARRAY_VERTEX] = points
	paper_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var paper_mat := StandardMaterial3D.new()
	paper_mat.albedo_texture = preload("res://assets/textures/admissions_ledger.jpg")
	paper_mat.roughness = 0.96
	paper_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper_mesh.surface_set_material(0, paper_mat)
	for center: Vector3 in [Vector3(1.9,0.055,-0.84), Vector3(3.45,0.061,0.41), Vector3(1.86,0.057,-3.38)]:
		for sheet in range(5):
			var page := MeshInstance3D.new()
			page.mesh = paper_mesh
			page.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			page.position = center + Vector3(rng.randfn(0, 0.42), sheet * 0.002, rng.randfn(0, 0.48))
			page.rotation.y = rng.randf_range(-PI, PI)
			page.scale = Vector3.ONE * rng.randf_range(0.9, 1.21)
			page.visibility_range_end = 24.0
			page.visibility_range_end_margin = 5.0
			page.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			g.add_child(page)
		_add_glb(g, "plaster_fall", center + Vector3(0.37,-0.065,0.32), Vector3(0, rng.randf_range(0,TAU),0), Vector3(0.32,0.16,0.37))
	var power_l := OmniLight3D.new()
	power_l.light_color = Color(1.0, 0.88, 0.72)
	power_l.light_energy = 0.0
	power_l.visible = false
	power_l.omni_range = 18.0
	power_l.shadow_enabled = false
	power_l.position = Vector3(1.6, 4.9, -1.5)
	g.add_child(power_l)
	asylum_power_lights.append(power_l)

	spawn_points.append(Vector3(8.2, 0.1, 5.2))
	spawn_points.append(Vector3(-7.4, 0.1, 5.8))
	spawn_points.append(Vector3(5.6, 0.1, -6.8))


func _build_grand_staircase() -> void:
	"""Sculpted 3-story weathered-oak Victorian staircase + PALE peeling plaster + BOLD layered graffiti (Ref #3!)."""
	var g := Node3D.new()
	g.name = "GrandStaircase"
	g.position.x = -0.46
	staircase_group = g
	add_child(g)
	_add_reflection_probe(g, Vector3(-6.5, 4.5, -2.0), Vector3(10.0, 11.0, 14.0), true, 1.15)

	_add_glb(g, "grand_staircase_aaa", Vector3.ZERO, Vector3.ZERO, Vector3.ONE)

	# Enclose the back of the return. Its stained plaster follows the incline overhead.
	for bay in range(7):
		var height := 3.26 + bay * 0.37
		_add_box(g, Vector3(-7.16 + bay * 0.57, height * 0.5, -2.85), Vector3(0.579, height, 0.19), mats["plaster"])
	_add_graffiti_mural(g, Vector3(-5.39, 2.04, -2.742), Vector2(3.71, 3.51), Vector3.ZERO, "ward_inscriptions_1.png", 0.73)
	_add_graffiti_mural(g, Vector3(-4.8, 2.05, -2.739), Vector2(2.46, 3.79), Vector3.ZERO, "spalled_brick.png", 0.41)
	# Plastered soffit and a walkable ramp under the transverse return flight.
	var return_slope := atan2(3.38, 4.52)
	_add_box(g, Vector3(-5.59, 5.01, -2.66), Vector3(5.69, 0.24, 2.13), mats["plaster"], Vector3(0, 0, return_slope))
	_add_box(g, Vector3(-3.12, 6.86, -2.66), Vector3(0.68, 0.28, 2.18), mats["wood_carved"])
	_add_glb(g, "ornate_door", Vector3(-7.60, 3.58, -7.91), Vector3.ZERO, Vector3(1.10, 1.18, 1.10))
	# A closed flight of sagging oak treads turns into the original return landing.
	var flight := Node3D.new()
	flight.position = Vector3(-7.52, 0.0, 3.62)
	flight.rotation.y = 0.014
	flight.scale.x = 1.04
	g.add_child(flight)
	_add_glb(flight, "worn_oak_flight", Vector3.ZERO)
	# The landing returns above the service passage, exposing the plaster soffit below its rail.
	var upper_flight := Node3D.new()
	upper_flight.position = Vector3(-4.81,3.50,-1.50)
	upper_flight.rotation.y = PI
	upper_flight.scale = Vector3(0.78,0.95,1.03)
	g.add_child(upper_flight)
	_add_glb(upper_flight, "worn_oak_flight", Vector3.ZERO)
	_add_box(upper_flight, Vector3(0,1.06,-2.12), Vector3(2.82,1.15,5.66), mats["plaster"], Vector3(atan2(0.219,0.284),0,0)).visible = false
	_add_box(g, Vector3(-5.92,3.37,-1.95), Vector3(4.91,0.25,1.32), mats["wood_carved"])
	_add_box(g, Vector3(-4.79,6.71,3.53), Vector3(2.40,0.28,1.23), mats["plaster"])
	var landing_key := SpotLight3D.new()
	landing_key.light_color = Color(1.0,0.79,0.56)
	landing_key.light_energy = 12.3
	landing_key.spot_angle = 51
	landing_key.spot_range = 7.5
	landing_key.shadow_enabled = true
	landing_key.light_bake_mode = Light3D.BAKE_STATIC
	g.add_child(landing_key)
	landing_key.look_at_from_position(g.to_global(Vector3(-6.94,6.67,-0.83)),g.to_global(Vector3(-4.7,5.26,0.73)))
	var stair_rng := RandomNumberGenerator.new()
	stair_rng.seed = 1967
	for step in range(0, 16, 2):
		var front := -step * 0.284
		var top := (step + 1) * 0.219
		for chip in range(stair_rng.randi_range(1, 2)):
			var side := -1.0 if stair_rng.randf() < 0.75 else 1.0
			var chip_pos := Vector3(side * stair_rng.randf_range(0.78, 1.31), top - 0.004, front - stair_rng.randf_range(0.034, 0.24))
			var size := stair_rng.randf_range(0.042, 0.132)
			_add_glb(flight, "rubble_boulder", chip_pos, Vector3(0.1, stair_rng.randf_range(0, TAU), 0.07), Vector3(size, size * 0.24, size * 0.65))
	_add_glb(g, "broken_lime_plaster", Vector3(-9.502, 4.17, -0.63), Vector3(-0.07, PI / 2.0, 0.015), Vector3(1.10, 1.05, 1.0))
	_add_graffiti_mural(g, Vector3(-7.03, 7.19, -7.90), Vector2(3.70, 3.05), Vector3.ZERO, "spalled_brick.png", 0.95)
	_add_glb(g, "landing_portal", Vector3(-7.86, 3.49, -3.16), Vector3(0, PI, 0), Vector3(1.12, 1.06, 0.96))
	_add_box(g, Vector3(-8.25, 5.53, -3.58), Vector3(3.28, 4.10, 0.38), mats["plaster_brick"])
	# Oak paneling and a continuous cornice along the return landing.
	# A strip of delaminating wall leaves a rough edge under the return balcony.
	_add_glb(g, "broken_spandrel", Vector3(-5.69, 0.23, -2.71), Vector3(0.04, 0.02, -0.07), Vector3(1.13, 1.58, 0.48))
	for panel in range(5):
		var z := -4.6 - panel * 0.65
		_add_box(g, Vector3(-9.38, 4.17, z), Vector3(0.14, 1.2, 0.58), mats["wood_carved"], Vector3.ZERO, false)
	_add_box(g, Vector3(-9.32, 4.8, -5.91), Vector3(0.24, 0.12, 3.37), mats["wood_carved"], Vector3.ZERO, false)
	_add_glb(g, "picture_frame", Vector3(-9.35, 4.11, -0.31), Vector3(0.12, PI * 0.5, -0.08), Vector3.ONE * 1.42)
	# A narrow upper landing wraps the stairwell and reveals a second row of spindles.
	# Service passage beside the return flight, framed by a plaster pier and a lintel.
	_add_box(g, Vector3(-3.54, 2.38, -2.31), Vector3(0.34, 4.76, 2.41), mats["plaster"])
	_add_box(g, Vector3(-3.54, 3.79, -0.06), Vector3(0.34, 2.01, 2.11), mats["plaster"])
	_add_box(g, Vector3(-3.54, 2.36, 1.54), Vector3(0.34, 4.72, 1.11), mats["plaster"])
	_add_glb(g, "broken_lime_plaster", Vector3(-3.721, 2.74, -2.34), Vector3(0.02, -PI / 2.0, -0.07), Vector3(0.60, 0.89, 1.0))
	_add_graffiti_mural(g, Vector3(-3.746, 1.91, -2.18), Vector2(2.08, 2.22), Vector3(0, -90, 0), "ward_inscriptions_1.png", 0.57)
	_add_graffiti_mural(g, Vector3(-3.732,2.05,1.52), Vector2(1.48,2.85), Vector3(0,-90,0), "ward_inscriptions_1.png", 0.95)
	_add_glb(g, "stripped_plaster", Vector3(-3.84,0.03,-1.95), Vector3(0,-0.035,0), Vector3(0.42,0.94,0.79))
	_add_glb(g, "splinter_heap", Vector3(-8.04,3.49,-2.07), Vector3(0,0.76,0), Vector3(0.60,0.58,0.61))
	# Two old cloth-covered wires sag below the landing fascia.
	for wire in range(2):
		var last := Vector3(-9.12, 7.52 + wire * 0.12, -2.86)
		for section in range(1, 15):
			var u := section / 14.0
			var pt := Vector3(-9.12 + 4.90 * u, 7.52 + wire * 0.12 + 0.16 * u - sin(PI * u) * (1.36 + wire * 0.19), -2.86 + 0.38 * u)
			var cable := _add_box(g, (last + pt) * 0.5, Vector3(0.023, 0.023, last.distance_to(pt)), mats["metal"], Vector3.ZERO, false)
			cable.look_at(g.to_global(pt))
			last = pt
	var upper_floor := 8.49
	_add_box(g, Vector3(-6.23, upper_floor, -4.22), Vector3(5.88, 0.29, 2.60), mats["plaster"])
	_add_box(g, Vector3(-6.23, upper_floor + 0.17, -2.95), Vector3(5.96, 0.10, 0.16), mats["wood_carved"])
	_add_box(g, Vector3(-6.23, upper_floor + 1.14, -2.95), Vector3(5.96, 0.13, 0.16), mats["wood_carved"])
	var spindle_xforms: Array[Transform3D] = []
	for spindle in range(22):
		if spindle != 7:
			spindle_xforms.append(Transform3D(Basis().scaled(Vector3.ONE * 0.92), Vector3(-9.05 + spindle * 0.263, upper_floor + 0.2, -2.95)))
	_add_glb_multimesh(g, "upper_spindle", spindle_xforms, null, 0.95)
	_add_glb(g, "arched_window", Vector3(-7.62, upper_floor + 0.23, -7.83), Vector3.ZERO, Vector3(1.06, 0.73, 1))
	var gallery_lamp := OmniLight3D.new()
	gallery_lamp.position = Vector3(-7.4, 9.55, -4.28)
	gallery_lamp.light_color = Color(1, 0.70, 0.39)
	gallery_lamp.light_energy = 3.2
	gallery_lamp.omni_range = 5.2
	gallery_lamp.shadow_enabled = false
	g.add_child(gallery_lamp)
	_add_glb(flight, "plaster_fall", Vector3(-1.03, 0.43, -0.51), Vector3(0.61, -0.47, 0.08), Vector3(0.34, 0.18, 0.47))
	_add_box(g, Vector3(-7.78, 3.427, -1.18), Vector3(2.76, 0.16, 0.77), mats["wood_carved"])
	var slope1 := atan2(0.219, 0.284)
	_add_box(flight, Vector3(0, 1.36, -2.41), Vector3(3.14, 1.18, 5.75), mats["wood_carved"], Vector3(slope1, 0, 0)).visible = false
	_add_box(flight, Vector3(-1.48, 2.35, -2.10), Vector3(0.26, 1.45, 5.75), mats["wood_carved"], Vector3(slope1, 0, 0)).visible = false
	_add_box(flight, Vector3(1.44, 2.35, -2.10), Vector3(0.26, 1.45, 5.75), mats["wood_carved"], Vector3(slope1, 0, 0)).visible = false
	_add_box(g, Vector3(-7.35, 3.45, -4.60), Vector3(5.10, 0.26, 6.80), mats["wood_carved"]).visible = false
	_add_box(g, Vector3(-1.20, 3.45, -6.35), Vector3(7.20, 0.26, 3.30), mats["wood_carved"]).visible = false
	# Invisible balustrade colliders prevent zombies or ragdolls from walking/hanging off the arch balcony lip!
	_add_box(g, Vector3(-1.20, 4.35, -4.68), Vector3(7.20, 1.80, 0.20), mats["wood_carved"]).visible = false
	_add_box(g, Vector3(2.40, 4.35, -6.35), Vector3(0.20, 1.80, 3.30), mats["wood_carved"]).visible = false

	# Bold high-contrast urban wildstyle graffiti + AmbientCG water leaks POPPING on pale dusty stairwell plaster!
	_add_graffiti_mural(g, Vector3(-9.48, 3.05, 0.35), Vector2(5.4, 4.4), Vector3(0, 90, 0), "ward_inscriptions_0.png", 0.98)
	_add_graffiti_mural(g, Vector3(-9.48, 6.35, -3.70), Vector2(5.6, 4.4), Vector3(0, 90, 0), "ward_inscriptions_1.png", 0.96)
	_add_graffiti_mural(g, Vector3(-6.20, 5.65, -7.94), Vector2(6.0, 4.6), Vector3(0, 0, 0), "ward_inscriptions_1.png", 0.95)
	_add_graffiti_mural(g, Vector3(-6.40, 9.05, -7.94), Vector2(5.4, 3.8), Vector3(0, 0, 0), "ward_inscriptions_0.png", 0.90)

	_add_graffiti_mural(g, Vector3(-9.46, 3.1, 0.14), Vector2(4.8, 5.8), Vector3(0,90,0), "seeping_plaster.png", 0.71)
	_add_graffiti_mural(g, Vector3(-3.75, 2.55, -2.15), Vector2(3.4, 4.4), Vector3(0,-90,0), "ward_inscriptions_0.png", 0.88)
	for step in [2, 7, 12]:
		var side := -1.0 if step % 3 != 0 else 1.0
		var pos := Vector3(side * stair_rng.randf_range(0.30,0.98), (step+1)*0.219, -step*0.284-0.08)
		_add_glb(flight, "plaster_fall", pos, Vector3(0.3,stair_rng.randf_range(-PI,PI),0.03), Vector3(0.48,0.24,0.34))
		_add_box(flight, pos + Vector3(-side*0.30,0.05,0), Vector3(0.77,0.046,0.081), mats["timber"], Vector3(0.12,stair_rng.randf_range(-0.35,0.35),0.06), false)
	var srng := RandomNumberGenerator.new()
	srng.seed = 3303
	var stair_wood: Array[Transform3D] = []
	var stair_conc: Array[Transform3D] = []
	for _k in range(22):
		var sx := srng.randf_range(-9.2, -4.4)
		var sz := srng.randf_range(2.2, 4.4)
		var sc := Vector3(srng.randf_range(0.08, 0.16), 0.025, srng.randf_range(0.32, 0.88))
		var b := Basis.from_euler(Vector3(srng.randf_range(-0.08, 0.08), srng.randf_range(0, TAU), srng.randf_range(-0.06, 0.06))).scaled(sc)
		var xf := Transform3D(b, Vector3(sx, 0.02, sz))
		if srng.randf() < 0.7:
			stair_wood.append(xf)
		else:
			stair_conc.append(xf)
	_add_box_multimesh(g, stair_wood, Vector3.ONE, mats["wood_carved"], false)
	_add_box_multimesh(g, stair_conc, Vector3.ONE, mats["concrete"], false)
	_add_glb(g, "cardboard_box", Vector3(-8.75, 0.0, 2.85), Vector3(0, 0.52, 0), Vector3(1.1, 1.1, 1.1))
	_add_glb(g, "wooden_chair", Vector3(-8.45, 3.58, -2.55), Vector3(0, 0.65, 0), Vector3(1.0, 1.0, 1.0))

	_add_glb(g, "caged_sconce", Vector3(-9.4, 4.75, -2.8), Vector3(0, PI * 0.5, 0), Vector3(1.25, 1.25, 1.25))
	var sl_mid := OmniLight3D.new()
	sl_mid.light_color = Color(1.0, 0.88, 0.72)
	sl_mid.light_energy = 3.8
	sl_mid.light_indirect_energy = 1.15
	sl_mid.light_volumetric_fog_energy = 0.45
	sl_mid.omni_range = 8.5
	sl_mid.omni_attenuation = 2.0
	sl_mid.shadow_enabled = true
	sl_mid.light_bake_mode = Light3D.BAKE_STATIC
	sl_mid.shadow_bias = 0.04
	sl_mid.position = Vector3(-9.05, 4.75, -2.2)
	g.add_child(sl_mid)

	spawn_points.append(Vector3(-7.6, 3.65, -5.8))


func _build_storage_alcove() -> void:
	var g := Node3D.new()
	g.name = "StorageAlcove"
	alcove_group = g
	add_child(g)

	_add_box(g, Vector3(-7.0, 0.008, 6.4), Vector3(5.6, 0.02, 2.9), mats["tile"], Vector3.ZERO, false)
	_add_box(g, Vector3(-4.2, 3.5, 6.2), Vector3(0.28, 7.0, 3.5), mats["plaster"])
	_add_glb(g, "ornate_door", Vector3(-7.6, 0.0, 7.88), Vector3(0, PI, 0), Vector3(0.95, 1.02, 0.95))

	for bp: Vector3 in [Vector3(-5.9, 0, 7.25), Vector3(-5.1, 0, 7.35), Vector3(-5.5, 0, 6.55)]:
		_add_glb(g, "wine_barrel", bp, Vector3(0, randf() * TAU, 0), Vector3(0.98, 0.98, 0.98), Vector3(0.65, 0.88, 0.65))
	for hp: Vector3 in [Vector3(-5.85, 1.15, 7.15), Vector3(-5.15, 1.15, 7.20), Vector3(-5.50, 1.78, 7.18)]:
		_add_glb(g, "wine_barrel", hp, Vector3(PI * 0.5, 0.14, 0.0), Vector3(0.92, 0.92, 0.92))
	_add_glb(g, "wooden_crate", Vector3(-8.8, 0, 6.9), Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	_add_glb(g, "military_crate", Vector3(-8.4, 0, 5.8), Vector3(0, -0.3, 0), Vector3(1.15, 1.15, 1.15))


func _sample_disp_height(img: Image, u: float, v: float) -> float:
	if img == null:
		return 0.5
	var w := img.get_width()
	var h := img.get_height()
	if w <= 0 or h <= 0:
		return 0.5
	var fx := u - floorf(u)
	var fy := v - floorf(v)
	return img.get_pixel(clampi(int(fx * float(w)), 0, w - 1), clampi(int(fy * float(h)), 0, h - 1)).r


func _build_tunnel_vault_mesh(z_start := -7.7, z_end := -28.3, radius := 2.28, spring_y := 1.15, a_segs := 36, z_segs := 56) -> ArrayMesh:
	var d_img: Image = null
	if not OS.has_feature("web"):
		var disp_tex := load("res://assets/textures/brick_vault_disp.jpg") as Texture2D
		d_img = disp_tex.get_image() if disp_tex else null
		if d_img and d_img.is_compressed():
			if d_img.decompress() != OK:
				d_img = null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a_min := -0.10
	var a_max := PI + 0.10
	var uv_density := 0.46
	var cols := a_segs + 1
	var rows := z_segs + 1
	var verts: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var norms: PackedVector3Array = []
	verts.resize(cols * rows)
	uvs.resize(cols * rows)
	norms.resize(cols * rows)

	for iz in range(rows):
		var tz := float(iz) / float(z_segs)
		var z := lerpf(z_start, z_end, tz)
		var end_fade := smoothstep(0.0, 0.04, tz) * (1.0 - smoothstep(0.96, 1.0, tz))
		for ia in range(cols):
			var ta := float(ia) / float(a_segs)
			var a := lerpf(a_min, a_max, ta)
			var u_m := -z
			var v_m := -a * radius
			var sag := (sin(z * 0.65 + 0.4) * 0.014 + sin(a * 3.0 + z * 0.35) * 0.010) * end_fade
			var h_disp := _sample_disp_height(d_img, u_m * uv_density, v_m * uv_density)
			# Recessed mortar / protruding bricks physically silhouette along the arch under flashlight!
			var relief := (h_disp - 0.5) * 0.026 * end_fade
			var r_eff := radius + sag - relief
			var ca := cos(a)
			var sa := sin(a)
			var idx := iz * cols + ia
			verts[idx] = Vector3(ca * r_eff, spring_y + sa * r_eff, z)
			uvs[idx] = Vector2(u_m, v_m)
			norms[idx] = Vector3(-ca, -sa, 0.0)

	for iz in range(rows):
		for ia in range(cols):
			var idx := iz * cols + ia
			var i_a0 := maxi(ia - 1, 0)
			var i_a1 := mini(ia + 1, a_segs)
			var i_z0 := maxi(iz - 1, 0)
			var i_z1 := mini(iz + 1, z_segs)
			var da := verts[iz * cols + i_a1] - verts[iz * cols + i_a0]
			var dz := verts[i_z1 * cols + ia] - verts[i_z0 * cols + ia]
			var n := dz.cross(da).normalized()
			if n.dot(norms[idx]) < 0.0:
				n = -n
			st.set_normal(n)
			st.set_uv(uvs[idx])
			st.add_vertex(verts[idx])

	for iz in range(z_segs):
		for ia in range(a_segs):
			var i00 := iz * cols + ia
			var i10 := iz * cols + (ia + 1)
			var i01 := (iz + 1) * cols + ia
			var i11 := (iz + 1) * cols + (ia + 1)
			# Clockwise front-face winding (cross opposite inward normal) facing INWARD into the tunnel!
			st.add_index(i00)
			st.add_index(i01)
			st.add_index(i11)
			st.add_index(i00)
			st.add_index(i11)
			st.add_index(i10)

	st.generate_tangents()
	return st.commit()


func _add_oriented_tri(st: SurfaceTool, p0: Vector3, uv0: Vector2, n0: Vector3,
		p1: Vector3, uv1: Vector2, n1: Vector3, p2: Vector3, uv2: Vector2, n2: Vector3, face_dir: Vector3) -> void:
	if (p1 - p0).cross(p2 - p0).dot(face_dir) <= 0.0:
		st.set_normal(n0); st.set_uv(uv0); st.add_vertex(p0)
		st.set_normal(n1); st.set_uv(uv1); st.add_vertex(p1)
		st.set_normal(n2); st.set_uv(uv2); st.add_vertex(p2)
	else:
		st.set_normal(n0); st.set_uv(uv0); st.add_vertex(p0)
		st.set_normal(n2); st.set_uv(uv2); st.add_vertex(p2)
		st.set_normal(n1); st.set_uv(uv1); st.add_vertex(p1)


func _build_tunnel_rib_mesh(radius := 2.26, depth := 0.22, width := 0.42, spring_y := 1.15, a_segs := 28) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a_min := -0.05
	var a_max := PI + 0.05
	var r_in := radius - depth
	var r_out := radius + 0.08
	var hz := width * 0.5
	for ia in range(a_segs):
		var a0 := lerpf(a_min, a_max, float(ia) / float(a_segs))
		var a1 := lerpf(a_min, a_max, float(ia + 1) / float(a_segs))
		var c0 := cos(a0); var s0 := sin(a0)
		var c1 := cos(a1); var s1 := sin(a1)
		var v0 := -a0 * r_in; var v1 := -a1 * r_in

		var p_in_0n := Vector3(c0 * r_in, spring_y + s0 * r_in, -hz)
		var p_in_0p := Vector3(c0 * r_in, spring_y + s0 * r_in, hz)
		var p_in_1n := Vector3(c1 * r_in, spring_y + s1 * r_in, -hz)
		var p_in_1p := Vector3(c1 * r_in, spring_y + s1 * r_in, hz)
		var n0 := Vector3(-c0, -s0, 0.0)
		var n1 := Vector3(-c1, -s1, 0.0)
		var n_mid := (n0 + n1).normalized()
		_add_oriented_tri(st, p_in_0p, Vector2(-hz, v0), n0, p_in_1p, Vector2(-hz, v1), n1, p_in_1n, Vector2(hz, v1), n1, n_mid)
		_add_oriented_tri(st, p_in_0p, Vector2(-hz, v0), n0, p_in_1n, Vector2(hz, v1), n1, p_in_0n, Vector2(hz, v0), n0, n_mid)

		var p_out_0p := Vector3(c0 * r_out, spring_y + s0 * r_out, hz)
		var p_out_1p := Vector3(c1 * r_out, spring_y + s1 * r_out, hz)
		var p_out_0n := Vector3(c0 * r_out, spring_y + s0 * r_out, -hz)
		var p_out_1n := Vector3(c1 * r_out, spring_y + s1 * r_out, -hz)
		var nf := Vector3(0, 0, 1)
		var nb := Vector3(0, 0, -1)
		_add_oriented_tri(st, p_in_0p, Vector2(r_in, v0), nf, p_out_1p, Vector2(r_out, v1), nf, p_in_1p, Vector2(r_in, v1), nf, nf)
		_add_oriented_tri(st, p_in_0p, Vector2(r_in, v0), nf, p_out_0p, Vector2(r_out, v0), nf, p_out_1p, Vector2(r_out, v1), nf, nf)
		_add_oriented_tri(st, p_in_0n, Vector2(r_in, v0), nb, p_in_1n, Vector2(r_in, v1), nb, p_out_1n, Vector2(r_out, v1), nb, nb)
		_add_oriented_tri(st, p_in_0n, Vector2(r_in, v0), nb, p_out_1n, Vector2(r_out, v1), nb, p_out_0n, Vector2(r_out, v0), nb, nb)

	st.generate_tangents()
	return st.commit()


func _build_catacomb_tunnel() -> void:
	"""SOLID SMOOTH CURVED BRICK BARREL-VAULT TUNNEL + CLOSE-RANGE RUBBLE lit ONLY by focused SureFire flashlight (Ref #13!)."""
	var g := Node3D.new()
	g.name = "CatacombTunnel"
	tunnel_group = g
	add_child(g)
	_add_reflection_probe(g, Vector3(0.0, 1.8, -18.0), Vector3(6.5, 5.0, 22.0), true, 1.15)
	_add_fog_volume(g, Vector3(0.0, 1.5, -17.5), Vector3(4.6, 3.6, 17.5), Color(0.32, 0.35, 0.40), 0.018)

	var tun_fl := _add_box(g, Vector3(0, -0.15, -18.0), Vector3(5.0, 0.3, 21.0), mats["tunnel_floor"])
	if tun_fl:
		tun_fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Continuous smooth horseshoe brick barrel vault mesh with meter-scaled continuous UVs + physical brick relief!
	var vault_mi := MeshInstance3D.new()
	vault_mi.name = "SmoothBrickBarrelVault"
	vault_mi.mesh = _build_tunnel_vault_mesh(-7.7, -28.3, 2.28, 1.15, 36, 56)
	vault_mi.material_override = mats["brick_vault"]
	vault_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(vault_mi)

	# Invisible arch collision hull matching the smooth barrel vault
	var arch_sb := StaticBody3D.new()
	arch_sb.collision_layer = 1
	arch_sb.set_meta(&"surface", "brick")
	for s in range(6):
		var a0 := (float(s) / 6.0) * PI
		var a1 := (float(s + 1) / 6.0) * PI
		var am := 0.5 * (a0 + a1)
		var seg_w := 2.0 * 2.28 * sin(0.5 * (a1 - a0)) + 0.14
		var cs := CollisionShape3D.new()
		var bsh := BoxShape3D.new()
		bsh.size = Vector3(0.36, seg_w, 20.6)
		cs.shape = bsh
		cs.position = Vector3(cos(am) * (2.28 + 0.16), 1.15 + sin(am) * (2.28 + 0.16), -18.0)
		cs.rotation = Vector3(0.0, 0.0, am)
		arch_sb.add_child(cs)
	g.add_child(arch_sb)

	# Lower vertical brick tunnel plinth walls below the springline
	_add_box(g, Vector3(-2.34, 0.62, -18.0), Vector3(0.38, 1.35, 20.6), mats["brick"])
	_add_box(g, Vector3(2.34, 0.62, -18.0), Vector3(0.38, 1.35, 20.6), mats["brick"])

	# Protruding curved radial brick arch ribs stepping cleanly along the enclosed vault
	var rib_mesh := _build_tunnel_rib_mesh(2.26, 0.22, 0.42, 1.15, 28)
	for i in range(5):
		var tz := -10.0 - i * 4.0
		var rmi := MeshInstance3D.new()
		rmi.mesh = rib_mesh
		rmi.material_override = mats["brick_vault"]
		rmi.position = Vector3(0.0, 0.0, tz)
		rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		g.add_child(rmi)
	var mid_rib := MeshInstance3D.new()
	mid_rib.mesh = rib_mesh
	mid_rib.material_override = mats["brick_vault"]
	mid_rib.position = Vector3(0.0, 0.0, -14.8)
	mid_rib.scale = Vector3(0.96, 0.97, 0.72)
	mid_rib.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	g.add_child(mid_rib)

	_add_glb(g, "wooden_crate", Vector3(1.28, 0.0, -21.4), Vector3(0, -0.45, 0.06), Vector3(0.95, 0.95, 0.95))
	_add_glb(g, "wine_barrel", Vector3(-1.32, 0.0, -22.6), Vector3(0.12, 0.4, 1.48), Vector3(0.88, 0.88, 0.88))

	# Hero fractured brick rubble + jagged splintered wooden beam right in the blazing flashlight hotspot (Ref #13 — ZERO boxy planks!)
	_add_glb(g, "vault_brickfall", Vector3(1.17,-0.14,-17.51), Vector3(0.12,-0.62,-0.11), Vector3(0.86,0.87,0.85))
	_add_glb(g, "vault_brickfall", Vector3(-1.42,-0.17,-17.87), Vector3(-0.04,1.70,0.16), Vector3(1.06,1.1,1.28))
	_add_glb(g, "splinter_heap", Vector3(-1.10,0.09,-14.43), Vector3(0.05,0.76,0.15), Vector3(0.83,0.91,0.73))
	_add_glb(g, "tunnel_rubble_hero", Vector3(-0.15, 0.0, -21.20), Vector3(0, PI - 0.18, 0), Vector3(0.92, 0.92, 0.92))

	# A recessed dressed-stone doorway interrupts the brick vault near the collapse.
	_add_glb(g, "hewn_archway", Vector3(-0.12, -0.35, -18.83), Vector3(-0.03, 0.27, 0.024), Vector3(1.17, 0.89, 1.05))
	var collapse_pile := _add_glb(g, "quarry_fall", Vector3(0.35,0.17,-15.56), Vector3(-0.23,1.72,-0.13), Vector3(1.19,1.21,1.06))
	if collapse_pile:
		var damp := ShaderMaterial.new()
		damp.shader = preload("res://shaders/quarry_stone.gdshader")
		damp.set_shader_parameter("stone",preload("res://assets/models/quarry_fall_SootedMasonry.jpg"))
		damp.set_shader_parameter("relief",preload("res://assets/models/quarry_fall_QuarryRelief.jpg"))
		damp.set_shader_parameter("aggregate",preload("res://assets/textures/concrete_rubble_albedo.jpg"))
		_apply_mat_recursive(collapse_pile,damp)
	# Rubble accumulates at the springing of the vault, leaving a worn strip down the middle.
	var bank := ShaderMaterial.new()
	bank.shader = preload("res://shaders/collapsed_masonry.gdshader")
	for map_name in ["albedo", "normal", "disp", "rough"]:
		bank.set_shader_parameter(map_name + "_tex", load("res://assets/textures/tunnel_rubble_" + map_name + ".jpg"))
	var rubble_floor := PlaneMesh.new()
	rubble_floor.size = Vector2(4.48, 18.0)
	rubble_floor.subdivide_width = 24
	rubble_floor.subdivide_depth = 60
	var mound := MeshInstance3D.new()
	mound.mesh = rubble_floor
	mound.material_override = bank
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mound.position = Vector3(0, 0.006, -18.7)
	g.add_child(mound)
	# Rain-blackened fieldstones spill out of the mortar in uneven fans.
	for collapse in [
		[Vector3(-1.34,-0.02,-17.12),1.38,1.40],
		[Vector3(1.30,0.03,-18.67),0.83,0.77],
		[Vector3(-1.56,0.04,-21.6),0.36,0.82],
	]:
		_add_glb(g, "fallen_stone_bank", collapse[0], Vector3(0.11,collapse[1],-0.05), Vector3.ONE * collapse[2])
	_add_glb(g, "fractured_bricks", Vector3(1.34,-0.27,-16.1), Vector3(0.34,1.12,0.46), Vector3(0.77,1.18,1.07))
	_add_glb(g, "dry_windfall", Vector3(-0.93,0.04,-16.40), Vector3(0.06,1.03,0.14), Vector3.ONE*0.54)

	var bulb := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.042
	sp.height = 0.084
	bulb.mesh = sp
	bulb.material_override = mats["bulb_warm"]
	bulb.position = Vector3(0.0, 2.95, -26.2)
	g.add_child(bulb)
	var tl := OmniLight3D.new()
	tl.light_color = Color(1.0, 0.72, 0.36)
	tl.light_energy = 1.8
	tl.light_volumetric_fog_energy = 1.1
	tl.set_meta("keep_vol_fog", true)
	tl.omni_range = 8.0
	tl.omni_attenuation = 1.80
	tl.shadow_enabled = false
	tl.light_bake_mode = Light3D.BAKE_STATIC
	tl.position = Vector3(0.0, 2.75, -26.2)
	g.add_child(tl)

	spawn_points.append(Vector3(0.0, 0.1, -15.5))
	spawn_points.append(Vector3(0.0, 0.1, -24.5))


func _snow_hash21_exact(p: Vector2) -> float:
	var qx := p.x * 127.1
	var qy := p.y * 311.7
	var fx := qx - floorf(qx)
	var fy := qy - floorf(qy)
	var dd := fx * (fx + 34.53) + fy * (fy + 34.53)
	fx += dd
	fy += dd
	var v := fx * fy
	return v - floorf(v)


func _snow_vnoise(p: Vector2) -> float:
	var ix := floorf(p.x)
	var iy := floorf(p.y)
	var fx := p.x - ix
	var fy := p.y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _snow_hash21_exact(Vector2(ix, iy))
	var b := _snow_hash21_exact(Vector2(ix + 1.0, iy))
	var c := _snow_hash21_exact(Vector2(ix, iy + 1.0))
	var d := _snow_hash21_exact(Vector2(ix + 1.0, iy + 1.0))
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func _snow_height_at(wx: float, wz: float) -> float:
	# Exact 1:1 mirror of snow_height_fast() in wet_snow_ground.gdshader
	var edge := smoothstep(1.5, 5.2, absf(wx + 1.4 * sin(wz * 0.14)))
	var drift := _snow_vnoise(Vector2(wx * 0.36, wz * 0.36)) * (0.18 + 0.50 * edge)
	var track_x := wx + sin(wz * 0.29) * 0.67
	var rut := exp(-6.5 * pow(absf(absf(track_x) - 0.72), 2.0))
	var in_yard := smoothstep(-27.8, -28.8, wz)
	var wall_bank := in_yard * smoothstep(2.1, 3.8, absf(wx)) * exp(-absf(-28.4 - wz) * 0.75) * 0.34
	var fence_bank := in_yard * exp(-pow((absf(wx) - 8.4) / 1.45, 2.0)) * 0.22
	var cabin_bank := smoothstep(-51.5, -53.4, wz) * smoothstep(1.6, 3.4, absf(wx)) * 0.28
	return drift - 0.11 * rut + 0.06 * sin(wx * 1.4 + wz * 0.9) + wall_bank + fence_bank + cabin_bank


func _build_snow_courtyard() -> void:
	var g := Node3D.new()
	g.name = "SnowCourtyard"
	courtyard_group = g
	add_child(g)
	_add_reflection_probe(g, Vector3(0.0, 4.5, -48.0), Vector3(48.0, 14.0, 46.0), false, 1.05)

	var hmap_body := StaticBody3D.new()
	hmap_body.name = "SnowTerrainCollider"
	hmap_body.collision_layer = 1
	hmap_body.set_meta(&"surface", "snow")
	var hmap_cs := CollisionShape3D.new()
	var hmap := HeightMapShape3D.new()
	hmap.map_width = 85
	hmap.map_depth = 67
	var hdata := PackedFloat32Array()
	hdata.resize(85 * 67)
	for iz in 67:
		var wz := -93.5 + float(iz)
		var row_off := iz * 85
		for ix in 85:
			var wx := -42.0 + float(ix)
			hdata[row_off + ix] = _snow_height_at(wx, wz)
	hmap.map_data = hdata
	hmap_cs.shape = hmap
	hmap_cs.position = Vector3(0.0, 0.0, -60.5)
	hmap_body.add_child(hmap_cs)
	g.add_child(hmap_body)

	var terrain_mesh := PlaneMesh.new()
	terrain_mesh.size = Vector2(84, 66)
	var low_geo := OS.has_feature("web") or _is_compat_renderer()
	terrain_mesh.subdivide_width = 112 if low_geo else 224
	terrain_mesh.subdivide_depth = 96 if low_geo else 192
	var snowfield := MeshInstance3D.new()
	snowfield.mesh = terrain_mesh
	snowfield.material_override = mats["snow_ground"]
	snowfield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	snowfield.position.z = -60.5
	snowfield.custom_aabb = AABB(Vector3(-42.0, -0.4, -33.0), Vector3(84.0, 2.2, 66.0))
	g.add_child(snowfield)

	_add_box(g, Vector3(-6.8, 3.0, -28.2), Vector3(9.2, 6.2, 0.7), mats["brick"])
	_add_box(g, Vector3(6.8, 3.0, -28.2), Vector3(9.2, 6.2, 0.7), mats["brick"])
	_add_box(g, Vector3(0.0, 4.9, -28.2), Vector3(4.8, 2.4, 0.7), mats["brick"])

	for side: float in [-1.0, 1.0]:
		var fx: float = side * 8.4
		for i in range(6):
			var fz: float = -31.0 - float(i) * 3.8
			_add_box(g, Vector3(fx, 0.62, fz), Vector3(0.14, 1.32, 0.14), mats["timber"], Vector3(0.04, 0, side * 0.05))
			if i < 5:
				_add_box(g, Vector3(fx, 0.96, fz - 1.9), Vector3(0.09, 0.11, 3.85), mats["timber"], Vector3.ZERO, false)
				_add_box(g, Vector3(fx, 0.48, fz - 1.9), Vector3(0.09, 0.11, 3.85), mats["timber"], Vector3.ZERO, false)

	var grng := RandomNumberGenerator.new()
	grng.seed = 3112
	for _r in range(14):
		var side_s := -1.0 if grng.randf() < 0.5 else 1.0
		var rx := side_s * grng.randf_range(5.8, 11.5)
		var rz := grng.randf_range(-52.5, -32.0)
		var k := grng.randi() % 4
		if k == 0:
			_add_glb(g, "rubble_boulder", Vector3(rx, -0.06, rz), Vector3(0, grng.randf_range(0, TAU), 0), Vector3.ONE * grng.randf_range(0.45, 0.85))
		elif k == 1:
			_add_glb(g, "winter_grass", Vector3(rx, 0.0, rz), Vector3(0, grng.randf_range(0, TAU), 0), Vector3.ONE * grng.randf_range(1.0, 1.45))
		elif k == 2:
			_add_glb(g, "dead_quiver_branch_01", Vector3(rx, 0.02, rz), Vector3(0, grng.randf_range(0, TAU), 0), Vector3.ONE * grng.randf_range(0.75, 1.25))
		else:
			_add_glb(g, "bark_debris", Vector3(rx, 0.01, rz), Vector3(0, grng.randf_range(0, TAU), 0), Vector3.ONE * grng.randf_range(0.85, 1.35))

	_add_glb(g, "fallen_log", Vector3(6.6, 0.0, -39.5), Vector3(0, 0.65, 0), Vector3(1.15, 1.15, 1.15))
	_add_glb(g, "fallen_log", Vector3(-6.4, 0.0, -44.2), Vector3(0, -0.82, 0), Vector3(1.10, 1.10, 1.10))

	var lp1 := Vector3(7.0, 0.0, -44.2)
	_add_box(g, lp1 + Vector3(0, 1.65, 0), Vector3(0.20, 3.3, 0.20), mats["timber"])
	_add_box(g, lp1 + Vector3(-0.38, 3.02, 0), Vector3(0.95, 0.12, 0.14), mats["timber"], Vector3.ZERO, false)
	_add_box(g, lp1 + Vector3(-0.38, 3.40, 0), Vector3(1.18, 0.10, 0.96), mats["timber"], Vector3(0.28, 0, 0), false)
	_add_box(g, lp1 + Vector3(-0.38, 3.40, 0), Vector3(1.18, 0.10, 0.96), mats["timber"], Vector3(-0.28, 0, 0), false)
	_add_glb(g, "wooden_lantern", lp1 + Vector3(-0.62, 2.52, 0), Vector3.ZERO, Vector3(1.25, 1.25, 1.25))
	_add_glb(g, "wooden_crate", lp1 + Vector3(-0.45, 0.0, 0.55), Vector3(0, 0.4, 0), Vector3(0.92, 0.92, 0.92))
	var b1 := _add_box(g, lp1 + Vector3(-0.62, 2.74, 0), Vector3(0.14, 0.18, 0.14), mats["bulb_warm"], Vector3.ZERO, false)
	if b1:
		b1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lgt1 := OmniLight3D.new()
	lgt1.light_color = Color(1.0, 0.72, 0.34)
	lgt1.light_energy = 8.7
	lgt1.light_volumetric_fog_energy = 0.89
	lgt1.set_meta("keep_vol_fog", true)
	lgt1.omni_range = 17.0
	lgt1.omni_attenuation = 1.48
	lgt1.shadow_enabled = true
	lgt1.position = lp1 + Vector3(-0.79, 2.55, 0.42)
	g.add_child(lgt1)
	_add_fog_volume(g, lp1 + Vector3(-0.5, 1.8, 0.0), Vector3(8.5, 4.8, 8.5), Color(0.84, 0.62, 0.36), 0.020)

	var rng := RandomNumberGenerator.new()
	rng.seed = 2029
	var fir_xforms: Array[Transform3D] = []
	var dead_xforms: Array[Transform3D] = []
	var yfir_xforms: Array[Transform3D] = []
	var pine_xforms: Array[Transform3D] = []
	for i in range(20):
		var angle := -PI * 0.06 - (float(i) / 20.0) * PI * 0.88
		var radius := rng.randf_range(14.5, 29.5)
		var tx := cos(angle) * radius * 1.12
		var tz := -34.0 + sin(angle) * radius * 1.32
		if abs(tx) < 6.4 and tz > -62.0:
			tx += (7.6 if tx >= 0 else -7.6)
		var scl := rng.randf_range(0.95, 1.45)
		var ry := rng.randf_range(0.0, TAU)
		var xf := Transform3D(Basis.from_euler(Vector3(0, ry, 0)).scaled(Vector3.ONE * scl), Vector3(tx, -0.1, tz))
		if i % 3 != 2:
			fir_xforms.append(xf)
		else:
			dead_xforms.append(xf)

	var framing := [
		["fir_tree", Vector3(-9.2, -0.1, -34.5), 1.15],
		["fir_tree", Vector3(9.6, -0.1, -35.8), 1.20],
		["fir_tree", Vector3(-7.6, -0.05, -40.5), 0.78],
		["fir_tree", Vector3(7.8, -0.05, -48.5), 0.82],
		["fir_tree", Vector3(-4.5, -0.1, -51.6), 1.20],
		["fir_tree", Vector3(4.6, -0.1, -52.0), 1.22],
		["dead_winter_tree", Vector3(-4.0, -0.1, -50.0), 0.98],
		["dead_winter_tree", Vector3(4.1, -0.1, -50.4), 1.04],
		["fir_tree", Vector3(-6.8, -0.1, -59.5), 1.32],
		["fir_tree", Vector3(6.8, -0.1, -59.0), 1.28],
	]
	for fr in framing:
		var xf := Transform3D(Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), 0)).scaled(Vector3.ONE * fr[2]), fr[1])
		if fr[0] == "fir_tree":
			fir_xforms.append(xf)
		else:
			dead_xforms.append(xf)

	# Younger firs fill the gaps in the understory along the fence.
	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector3(side * rng.randf_range(6.2, 12.7), -0.04, rng.randf_range(-58.0, -31.5))
		yfir_xforms.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), 0)).scaled(Vector3.ONE * rng.randf_range(0.66, 1.65)), pos))

	# Younger Scots pines grow in the wind shadow of logs and the sagging fence.
	for pine in [
		[Vector3(-3.36, -0.15, -38.11), 0.89, 0.53],
		[Vector3(-3.66, -0.10, -43.45), 0.66, -0.83],
		[Vector3(-4.83, -0.11, -46.72), 0.85, 2.41],
		[Vector3(5.04, -0.12, -38.72), 1.13, -1.11],
		[Vector3(5.62, -0.09, -46.57), 1.05, 2.17],
	]:
		pine_xforms.append(Transform3D(Basis.from_euler(Vector3(0.04, pine[2], -0.09)).scaled(Vector3.ONE * pine[1]), pine[0]))
	# Small clustered plants track the thawed soil along the inside of the fence.
	var forest_rng := RandomNumberGenerator.new()
	forest_rng.seed = 29214
	for bank: float in [-1.0, 1.0]:
		for group in range(9):
			var z := -32.7 - group * 2.35 + forest_rng.randf_range(-0.56, 0.56)
			var x := -sin(z * 0.14) * 1.4 + bank * forest_rng.randf_range(4.35, 6.05)
			var clump := Vector3(x, -0.045, z)
			var species := "winter_grass" if (group % 2 == 0) else "undergrowth_fern"
			_add_glb(g, species, clump, Vector3(0, forest_rng.randf_range(0, TAU), 0), Vector3.ONE * forest_rng.randf_range(0.45, 0.82))
			if group % 3 == 1:
				yfir_xforms.append(Transform3D(Basis.from_euler(Vector3(0.07, forest_rng.randf_range(0, TAU), 0)).scaled(Vector3.ONE * forest_rng.randf_range(0.55, 0.98)), clump + Vector3(bank, 0, 0)))
			elif group % 3 == 2:
				_add_glb(g, "dry_windfall", clump, Vector3(0, forest_rng.randf_range(0, TAU), 0), Vector3.ONE * 0.82)
			else:
				_add_glb(g, "rubble_boulder", clump, Vector3(0, forest_rng.randf_range(0, TAU), 0), Vector3.ONE * forest_rng.randf_range(0.24, 0.51))
	_add_glb(g, "fallen_spruce", Vector3(5.83, -0.24, -42.6), Vector3(0.72, 1.44, 0.02), Vector3.ONE * 0.46)
	_add_glb(g, "fallen_spruce", Vector3(-3.75, -0.14, -50.35), Vector3(0, -0.61, -0.02), Vector3.ONE * 0.42)
	for thicket in [Vector3(4.85,-0.11,-35.32), Vector3(-2.87,-0.10,-39.7), Vector3(5.74,-0.08,-44.42), Vector3(-4.63,-0.13,-46.5)]:
		_add_glb(g, "spruce_snag", thicket, Vector3(0.12,forest_rng.randf_range(-PI,PI),0.08), Vector3.ONE*forest_rng.randf_range(0.52,0.81))
		pine_xforms.append(Transform3D(Basis.from_euler(Vector3(0.12,forest_rng.randf_range(-PI,PI),-0.09)).scaled(Vector3.ONE*forest_rng.randf_range(0.65,1.08)), thicket + Vector3(forest_rng.randfn(0,0.6),0,forest_rng.randfn(0,0.5))))
	# Stadium moon_bounce & canopy_light removed so lantern + flashlight carry contrast
	_add_fog_volume(g, Vector3(0.8, 0.83, -48.7), Vector3(20.4, 2.13, 8.6), Color(0.48, 0.46, 0.43), 0.021)
	var h_rng := RandomNumberGenerator.new()
	h_rng.seed = 4049
	for _ht in range(10):
		var htx := h_rng.randf_range(-17.8, -8.2)
		var htz := h_rng.randf_range(-47.5, -40.0)
		var hscl := h_rng.randf_range(0.90, 1.45)
		var xf := Transform3D(Basis.from_euler(Vector3(0, h_rng.randf_range(0, TAU), 0)).scaled(Vector3.ONE * hscl), Vector3(htx, -0.1, htz))
		if h_rng.randf() < 0.65:
			dead_xforms.append(xf)
		else:
			fir_xforms.append(xf)

	for trunk in [
		[Vector3(-14.66, -0.1, -39.18), 1.72],
		[Vector3(-9.98, -0.1, -39.66), 1.64],
		[Vector3(-12.98, -0.1, -41.56), 1.80],
	]:
		dead_xforms.append(Transform3D(Basis.from_euler(Vector3(0.03, 0.41, 0.07)).scaled(Vector3.ONE * trunk[1]), trunk[0]))
	_add_glb_spatial_chunks(g, "fir_tree", fir_xforms, null, 1.35)
	_add_glb_spatial_chunks(g, "dead_winter_tree", dead_xforms, null, 1.35)
	_add_glb_spatial_chunks(g, "young_fir", yfir_xforms, null, 1.35)
	_add_glb_spatial_chunks(g, "winter_pine", pine_xforms, null, 1.35)
	for trunk in [
		[Vector3(-14.43, -0.19, -38.92), 1.25, 0.83],
		[Vector3(-10.35, -0.19, -38.83), 1.34, -1.12],
		[Vector3(-12.77, -0.16, -40.72), 1.43, -0.43],
	]:
		_add_glb(g, "spruce_snag", trunk[0], Vector3(0.06, trunk[2], 0.08), Vector3(trunk[1], trunk[1] * 1.31, trunk[1]))
	bg_horde_group = Node3D.new()
	bg_horde_group.name = "CourtyardHorde"
	g.add_child(bg_horde_group)
	var bg_horde := [
		["zombie_tactical", Vector3(-12.68, -0.06, -36.94), -0.14, 0.60],
		["zombie_tactical", Vector3(-11.02, -0.21, -37.23), -0.49, 0.36],
		["zombie_tactical", Vector3(-13.54, 0.02, -37.81), 0.62, 4.75],
		["zombie_tactical", Vector3(-13.74, -0.08, -36.97), 0.31, 0.35],
		["zombie_tactical", Vector3(-10.66, -0.19, -36.96), -0.62, 1.41],
		["winter_infected", Vector3(-12.55, 0.02, -39.05), 0.22, 0.85],
		["winter_infected", Vector3(-13.45, 0.02, -39.55), 0.32, 0.65],
		["zombie_runner", Vector3(-10.65, 0.02, -39.15), -0.18, 1.15],
	]
	if OS.has_feature("web"):
		bg_horde = bg_horde.slice(0, 4)
	for idx in bg_horde.size():
		var bh: Array = bg_horde[idx]
		var zb: Node3D = null
		var baked_p := "res://assets/baked/%s.scn" % bh[0]
		if (bh[0] == "zombie_tactical" or bh[0] == "zombie_runner") and ResourceLoader.exists(baked_p):
			var bp := load(baked_p) as PackedScene
			if bp:
				zb = bp.instantiate() as Node3D
				zb.position = bh[1]
				zb.rotation = Vector3(0.05, bh[2], 0.0)
				zb.scale = Vector3.ONE
				bg_horde_group.add_child(zb)
		else:
			zb = _add_glb(bg_horde_group, bh[0], bh[1], Vector3(0.05, bh[2], 0.0), Vector3.ONE * 1.13)
		if zb:
			var ap := _find_type(zb, "AnimationPlayer") as AnimationPlayer
			var sk := _find_type(zb, "Skeleton3D") as Skeleton3D
			if ap:
				var al := ap.get_animation_list()
				if not al.is_empty():
					var chosen := al[0]
					for an in al:
						if "spot" in an.to_lower():
							chosen = an
							break
					ap.play(chosen)
					ap.seek(float(bh[3]), true)
					ap.advance(0.0)
					ap.stop()
				ap.queue_free()
			if sk:
				sk.force_update_all_bone_transforms()
				sk.set_process(false)
			var z_var: int = ZombieAI.Variant.TACTICAL_SOLDIER if bh[0] == "zombie_tactical" else ZombieAI.Variant.RUNNER
			for surface: Node in zb.find_children("*", "MeshInstance3D", true, false):
				var actor_mesh := surface as MeshInstance3D
				var part := str(actor_mesh.name)
				if "eyelash" in part.to_lower() or (idx in [1, 3] and part.begins_with("SkiGoggle")):
					actor_mesh.hide()
					continue
				actor_mesh.layers = 8
				actor_mesh.lod_bias = 1.0
				actor_mesh.visibility_range_end = 0.0
				actor_mesh.extra_cull_margin = 1.0
				actor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if actor_mesh.mesh:
					for surface_id in actor_mesh.mesh.get_surface_count():
						var cur_m := actor_mesh.get_active_material(surface_id)
						if not (cur_m is ShaderMaterial):
							var mat_s := ZombieAI._upgrade_zombie_material(cur_m, z_var)
							actor_mesh.set_surface_override_material(surface_id, mat_s)

	for entry in [
		[Vector3(-13.66, -0.14, -38.35), 0.27, 0.95],
		[Vector3(-10.29, -0.11, -38.61), -0.43, 1.01],
		[Vector3(-11.75, 0.0, -38.41), -0.15, 0.98],
	]:
		_add_glb(g, "winter_infected", entry[0], Vector3(0.025, entry[1], 0.035), Vector3.ONE * entry[2])

	var forest_rim := OmniLight3D.new()
	forest_rim.light_color = Color(0.56, 0.66, 0.82)
	forest_rim.light_energy = 1.35
	forest_rim.light_volumetric_fog_energy = 0.0
	forest_rim.omni_range = 10.5
	forest_rim.omni_attenuation = 1.55
	forest_rim.shadow_enabled = false
	forest_rim.position = Vector3(-9.59, 2.75, -38.55)
	forest_rim.set_meta("base_energy", 1.35)
	outdoor_fill_lights.append(forest_rim)
	g.add_child(forest_rim)
	_add_fog_volume(g, Vector3(-12.31, 1.86, -40.57), Vector3(7.3, 4.5, 4.0), Color(0.43, 0.47, 0.59), 0.025)

	var horde_rim_l := OmniLight3D.new()
	horde_rim_l.light_color = Color(0.72, 0.75, 0.90)
	horde_rim_l.light_energy = 0.96
	horde_rim_l.omni_range = 4.1
	horde_rim_l.omni_attenuation = 1.45
	horde_rim_l.light_size = 0.46
	horde_rim_l.shadow_enabled = false
	horde_rim_l.light_volumetric_fog_energy = 0.13
	horde_rim_l.position = Vector3(-12.68, 2.47, -35.34)
	horde_rim_l.set_meta("base_energy", 0.96)
	outdoor_fill_lights.append(horde_rim_l)
	g.add_child(horde_rim_l)
	var sky_bounce := OmniLight3D.new()
	sky_bounce.position = Vector3(-11.24, 2.36, -34.91)
	sky_bounce.light_color = Color(0.51, 0.57, 0.73)
	sky_bounce.light_energy = 0.36
	sky_bounce.omni_range = 9.8
	sky_bounce.light_specular = 0.10
	sky_bounce.set_meta("base_energy", 0.36)
	outdoor_fill_lights.append(sky_bounce)
	g.add_child(sky_bounce)
	var woodland_bounce := OmniLight3D.new()
	woodland_bounce.position = Vector3(-13.86, 2.13, -36.13)
	woodland_bounce.light_color = Color(0.60, 0.63, 0.85)
	woodland_bounce.light_energy = 0.58
	woodland_bounce.omni_range = 5.0
	woodland_bounce.light_specular = 0.16
	woodland_bounce.shadow_enabled = false
	woodland_bounce.set_meta("base_energy", 0.58)
	outdoor_fill_lights.append(woodland_bounce)
	g.add_child(woodland_bounce)
	var moon_break := SpotLight3D.new()
	moon_break.light_color = Color(0.82, 0.84, 0.91)
	moon_break.light_energy = 12.7
	moon_break.spot_range = 8.5
	moon_break.shadow_enabled = false
	moon_break.spot_angle = 37
	moon_break.light_specular = 0.10
	moon_break.light_cull_mask = 8
	moon_break.set_meta("base_energy", 12.7)
	outdoor_fill_lights.append(moon_break)
	g.add_child(moon_break)
	moon_break.look_at_from_position(Vector3(-13.39, 2.54, -34.82), Vector3(-12.21, 1.74, -37.15))

	_add_box(g, Vector3(-28, 3, -55), Vector3(1, 6, 56), mats["timber"]).visible = false
	_add_box(g, Vector3(28, 3, -55), Vector3(1, 6, 56), mats["timber"]).visible = false
	_add_box(g, Vector3(0, 3, -82), Vector3(58, 6, 1), mats["timber"]).visible = false

	spawn_points.append(Vector3(-5.0, 0.1, -34.0))
	spawn_points.append(Vector3(5.5, 0.1, -36.5))
	spawn_points.append(Vector3(-10.5, 0.1, -45.0))
	spawn_points.append(Vector3(10.5, 0.1, -46.5))


func _find_type(root: Node, cls: String) -> Node:
	if root.get_class() == cls:
		return root
	for c in root.get_children():
		var f := _find_type(c, cls)
		if f:
			return f
	return null


func _build_cabin() -> void:
	var g := Node3D.new()
	g.name = "TimberCabin"
	g.position = Vector3(0.0, 0.0, -56.0)
	cabin_group = g
	add_child(g)

	_add_glb(g, "cabin_facade", Vector3(0, -0.03, 2.36), Vector3.ZERO, Vector3(1.20, 1.13, 1.29))

	_add_box(g, Vector3(0, 0.06, 0), Vector3(7.4, 0.16, 6.2), mats["timber"]).visible = false
	_add_box(g, Vector3(0, 2.2, -3.05), Vector3(7.4, 4.4, 0.26), mats["timber"]).visible = false
	_add_box(g, Vector3(-3.65, 2.2, 0.0), Vector3(0.26, 4.4, 6.2), mats["timber"]).visible = false
	_add_box(g, Vector3(3.65, 2.2, 0.0), Vector3(0.26, 4.4, 6.2), mats["timber"]).visible = false
	_add_box(g, Vector3(-2.35, 2.2, 3.1), Vector3(2.7, 4.4, 0.28), mats["timber"]).visible = false
	_add_box(g, Vector3(2.35, 2.2, 3.1), Vector3(2.7, 4.4, 0.28), mats["timber"]).visible = false

	_add_glb(g, "wine_barrel", Vector3(-1.72, 0.14, 4.25), Vector3(0, 0.4, 0.06), Vector3(0.86, 0.86, 0.86))
	_add_glb(g, "wooden_crate", Vector3(-2.55, 0.0, 4.85), Vector3(0, 0.35, -0.05), Vector3(0.88, 0.88, 0.88))
	_add_glb(g, "ammo_box", Vector3(1.62, 0.14, 4.15), Vector3(0, -0.52, 0), Vector3(1.25, 1.25, 1.25))
	_add_glb(g, "trashbag", Vector3(2.32, 0.0, 4.95), Vector3(0, 1.2, 0), Vector3(1.15, 1.15, 1.15))
	_add_glb(g, "fallen_log", Vector3(3.15, 0.0, 5.55), Vector3(0, 0.38, 0), Vector3(0.85, 0.85, 0.85))
	_add_glb(g, "winter_grass", Vector3(-2.15, 0.0, 6.15), Vector3(0, 0.7, 0), Vector3(1.35, 1.35, 1.35))
	_add_glb(g, "winter_grass", Vector3(2.45, 0.0, 6.45), Vector3(0, 2.1, 0), Vector3(1.40, 1.40, 1.40))
	_add_glb(g, "dead_quiver_branch_01", Vector3(-1.45, 0.02, 7.20), Vector3(0, 0.5, 0), Vector3(1.15, 1.15, 1.15))

	_add_glb(g, "hanging_industrial_lamp", Vector3(-1.85, 3.35, -1.2), Vector3.ZERO, Vector3(0.95, 0.95, 0.95))
	# Pitch-dark charred interior backing behind doorway so zombies emerge from an eerie dark cabin void (Ref #15!)
	var dark_void := StandardMaterial3D.new()
	dark_void.metallic_specular = 0.0
	dark_void.albedo_color = Color(0.009, 0.007, 0.005)
	dark_void.roughness = 0.98
	_add_box(g, Vector3(0.0, 2.0, -1.8), Vector3(6.6, 3.8, 0.18), dark_void, Vector3.ZERO, false)
	_add_box(g, Vector3(-2.6, 2.0, 0.5), Vector3(0.18, 3.8, 4.6), dark_void, Vector3.ZERO, false)
	_add_box(g, Vector3(2.6, 2.0, 0.5), Vector3(0.18, 3.8, 4.6), dark_void, Vector3.ZERO, false)
	var cl := OmniLight3D.new()
	cl.light_color = Color(0.86, 0.88, 0.92)
	cl.light_energy = 0.12
	cl.light_volumetric_fog_energy = 0.0
	cl.omni_range = 2.65
	cl.shadow_enabled = false
	cl.position = Vector3(-1.27, 1.87, 4.98)
	g.add_child(cl)

	# Extra cluttered derelict shack debris around cabin porch (crates, tangled branches, dark rusted barrel!)
	_add_glb(g, "military_crate", Vector3(2.15, 0.0, 4.45), Vector3(0, -0.35, 0.06), Vector3(0.95, 0.95, 0.95))
	_add_glb(g, "dead_quiver_branch_01", Vector3(1.55, 0.02, 6.20), Vector3(0.08, -1.2, 0), Vector3(1.35, 1.35, 1.35))
	_add_glb(g, "bark_debris", Vector3(0.25, 0.01, 6.45), Vector3(0, 0.7, 0), Vector3(1.5, 1.2, 1.5))

	# Subtle distant warm amber streetlight halo high above cabin roof (volumetric fog glow ONLY — never floods cabin wall like Ref #15!)
	var top_bulb := MeshInstance3D.new()
	var tbsp := SphereMesh.new()
	tbsp.radius = 0.065
	tbsp.height = 0.13
	top_bulb.mesh = tbsp
	top_bulb.material_override = mats["bulb_warm"]
	top_bulb.position = Vector3(0.55, 4.82, 3.74)
	g.add_child(top_bulb)
	var top_l := OmniLight3D.new()
	top_l.light_color = Color(1.0, 0.68, 0.28)
	top_l.light_energy = 1.34
	top_l.light_volumetric_fog_energy = 2.2
	top_l.set_meta("keep_vol_fog", true)
	top_l.omni_range = 7.5
	top_l.omni_attenuation = 1.85
	top_l.position = Vector3(0.55, 4.76, 3.90)
	g.add_child(top_l)

	var cabin_bounce := OmniLight3D.new()
	cabin_bounce.light_color = Color(1.0, 0.72, 0.42)
	cabin_bounce.light_energy = 0.85
	cabin_bounce.light_specular = 0.0
	cabin_bounce.light_volumetric_fog_energy = 0.0
	cabin_bounce.light_bake_mode = Light3D.BAKE_DISABLED
	cabin_bounce.omni_range = 6.0
	cabin_bounce.omni_attenuation = 1.8
	cabin_bounce.shadow_enabled = false
	cabin_bounce.position = Vector3(0.0, 2.4, 0.5)
	g.add_child(cabin_bounce)
	var porch_pool := SpotLight3D.new()
	porch_pool.light_color = Color(1.0, 0.76, 0.48)
	porch_pool.light_energy = 11.6
	porch_pool.light_cull_mask = 0xFFFFD
	porch_pool.spot_angle = 48.0
	porch_pool.spot_range = 12.0
	porch_pool.light_volumetric_fog_energy = 0.72
	porch_pool.shadow_enabled = true
	porch_pool.light_bake_mode = Light3D.BAKE_STATIC
	g.add_child(porch_pool)
	porch_pool.look_at_from_position(g.to_global(Vector3(0.55, 4.67, 4.12)), g.to_global(Vector3(0.42, 0.0, 9.7)))
	# The battered hayloft facing rises behind the shallow lean-to.
	_add_glb(g, "split_siding", Vector3(0.0, 2.85, 3.24), Vector3(-0.026, -0.014, 0.021), Vector3(1.40, 0.76, 1.08))
	_add_glb(g, "hanging_industrial_lamp", Vector3(0.55, 4.94, 3.70), Vector3(0.10, -0.30, -0.09), Vector3.ONE * 0.86)
	_add_glb(g, "threshold_lining", Vector3(0.02, 0.06, 3.48), Vector3(0, 0.012, -0.009), Vector3(0.96, 0.91, 1))
	_add_glb(g, "ward_door", Vector3(0.97,0.10,3.45), Vector3(0,1.70,-0.045), Vector3(1.04,1.21,1))
	_add_glb(g, "splinter_heap", Vector3(-1.65,0.00,6.02), Vector3(-0.04,-0.73,0), Vector3(0.82,0.64,0.68))
	# Salvaged vertical siding forms the lean-to on either side of the notched log porch.
	_add_glb(g, "split_siding", Vector3(-3.47, -0.08, 4.02), Vector3(0.02, 0.10, 0.028), Vector3(0.84, 0.99, 1.01))
	_add_glb(g, "split_siding", Vector3(3.33, -0.12, 4.14), Vector3(-0.03, -0.14, -0.034), Vector3(0.77, 1.05, 0.96))
	_add_glb(g, "porch_steps", Vector3(0.10, -0.19, 5.75), Vector3(0.06, -PI * 0.5, -0.04), Vector3(1.50, 1, 1.74))
	_add_glb(g, "plaster_fall", Vector3(-2.08, -0.17, 6.16), Vector3(-0.10, 0.91, 0.04), Vector3(0.54, 0.46, 0.76))
	_add_glb(g, "caged_sconce", Vector3(1.78, 2.63, 6.12), Vector3.ZERO, Vector3.ONE * 0.86)
	_add_glb(g, "wooden_chair", Vector3(-2.02, 0.04, 5.86), Vector3(0.38, 0.67, -1.13), Vector3.ONE * 0.94)
	_add_glb(g, "dry_windfall", Vector3(1.78, 0.02, 6.73), Vector3(0, -0.89, 0), Vector3.ONE * 0.85)

	spawn_points.append(Vector3(0.0, 0.1, -51.5))


func _build_interactables() -> void:
	var gen := InteractableObject.new()
	gen.name = "AsylumGenerator"
	gen.kind = InteractableObject.Kind.GENERATOR
	gen.collision_layer = 16 | 1
	gen.position = Vector3(-3.2, 0.0, -6.2)
	add_child(gen)
	var gcol := CollisionShape3D.new()
	var gsh := BoxShape3D.new()
	gsh.size = Vector3(1.1, 0.9, 0.7)
	gcol.shape = gsh
	gcol.position = Vector3(0, 0.45, 0)
	gen.add_child(gcol)
	_add_glb(gen, "military_crate", Vector3.ZERO, Vector3.ZERO, Vector3(1.25, 1.25, 1.25))
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.25, 0.15)
	gl.light_energy = 1.3
	gl.omni_range = 4.2
	gl.position = Vector3(0, 0.92, 0.32)
	gen.add_child(gl)
	gen.glow_light = gl
	interactables.append(gen)

	var mbox := InteractableObject.new()
	mbox.name = "MysteryBox"
	mbox.kind = InteractableObject.Kind.MYSTERY_BOX
	mbox.cost = 500
	mbox.collision_layer = 16 | 1
	mbox.position = Vector3(-6.8, 0.0, -42.0)
	mbox.rotation.y = 0.45
	add_child(mbox)
	var mcol := CollisionShape3D.new()
	var msh := BoxShape3D.new()
	msh.size = Vector3(1.5, 0.72, 0.72)
	mcol.shape = msh
	mcol.position = Vector3(0, 0.36, 0)
	mbox.add_child(mcol)
	_add_box(mbox, Vector3(0, 0.30, 0), Vector3(1.48, 0.60, 0.68), mats["wood_carved"], Vector3.ZERO, false)
	var lid := Node3D.new()
	lid.position = Vector3(0, 0.60, -0.34)
	mbox.add_child(lid)
	_add_box(lid, Vector3(0, 0.06, 0.34), Vector3(1.52, 0.12, 0.72), mats["timber"], Vector3.ZERO, false)
	mbox.lid_node = lid
	var ml := OmniLight3D.new()
	ml.light_color = Color(1.0, 0.75, 0.28)
	ml.light_energy = 1.2
	ml.light_volumetric_fog_energy = 2.0
	ml.omni_range = 6.5
	ml.position = Vector3(0, 0.75, 0)
	mbox.add_child(ml)
	mbox.glow_light = ml
	interactables.append(mbox)

	var bar := InteractableObject.new()
	bar.name = "WindowBarricade"
	bar.kind = InteractableObject.Kind.BARRICADE
	bar.collision_layer = 16 | 1
	bar.position = Vector3(9.68, 0.0, 0.25)
	bar.plank_count = 2
	add_child(bar)
	var bcol := CollisionShape3D.new()
	var bsh := BoxShape3D.new()
	bsh.size = Vector3(0.4, 2.6, 2.4)
	bcol.shape = bsh
	bcol.position = Vector3(0, 1.8, 0)
	bar.add_child(bcol)
	for i in range(4):
		var pl := _add_box(bar, Vector3(-0.08, 1.95 + i * 0.42, 0.0), Vector3(0.08, 0.18, 2.45),
			mats["timber"], Vector3(0.06 * (i % 2 * 2 - 1), 0, 0), false)
		pl.visible = i < bar.plank_count
		bar.plank_nodes.append(pl)
	interactables.append(bar)

	# Journey Melee Weapon Pickups: Fire Axe (Lobby near tunnel pillar) & Tactical Machete (Courtyard Cabin porch)
	_spawn_melee_pickup("FireAxePickup", "fire_axe", "FIRE AXE", Vector3(-1.95, 0.0, -3.25), Vector3(0.0, 0.55, 0.0), lobby_group)
	_spawn_melee_pickup("MachetePickup", "machete", "TACTICAL MACHETE", Vector3(-2.45, 0.0, -49.6), Vector3(0.0, -0.40, 0.0), courtyard_group)


func _spawn_melee_pickup(node_name: String, m_id: String, label: String, pos: Vector3, rot: Vector3, parent_grp: Node3D) -> void:
	var pk := InteractableObject.new()
	pk.name = node_name
	pk.kind = InteractableObject.Kind.MELEE_PICKUP
	pk.melee_id = m_id
	pk.weapon_label = label
	pk.collision_layer = 16
	pk.position = pos
	pk.rotation = rot
	(parent_grp if parent_grp != null else self).add_child(pk)

	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.65, 1.1, 0.65)
	col.shape = sh
	col.position = Vector3(0.0, 0.55, 0.0)
	pk.add_child(col)

	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.28, 0.30, 0.33)
	steel.metallic = 0.85
	steel.roughness = 0.32
	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color(0.72, 0.74, 0.76)
	edge.metallic = 0.92
	edge.roughness = 0.20
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.22, 0.13)
	wood.roughness = 0.78

	var vis := Node3D.new()
	vis.position = Vector3(0.0, 0.42, 0.0)
	vis.rotation = Vector3(0.22, 0.0, 0.18)
	pk.add_child(vis)
	if m_id == "fire_axe":
		var hdl := MeshInstance3D.new()
		var hm := CylinderMesh.new(); hm.top_radius = 0.018; hm.bottom_radius = 0.022; hm.height = 0.82; hm.material = wood
		hdl.mesh = hm; vis.add_child(hdl)
		var head := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.18, 0.11, 0.030); bm.material = steel
		head.mesh = bm; head.position = Vector3(0.06, 0.34, 0.0); vis.add_child(head)
		var bit := MeshInstance3D.new()
		var em := BoxMesh.new(); em.size = Vector3(0.04, 0.13, 0.012); em.material = edge
		bit.mesh = em; bit.position = Vector3(0.16, 0.34, 0.0); vis.add_child(bit)
	else:
		var grip := MeshInstance3D.new()
		var gm := CylinderMesh.new(); gm.top_radius = 0.016; gm.bottom_radius = 0.018; gm.height = 0.16; gm.material = wood
		grip.mesh = gm; grip.position = Vector3(0.0, -0.18, 0.0); vis.add_child(grip)
		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.055, 0.48, 0.008); bm.material = steel
		blade.mesh = bm; blade.position = Vector3(0.0, 0.14, 0.0); vis.add_child(blade)
		var b_edge := MeshInstance3D.new()
		var em := BoxMesh.new(); em.size = Vector3(0.014, 0.46, 0.005); em.material = edge
		b_edge.mesh = em; b_edge.position = Vector3(0.032, 0.14, 0.0); vis.add_child(b_edge)

	var glint := OmniLight3D.new()
	glint.light_color = Color(0.95, 0.82, 0.58)
	glint.light_energy = 0.55
	glint.omni_range = 2.6
	glint.shadow_enabled = false
	glint.position = Vector3(0.0, 0.65, 0.15)
	pk.add_child(glint)
	interactables.append(pk)


func _build_snow_particles() -> void:
	snow_particles = GPUParticles3D.new()
	snow_particles.name = "NightSnowfall"
	var is_web := OS.has_feature("web")
	snow_particles.amount = 180 if is_web else 450
	snow_particles.lifetime = 6.5
	snow_particles.preprocess = 0.0 if is_web else 3.0
	snow_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	snow_particles.visibility_aabb = AABB(Vector3(-32, -2, -32), Vector3(64, 18, 64))
	snow_particles.position = Vector3(0.0, 8.5, -48.0)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(24.0, 1.5, 22.0)
	pm.direction = Vector3(0.22, -1.0, 0.12).normalized()
	pm.spread = 16.0
	pm.initial_velocity_min = 1.1
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0.25, -0.6, 0.0)
	pm.scale_min = 0.036
	pm.scale_max = 0.092
	pm.color = Color(0.62, 0.68, 0.78, 0.24)
	snow_particles.process_material = pm

	var qm := QuadMesh.new()
	qm.size = Vector2(0.085, 0.15)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_texture = load("res://assets/textures/snow_flake.png")
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = sm
	snow_particles.draw_pass_1 = qm
	add_child(snow_particles)


func set_asylum_power(on: bool) -> void:
	for l in asylum_power_lights:
		l.light_energy = 5.5 if on else 0.0
		l.visible = on


func _add_box_occluder(parent: Node3D, pos: Vector3, size: Vector3) -> OccluderInstance3D:
	var oi := OccluderInstance3D.new()
	var bo := BoxOccluder3D.new()
	bo.size = size
	oi.occluder = bo
	oi.position = pos
	oi.bake_mask = 1
	parent.add_child(oi)
	return oi


func _build_occluders() -> void:
	if OS.has_feature("web") or _is_compat_renderer():
		return
	var occ_root := Node3D.new()
	occ_root.name = "WorldOccluders"
	add_child(occ_root)
	# Strictly inset opaque wall/shell occluders so camera-angle visibility needs ZERO room-popping!
	# Lobby west & south walls + ceiling + records return wall
	_add_box_occluder(occ_root, Vector3(-10.15, 3.5, 0.0), Vector3(0.16, 6.8, 16.0))
	_add_box_occluder(occ_root, Vector3(0.0, 3.5, 8.15), Vector3(20.0, 6.8, 0.16))
	_add_box_occluder(occ_root, Vector3(4.95, 3.5, 1.76), Vector3(4.1, 6.7, 0.10))
	_add_box_occluder(occ_root, Vector3(3.2, 7.15, 0.0), Vector3(13.6, 0.14, 16.0))
	# Lobby north wall flanking the tunnel archway (tightened around x in [-2.02..2.02], y in [0..3.48])
	_add_box_occluder(occ_root, Vector3(-6.12, 3.5, -8.15), Vector3(7.90, 7.0, 0.18))
	_add_box_occluder(occ_root, Vector3(6.12, 3.5, -8.15), Vector3(7.90, 7.0, 0.18))
	_add_box_occluder(occ_root, Vector3(0.0, 5.38, -8.15), Vector3(4.36, 3.44, 0.18))
	# Upper 3-story stairwell north wall, roof, and east shaft wall (prevents upper stairwell leak from courtyard)
	_add_box_occluder(occ_root, Vector3(-6.9, 9.1, -8.15), Vector3(7.2, 4.2, 0.18))
	_add_box_occluder(occ_root, Vector3(-6.9, 11.15, -2.5), Vector3(7.2, 0.16, 11.2))
	_add_box_occluder(occ_root, Vector3(-3.65, 9.1, -2.5), Vector3(0.16, 4.2, 11.2))
	# Lobby east wall flanking the tall arched windows
	_add_box_occluder(occ_root, Vector3(10.15, 3.5, -6.2), Vector3(0.18, 7.0, 3.6))
	_add_box_occluder(occ_root, Vector3(10.15, 3.5, 4.8), Vector3(0.18, 7.0, 6.4))
	# Solid tunnel outer masonry shell + vault upper haunches
	_add_box_occluder(occ_root, Vector3(-2.52, 1.8, -18.0), Vector3(0.16, 3.5, 19.6))
	_add_box_occluder(occ_root, Vector3(2.52, 1.8, -18.0), Vector3(0.16, 3.5, 19.6))
	_add_box_occluder(occ_root, Vector3(0.0, 3.65, -18.0), Vector3(4.8, 0.16, 19.6))
	_add_box_occluder(occ_root, Vector3(-1.95, 3.15, -18.0), Vector3(1.1, 1.0, 19.6))
	_add_box_occluder(occ_root, Vector3(1.95, 3.15, -18.0), Vector3(1.1, 1.0, 19.6))
	# Courtyard brick retaining walls flanking the tunnel exit (leaves exit archway 100% open!)
	_add_box_occluder(occ_root, Vector3(-6.80, 3.0, -28.2), Vector3(9.0, 5.9, 0.34))
	_add_box_occluder(occ_root, Vector3(6.80, 3.0, -28.2), Vector3(9.0, 5.9, 0.34))
	_add_box_occluder(occ_root, Vector3(0.0, 4.92, -28.2), Vector3(4.6, 2.25, 0.34))
	# Timber cabin solid back & side walls (world z = -56)
	_add_box_occluder(occ_root, Vector3(0.0, 2.2, -59.05), Vector3(7.0, 4.1, 0.14))
	_add_box_occluder(occ_root, Vector3(-3.65, 2.2, -56.0), Vector3(0.14, 4.1, 5.8))
	_add_box_occluder(occ_root, Vector3(3.65, 2.2, -56.0), Vector3(0.14, 4.1, 5.8))


func _build_voxel_gi() -> void:
	voxel_gis.clear()
	if _is_compat_renderer():
		return
	var specs := [
		{"key": "lobby", "pos": Vector3(-1.5, 4.8, -0.5), "size": Vector3(24.0, 13.5, 20.0), "subdiv": VoxelGI.SUBDIV_128},
		{"key": "tunnel", "pos": Vector3(0.0, 2.2, -18.0), "size": Vector3(11.0, 6.5, 22.0), "subdiv": VoxelGI.SUBDIV_64},
		{"key": "cabin", "pos": Vector3(0.0, 2.6, -56.0), "size": Vector3(13.0, 7.0, 13.0), "subdiv": VoxelGI.SUBDIV_64},
	]
	for sp in specs:
		var gi := VoxelGI.new()
		gi.name = "VoxelGI_" + sp["key"]
		gi.position = sp["pos"]
		gi.size = sp["size"]
		gi.subdiv = sp["subdiv"]
		gi.set_meta("gi_key", sp["key"])
		add_child(gi)
		var res_p := "res://assets/baked/gi_%s.res" % sp["key"]
		var usr_p := "user://gi_%s.res" % sp["key"]
		if ResourceLoader.exists(res_p):
			gi.data = load(res_p) as VoxelGIData
		elif ResourceLoader.exists(usr_p):
			gi.data = load(usr_p) as VoxelGIData
		voxel_gis.append(gi)


func bake_voxel_gis(save_to_res: bool = false) -> void:
	if lobby_group: lobby_group.visible = true
	if staircase_group: staircase_group.visible = true
	if alcove_group: alcove_group.visible = true
	if tunnel_group: tunnel_group.visible = true
	if cabin_group: cabin_group.visible = true
	for gi in voxel_gis:
		var key := str(gi.get_meta("gi_key", "lobby"))
		var target_path := ("res://assets/baked/gi_%s.res" % key) if save_to_res else ("user://gi_%s.res" % key)
		gi.bake(null, false)
		if gi.data:
			gi.data.dynamic_range = 2.0
			gi.data.energy = 1.15
			gi.data.propagation = 0.55
			gi.data.bias = 1.5
			gi.data.normal_bias = 0.8
			gi.data.interior = true
			ResourceSaver.save(gi.data, target_path, ResourceSaver.FLAG_COMPRESS)
			print("BAKED GI:", target_path, " bytes=", FileAccess.get_file_as_bytes(target_path).size() if FileAccess.file_exists(target_path) else -1)
