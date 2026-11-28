class_name VFXManager
extends Node3D

static var instance: VFXManager = null

const MAX_BLOOD_DECALS := 56
const MAX_BLOOD_POOLS := 20
const MAX_IMPACT_DECALS := 64
const POOL_BLOOD_MIST := 14
const POOL_BLOOD_STREAKS := 14
const POOL_TISSUE_CHUNKS := 10
const POOL_IMPACT_DUST := 10
const POOL_IMPACT_CHIPS := 8
const POOL_METAL_SPARKS := 6
const POOL_MUZZLE_SPARKS := 4
const POOL_AUDIO_PLAYERS := 6

var _tex_blood_decal: Texture2D
var _tex_blood_decal_n: Texture2D
var _tex_blood_decal_orm: Texture2D
var _tex_blood_mist: Texture2D
var _tex_blood_arrival: Texture2D
var _tex_bullet_hole: Texture2D
var _tex_bullet_hole_n: Texture2D
var _tex_bullet_hole_orm: Texture2D
var _tex_wood_hole: Texture2D
var _tex_wood_hole_n: Texture2D
var _tex_smoke_puff: Texture2D
var _tex_spark_streak: Texture2D
var _sfx_impact_hard: AudioStream

var _soft_lit_shader: Shader
var _blood_pool_shader: Shader

var _blood_decals: Array[Decal] = []
var _blood_decal_idx := 0

var _impact_decals: Array[Decal] = []
var _impact_decal_idx := 0

var _blood_pools: Array[Dictionary] = []
var _blood_pool_idx := 0
var _active_pool_growths: Array[Dictionary] = []

var _mist_pool: Array[GPUParticles3D] = []
var _mist_idx := 0
var _streak_pool: Array[GPUParticles3D] = []
var _streak_idx := 0
var _chunk_pool: Array[GPUParticles3D] = []
var _chunk_idx := 0
var _dust_pool: Array[GPUParticles3D] = []
var _dust_idx := 0
var _chip_pool: Array[GPUParticles3D] = []
var _chip_idx := 0
var _chip_mesh_stone: BoxMesh
var _chip_mesh_masonry: BoxMesh
var _chip_mesh_wood: BoxMesh
var _spark_pool: Array[GPUParticles3D] = []
var _spark_idx := 0
var _muzzle_spark_pool: Array[GPUParticles3D] = []
var _muzzle_spark_idx := 0
var _audio_pool: Array[AudioStreamPlayer3D] = []
var _audio_idx := 0

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	_load_resources()
	_allocate_pools()

func _load_resources() -> void:
	_tex_blood_decal = load("res://assets/textures/blood_decal.png")
	_tex_blood_decal_n = load("res://assets/textures/blood_decal_normal.png")
	_tex_blood_decal_orm = load("res://assets/textures/blood_decal_orm.png")
	_tex_blood_mist = load("res://assets/textures/blood_mist.png")
	_tex_blood_arrival = load("res://assets/textures/blood_arrival_noise.png")
	_tex_bullet_hole = load("res://assets/textures/bullet_hole.png")
	_tex_bullet_hole_n = load("res://assets/textures/bullet_hole_normal.png")
	_tex_bullet_hole_orm = load("res://assets/textures/bullet_hole_orm.png")
	_tex_wood_hole = load("res://assets/textures/wood_hole_albedo.png")
	_tex_wood_hole_n = load("res://assets/textures/wood_hole_normal.png")
	_tex_smoke_puff = load("res://assets/textures/smoke_puff.png")
	_tex_spark_streak = load("res://assets/textures/spark_streak.png")
	_sfx_impact_hard = load("res://assets/audio/impact_hard.wav")
	_soft_lit_shader = load("res://shaders/soft_lit_particle.gdshader")
	_blood_pool_shader = load("res://shaders/blood_pool.gdshader")

