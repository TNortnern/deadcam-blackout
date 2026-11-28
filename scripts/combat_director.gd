extends Node3D
class_name CombatDirector
## Owns the world-space enemy hazards that outlive a single zombie: spitter acid globs and the pools they leave,
## plus the area effects of screams and ground slams. Everything is pooled so a late wave allocates nothing.

static var instance: CombatDirector = null

const MAX_GLOBS := 6
const MAX_POOLS := 8
const GLOB_GRAVITY := 9.5

var player: PlayerBodycam = null

var _globs: Array[Dictionary] = []
var _pools: Array[Dictionary] = []
var _pool_idx: int = 0
var _glob_mesh: SphereMesh
var _glob_mat: StandardMaterial3D
var _pool_shader: Shader
var _noise_tex: Texture2D
var _audio: Array[AudioStreamPlayer3D] = []
var _audio_idx: int = 0
var _sfx_sizzle: AudioStream
var _sfx_slam: AudioStream


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if ResourceLoader.exists("res://assets/audio/acid_sizzle.wav"):
		_sfx_sizzle = load("res://assets/audio/acid_sizzle.wav")
	if ResourceLoader.exists("res://assets/audio/zombie_slam.wav"):
		_sfx_slam = load("res://assets/audio/zombie_slam.wav")
	_pool_shader = load("res://shaders/blood_pool.gdshader")
	var nt := NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.seed = 9041
	fn.frequency = 0.035
	nt.noise = fn
	_noise_tex = nt

	_glob_mesh = SphereMesh.new()
	_glob_mesh.radius = 0.075
	_glob_mesh.height = 0.15
	_glob_mesh.radial_segments = 12
	_glob_mesh.rings = 6
	_glob_mat = StandardMaterial3D.new()
	_glob_mat.albedo_color = Color(0.46, 0.60, 0.10)
	_glob_mat.roughness = 0.12
	_glob_mat.metallic_specular = 0.85
	_glob_mat.emission_enabled = true
	_glob_mat.emission = Color(0.30, 0.44, 0.04)
	_glob_mat.emission_energy_multiplier = 0.9
	_glob_mesh.material = _glob_mat
	for _i in range(MAX_GLOBS):
		var mi := MeshInstance3D.new()
		mi.mesh = _glob_mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_globs.append({"node": mi, "active": false, "vel": Vector3.ZERO, "age": 0.0})

	for _i in range(MAX_POOLS):
		var pm := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.0, 1.0)
		pm.mesh = qm
		var sm := ShaderMaterial.new()
		sm.shader = _pool_shader
		sm.set_shader_parameter("noise_tex", _noise_tex)
		sm.set_shader_parameter("core_color", Color(0.16, 0.24, 0.02))
		sm.set_shader_parameter("rim_color", Color(0.34, 0.46, 0.06))
		sm.set_shader_parameter("wet_roughness", 0.05)
		sm.set_shader_parameter("rim_roughness", 0.16)
		sm.set_shader_parameter("growth", 0.14)
		pm.material_override = sm
		pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pm.visible = false
		add_child(pm)
		_pools.append({"node": pm, "mat": sm, "active": false, "age": 0.0, "dur": 0.0, "radius": 1.0, "tick": 0.0, "pos": Vector3.ZERO})

	for _i in range(4):
		var ap := AudioStreamPlayer3D.new()
		ap.unit_size = 5.0
		ap.max_distance = 26.0
		add_child(ap)
		_audio.append(ap)


func _play_at(stream: AudioStream, pos: Vector3, pitch := 1.0, vol_db := -3.0) -> void:
	if stream == null or _audio.is_empty():
		return
	var ap := _audio[_audio_idx % _audio.size()]
	_audio_idx += 1
	ap.global_position = pos
	ap.stream = stream
	ap.pitch_scale = pitch
	ap.volume_db = vol_db
	ap.play()