func _allocate_pools() -> void:
	var is_web := OS.has_feature("web")
	var is_compat := is_web or RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if not is_compat:
		for i in MAX_BLOOD_DECALS:
			var d := Decal.new()
			d.name = "BloodDecal_%d" % i
			d.texture_albedo = _tex_blood_decal
			d.texture_normal = _tex_blood_decal_n
			d.texture_orm = _tex_blood_decal_orm
			d.cull_mask = 1
			d.distance_fade_enabled = true
			d.distance_fade_begin = 22.0
			d.distance_fade_length = 8.0
			d.visible = false
			add_child(d)
			_blood_decals.append(d)

		for i in MAX_IMPACT_DECALS:
			var d := Decal.new()
			d.name = "ImpactDecal_%d" % i
			d.texture_albedo = _tex_bullet_hole
			d.texture_normal = _tex_bullet_hole_n
			d.texture_orm = _tex_bullet_hole_orm
			d.cull_mask = 1
			d.distance_fade_enabled = true
			d.distance_fade_begin = 18.0
			d.distance_fade_length = 6.0
			d.visible = false
			add_child(d)
			_impact_decals.append(d)

		# Keep all decal atlas textures registered at startup so the first wood/blood hit never rebuilds the atlas!
		for keeper_idx in range(3):
			var kd := Decal.new()
			kd.name = "DecalAtlasKeeper_%d" % keeper_idx
			kd.position = Vector3(float(keeper_idx) * 2.0, -48.0, 0.0)
			kd.size = Vector3(0.05, 0.05, 0.05)
			kd.cull_mask = 1
			if keeper_idx == 0:
				kd.texture_albedo = _tex_blood_decal
				kd.texture_normal = _tex_blood_decal_n
				kd.texture_orm = _tex_blood_decal_orm
			elif keeper_idx == 1:
				kd.texture_albedo = _tex_bullet_hole
				kd.texture_normal = _tex_bullet_hole_n
				kd.texture_orm = _tex_bullet_hole_orm
			else:
				kd.texture_albedo = _tex_wood_hole
				kd.texture_normal = _tex_wood_hole_n
			kd.visible = true
			add_child(kd)

	var pool_mesh := QuadMesh.new()
	pool_mesh.size = Vector2(1.0, 1.0)
	pool_mesh.orientation = PlaneMesh.FACE_Z
	var n_blood_pools := 10 if is_web else MAX_BLOOD_POOLS
	for i in n_blood_pools:
		var mi := MeshInstance3D.new()
		mi.name = "BloodPool_%d" % i
		mi.mesh = pool_mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = 1
		var sm := ShaderMaterial.new()
		sm.shader = _blood_pool_shader
		sm.set_shader_parameter("noise_tex", _tex_blood_arrival)
		sm.set_shader_parameter("growth", 0.0)
		sm.set_shader_parameter("seed", float(i) * 1.73)
		mi.material_override = sm
		mi.visible = false
		add_child(mi)
		_blood_pools.append({"mesh": mi, "mat": sm, "growth": 0.0, "speed": 0.35})

	var n_mist := 4 if is_web else POOL_BLOOD_MIST
	for i in n_mist:
		_mist_pool.append(_make_soft_lit_emitter(
			"BloodMist_%d" % i, _tex_blood_mist, Color(0.84, 0.015, 0.018, 0.76),
			14, 0.28, Vector2(0.22, 0.22), 2.4, 5.4, 20.0, -1.5, 0.20, 0.45, 0.95
		))

	var n_streak := 4 if is_web else POOL_BLOOD_STREAKS
	for i in n_streak:
		var p := GPUParticles3D.new()
		p.name = "BloodStreak_%d" % i
		p.one_shot = true
		p.explosiveness = 0.94
		p.emitting = false
		p.amount = 24
		p.lifetime = 0.44
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pm := ParticleProcessMaterial.new()
		pm.particle_flag_align_y = true
		pm.direction = Vector3(0, 0, 1)
		pm.spread = 22.0
		pm.initial_velocity_min = 3.5
		pm.initial_velocity_max = 9.8
		pm.gravity = Vector3(0, -11.8, 0)
		pm.damping_min = 1.6
		pm.damping_max = 3.4
		pm.scale_min = 0.70
		pm.scale_max = 1.45
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.028, 0.17)
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = _tex_spark_streak if _tex_spark_streak else _tex_blood_mist
		mat.albedo_color = Color(0.26, 0.005, 0.007, 0.96)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.10
		mat.metallic_specular = 0.78
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		q.material = mat
		p.draw_pass_1 = q
		add_child(p)
		_streak_pool.append(p)

	var n_chunk := 3 if is_web else POOL_TISSUE_CHUNKS
	for i in n_chunk:
		var p := GPUParticles3D.new()
		p.name = "TissueChunks_%d" % i
		p.one_shot = true
		p.explosiveness = 0.96
		p.emitting = false
		p.amount = 10
		p.lifetime = 0.65
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0, 0.25, 1)
		pm.spread = 38.0
		pm.initial_velocity_min = 2.4
		pm.initial_velocity_max = 6.8
		pm.gravity = Vector3(0, -13.0, 0)
		pm.angular_velocity_min = -320.0
		pm.angular_velocity_max = 320.0
		pm.scale_min = 0.6
		pm.scale_max = 1.45
		p.process_material = pm
		var bm := BoxMesh.new()
		bm.size = Vector3(0.024, 0.018, 0.030)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.14, 0.014, 0.016, 1.0)
		mat.roughness = 0.24
		mat.metallic_specular = 0.58
		bm.material = mat
		p.draw_pass_1 = bm
		add_child(p)
		_chunk_pool.append(p)

	var n_dust := 4 if is_web else POOL_IMPACT_DUST
	for i in n_dust:
		_dust_pool.append(_make_soft_lit_emitter(
			"ImpactDust_%d" % i, _tex_smoke_puff, Color(0.74, 0.70, 0.64, 0.58),
			10, 0.44, Vector2(0.32, 0.32), 1.4, 3.6, 26.0, -1.2, 0.30, 0.72, 1.50
		))

	var _make_chip_mesh := func(sz: Vector3, col: Color) -> BoxMesh:
		var m := BoxMesh.new()
		m.size = sz
		var mt := StandardMaterial3D.new()
		mt.albedo_color = col
		mt.roughness = 0.90
		mt.metallic_specular = 0.14
		m.material = mt
		return m
	_chip_mesh_stone = _make_chip_mesh.call(Vector3(0.017, 0.022, 0.013), Color(0.62, 0.59, 0.54, 1.0))
	_chip_mesh_masonry = _make_chip_mesh.call(Vector3(0.018, 0.020, 0.014), Color(0.52, 0.22, 0.14, 1.0))
	_chip_mesh_wood = _make_chip_mesh.call(Vector3(0.008, 0.064, 0.007), Color(0.66, 0.48, 0.28, 1.0))

	var n_chip := 3 if is_web else POOL_IMPACT_CHIPS
	for i in n_chip:
		var p := GPUParticles3D.new()
		p.name = "ImpactChips_%d" % i
		p.one_shot = true
		p.explosiveness = 0.96
		p.emitting = false
		p.amount = 11
		p.lifetime = 0.58
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pm := ParticleProcessMaterial.new()
		pm.particle_flag_align_y = true
		pm.direction = Vector3(0, 0, 1)
		pm.spread = 42.0
		pm.initial_velocity_min = 2.2
		pm.initial_velocity_max = 6.4
		pm.gravity = Vector3(0, -12.5, 0)
		pm.angular_velocity_min = -360.0
		pm.angular_velocity_max = 360.0
		pm.scale_min = 0.65
		pm.scale_max = 1.35
		p.process_material = pm
		p.draw_pass_1 = _chip_mesh_stone
		add_child(p)
		_chip_pool.append(p)

	var n_spark := 2 if is_web else POOL_METAL_SPARKS
	for i in n_spark:
		_spark_pool.append(_make_spark_emitter("MetalSparks_%d" % i, 18, 0.24, 4.5, 11.5, 34.0))

	var n_mspark := 2 if is_web else POOL_MUZZLE_SPARKS
	for i in n_mspark:
		_muzzle_spark_pool.append(_make_spark_emitter("MuzzleSparks_%d" % i, 14, 0.12, 6.5, 14.5, 16.0))

	for i in POOL_AUDIO_PLAYERS:
		var ap := AudioStreamPlayer3D.new()
		ap.name = "ImpactSFX_%d" % i
		ap.stream = _sfx_impact_hard
		ap.unit_size = 2.6
		ap.max_distance = 22.0
		add_child(ap)
		_audio_pool.append(ap)

func _make_soft_lit_emitter(
	ename: String, tex: Texture2D, tint: Color, amount: int, lifetime: float,
	quad_size: Vector2, v_min: float, v_max: float, spread: float,
	grav_y: float, soft_fade: float, wrap_l: float, max_lit: float
) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = ename
	p.one_shot = true
	p.explosiveness = 0.88
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1)
	pm.spread = spread
	pm.initial_velocity_min = v_min
	pm.initial_velocity_max = v_max
	pm.gravity = Vector3(0, grav_y, 0)
	pm.damping_min = 3.2
	pm.damping_max = 6.5
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = 0.65
	pm.scale_max = 1.55
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.16, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	p.process_material = pm

	var q := QuadMesh.new()
	q.size = quad_size
	var sm := ShaderMaterial.new()
	sm.shader = _soft_lit_shader
	sm.set_shader_parameter("albedo_tex", tex)
	sm.set_shader_parameter("tint_color", tint)
	sm.set_shader_parameter("soft_fade_dist", soft_fade)
	sm.set_shader_parameter("wrap_lighting", wrap_l)
	sm.set_shader_parameter("max_lit", max_lit)
	if ename.begins_with("BloodMist"):
		sm.set_shader_parameter("self_ambient", 0.09)
	q.material = sm
	p.draw_pass_1 = q
	add_child(p)
	return p