func clear_all() -> void:
	for g in _globs:
		g["active"] = false
		(g["node"] as Node3D).visible = false
	for p in _pools:
		p["active"] = false
		(p["node"] as Node3D).visible = false


func spawn_acid_glob(from: Vector3, target_pos: Vector3) -> void:
	# Ballistic lob: pick a flight time from the range, then solve the launch velocity that lands on the target
	var slot: Dictionary = {}
	for g in _globs:
		if not bool(g["active"]):
			slot = g
			break
	if slot.is_empty():
		slot = _globs[0]
	var d := from.distance_to(target_pos)
	var t := clampf(d / 12.5, 0.42, 1.05)
	var vel := (target_pos - from - Vector3(0.0, -0.5 * GLOB_GRAVITY * t * t, 0.0)) / t
	slot["active"] = true
	slot["vel"] = vel
	slot["age"] = 0.0
	var n := slot["node"] as MeshInstance3D
	n.global_position = from
	n.visible = true


func _physics_process(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	for g in _globs:
		if not bool(g["active"]):
			continue
		var n := g["node"] as MeshInstance3D
		var vel: Vector3 = g["vel"]
		var p0 := n.global_position
		vel.y -= GLOB_GRAVITY * delta
		var p1 := p0 + vel * delta
		g["vel"] = vel
		g["age"] = float(g["age"]) + delta
		var hit_pos := Vector3.ZERO
		var hit_n := Vector3.UP
		var landed := false
		# Direct hit on the player: segment against the capsule's centre line
		if player and is_instance_valid(player) and not player.dead:
			var c := player.global_position + Vector3(0.0, 0.9, 0.0)
			var seg := p1 - p0
			var tt := clampf((c - p0).dot(seg) / maxf(seg.length_squared(), 0.0001), 0.0, 1.0)
			var closest := p0 + seg * tt
			var dv := closest - c
			if Vector2(dv.x, dv.z).length() < 0.48 and absf(dv.y) < 1.0:
				landed = true
				hit_pos = closest
				hit_n = Vector3.UP
				player.last_hit_by = "SPITTER ACID"
				player.take_damage(14.0, p0 - vel.normalized())
				player.apply_slow(0.7, 1.4)
		if not landed and space:
			var q := PhysicsRayQueryParameters3D.create(p0, p1, 1)
			var res := space.intersect_ray(q)
			if not res.is_empty():
				landed = true
				hit_pos = res["position"]
				hit_n = res["normal"]
		if landed or float(g["age"]) > 4.0:
			g["active"] = false
			n.visible = false
			if landed:
				_acid_splash(hit_pos, hit_n)
		else:
			n.global_position = p1
			# Stretch the glob along its velocity so it reads as a thrown string of bile rather than a ball
			var sp := vel.length()
			if sp > 0.5:
				var fwd := vel / sp
				var up := Vector3.UP if absf(fwd.y) < 0.95 else Vector3.RIGHT
				var bx := up.cross(fwd).normalized()
				var by := fwd.cross(bx).normalized()
				n.global_transform.basis = Basis(bx, by, fwd * clampf(1.0 + sp * 0.11, 1.0, 2.6))

	for p in _pools:
		if not bool(p["active"]):
			continue
		var age := float(p["age"]) + delta
		p["age"] = age
		var dur := float(p["dur"])
		var sm := p["mat"] as ShaderMaterial
		var grow := clampf(age / 0.35, 0.0, 1.0)
		var fade := clampf((dur - age) / 0.8, 0.0, 1.0)
		sm.set_shader_parameter("growth", maxf(0.05, grow * fade))
		if age >= dur:
			p["active"] = false
			(p["node"] as Node3D).visible = false
			continue
		p["tick"] = float(p["tick"]) - delta
		if float(p["tick"]) <= 0.0:
			p["tick"] = 0.5
			if player and is_instance_valid(player) and not player.dead:
				var pp := player.global_position
				var c2: Vector3 = p["pos"]
				if Vector2(pp.x - c2.x, pp.z - c2.z).length() <= float(p["radius"]) * fade and absf(pp.y - c2.y) < 1.2:
					player.last_hit_by = "ACID POOL"
					player.take_damage(6.0, c2)
					player.apply_slow(0.72, 0.8)


func _acid_splash(pos: Vector3, normal: Vector3) -> void:
	_play_at(_sfx_sizzle, pos, randf_range(0.92, 1.1), -4.0)
	if VFXManager.instance:
		VFXManager.instance.spawn_tinted_mist(pos + normal * 0.08, normal, Color(0.52, 0.66, 0.10, 0.72), 1.1)
	if player and is_instance_valid(player) and not player.dead:
		var d := player.global_position.distance_to(pos)
		if d < 1.7:
			player.take_damage(lerpf(10.0, 4.0, d / 1.7), pos)
	if normal.y > 0.6:
		spawn_acid_pool(pos, 1.35, 4.2)


func spawn_acid_pool(pos: Vector3, radius: float, dur: float) -> void:
	var p := _pools[_pool_idx % _pools.size()]
	_pool_idx += 1
	var n := p["node"] as MeshInstance3D
	n.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).rotated(Vector3.UP, randf() * TAU), pos + Vector3(0.0, 0.025, 0.0))
	n.scale = Vector3(radius * 2.3, radius * 2.3, 1.0)
	n.visible = true
	(p["mat"] as ShaderMaterial).set_shader_parameter("seed", randf() * 10.0)
	p["active"] = true
	p["age"] = 0.0
	p["dur"] = dur
	p["radius"] = radius
	p["tick"] = 0.35
	p["pos"] = pos