func _make_spark_emitter(ename: String, amount: int, lifetime: float, v_min: float, v_max: float, spread: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = ename
	p.one_shot = true
	p.explosiveness = 0.96
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.particle_flag_align_y = true
	pm.direction = Vector3(0, 0, 1)
	pm.spread = spread
	pm.initial_velocity_min = v_min
	pm.initial_velocity_max = v_max
	pm.gravity = Vector3(0, -9.8, 0)
	pm.damping_min = 1.8
	pm.damping_max = 4.5
	pm.scale_min = 0.6
	pm.scale_max = 1.35
	p.process_material = pm

	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.11)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _tex_spark_streak
	mat.albedo_color = Color(3.6, 1.95, 0.55, 1.0)
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = mat
	p.draw_pass_1 = q
	add_child(p)
	return p

func prewarm() -> void:
	var hide_pos := Vector3(0.0, -45.0, 0.0)
	for list in [_mist_pool, _streak_pool, _chunk_pool, _dust_pool, _chip_pool, _spark_pool, _muzzle_spark_pool]:
		if list.is_empty():
			continue
		var p: GPUParticles3D = list[0]
		p.global_position = hide_pos
		p.restart()
		p.emitting = true

func _process(delta: float) -> void:
	var i := _active_pool_growths.size() - 1
	while i >= 0:
		var entry: Dictionary = _active_pool_growths[i]
		var g: float = minf(1.0, float(entry["growth"]) + delta * float(entry["speed"]))
		entry["growth"] = g
		var sm: ShaderMaterial = entry["mat"]
		sm.set_shader_parameter("growth", g)
		if g >= 1.0:
			_active_pool_growths.remove_at(i)
		i -= 1

func _orient_along_dir(dir: Vector3) -> Basis:
	var d := dir.normalized()
	if d.length_squared() < 0.001:
		d = Vector3.FORWARD
	var up_ref := Vector3.UP if absf(d.y) < 0.94 else Vector3.RIGHT
	var right := up_ref.cross(d).normalized()
	var up := d.cross(right).normalized()
	return Basis(right, up, d)

func _orient_decal_onto_surface(pos: Vector3, normal: Vector3, tangent_hint: Vector3 = Vector3.ZERO) -> Transform3D:
	var n := normal.normalized()
	if n.length_squared() < 0.001:
		n = Vector3.UP
	# Decal projects along its local -Y axis! So +Y of Decal must match surface normal.
	var ref := tangent_hint
	if ref.length_squared() < 0.01 or absf(ref.normalized().dot(n)) > 0.94:
		ref = Vector3.FORWARD if absf(n.z) < 0.9 else Vector3.RIGHT
	var x_axis := ref.cross(n).normalized()
	var z_axis := x_axis.cross(n).normalized()
	if tangent_hint.length_squared() < 0.01:
		var rot := Basis(n, randf() * TAU)
		x_axis = rot * x_axis
		z_axis = rot * z_axis
	return Transform3D(Basis(x_axis, n, z_axis), pos + n * 0.01)

func _orient_quad_normal(pos: Vector3, normal: Vector3, yaw_rand: float) -> Transform3D:
	var n := normal.normalized()
	if n.length_squared() < 0.001:
		n = Vector3.UP
	var ref := Vector3.FORWARD if absf(n.z) < 0.9 else Vector3.RIGHT
	var x_axis := ref.cross(n).normalized()
	var y_axis := n.cross(x_axis).normalized()
	# QuadMesh FACE_Z normal points along +Z; rotate around Z = surface normal
	var b := Basis(x_axis, y_axis, n) * Basis(Vector3.BACK, yaw_rand)
	return Transform3D(b, pos + n * 0.007)

func spawn_blood_impact(pos: Vector3, shot_dir: Vector3, intensity: float = 1.0, is_headshot: bool = false, is_close: bool = false, skip_floor_drip: bool = false) -> void:
	var dir := shot_dir.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD

	# 1a. Lit crimson entry/front blood mist (visible toward camera on impact)
	var entry_mist := _mist_pool[_mist_idx % _mist_pool.size()]
	_mist_idx += 1
	entry_mist.global_transform = Transform3D(_orient_along_dir(-dir), pos - dir * 0.08)
	var em_pm := entry_mist.process_material as ParticleProcessMaterial
	em_pm.spread = 46.0
	em_pm.initial_velocity_min = 0.8 * intensity
	em_pm.initial_velocity_max = 2.6 * intensity
	em_pm.scale_min = 0.45 * clampf(intensity, 0.7, 1.25)
	em_pm.scale_max = 1.05 * clampf(intensity, 0.7, 1.40)
	var em_mat := entry_mist.draw_pass_1.material as ShaderMaterial
	if em_mat:
		em_mat.set_shader_parameter("tint_color", Color(0.86, 0.015, 0.018, 0.78))
	entry_mist.restart()
	entry_mist.emitting = true

	# 1b. Lit crimson exit blood mist (exit direction + gentle drift)
	var mist := _mist_pool[_mist_idx % _mist_pool.size()]
	_mist_idx += 1
	mist.global_transform = Transform3D(_orient_along_dir(dir), pos + dir * 0.14)
	var m_pm := mist.process_material as ParticleProcessMaterial
	m_pm.spread = 24.0
	m_pm.initial_velocity_min = 1.6 * intensity
	m_pm.initial_velocity_max = (4.2 if not is_headshot else 6.0) * intensity
	m_pm.scale_min = 0.55 * clampf(intensity, 0.7, 1.35)
	m_pm.scale_max = 1.25 * clampf(intensity, 0.7, 1.55)
	var m_mat := mist.draw_pass_1.material as ShaderMaterial
	if m_mat:
		m_mat.set_shader_parameter("tint_color", Color(0.82, 0.015, 0.018, 0.72 if is_headshot else 0.58))
	mist.restart()
	mist.emitting = true

	# 2. High-velocity arterial droplet streaks (exit cone)
	var st := _streak_pool[_streak_idx % _streak_pool.size()]
	_streak_idx += 1
	st.global_transform = Transform3D(_orient_along_dir(dir), pos)
	var s_pm := st.process_material as ParticleProcessMaterial
	s_pm.spread = 28.0 if is_headshot else 18.0
	s_pm.initial_velocity_min = 3.2 * intensity
	s_pm.initial_velocity_max = (10.5 if is_headshot else 8.2) * intensity
	st.restart()
	st.emitting = true

	# 3. Back-spatter mist + tissue chunks for headshots or close shotgun blasts
	if is_headshot or (is_close and intensity >= 1.2):
		var back_st := _streak_pool[_streak_idx % _streak_pool.size()]
		_streak_idx += 1
		back_st.global_transform = Transform3D(_orient_along_dir(-dir), pos)
		var bs_pm := back_st.process_material as ParticleProcessMaterial
		bs_pm.spread = 32.0
		bs_pm.initial_velocity_min = 2.0
		bs_pm.initial_velocity_max = 5.4
		back_st.restart()
		back_st.emitting = true

		var ch := _chunk_pool[_chunk_idx % _chunk_pool.size()]
		_chunk_idx += 1
		ch.global_transform = Transform3D(_orient_along_dir(dir), pos)
		ch.restart()
		ch.emitting = true

	# 4. World backdrop raycasts for stretched wall/floor arterial splatters
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var splat_rays := 2 if (is_headshot or intensity > 1.2) else 1
	for r_idx in splat_rays:
		var spread_dir := (dir + Vector3(randf_range(-0.18, 0.18), randf_range(-0.16, 0.08), randf_range(-0.18, 0.18))).normalized()
		var q := PhysicsRayQueryParameters3D.create(pos, pos + spread_dir * 3.8, 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			var h_pos: Vector3 = hit["position"]
			var h_norm: Vector3 = hit["normal"]
			var angle_cosine := absf(spread_dir.dot(h_norm))
			var stretch := clampf(1.0 / maxf(angle_cosine, 0.34), 1.0, 2.35)
			var tangent := spread_dir - h_norm * spread_dir.dot(h_norm)
			var sz := randf_range(0.58, 1.05) * (1.25 if is_headshot else 1.0)
			spawn_blood_decal(h_pos, h_norm, Vector3(sz, 0.32, sz * stretch), tangent)

	# 5. Floor drip directly beneath wound
	if not skip_floor_drip:
		var down_q := PhysicsRayQueryParameters3D.create(pos, pos + Vector3(randf_range(-0.22, 0.22), -2.6, randf_range(-0.22, 0.22)), 1)
		var f_hit := space.intersect_ray(down_q)
		if not f_hit.is_empty():
			var fs := randf_range(0.45, 0.85) * clampf(intensity, 0.8, 1.35)
			spawn_blood_decal(f_hit["position"], f_hit["normal"], Vector3(fs, 0.35, fs))

func spawn_dismember_burst(pos: Vector3, shot_dir: Vector3, is_head: bool = false) -> void:
	var dir := shot_dir.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3.UP
	spawn_blood_impact(pos, dir, 1.65 if is_head else 1.40, true, true, true)
	# Extra upward arterial fountain + bone/flesh chunks for unmistakable dismemberment
	var up_dir := (dir * 0.45 + Vector3.UP * 0.85).normalized()
	var st := _streak_pool[_streak_idx % _streak_pool.size()]
	_streak_idx += 1
	st.global_transform = Transform3D(_orient_along_dir(up_dir), pos)
	var s_pm := st.process_material as ParticleProcessMaterial
	s_pm.spread = 42.0 if is_head else 34.0
	s_pm.initial_velocity_min = 3.8
	s_pm.initial_velocity_max = 11.2 if is_head else 8.8
	st.restart()
	st.emitting = true

	var ch := _chunk_pool[_chunk_idx % _chunk_pool.size()]
	_chunk_idx += 1
	ch.global_transform = Transform3D(_orient_along_dir(up_dir), pos)
	ch.restart()
	ch.emitting = true

	var space := get_world_3d().direct_space_state
	if space:
		var down_q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.15, 0), pos + Vector3(0, -3.5, 0), 1)
		var f_hit := space.intersect_ray(down_q)
		if not f_hit.is_empty():
			spawn_blood_pool(f_hit["position"], f_hit["normal"], 1.85 if is_head else 1.45, 0.42)