func ground_slam(pos: Vector3, radius: float, damage: float, source: Node3D) -> void:
	_play_at(_sfx_slam, pos, randf_range(0.9, 1.05), 2.0)
	if VFXManager.instance:
		for k in range(5):
			var a := TAU * float(k) / 5.0 + randf() * 0.5
			var off := Vector3(cos(a), 0.0, sin(a)) * radius * 0.55
			VFXManager.instance.spawn_tinted_mist(pos + off + Vector3(0.0, 0.08, 0.0), (off.normalized() + Vector3.UP).normalized(), Color(0.62, 0.58, 0.52, 0.55), 1.3)
	if player == null or not is_instance_valid(player) or player.dead:
		return
	var to := player.global_position - pos
	var d := Vector2(to.x, to.z).length()
	player.trauma = minf(1.0, player.trauma + clampf(1.0 - d / (radius * 3.0), 0.0, 0.6))
	if d <= radius and absf(to.y) < 1.4:
		var fall := clampf(1.0 - (d / radius) * 0.5, 0.5, 1.0)
		player.take_damage(damage * fall, source.global_position + Vector3(0.0, 1.2, 0.0) if source else pos)
		var dir := Vector3(to.x, 0.0, to.z).normalized() if d > 0.05 else Vector3.FORWARD
		player.apply_external_impulse(dir * 7.5 * fall + Vector3(0.0, 3.2, 0.0))


func scream_wave(pos: Vector3, source: ZombieAI) -> void:
	# Rallies every zombie in earshot and rattles the bodycam if the player is close
	for z_raw in ZombieAI._all_zombies:
		var z := z_raw as ZombieAI
		if is_instance_valid(z) and not z.dead and z != source and z.global_position.distance_to(pos) < 17.0:
			z.enrage(6.5)
	if player and is_instance_valid(player) and not player.dead:
		var d := player.global_position.distance_to(pos)
		if d < 11.0:
			var k := 1.0 - d / 11.0
			player.trauma = minf(1.0, player.trauma + 0.35 + 0.35 * k)
			player.hit_glitch = maxf(player.hit_glitch, 0.22 + 0.3 * k)
			player.ads_lockout = maxf(player.ads_lockout, 0.35 + 0.5 * k)