func spawn_blood_decal(pos: Vector3, normal: Vector3, size_vec: Vector3, tangent_hint: Vector3 = Vector3.ZERO) -> Decal:
	if _blood_decals.is_empty():
		return null
	var d := _blood_decals[_blood_decal_idx % _blood_decals.size()]
	_blood_decal_idx += 1
	d.global_transform = _orient_decal_onto_surface(pos, normal, tangent_hint)
	d.size = size_vec
	var tone := randf_range(0.28, 0.44)
	d.modulate = Color(tone, tone * 0.05, tone * 0.06, 0.94)
	d.visible = true
	return d

func spawn_blood_pool(floor_pos: Vector3, normal: Vector3 = Vector3.UP, target_size: float = 1.65, speed: float = 0.32) -> MeshInstance3D:
	if _blood_pools.is_empty():
		return null
	var entry: Dictionary = _blood_pools[_blood_pool_idx % _blood_pools.size()]
	_blood_pool_idx += 1
	var mi: MeshInstance3D = entry["mesh"]
	var sm: ShaderMaterial = entry["mat"]
	mi.global_transform = _orient_quad_normal(floor_pos, normal, randf() * TAU)
	mi.scale = Vector3(target_size, target_size, 1.0)
	entry["growth"] = 0.14
	entry["speed"] = speed
	sm.set_shader_parameter("growth", 0.14)
	sm.set_shader_parameter("seed", randf() * 10.0)
	mi.visible = true
	if not _active_pool_growths.has(entry):
		_active_pool_growths.append(entry)
	return mi

func spawn_muzzle_sparks(pos: Vector3, fwd_dir: Vector3, is_shotgun: bool = false) -> void:
	if _muzzle_spark_pool.is_empty():
		return
	var p := _muzzle_spark_pool[_muzzle_spark_idx % _muzzle_spark_pool.size()]
	_muzzle_spark_idx += 1
	p.global_transform = Transform3D(_orient_along_dir(fwd_dir), pos)
	var pm := p.process_material as ParticleProcessMaterial
	pm.spread = 22.0 if is_shotgun else 13.0
	pm.initial_velocity_min = 7.0
	pm.initial_velocity_max = 16.5 if is_shotgun else 13.5
	p.restart()
	p.emitting = true

func spawn_surface_impact(pos: Vector3, normal: Vector3, incident_dir: Vector3, collider: Object, weapon_idx: int) -> void:
	var surface := "plaster"
	if collider is Node and (collider as Node).has_meta(&"surface"):
		surface = str((collider as Node).get_meta(&"surface"))

	var refl := incident_dir.normalized().bounce(normal.normalized()).normalized()
	var splash_dir := (normal.normalized() * 0.65 + refl * 0.35).normalized()
	var hole_scale := 0.17 if weapon_idx == 0 else (0.22 if weapon_idx == 1 else 0.19)

	# 1. Surface-specific dust plume (lit, soft depth-faded, never blown out white)
	var dust := _dust_pool[_dust_idx % _dust_pool.size()]
	_dust_idx += 1
	dust.global_transform = Transform3D(_orient_along_dir(splash_dir), pos + normal * 0.025)
	var d_pm := dust.process_material as ParticleProcessMaterial
	var d_mat := dust.draw_pass_1.material as ShaderMaterial
	match surface:
		"brick":
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.62, 0.34, 0.24, 0.64))
			d_pm.initial_velocity_min = 1.4; d_pm.initial_velocity_max = 3.8
		"stone", "tile":
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.56, 0.58, 0.61, 0.56))
			d_pm.initial_velocity_min = 1.5; d_pm.initial_velocity_max = 4.0
		"wood":
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.68, 0.55, 0.38, 0.44))
			d_pm.initial_velocity_min = 1.2; d_pm.initial_velocity_max = 3.2
		"snow":
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.84, 0.90, 0.98, 0.72))
			d_pm.initial_velocity_min = 2.0; d_pm.initial_velocity_max = 4.8
		"metal":
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.45, 0.46, 0.48, 0.28))
			d_pm.initial_velocity_min = 0.8; d_pm.initial_velocity_max = 2.4
		_:
			if d_mat: d_mat.set_shader_parameter("tint_color", Color(0.76, 0.72, 0.66, 0.60))
			d_pm.initial_velocity_min = 1.4; d_pm.initial_velocity_max = 3.8
	dust.restart()
	dust.emitting = true

	# 2. Tumbling 3D chips / wood splinters (no chips on snow or metal)
	if surface != "snow" and surface != "metal":
		var ch := _chip_pool[_chip_idx % _chip_pool.size()]
		_chip_idx += 1
		ch.global_transform = Transform3D(_orient_along_dir(splash_dir), pos + normal * 0.025)
		if surface == "wood":
			ch.draw_pass_1 = _chip_mesh_wood
		elif surface == "brick":
			ch.draw_pass_1 = _chip_mesh_masonry
		else:
			ch.draw_pass_1 = _chip_mesh_stone
		ch.restart()
		ch.emitting = true

	# 3. Real ricochet sparks ONLY on metal!
	if surface == "metal":
		var sp := _spark_pool[_spark_idx % _spark_pool.size()]
		_spark_idx += 1
		sp.global_transform = Transform3D(_orient_along_dir(refl), pos + normal * 0.02)
		sp.restart()
		sp.emitting = true

	# 4. Normal+ORM Crater Decal (omitted cleanly on loose snow)
	if surface != "snow" and not _impact_decals.is_empty():
		var d := _impact_decals[_impact_decal_idx % _impact_decals.size()]
		_impact_decal_idx += 1
		d.global_transform = _orient_decal_onto_surface(pos, normal)
		if surface == "wood":
			d.texture_albedo = _tex_wood_hole
			d.texture_normal = _tex_wood_hole_n
			d.texture_orm = null
			d.modulate = Color(1.0, 1.0, 1.0, 0.96)
			d.size = Vector3(hole_scale * 0.95, 0.20, hole_scale * 1.45)
		else:
			d.texture_albedo = _tex_bullet_hole
			d.texture_normal = _tex_bullet_hole_n
			d.texture_orm = _tex_bullet_hole_orm
			if surface == "brick":
				d.modulate = Color(0.86, 0.64, 0.56, 0.95)
			elif surface == "metal":
				d.modulate = Color(0.32, 0.34, 0.38, 0.96)
			else:
				d.modulate = Color(0.92, 0.90, 0.86, 0.95)
			var mult := 0.65 if surface == "metal" else 1.0
			d.size = Vector3(hole_scale * mult, 0.20, hole_scale * mult)
		d.visible = true

	# 5. Pooled impact audio
	if _sfx_impact_hard and not _audio_pool.is_empty():
		var ap := _audio_pool[_audio_idx % _audio_pool.size()]
		_audio_idx += 1
		ap.global_position = pos
		match surface:
			"metal":
				ap.pitch_scale = randf_range(1.45, 1.85)
				ap.volume_db = -6.0
			"wood":
				ap.pitch_scale = randf_range(0.68, 0.88)
				ap.volume_db = -9.0
			"snow":
				ap.pitch_scale = randf_range(0.45, 0.62)
				ap.volume_db = -18.0
			_:
				ap.pitch_scale = randf_range(0.88, 1.15)
				ap.volume_db = -8.5
		ap.play()

func spawn_tinted_mist(pos: Vector3, dir: Vector3, tint: Color, intensity: float = 1.0) -> void:
	# Generic lit puff from the pooled dust emitters (acid splashes, slam dust, shattered visors)
	if _dust_pool.is_empty():
		return
	var d_dir := dir.normalized() if dir.length_squared() > 0.001 else Vector3.UP
	var dust := _dust_pool[_dust_idx % _dust_pool.size()]
	_dust_idx += 1
	dust.global_transform = Transform3D(_orient_along_dir(d_dir), pos)
	var d_pm := dust.process_material as ParticleProcessMaterial
	var d_mat := dust.draw_pass_1.material as ShaderMaterial
	if d_mat:
		d_mat.set_shader_parameter("tint_color", tint)
	d_pm.initial_velocity_min = 1.2 * intensity
	d_pm.initial_velocity_max = 3.6 * intensity
	dust.restart()
	dust.emitting = true


func run_pipeline_warmup(cam_pos: Vector3, cam_fwd: Vector3) -> void:
	var target_pos := cam_pos + cam_fwd.normalized() * 3.0
	spawn_blood_impact(target_pos, cam_fwd, 1.1, true, true)
	spawn_muzzle_sparks(cam_pos + cam_fwd * 0.7, cam_fwd, true)
	var dummy_wood := Node.new()
	dummy_wood.set_meta(&"surface", "wood")
	spawn_surface_impact(target_pos + Vector3(0.3, 0.0, 0.0), -cam_fwd, cam_fwd, dummy_wood, 2)
	var dummy_metal := Node.new()
	dummy_metal.set_meta(&"surface", "metal")
	spawn_surface_impact(target_pos + Vector3(-0.3, 0.0, 0.0), -cam_fwd, cam_fwd, dummy_metal, 1)
	dummy_wood.free()
	dummy_metal.free()
	spawn_blood_pool(Vector3(target_pos.x, 0.01, target_pos.z), Vector3.UP, 1.1, 1.5)

func clear_warmup_effects() -> void:
	for d in _blood_decals:
		d.visible = false
	for d in _impact_decals:
		d.visible = false
	for entry in _blood_pools:
		(entry["mesh"] as MeshInstance3D).visible = false
	_active_pool_growths.clear()
	_blood_decal_idx = 0
	_impact_decal_idx = 0
	_blood_pool_idx = 0
