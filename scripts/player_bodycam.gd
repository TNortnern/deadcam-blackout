extends CharacterBody3D
class_name PlayerBodycam

const WEAPONS := [
	{
		"name": "G17 TACTICAL",
		"glb": "res://assets/models/weapon_pistol.glb",
		"audio": "res://assets/audio/gun_pistol.wav",
		"audio_b": "res://assets/audio/gun_pistol_b.wav",
		"mag_size": 15,
		"reserve_max": 90,
		"damage": 38.0,
		"fire_rate": 0.18,
		"auto": false,
		"pellets": 1,
		"spread": 0.012,
		"recoil_pitch": 0.055,
		"recoil_kick": 0.045,
		"flash_scale": 0.72,
		"hip_pos": Vector3(0.077, -0.180, -0.221),
		"hip_rot": Vector3(-0.13, 0.06, -0.062),
		"ads_pos": Vector3(0.0, -0.095, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.05, -0.28),
		"ejection": Vector3(0.025, 0.055, -0.08),
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "M16A2 REFLEX",
		"glb": "res://assets/models/weapon_rifle.glb",
		"audio": "res://assets/audio/gun_rifle.wav",
		"audio_b": "res://assets/audio/gun_rifle_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 34.0,
		"fire_rate": 0.095,
		"auto": true,
		"pellets": 1,
		"spread": 0.010,
		"recoil_pitch": 0.038,
		"recoil_kick": 0.032,
		"flash_scale": 1.0,
		"hip_pos": Vector3(0.116, -0.229, -0.249),
		"hip_rot": Vector3(0.02, 0.11, -0.05),
		"ads_pos": Vector3(0.0, -0.091, -0.273),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.03, -0.62),
		"ejection": Vector3(0.055, 0.045, -0.06),
		"has_holo": true,
		"holo_pos": Vector3(0.0, 0.091, -0.096),
	},
	{
		"name": "M870 BREACHER",
		"glb": "res://assets/models/weapon_shotgun.glb",
		"audio": "res://assets/audio/gun_shotgun.wav",
		"audio_b": "res://assets/audio/gun_shotgun_b.wav",
		"mag_size": 8,
		"reserve_max": 48,
		"damage": 24.0,
		"fire_rate": 0.72,
		"auto": false,
		"pellets": 7,
		"spread": 0.055,
		"recoil_pitch": 0.11,
		"recoil_kick": 0.085,
		"flash_scale": 1.35,
		"hip_pos": Vector3(0.112, -0.205, -0.245),
		"hip_rot": Vector3(0.02, 0.10, -0.05),
		"ads_pos": Vector3(0.0, -0.036, -0.270),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.015, -0.695),
		"ejection": Vector3(0.024, 0.014, -0.150),
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "COMBAT KNIFE",
		"glb": "",
		"audio": "res://assets/audio/melee_swing.wav",
		"is_melee": true,
		"mag_size": 1,
		"reserve_max": 0,
		"damage": 55.0,
		"fire_rate": 0.44,
		"auto": false,
		"pellets": 1,
		"spread": 0.0,
		"recoil_pitch": 0.02,
		"recoil_kick": 0.02,
		"flash_scale": 0.0,
		"hip_pos": Vector3(0.20, -0.24, -0.36),
		"hip_rot": Vector3(0.20, -0.78, 0.28),
		"ads_pos": Vector3(0.14, -0.19, -0.32),
		"ads_rot": Vector3(0.24, -0.62, 0.34),
		"muzzle": Vector3(0.0, 0.0, -0.35),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "COMPOUND BOW",
		"glb": "",
		"custom_rig": "bow",
		"audio": "res://assets/audio/bow_release.wav",
		"is_bow": true,
		"mag_size": 1,
		"reserve_max": 18,
		"damage": 160.0,
		"fire_rate": 0.42,
		"auto": false,
		"pellets": 1,
		"spread": 0.002,
		"recoil_pitch": 0.025,
		"recoil_kick": 0.020,
		"flash_scale": 0.0,
		"hip_pos": Vector3(0.145, -0.155, -0.34),
		"hip_rot": Vector3(0.02, 0.06, -0.24),
		"ads_pos": Vector3(0.024, -0.095, -0.30),
		"ads_rot": Vector3(0.0, 0.0, -0.08),
		"muzzle": Vector3(0.0, 0.02, -0.42),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "MP5A3 SUPPRESSED",
		"glb": "",
		"custom_rig": "mp5",
		"audio": "res://assets/audio/gun_mp5_sd.wav",
		"audio_b": "res://assets/audio/gun_mp5_sd_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 24.0,
		"fire_rate": 0.068,
		"auto": true,
		"pellets": 1,
		"spread": 0.014,
		"recoil_pitch": 0.022,
		"recoil_kick": 0.020,
		"flash_scale": 0.22,
		"hip_pos": Vector3(0.125, -0.175, -0.30),
		"hip_rot": Vector3(0.02, 0.09, -0.05),
		"ads_pos": Vector3(0.0, -0.078, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.025, -0.58),
		"ejection": Vector3(0.036, 0.032, -0.09),
		"has_holo": true,
		"holo_pos": Vector3(0.0, 0.078, -0.085),
	},
	{
		"name": ".44 MAGNUM",
		"glb": "",
		"custom_rig": "magnum",
		"audio": "res://assets/audio/gun_magnum.wav",
		"audio_b": "res://assets/audio/gun_magnum_b.wav",
		"mag_size": 6,
		"reserve_max": 42,
		"damage": 115.0,
		"fire_rate": 0.42,
		"auto": false,
		"pellets": 1,
		"spread": 0.009,
		"recoil_pitch": 0.135,
		"recoil_kick": 0.075,
		"flash_scale": 1.25,
		"hip_pos": Vector3(0.105, -0.160, -0.28),
		"hip_rot": Vector3(-0.04, 0.06, -0.05),
		"ads_pos": Vector3(0.0, -0.072, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.042, -0.38),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "M700 .308 HUNTING",
		"glb": "",
		"custom_rig": "hunting",
		"audio": "res://assets/audio/gun_hunting.wav",
		"audio_b": "res://assets/audio/gun_hunting_b.wav",
		"mag_size": 5,
		"reserve_max": 35,
		"damage": 165.0,
		"fire_rate": 1.05,
		"auto": false,
		"pellets": 1,
		"spread": 0.002,
		"recoil_pitch": 0.120,
		"recoil_kick": 0.080,
		"flash_scale": 1.30,
		"ads_fov": 42.0,
		"hip_pos": Vector3(0.132, -0.185, -0.32),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.088, -0.23),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.030, -0.82),
		"ejection": Vector3(0.040, 0.036, -0.10),
		"has_holo": true,
		"holo_pos": Vector3(0.0, 0.088, -0.12),
	}
]

const MELEE_CATALOG := {
	"knife": {"name": "COMBAT KNIFE", "damage": 55.0, "reach": 2.15, "dur": 0.42},
	"fire_axe": {"name": "FIRE AXE", "damage": 94.0, "reach": 2.48, "dur": 0.56},
	"machete": {"name": "TACTICAL MACHETE", "damage": 78.0, "reach": 2.34, "dur": 0.46},
}

var head: Node3D
var camera: Camera3D
var cam_attrs: CameraAttributesPractical
var weapon_clearance: Node3D
var weapon_pivot: Node3D
var weapon_rig_holder: Node3D
var holo_quad: MeshInstance3D
var vm_rim: OmniLight3D
var flashlight: SpotLight3D
var flashlight_spill: SpotLight3D
var flashlight_bounce: OmniLight3D
var flashlight_cone: MeshInstance3D
var dust_motes: GPUParticles3D
var muzzle_light: OmniLight3D
var muzzle_vm_light: OmniLight3D
var muzzle_flash_rig: Node3D
var _flash_mats: Array[ShaderMaterial] = []
var muzzle_smoke: GPUParticles3D
var interact_ray: RayCast3D

var sfx_gun: AudioStreamPlayer
var sfx_misc: AudioStreamPlayer
var sfx_reload: AudioStreamPlayer
var sfx_step: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_hit_tick: AudioStreamPlayer
var sfx_casing: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer
var sfx_slash: AudioStreamPlayer

var health: float = 100.0
var max_health: float = 100.0
var dead: bool = false
var flashlight_on: bool = true
var is_ads: bool = false
var is_crouching: bool = false
var is_sprinting: bool = false
var is_reloading: bool = false

# Multi-stage reload sequencer state
var reload_elapsed: float = 0.0
var reload_dur: float = 1.85
var reload_was_empty: bool = false
var reload_flags: int = 0
var reload_shell_timer: float = 0.0
var reload_shell_phase: int = 0 # 0=enter, 1=loop, 2=exit
var reload_cancel_req: bool = false
var _shotgun_fire_on_cancel: bool = false
var _last_near_focus: float = -1.0
var reload_pos_off: Vector3 = Vector3.ZERO
var reload_rot_off: Vector3 = Vector3.ZERO

var fire_cd: float = 0.0
var muzzle_elapsed: float = 9.0
var muzzle_peak_e: float = 0.0
var muzzle_flash_timer: float = 0.0
var damage_flash: float = 0.0
var damage_invuln: float = 0.0
var ads_lockout: float = 0.0
var hit_glitch: float = 0.0
var hit_ca_boost: float = 0.0
var hit_dir_screen: Vector2 = Vector2.ZERO
var _ads_blend: float = 0.0
var _sprint_blend: float = 0.0
var _sprint_out_timer: float = 0.0
var _iris_wall_dim: float = 1.0
var _was_on_floor: bool = true
var _pre_land_vy: float = 0.0
var _land_dip: float = 0.0

var current_weapon: int = 0
var unlocked_weapons: Array[bool] = [true, true, true, true, true, true, true, true]
var ammo_in_mag: Array[int] = [15, 30, 8, 1, 1, 30, 6, 5]
var ammo_reserve: Array[int] = [90, 180, 48, 0, 18, 180, 42, 35]
var equipped_melee_id: String = "knife"
var _melee_timer: float = 0.0
var _melee_dur: float = 0.42
var _melee_hit_done: bool = false
var _melee_nodes: Dictionary = {} # melee_id -> Node3D

# Bow, Revolver & Bolt-Action Hunting Rifle state
var _bow_drawing: bool = false
var _bow_draw: float = 0.0
var _bow_hold_time: float = 0.0
var _bow_nock_timer: float = 0.0
var _bow_parts: Dictionary = {}
var _arrows: Array[Dictionary] = []
var _revolver_cyl_angle: float = 0.0
var _revolver_hammer: float = 0.0
var _hunting_bolt_timer: float = 0.0
var _hunting_bolt_did_sfx: bool = false

var yaw: float = 0.0
var pitch: float = 0.0
var yaw_vel: float = 0.0
var _last_yaw: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO
var recoil_vel: Vector2 = Vector2.ZERO
var recoil_z: float = 0.0
var recoil_roll: float = 0.0
var recoil_fov: float = 0.0
var hit_roll_kick: float = 0.0
var hit_pitch_kick: float = 0.0
var trauma: float = 0.0
var _noise: FastNoiseLite
var bob_phase: float = 0.0
var step_dist: float = 0.0
var step_side: float = 1.0
var step_roll_impulse: float = 0.0
var bolt_blowback: float = 0.0
var shotgun_pump_timer: float = 0.0
var shotgun_pump_did_sfx: bool = false
var _barrel_heat_timer: float = 0.0
var _barrel_heat_step: float = 0.0
var _flash_shadow_boost: float = 0.0
var mouse_sens: float = 0.0022
var input_enabled: bool = true
var deterministic_camera: bool = false
var skip_initial_weapon_prebuild: bool = false

var game_manager: Node = null
var _glb_cache: Dictionary = {}
var _casings: Array[Dictionary] = []
var _weapon_rigs: Array[Node3D] = []
var _weapon_audio: Array[AudioStream] = []
var _weapon_audio_vars: Array = []
var _gun_alt_flip: int = 0
var _m16_dust_open: bool = false
var _shotgun_shell_rig: Node3D = null
var _w_parts_by_idx: Array[Dictionary] = []
var _w_parts: Dictionary = {} # group_name -> Array[Node3D]
var _w_rest_pos: Dictionary = {} # instance_id -> Vector3
var _w_rest_rot: Dictionary = {} # instance_id -> Vector3

const EJECT_G17 := Vector3(0.0, -0.9336, 0.3583)
const PIVOT_G17_SLIDESTOP := Vector3(-0.010, 0.025, -0.162)
const PIVOT_G17_TRIGGER := Vector3(0.0, 0.022, -0.155)
const EJECT_AR := Vector3(0.012, -0.9758, -0.2183)
const PIVOT_AR_MAG := Vector3(0.0, -0.135, -0.135)
const PIVOT_AR_HAND := Vector3(-0.010, -0.055, -0.310)
const PIVOT_AR_LATCH := Vector3(-0.028, 0.0066, 0.038)
const PIVOT_AR_DUST := Vector3(0.0185, -0.0275, -0.119)
const PIVOT_AR_CATCH := Vector3(-0.0185, -0.039, -0.081)
const AXIS_AR_ASSIST := Vector3(-0.38, 0.0, -0.92)
const PORT_M870 := Vector3(0.001, -0.058, -0.124)
const SHELL_M870_START := Vector3(0.001, -0.165, -0.105)
const SHELL_M870_ENTER := Vector3(0.001, -0.038, -0.158)
const SHELL_M870_SEAT := Vector3(0.001, -0.029, -0.198)
const PIVOT_M870_LIFTER := Vector3(0.001, -0.036, -0.184)

static var _casing_mesh: CylinderMesh = null
static var _hull_mesh: CylinderMesh = null
static var _mag_mesh_g17: BoxMesh = null
static var _mag_mesh_ar: Mesh = null
static var _mag_mat_ar: Material = null
static var _mag_mat_dark: StandardMaterial3D = null
static var _sfx_flashlight_click: AudioStream = null
static var _sfx_reload_mech: AudioStream = null
static var _sfx_mag_out: AudioStream = null
static var _sfx_mag_in: AudioStream = null
static var _sfx_bolt: AudioStream = null
static var _sfx_shell_in: AudioStream = null
static var _sfx_hit_flesh: Array[AudioStream] = []
static var _sfx_hit_head: Array[AudioStream] = []
static var _sfx_hit_confirm: AudioStream = null
static var _sfx_shell_clink: Array[AudioStream] = []
static var _sfx_impact_hard: AudioStream = null
static var _sfx_player_slash: Array[AudioStream] = []
static var _sfx_player_hurt: AudioStream = null
static var _sfx_melee_swing: AudioStream = null
static var _sfx_melee_cleave: AudioStream = null
static var _sfx_bow_draw: AudioStream = null
static var _sfx_bow_release: AudioStream = null
static var _sfx_arrow_impact: AudioStream = null

signal player_died
signal weapon_changed(index: int, name: String)
signal hit_confirmed(is_headshot: bool, killed: bool)
signal status_message(msg: String)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	_noise = FastNoiseLite.new()
	_noise.seed = 4077
	_noise.frequency = 1.8
	_preload_combat_fx()
	_build_rig()
	if not skip_initial_weapon_prebuild:
		_equip_weapon(0)


func _preload_combat_fx() -> void:
	for p in ["res://assets/audio/hit_flesh_a.wav", "res://assets/audio/hit_flesh_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_hit_flesh.append(load(p))
	for p in ["res://assets/audio/hit_headshot_a.wav", "res://assets/audio/hit_headshot_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_hit_head.append(load(p))
	for p in ["res://assets/audio/shell_clink_a.wav", "res://assets/audio/shell_clink_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_shell_clink.append(load(p))
	for p in ["res://assets/audio/player_hit_slash_a.wav", "res://assets/audio/player_hit_slash_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_player_slash.append(load(p))
	if ResourceLoader.exists("res://assets/audio/player_hurt.wav"):
		_sfx_player_hurt = load("res://assets/audio/player_hurt.wav")
	if ResourceLoader.exists("res://assets/audio/reload_mag_out.wav"):
		_sfx_mag_out = load("res://assets/audio/reload_mag_out.wav")
	if ResourceLoader.exists("res://assets/audio/reload_mag_in.wav"):
		_sfx_mag_in = load("res://assets/audio/reload_mag_in.wav")
	if ResourceLoader.exists("res://assets/audio/reload_bolt.wav"):
		_sfx_bolt = load("res://assets/audio/reload_bolt.wav")
	if ResourceLoader.exists("res://assets/audio/reload_shell_in.wav"):
		_sfx_shell_in = load("res://assets/audio/reload_shell_in.wav")
	if ResourceLoader.exists("res://assets/audio/hit_confirm.wav"):
		_sfx_hit_confirm = load("res://assets/audio/hit_confirm.wav")
	if ResourceLoader.exists("res://assets/audio/impact_hard.wav"):
		_sfx_impact_hard = load("res://assets/audio/impact_hard.wav")
	if ResourceLoader.exists("res://assets/audio/melee_swing.wav"):
		_sfx_melee_swing = load("res://assets/audio/melee_swing.wav")
	if ResourceLoader.exists("res://assets/audio/melee_cleave.wav"):
		_sfx_melee_cleave = load("res://assets/audio/melee_cleave.wav")
	if ResourceLoader.exists("res://assets/audio/bow_draw.wav"):
		_sfx_bow_draw = load("res://assets/audio/bow_draw.wav")
	if ResourceLoader.exists("res://assets/audio/bow_release.wav"):
		_sfx_bow_release = load("res://assets/audio/bow_release.wav")
	if ResourceLoader.exists("res://assets/audio/arrow_impact.wav"):
		_sfx_arrow_impact = load("res://assets/audio/arrow_impact.wav")

	if _casing_mesh == null:
		_casing_mesh = CylinderMesh.new()
		_casing_mesh.top_radius = 0.0045
		_casing_mesh.bottom_radius = 0.0052
		_casing_mesh.height = 0.026
		_casing_mesh.radial_segments = 8
		_casing_mesh.rings = 1
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.92, 0.72, 0.30)
		cmat.metallic = 0.94
		cmat.roughness = 0.22
		_casing_mesh.material = cmat
	if _hull_mesh == null:
		_hull_mesh = CylinderMesh.new()
		_hull_mesh.top_radius = 0.0090
		_hull_mesh.bottom_radius = 0.0094
		_hull_mesh.height = 0.062
		_hull_mesh.radial_segments = 8
		_hull_mesh.rings = 1
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(0.68, 0.06, 0.04)
		hmat.metallic = 0.14
		hmat.roughness = 0.34
		_hull_mesh.material = hmat


func _build_rig() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.72
	col.shape = cap
	col.position = Vector3(0, 0.86, 0)
	add_child(col)

	head = Node3D.new()
	head.position = Vector3(0, 1.56, 0)
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 94.0
	camera.near = 0.03
	camera.far = 150.0
	camera.current = true
	camera.cull_mask = 0xFFFFF
	cam_attrs = CameraAttributesPractical.new()
	cam_attrs.dof_blur_far_enabled = false
	cam_attrs.dof_blur_near_enabled = false
	cam_attrs.dof_blur_amount = 0.075
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		cam_attrs.auto_exposure_enabled = true
		cam_attrs.auto_exposure_scale = 0.68
		cam_attrs.auto_exposure_speed = 1.8
		cam_attrs.auto_exposure_min_sensitivity = 320.0
		cam_attrs.auto_exposure_max_sensitivity = 960.0
	camera.attributes = cam_attrs
	head.add_child(camera)

	interact_ray = RayCast3D.new()
	interact_ray.target_position = Vector3(0, 0, -2.8)
	interact_ray.collision_mask = 1 | 16
	camera.add_child(interact_ray)

	weapon_clearance = Node3D.new()
	camera.add_child(weapon_clearance)
	weapon_pivot = Node3D.new()
	weapon_clearance.add_child(weapon_pivot)

	weapon_rig_holder = Node3D.new()
	weapon_pivot.add_child(weapon_rig_holder)

	vm_rim = OmniLight3D.new()
	vm_rim.light_color = Color(0.86, 0.90, 0.96)
	vm_rim.light_energy = 0.16
	vm_rim.light_volumetric_fog_energy = 0.0
	vm_rim.omni_range = 1.8
	vm_rim.omni_attenuation = 1.6
	vm_rim.light_cull_mask = 2
	vm_rim.shadow_enabled = false
	vm_rim.light_bake_mode = Light3D.BAKE_DISABLED
	vm_rim.position = Vector3(-0.24, 0.15, -0.04)
	camera.add_child(vm_rim)

	holo_quad = MeshInstance3D.new()
	var hqm := QuadMesh.new()
	hqm.size = Vector2(0.014, 0.014)
	holo_quad.mesh = hqm
	var hmat := ShaderMaterial.new()
	hmat.render_priority = 8
	hmat.shader = load("res://shaders/holographic_sight.gdshader")
	holo_quad.material_override = hmat
	holo_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holo_quad.layers = 2
	weapon_pivot.add_child(holo_quad)

	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(0.96, 0.98, 1.0)
	flashlight.light_energy = 28.0
	flashlight.light_size = 0.0
	flashlight.light_indirect_energy = 1.0
	flashlight.light_volumetric_fog_energy = 0.72
	flashlight.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight.spot_range = 26.0
	flashlight.spot_attenuation = 1.12
	flashlight.spot_angle = 55.0
	flashlight.spot_angle_attenuation = 0.68
	flashlight.shadow_enabled = true
	var is_compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	flashlight.shadow_bias = 0.055 if is_compat else 0.025
	flashlight.shadow_normal_bias = 1.35 if is_compat else 0.45
	flashlight.shadow_caster_mask = 1 | 8
	flashlight.light_cull_mask = 0xFFFFD
	flashlight.light_projector = load("res://assets/textures/flashlight_cookie.png")
	flashlight.position = Vector3(0.09, -0.07, -0.44)
	camera.add_child(flashlight)

	# Compatibility stub kept disabled (outer spill is baked into the 1024px TIR optical cookie)
	flashlight_spill = SpotLight3D.new()
	flashlight_spill.light_energy = 0.0
	flashlight_spill.spot_range = 0.01
	flashlight_spill.shadow_enabled = false
	flashlight_spill.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight_spill.visible = false
	camera.add_child(flashlight_spill)

	# Single unshadowed dynamic bounce light driven by the flashlight hit ray (zero GI grid relight)
	flashlight_bounce = OmniLight3D.new()
	flashlight_bounce.top_level = true
	flashlight_bounce.light_color = Color(0.92, 0.88, 0.82)
	flashlight_bounce.light_energy = 0.0
	flashlight_bounce.light_specular = 0.0
	flashlight_bounce.light_volumetric_fog_energy = 0.0
	flashlight_bounce.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight_bounce.shadow_enabled = false
	flashlight_bounce.omni_range = 4.5
	flashlight_bounce.omni_attenuation = 2.0
	flashlight_bounce.light_cull_mask = 0xFFFFD
	flashlight_bounce.visible = false
	camera.add_child(flashlight_bounce)

	# Corrected cone orientation: narrow tip at emitter (-0.45) expanding outward toward -Z!
	flashlight_cone = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.15
	cm.bottom_radius = 0.025
	cm.height = 5.0
	cm.radial_segments = 24
	cm.rings = 4
	cm.cap_top = false
	cm.cap_bottom = false
	flashlight_cone.mesh = cm
	var cmat := ShaderMaterial.new()
	cmat.shader = load("res://shaders/flashlight_vol.gdshader")
	cmat.set_shader_parameter("intensity", 0.009)
	flashlight_cone.material_override = cmat
	flashlight_cone.position = Vector3(0.09, -0.07, -2.95)
	flashlight_cone.rotation.x = -PI * 0.5
	flashlight_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(flashlight_cone)

	# Camera-following ambient floating dust motes (lit strictly by real flashlight/lamps!)
	_build_dust_motes()

	# World muzzle flash light + dedicated viewmodel flash light (both off until firing -> zero idle tunnel overhead!)
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.78, 0.44)
	muzzle_light.light_energy = 0.0
	muzzle_light.light_volumetric_fog_energy = 0.0
	muzzle_light.omni_range = 5.5
	muzzle_light.omni_attenuation = 1.65
	muzzle_light.shadow_enabled = false
	muzzle_light.light_bake_mode = Light3D.BAKE_DISABLED
	muzzle_light.light_cull_mask = 0xFFFFD
	muzzle_light.visible = false
	weapon_pivot.add_child(muzzle_light)

	muzzle_vm_light = OmniLight3D.new()
	muzzle_vm_light.light_color = Color(1.0, 0.72, 0.36)
	muzzle_vm_light.light_energy = 0.0
	muzzle_vm_light.light_volumetric_fog_energy = 0.0
	muzzle_vm_light.omni_range = 1.4
	muzzle_vm_light.omni_attenuation = 1.8
	muzzle_vm_light.shadow_enabled = false
	muzzle_vm_light.light_bake_mode = Light3D.BAKE_DISABLED
	muzzle_vm_light.light_cull_mask = 2
	muzzle_vm_light.visible = false
	weapon_pivot.add_child(muzzle_vm_light)

	_build_muzzle_flash_rig()
	_build_muzzle_smoke()

	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var has_limiter := false
		for bi in range(AudioServer.get_bus_effect_count(master_idx)):
			if AudioServer.get_bus_effect(master_idx, bi) is AudioEffectLimiter:
				has_limiter = true
				break
		if not has_limiter:
			var lim := AudioEffectLimiter.new()
			lim.ceiling_db = -0.3
			lim.threshold_db = -1.5
			lim.soft_clip_db = 0.0
			AudioServer.add_bus_effect(master_idx, lim)

	sfx_gun = AudioStreamPlayer.new()
	sfx_gun.volume_db = -1.0
	sfx_gun.max_polyphony = 6
	add_child(sfx_gun)

	sfx_misc = AudioStreamPlayer.new()
	sfx_misc.volume_db = -5.0
	add_child(sfx_misc)

	sfx_reload = AudioStreamPlayer.new()
	sfx_reload.volume_db = -3.0
	add_child(sfx_reload)

	sfx_step = AudioStreamPlayer.new()
	sfx_step.stream = load("res://assets/audio/footstep.wav")
	sfx_step.volume_db = -10.5
	add_child(sfx_step)

	sfx_hit = AudioStreamPlayer.new()
	sfx_hit.volume_db = -1.5
	add_child(sfx_hit)

	sfx_hit_tick = AudioStreamPlayer.new()
	sfx_hit_tick.volume_db = -5.5
	add_child(sfx_hit_tick)

	sfx_casing = AudioStreamPlayer.new()
	sfx_casing.volume_db = -9.0
	add_child(sfx_casing)

	sfx_hurt = AudioStreamPlayer.new()
	sfx_hurt.volume_db = -1.5
	add_child(sfx_hurt)

	sfx_slash = AudioStreamPlayer.new()
	sfx_slash.volume_db = -1.0
	add_child(sfx_slash)

	if not skip_initial_weapon_prebuild:
		_prebuild_weapon_rigs()


func _build_dust_motes() -> void:
	dust_motes = GPUParticles3D.new()
	dust_motes.amount = 140
	dust_motes.lifetime = 5.0
	dust_motes.preprocess = 0.0 if OS.has_feature("web") else 2.0
	dust_motes.local_coords = false
	dust_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust_motes.visibility_aabb = AABB(Vector3(-8, -5, -10), Vector3(16, 10, 14))
	dust_motes.position = Vector3(0.0, 0.0, -5.8)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.2, 2.2, 3.0)
	pm.direction = Vector3(0.15, 0.4, 0.1).normalized()
	pm.spread = 180.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.10
	pm.gravity = Vector3(0.0, 0.015, 0.0)
	pm.scale_min = 0.45
	pm.scale_max = 1.0
	pm.color = Color(0.68, 0.72, 0.78, 0.11)
	dust_motes.process_material = pm

	var qm := QuadMesh.new()
	qm.size = Vector2(0.013, 0.013)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	sm.albedo_texture = load("res://assets/textures/gunsmoke_wisp.png")
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = sm
	dust_motes.draw_pass_1 = qm
	camera.add_child(dust_motes)


func _build_muzzle_flash_rig() -> void:
	muzzle_flash_rig = Node3D.new()
	muzzle_flash_rig.visible = false
	weapon_pivot.add_child(muzzle_flash_rig)

	var flash_shader := load("res://shaders/muzzle_flash.gdshader") as Shader
	var front_tex := load("res://assets/textures/muzzle_flash_front.png")
	var side_tex := load("res://assets/textures/muzzle_flash_side.png")

	var f_mat := ShaderMaterial.new()
	f_mat.shader = flash_shader
	f_mat.set_shader_parameter("shape_tex", front_tex)
	f_mat.set_shader_parameter("is_side", 0.0)
	f_mat.set_shader_parameter("intensity", 3.1)
	f_mat.set_shader_parameter("cool_t", 0.0)
	_flash_mats.append(f_mat)

	var front_mi := MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(0.24, 0.24)
	front_mi.mesh = fq
	front_mi.material_override = f_mat
	front_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	front_mi.layers = 2
	muzzle_flash_rig.add_child(front_mi)

	var s_mat := ShaderMaterial.new()
	s_mat.shader = flash_shader
	s_mat.set_shader_parameter("shape_tex", side_tex)
	s_mat.set_shader_parameter("is_side", 1.0)
	s_mat.set_shader_parameter("intensity", 2.8)
	s_mat.set_shader_parameter("cool_t", 0.0)
	_flash_mats.append(s_mat)

	for roll_z: float in [0.0, PI * 0.5]:
		var holder := Node3D.new()
		holder.rotation.z = roll_z
		var side_mi := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(0.35, 0.16)
		side_mi.mesh = sq
		side_mi.material_override = s_mat
		side_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		side_mi.layers = 2
		side_mi.rotation.y = PI * 0.5
		side_mi.position = Vector3(0.0, 0.0, -0.15)
		holder.add_child(side_mi)
		muzzle_flash_rig.add_child(holder)


func _build_muzzle_smoke() -> void:
	muzzle_smoke = GPUParticles3D.new()
	muzzle_smoke.emitting = false
	if OS.has_feature("web"):
		muzzle_smoke.one_shot = true
		muzzle_smoke.explosiveness = 0.90
		muzzle_smoke.amount = 6
	else:
		muzzle_smoke.amount = 24
	muzzle_smoke.lifetime = 1.05
	muzzle_smoke.local_coords = false
	muzzle_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.85, -0.35)
	pm.spread = 24.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.80
	pm.gravity = Vector3(0.0, 0.45, 0.0)
	pm.damping_min = 0.9
	pm.damping_max = 1.6
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = 0.45
	pm.scale_max = 1.25
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	muzzle_smoke.process_material = pm

	var qm := QuadMesh.new()
	qm.size = Vector2(0.14, 0.14)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/soft_lit_particle.gdshader")
	sm.set_shader_parameter("albedo_tex", load("res://assets/textures/gunsmoke_wisp.png"))
	sm.set_shader_parameter("tint_color", Color(0.72, 0.74, 0.78, 0.16))
	sm.set_shader_parameter("soft_fade_dist", 0.24)
	sm.set_shader_parameter("near_fade_start", 0.10)
	sm.set_shader_parameter("near_fade_end", 0.38)
	sm.set_shader_parameter("wrap_lighting", 0.72)
	sm.set_shader_parameter("max_lit", 0.85)
	qm.material = sm
	muzzle_smoke.draw_pass_1 = qm
	weapon_pivot.add_child(muzzle_smoke)


func _prep_viewmodel_node(n: Node) -> void:
	if n is GeometryInstance3D:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.layers = 2
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var source := n.get_active_material(i) as StandardMaterial3D
			if source == null:
				continue
			var mname := str(source.resource_name).to_lower()
			if mname.begins_with("arms"):
				var cloth := source.duplicate() as StandardMaterial3D
				cloth.albedo_texture = preload("res://assets/textures/field_glove_albedo.jpg")
				cloth.albedo_color = Color(0.56, 0.56, 0.54)
				cloth.normal_scale = 1.35
				cloth.roughness = 0.92
				cloth.metallic = 0.0
				cloth.metallic_specular = 0.05
				cloth.rim_enabled = false
				n.set_surface_override_material(i, cloth)
			else:
				var gun := source.duplicate() as StandardMaterial3D
				var nname := n.name.to_lower()
				if "magazine_m16a2" in nname:
					gun.albedo_color = Color(2.35, 2.40, 2.24)
					gun.metallic = 0.48
					gun.roughness = 0.36
					gun.metallic_specular = 0.62
					gun.anisotropy_enabled = false
				elif "m16" in mname or "slide" in mname or "barrel" in mname or "reflex" in mname or "frame" in mname or "bolt" in mname or "mag" in mname or "charge" in mname or gun.metallic > 0.20:
					gun.metallic = 0.56
					gun.roughness = 0.44
					gun.metallic_specular = 0.56
					gun.anisotropy_enabled = false
				elif mname == "material" or "remington" in mname or "shotgun" in mname:
					gun.metallic = clampf(maxf(gun.metallic, 0.38), 0.35, 0.66)
					gun.roughness = clampf(gun.roughness, 0.38, 0.58)
					gun.metallic_specular = 0.48
					gun.anisotropy_enabled = false
				else:
					gun.metallic = 0.04
					gun.roughness = clampf(gun.roughness, 0.48, 0.65)
				n.set_surface_override_material(i, gun)
	for c in n.get_children():
		_prep_viewmodel_node(c)


func _find_mesh_islands(verts: PackedVector3Array, indices: PackedInt32Array) -> Array:
	var nv := verts.size()
	var parent := PackedInt32Array()
	parent.resize(nv)
	for i in nv:
		parent[i] = i
	var tri_count := int(indices.size() / 3)
	for ti in tri_count:
		var a := indices[ti * 3]
		var b := indices[ti * 3 + 1]
		var c := indices[ti * 3 + 2]
		var ra := a
		while parent[ra] != ra:
			parent[ra] = parent[parent[ra]]
			ra = parent[ra]
		var rb := b
		while parent[rb] != rb:
			parent[rb] = parent[parent[rb]]
			rb = parent[rb]
		if ra != rb:
			parent[rb] = ra
		var rc := c
		while parent[rc] != rc:
			parent[rc] = parent[parent[rc]]
			rc = parent[rc]
		if ra != rc:
			parent[rc] = ra

	var comp_tris: Dictionary = {}
	var comp_vset: Dictionary = {}
	for ti in tri_count:
		var a := indices[ti * 3]
		var b := indices[ti * 3 + 1]
		var c := indices[ti * 3 + 2]
		var r := a
		while parent[r] != r:
			parent[r] = parent[parent[r]]
			r = parent[r]
		if not comp_tris.has(r):
			comp_tris[r] = PackedInt32Array()
			comp_vset[r] = {}
		var ta: PackedInt32Array = comp_tris[r]
		ta.append(a)
		ta.append(b)
		ta.append(c)
		comp_tris[r] = ta
		var vs: Dictionary = comp_vset[r]
		vs[a] = true
		vs[b] = true
		vs[c] = true

	var islands: Array = []
	for r in comp_tris.keys():
		var vs: Dictionary = comp_vset[r]
		var sum := Vector3.ZERO
		var min_z_v := Vector3(0.0, 0.0, 1e9)
		var max_z_v := Vector3(0.0, 0.0, -1e9)
		for vi: int in vs.keys():
			var v := verts[vi]
			sum += v
			if v.z < min_z_v.z:
				min_z_v = v
			if v.z > max_z_v.z:
				max_z_v = v
		var cnt := vs.size()
		islands.append({
			"tris": comp_tris[r],
			"count": cnt,
			"avg": sum / float(maxi(cnt, 1)),
			"min_z_v": min_z_v,
			"max_z_v": max_z_v,
		})
	return islands


func _build_submesh_from_tris(src_arrays: Array, tri_indices: PackedInt32Array, mat: Material) -> ArrayMesh:
	var am := ArrayMesh.new()
	if tri_indices.is_empty():
		return am
	var src_v: PackedVector3Array = src_arrays[Mesh.ARRAY_VERTEX]
	var has_n: bool = src_arrays[Mesh.ARRAY_NORMAL] != null
	var has_t: bool = src_arrays[Mesh.ARRAY_TANGENT] != null
	var has_uv: bool = src_arrays[Mesh.ARRAY_TEX_UV] != null
	var has_uv2: bool = src_arrays[Mesh.ARRAY_TEX_UV2] != null
	var has_col: bool = src_arrays[Mesh.ARRAY_COLOR] != null
	var src_n: PackedVector3Array = src_arrays[Mesh.ARRAY_NORMAL] if has_n else PackedVector3Array()
	var src_t: PackedFloat32Array = src_arrays[Mesh.ARRAY_TANGENT] if has_t else PackedFloat32Array()
	var src_uv: PackedVector2Array = src_arrays[Mesh.ARRAY_TEX_UV] if has_uv else PackedVector2Array()
	var src_uv2: PackedVector2Array = src_arrays[Mesh.ARRAY_TEX_UV2] if has_uv2 else PackedVector2Array()
	var src_col: PackedColorArray = src_arrays[Mesh.ARRAY_COLOR] if has_col else PackedColorArray()

	var remap := PackedInt32Array()
	remap.resize(src_v.size())
	remap.fill(-1)
	var dst_v := PackedVector3Array()
	var dst_n := PackedVector3Array()
	var dst_t := PackedFloat32Array()
	var dst_uv := PackedVector2Array()
	var dst_uv2 := PackedVector2Array()
	var dst_col := PackedColorArray()
	var dst_idx := PackedInt32Array()
	dst_idx.resize(tri_indices.size())

	for k in tri_indices.size():
		var oi := tri_indices[k]
		var ni := remap[oi]
		if ni < 0:
			ni = dst_v.size()
			remap[oi] = ni
			dst_v.append(src_v[oi])
			if has_n:
				dst_n.append(src_n[oi])
			if has_t:
				var ti4 := oi * 4
				dst_t.append(src_t[ti4])
				dst_t.append(src_t[ti4 + 1])
				dst_t.append(src_t[ti4 + 2])
				dst_t.append(src_t[ti4 + 3])
			if has_uv:
				dst_uv.append(src_uv[oi])
			if has_uv2:
				dst_uv2.append(src_uv2[oi])
			if has_col:
				dst_col.append(src_col[oi])
		dst_idx[k] = ni

	var out_arr := []
	out_arr.resize(Mesh.ARRAY_MAX)
	out_arr[Mesh.ARRAY_VERTEX] = dst_v
	if has_n:
		out_arr[Mesh.ARRAY_NORMAL] = dst_n
	if has_t:
		out_arr[Mesh.ARRAY_TANGENT] = dst_t
	if has_uv:
		out_arr[Mesh.ARRAY_TEX_UV] = dst_uv
	if has_uv2:
		out_arr[Mesh.ARRAY_TEX_UV2] = dst_uv2
	if has_col:
		out_arr[Mesh.ARRAY_COLOR] = dst_col
	out_arr[Mesh.ARRAY_INDEX] = dst_idx
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arr)
	if mat != null:
		am.surface_set_material(0, mat)
	return am


func _find_mesh_by_name(n: Node, target_lower: String) -> MeshInstance3D:
	if n is MeshInstance3D and n.name.to_lower() == target_lower:
		return n as MeshInstance3D
	for c in n.get_children():
		var found := _find_mesh_by_name(c, target_lower)
		if found != null:
			return found
	return null


func _split_weapon_rig_meshes(inst: Node3D, weapon_idx: int) -> void:
	# 1. Split combined arms mesh into independent ArmLeft and ArmRight siblings
	var arm_target := "object_86_hero" if weapon_idx == 0 else ("object_67_hero" if weapon_idx == 1 else "shotgunarms")
	var arm_mi := _find_mesh_by_name(inst, arm_target)
	if arm_mi != null and arm_mi.mesh != null and arm_mi.mesh.get_surface_count() > 0:
		var arrays := arm_mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if not verts.is_empty() and not indices.is_empty():
			var islands := _find_mesh_islands(verts, indices)
			islands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) > int(b["count"]))
			if islands.size() >= 2:
				var s0: Dictionary = islands[0]
				var s1: Dictionary = islands[1]
				var left_sleeve: Dictionary = s0 if (s0["avg"] as Vector3).x < (s1["avg"] as Vector3).x else s1
				var right_sleeve: Dictionary = s1 if left_sleeve == s0 else s0
				var left_cuff: Vector3 = left_sleeve["min_z_v"]
				var right_cuff: Vector3 = right_sleeve["min_z_v"]
				var left_tris := PackedInt32Array()
				var right_tris := PackedInt32Array()
				left_tris.append_array(left_sleeve["tris"])
				right_tris.append_array(right_sleeve["tris"])
				for ii in range(2, islands.size()):
					var isl: Dictionary = islands[ii]
					var cuff: Vector3 = isl["max_z_v"]
					if cuff.distance_to(left_cuff) <= cuff.distance_to(right_cuff):
						left_tris.append_array(isl["tris"])
					else:
						right_tris.append_array(isl["tris"])
				var base_mat := arm_mi.mesh.surface_get_material(0)
				var ovr_mat := arm_mi.get_surface_override_material(0)
				var pnode := arm_mi.get_parent()
				for pair in [["ArmLeft", left_tris], ["ArmRight", right_tris]]:
					var smi := MeshInstance3D.new()
					smi.name = pair[0]
					smi.mesh = _build_submesh_from_tris(arrays, pair[1], base_mat)
					smi.transform = arm_mi.transform
					smi.layers = 2
					smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					if ovr_mat != null:
						smi.set_surface_override_material(0, ovr_mat)
					pnode.add_child(smi)
				pnode.remove_child(arm_mi)
				arm_mi.queue_free()

	# 2. For M870, split loading-gate lifter island out of ShotgunReceiver
	if weapon_idx == 2:
		var recv_mi := _find_mesh_by_name(inst, "shotgunreceiver")
		if recv_mi != null and recv_mi.mesh != null and recv_mi.mesh.get_surface_count() > 0:
			var arrays := recv_mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if not verts.is_empty() and not indices.is_empty():
				var islands := _find_mesh_islands(verts, indices)
				var lifter_tris := PackedInt32Array()
				var body_tris := PackedInt32Array()
				for isl: Dictionary in islands:
					var avg: Vector3 = isl["avg"]
					var cnt: int = isl["count"]
					if cnt < 400 and absf(avg.x) < 0.015 and avg.y >= -0.050 and avg.y <= -0.025 and avg.z >= -0.195 and avg.z <= -0.095:
						lifter_tris.append_array(isl["tris"])
					else:
						body_tris.append_array(isl["tris"])
				if not lifter_tris.is_empty() and not body_tris.is_empty():
					var base_mat := recv_mi.mesh.surface_get_material(0)
					var ovr_mat := recv_mi.get_surface_override_material(0)
					recv_mi.mesh = _build_submesh_from_tris(arrays, body_tris, base_mat)
					if ovr_mat != null:
						recv_mi.set_surface_override_material(0, ovr_mat)
					var lmi := MeshInstance3D.new()
					lmi.name = "ShotgunLifter"
					lmi.mesh = _build_submesh_from_tris(arrays, lifter_tris, base_mat)
					lmi.transform = recv_mi.transform
					lmi.layers = 2
					lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					if ovr_mat != null:
						lmi.set_surface_override_material(0, ovr_mat)
					recv_mi.get_parent().add_child(lmi)


func _collect_weapon_parts(n: Node, target_parts: Dictionary = _w_parts) -> void:
	if n is Node3D:
		var nl := n.name.to_lower()
		var grp := ""
		if "g17_magazine_03" in nl or "magazine_m16a2" in nl or "g17_base_03" in nl:
			grp = "mag"
		elif "g17_bullet" in nl:
			grp = "mag_bullet"
		elif "g17_slidestopper" in nl:
			grp = "slidestop"
		elif "g17_trigger" in nl:
			grp = "trigger"
		elif "m16a2_bolt_m16a2" in nl or "g17_slide_" in nl:
			grp = "slide"
		elif "m16a2_chargehandle2" in nl:
			grp = "charge_latch"
		elif "chargehandle" in nl:
			grp = "charge"
		elif "m16a2_ejection_port_cover" in nl:
			grp = "dust_cover"
		elif "m16a2_release" in nl:
			grp = "bolt_catch"
		elif "m16a2_boltcatch" in nl:
			grp = "fwd_assist"
		elif "pump" in nl or "forend" in nl:
			grp = "pump"
		elif nl == "armleft":
			grp = "arm_left"
		elif nl == "armright":
			grp = "arm_right"
		elif nl == "shotgunlifter":
			grp = "lifter"
		if grp != "":
			if not target_parts.has(grp):
				target_parts[grp] = []
			(target_parts[grp] as Array).append(n)
			var iid := n.get_instance_id()
			_w_rest_pos[iid] = (n as Node3D).position
			_w_rest_rot[iid] = (n as Node3D).rotation
	for c in n.get_children():
		_collect_weapon_parts(c, target_parts)


func _build_shotgun_shell_rig() -> Node3D:
	var rig := Node3D.new()
	rig.name = "ShotgunReloadShell"
	rig.visible = false
	var hull := MeshInstance3D.new()
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = 0.0084
	hmesh.bottom_radius = 0.0084
	hmesh.height = 0.042
	hmesh.radial_segments = 16
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.66, 0.07, 0.06)
	hmat.roughness = 0.52
	hmat.metallic = 0.04
	hmesh.material = hmat
	hull.mesh = hmesh
	hull.rotation.x = PI * 0.5
	hull.layers = 2
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.add_child(hull)

	var brass := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.0088
	bmesh.bottom_radius = 0.0088
	bmesh.height = 0.014
	bmesh.radial_segments = 16
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.88, 0.70, 0.30)
	bmat.metallic = 0.88
	bmat.roughness = 0.24
	bmesh.material = bmat
	brass.mesh = bmesh
	brass.position = Vector3(0.0, 0.0, 0.022)
	brass.rotation.x = PI * 0.5
	brass.layers = 2
	brass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.add_child(brass)
	return rig


func _attach_ar_top_cartridge(inst: Node3D, parts: Dictionary) -> void:
	var mag_mi := _find_mesh_by_name(inst, "magazine_m16a2_0_hero")
	if mag_mi == null:
		return
	if mag_mi.mesh != null:
		_mag_mesh_ar = mag_mi.mesh
		_mag_mat_ar = mag_mi.get_surface_override_material(0)
	var round_rig := Node3D.new()
	round_rig.name = "ARTopCartridge"
	round_rig.position = Vector3(0.0, -0.036, -0.122)
	round_rig.rotation = Vector3(PI * 0.5 - 0.14, 0.0, 0.0)
	var brass := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.0046
	bmesh.bottom_radius = 0.0046
	bmesh.height = 0.044
	bmesh.radial_segments = 12
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.92, 0.74, 0.32)
	bmat.metallic = 0.90
	bmat.roughness = 0.22
	bmesh.material = bmat
	brass.mesh = bmesh
	brass.layers = 2
	brass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	round_rig.add_child(brass)
	var tip := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.0010
	tmesh.bottom_radius = 0.0044
	tmesh.height = 0.013
	tmesh.radial_segments = 12
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.82, 0.44, 0.24)
	tmat.metallic = 0.86
	tmat.roughness = 0.26
	tmesh.material = tmat
	tip.mesh = tmesh
	tip.position = Vector3(0.0, 0.028, 0.0)
	tip.layers = 2
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	round_rig.add_child(tip)
	mag_mi.add_child(round_rig)
	if not parts.has("mag_bullet"):
		parts["mag_bullet"] = []
	(parts["mag_bullet"] as Array).append(round_rig)
	var iid := round_rig.get_instance_id()
	_w_rest_pos[iid] = round_rig.position
	_w_rest_rot[iid] = round_rig.rotation


func _build_melee_viewmodel_rig(holder: Node3D) -> void:
	_melee_nodes.clear()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.24, 0.26, 0.29)
	steel.metallic = 0.86
	steel.roughness = 0.30
	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color(0.76, 0.78, 0.80)
	edge.metallic = 0.94
	edge.roughness = 0.18
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.11, 0.11, 0.12)
	grip_mat.roughness = 0.84
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.24, 0.13, 0.07)
	wood_mat.roughness = 0.82
	var blood_mat := StandardMaterial3D.new()
	blood_mat.albedo_color = Color(0.34, 0.02, 0.025)
	blood_mat.roughness = 0.18
	blood_mat.metallic_specular = 0.75

	var _vm_part := func(parent: Node3D, m: Mesh, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.position = pos
		mi.rotation = rot
		mi.layers = 2
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi

	# 1. Combat Knife
	var knife := Node3D.new()
	knife.name = "Melee_Knife"
	var kh := CylinderMesh.new(); kh.top_radius = 0.015; kh.bottom_radius = 0.016; kh.height = 0.13; kh.material = grip_mat
	_vm_part.call(knife, kh, Vector3(0.0, -0.06, 0.0))
	var kg := BoxMesh.new(); kg.size = Vector3(0.048, 0.012, 0.024); kg.material = steel
	_vm_part.call(knife, kg, Vector3(0.0, 0.01, 0.0))
	var kb := BoxMesh.new(); kb.size = Vector3(0.008, 0.21, 0.032); kb.material = steel
	_vm_part.call(knife, kb, Vector3(0.0, 0.12, -0.004))
	var ke := BoxMesh.new(); ke.size = Vector3(0.004, 0.20, 0.008); ke.material = edge
	_vm_part.call(knife, ke, Vector3(0.0, 0.12, -0.022))
	holder.add_child(knife)
	_melee_nodes["knife"] = knife

	# 2. Fire Axe
	var axe := Node3D.new()
	axe.name = "Melee_FireAxe"
	var ah := CylinderMesh.new(); ah.top_radius = 0.017; ah.bottom_radius = 0.020; ah.height = 0.68; ah.material = wood_mat
	_vm_part.call(axe, ah, Vector3(0.0, 0.08, 0.0))
	var ag := CylinderMesh.new(); ag.top_radius = 0.021; ag.bottom_radius = 0.022; ag.height = 0.16; ag.material = grip_mat
	_vm_part.call(axe, ag, Vector3(0.0, -0.14, 0.0))
	var ahd := BoxMesh.new(); ahd.size = Vector3(0.028, 0.105, 0.18); ahd.material = steel
	_vm_part.call(axe, ahd, Vector3(0.0, 0.36, -0.06))
	var abit := BoxMesh.new(); abit.size = Vector3(0.012, 0.125, 0.036); abit.material = edge
	_vm_part.call(axe, abit, Vector3(0.0, 0.36, -0.155))
	var abld := BoxMesh.new(); abld.size = Vector3(0.014, 0.09, 0.045); abld.material = blood_mat
	_vm_part.call(axe, abld, Vector3(0.0, 0.35, -0.135))
	axe.visible = false
	holder.add_child(axe)
	_melee_nodes["fire_axe"] = axe

	# 3. Tactical Machete
	var mach := Node3D.new()
	mach.name = "Melee_Machete"
	var mh := CylinderMesh.new(); mh.top_radius = 0.016; mh.bottom_radius = 0.018; mh.height = 0.15; mh.material = grip_mat
	_vm_part.call(mach, mh, Vector3(0.0, -0.06, 0.0))
	var mb := BoxMesh.new(); mb.size = Vector3(0.008, 0.44, 0.056); mb.material = steel
	_vm_part.call(mach, mb, Vector3(0.0, 0.22, -0.01))
	var me := BoxMesh.new(); me.size = Vector3(0.004, 0.42, 0.012); me.material = edge
	_vm_part.call(mach, me, Vector3(0.0, 0.22, -0.040))
	var mbl := BoxMesh.new(); mbl.size = Vector3(0.010, 0.18, 0.032); mbl.material = blood_mat
	_vm_part.call(mach, mbl, Vector3(0.0, 0.30, -0.025))
	mach.visible = false
	holder.add_child(mach)
	_melee_nodes["machete"] = mach


func _make_vm_mat(col: Color, rough: float, metal: float = 0.0, spec: float = 0.45, emit := Color.BLACK, pbr_prefix := "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = spec
	if pbr_prefix != "":
		var ap := "res://assets/textures/%s_albedo.jpg" % pbr_prefix
		var np := "res://assets/textures/%s_normal.jpg" % pbr_prefix
		var rp := "res://assets/textures/%s_rough.jpg" % pbr_prefix
		if ResourceLoader.exists(ap):
			m.albedo_texture = load(ap)
		if ResourceLoader.exists(np):
			m.normal_enabled = true
			m.normal_texture = load(np)
			m.normal_scale = 0.85
		if ResourceLoader.exists(rp):
			m.roughness_texture = load(rp)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(4.0, 4.0, 4.0)
	if emit != Color.BLACK:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = 2.4
	return m


func _add_vm_mesh(parent: Node3D, m: Mesh, pos: Vector3, rot := Vector3.ZERO, n_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if n_name != "":
		mi.name = n_name
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	mi.layers = 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build_bow_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	_bow_parts.clear()
	var riser_mat := _make_vm_mat(Color(0.28, 0.30, 0.32), 0.44, 0.72, 0.58, Color.BLACK, "metal_tactical")
	var limb_mat := _make_vm_mat(Color(0.22, 0.24, 0.22), 0.48, 0.28, 0.45, Color.BLACK, "metal_tactical")
	var cam_mat := _make_vm_mat(Color(0.62, 0.10, 0.08), 0.32, 0.82, 0.65)
	var string_mat := _make_vm_mat(Color(0.84, 0.82, 0.78), 0.75, 0.0, 0.15)
	var grip_mat := _make_vm_mat(Color(0.42, 0.28, 0.18), 0.85, 0.0, 0.14, Color.BLACK, "wood_carved")
	var shaft_mat := _make_vm_mat(Color(0.14, 0.15, 0.16), 0.36, 0.35, 0.50)
	var tip_mat := _make_vm_mat(Color(0.78, 0.80, 0.84), 0.22, 0.92, 0.75)
	var fletch_mat := _make_vm_mat(Color(0.82, 0.12, 0.10), 0.52, 0.0, 0.25)
	var pin_g := _make_vm_mat(Color(0.2, 1.0, 0.3), 0.2, 0.0, 0.2, Color(0.2, 1.0, 0.35))
	var pin_y := _make_vm_mat(Color(1.0, 0.8, 0.15), 0.2, 0.0, 0.2, Color(1.0, 0.75, 0.15))

	# Machined riser + grip + stabilizer
	var r_main := BoxMesh.new(); r_main.size = Vector3(0.024, 0.32, 0.038); r_main.material = riser_mat
	_add_vm_mesh(holder, r_main, Vector3(-0.028, 0.0, -0.18))
	var r_grip := CylinderMesh.new(); r_grip.top_radius = 0.015; r_grip.bottom_radius = 0.016; r_grip.height = 0.12; r_grip.material = grip_mat
	_add_vm_mesh(holder, r_grip, Vector3(-0.028, -0.04, -0.172))
	var stab := CylinderMesh.new(); stab.top_radius = 0.008; stab.bottom_radius = 0.010; stab.height = 0.18; stab.material = riser_mat
	_add_vm_mesh(holder, stab, Vector3(-0.028, -0.095, -0.28), Vector3(PI * 0.5, 0, 0))
	var s_ring := CylinderMesh.new(); s_ring.top_radius = 0.022; s_ring.bottom_radius = 0.022; s_ring.height = 0.014; s_ring.material = riser_mat
	_add_vm_mesh(holder, s_ring, Vector3(-0.006, 0.055, -0.21), Vector3(PI * 0.5, 0, 0))
	var p1 := BoxMesh.new(); p1.size = Vector3(0.014, 0.0025, 0.0025); p1.material = pin_g
	_add_vm_mesh(holder, p1, Vector3(-0.010, 0.059, -0.21))
	var p2 := BoxMesh.new(); p2.size = Vector3(0.012, 0.0022, 0.0022); p2.material = pin_y
	_add_vm_mesh(holder, p2, Vector3(-0.011, 0.052, -0.21))

	# Upper & lower flexing limbs seated flush in riser pockets + eccentric cams
	var limb_top := Node3D.new(); limb_top.name = "BowLimbTop"; limb_top.position = Vector3(-0.028, 0.15, -0.18)
	var lt_m := BoxMesh.new(); lt_m.size = Vector3(0.026, 0.24, 0.014); lt_m.material = limb_mat
	_add_vm_mesh(limb_top, lt_m, Vector3(0.0, 0.105, 0.030), Vector3(0.26, 0, 0))
	var cam_t := CylinderMesh.new(); cam_t.top_radius = 0.026; cam_t.bottom_radius = 0.026; cam_t.height = 0.010; cam_t.material = cam_mat
	var cam_t_node := _add_vm_mesh(limb_top, cam_t, Vector3(0.0, 0.220, 0.062), Vector3(0, 0, PI * 0.5))
	holder.add_child(limb_top)

	var limb_bot := Node3D.new(); limb_bot.name = "BowLimbBot"; limb_bot.position = Vector3(-0.028, -0.15, -0.18)
	var lb_m := BoxMesh.new(); lb_m.size = Vector3(0.026, 0.24, 0.014); lb_m.material = limb_mat
	_add_vm_mesh(limb_bot, lb_m, Vector3(0.0, -0.105, 0.030), Vector3(-0.26, 0, 0))
	var cam_b := CylinderMesh.new(); cam_b.top_radius = 0.026; cam_b.bottom_radius = 0.026; cam_b.height = 0.010; cam_b.material = cam_mat
	var cam_b_node := _add_vm_mesh(limb_bot, cam_b, Vector3(0.0, -0.220, 0.062), Vector3(0, 0, PI * 0.5))
	holder.add_child(limb_bot)

	# Upper & lower dynamic bowstring halves (unit height = 1.0, scaled exactly from cam to arrow nock!)
	var st_m := CylinderMesh.new(); st_m.top_radius = 0.0018; st_m.bottom_radius = 0.0018; st_m.height = 1.0; st_m.material = string_mat
	var str_top := _add_vm_mesh(holder, st_m, Vector3(-0.022, 0.18, -0.11), Vector3.ZERO, "BowStringTop")
	var str_bot := _add_vm_mesh(holder, st_m, Vector3(-0.022, -0.18, -0.11), Vector3.ZERO, "BowStringBot")

	# Nocked carbon arrow with broadhead & crimson fletching
	var arrow := Node3D.new(); arrow.name = "BowNockedArrow"; arrow.position = Vector3(-0.012, 0.030, -0.24)
	var sh := CylinderMesh.new(); sh.top_radius = 0.0036; sh.bottom_radius = 0.0036; sh.height = 0.50; sh.material = shaft_mat
	_add_vm_mesh(arrow, sh, Vector3(0, 0, -0.12), Vector3(PI * 0.5, 0, 0))
	var bh := CylinderMesh.new(); bh.top_radius = 0.0005; bh.bottom_radius = 0.010; bh.height = 0.044; bh.radial_segments = 4; bh.material = tip_mat
	_add_vm_mesh(arrow, bh, Vector3(0, 0, -0.385), Vector3(-PI * 0.5, 0, 0))
	var fl := BoxMesh.new(); fl.size = Vector3(0.002, 0.018, 0.068); fl.material = fletch_mat
	_add_vm_mesh(arrow, fl, Vector3(0, 0.009, 0.085))
	_add_vm_mesh(arrow, fl, Vector3(0.008, -0.005, 0.085), Vector3(0, 0, 2.09))
	_add_vm_mesh(arrow, fl, Vector3(-0.008, -0.005, 0.085), Vector3(0, 0, -2.09))
	holder.add_child(arrow)

	_bow_parts = {
		"limb_top": limb_top,
		"limb_bot": limb_bot,
		"cam_top": cam_t_node,
		"cam_bot": cam_b_node,
		"str_top": str_top,
		"str_bot": str_bot,
		"arrow": arrow,
	}
	parts["bow_arrow"] = [arrow]
	_pose_bow_rig()


func _build_mp5_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var steel := _make_vm_mat(Color(0.32, 0.34, 0.36), 0.38, 0.78, 0.58, Color.BLACK, "metal_tactical")
	var poly := _make_vm_mat(Color(0.14, 0.15, 0.16), 0.74, 0.08, 0.24, Color.BLACK, "metal_tactical")
	var sd_mat := _make_vm_mat(Color(0.28, 0.29, 0.30), 0.60, 0.48, 0.38, Color.BLACK, "metal_tactical")
	var optic_m := _make_vm_mat(Color(0.24, 0.24, 0.26), 0.36, 0.65, 0.55, Color.BLACK, "metal_tactical")

	# Upper stamped steel receiver + lower polymer trigger housing
	var rec := BoxMesh.new(); rec.size = Vector3(0.038, 0.052, 0.28); rec.material = steel
	_add_vm_mesh(holder, rec, Vector3(0.0, 0.022, -0.14))
	var low := BoxMesh.new(); low.size = Vector3(0.032, 0.038, 0.16); low.material = poly
	_add_vm_mesh(holder, low, Vector3(0.0, -0.018, -0.09))
	var grip := BoxMesh.new(); grip.size = Vector3(0.028, 0.095, 0.040); grip.material = poly
	_add_vm_mesh(holder, grip, Vector3(0.0, -0.068, -0.032), Vector3(-0.26, 0, 0))
	# Integrated MP5SD ribbed cylindrical suppressor & forend
	var fore := CylinderMesh.new(); fore.top_radius = 0.024; fore.bottom_radius = 0.025; fore.height = 0.16; fore.material = poly
	_add_vm_mesh(holder, fore, Vector3(0.0, 0.020, -0.34), Vector3(PI * 0.5, 0, 0))
	var supp := CylinderMesh.new(); supp.top_radius = 0.019; supp.bottom_radius = 0.019; supp.height = 0.22; supp.material = sd_mat
	_add_vm_mesh(holder, supp, Vector3(0.0, 0.024, -0.49), Vector3(PI * 0.5, 0, 0))
	# Cocking tube + animated HK charging handle
	var tube := CylinderMesh.new(); tube.top_radius = 0.011; tube.bottom_radius = 0.011; tube.height = 0.18; tube.material = steel
	_add_vm_mesh(holder, tube, Vector3(0.0, 0.044, -0.31), Vector3(PI * 0.5, 0, 0))
	var ch_m := CylinderMesh.new(); ch_m.top_radius = 0.0055; ch_m.bottom_radius = 0.0055; ch_m.height = 0.036; ch_m.material = steel
	var ch_node := _add_vm_mesh(holder, ch_m, Vector3(-0.026, 0.046, -0.34), Vector3(0, 0, PI * 0.42), "MP5_Charge")
	# Curved 30-rd magazine
	var mag_root := Node3D.new(); mag_root.name = "MP5_Mag"; mag_root.position = Vector3(0.0, -0.045, -0.185)
	var m1 := BoxMesh.new(); m1.size = Vector3(0.022, 0.105, 0.036); m1.material = steel
	_add_vm_mesh(mag_root, m1, Vector3(0.0, -0.045, 0.0), Vector3(0.14, 0, 0))
	var m2 := BoxMesh.new(); m2.size = Vector3(0.021, 0.090, 0.035); m2.material = steel
	_add_vm_mesh(mag_root, m2, Vector3(0.0, -0.130, -0.020), Vector3(0.28, 0, 0))
	holder.add_child(mag_root)
	# Compact red-dot sight frame
	var rail := BoxMesh.new(); rail.size = Vector3(0.024, 0.010, 0.10); rail.material = optic_m
	_add_vm_mesh(holder, rail, Vector3(0.0, 0.052, -0.095))
	var opt_l := BoxMesh.new(); opt_l.size = Vector3(0.005, 0.032, 0.044); opt_l.material = optic_m
	_add_vm_mesh(holder, opt_l, Vector3(-0.017, 0.074, -0.088))
	_add_vm_mesh(holder, opt_l, Vector3(0.017, 0.074, -0.088))
	var opt_t := BoxMesh.new(); opt_t.size = Vector3(0.038, 0.005, 0.044); opt_t.material = optic_m
	_add_vm_mesh(holder, opt_t, Vector3(0.0, 0.091, -0.088))
	# Collapsible stock rails
	var sr := BoxMesh.new(); sr.size = Vector3(0.006, 0.012, 0.14); sr.material = steel
	_add_vm_mesh(holder, sr, Vector3(-0.021, 0.016, 0.04))
	_add_vm_mesh(holder, sr, Vector3(0.021, 0.016, 0.04))

	parts["mag"] = [mag_root]
	parts["charge"] = [ch_node]
	for n: Node3D in [mag_root, ch_node]:
		_w_rest_pos[n.get_instance_id()] = n.position
		_w_rest_rot[n.get_instance_id()] = n.rotation


func _build_magnum_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var chrome := _make_vm_mat(Color(0.86, 0.88, 0.90), 0.26, 0.88, 0.72, Color.BLACK, "metal_tactical")
	var dark_st := _make_vm_mat(Color(0.24, 0.25, 0.27), 0.38, 0.82, 0.55, Color.BLACK, "metal_tactical")
	var walnut := _make_vm_mat(Color(0.58, 0.36, 0.22), 0.62, 0.02, 0.22, Color.BLACK, "wood_carved")
	var ramp := _make_vm_mat(Color(0.95, 0.24, 0.08), 0.35, 0.0, 0.3, Color(0.85, 0.18, 0.04))

	# Frame, top strap, trigger guard
	var frame := BoxMesh.new(); frame.size = Vector3(0.026, 0.056, 0.115); frame.material = chrome
	_add_vm_mesh(holder, frame, Vector3(0.0, 0.012, -0.105))
	var strap := BoxMesh.new(); strap.size = Vector3(0.022, 0.012, 0.095); strap.material = chrome
	_add_vm_mesh(holder, strap, Vector3(0.0, 0.050, -0.125))
	# Heavy 6.5" ventilated-rib barrel + full underlug
	var bbl := CylinderMesh.new(); bbl.top_radius = 0.012; bbl.bottom_radius = 0.012; bbl.height = 0.20; bbl.material = chrome
	_add_vm_mesh(holder, bbl, Vector3(0.0, 0.040, -0.265), Vector3(PI * 0.5, 0, 0))
	var lug := BoxMesh.new(); lug.size = Vector3(0.018, 0.026, 0.195); lug.material = chrome
	_add_vm_mesh(holder, lug, Vector3(0.0, 0.024, -0.262))
	var rib := BoxMesh.new(); rib.size = Vector3(0.012, 0.010, 0.195); rib.material = chrome
	_add_vm_mesh(holder, rib, Vector3(0.0, 0.054, -0.262))
	var fs := BoxMesh.new(); fs.size = Vector3(0.004, 0.011, 0.016); fs.material = ramp
	_add_vm_mesh(holder, fs, Vector3(0.0, 0.062, -0.350))
	# Checkered walnut grip
	var grip := BoxMesh.new(); grip.size = Vector3(0.030, 0.105, 0.046); grip.material = walnut
	_add_vm_mesh(holder, grip, Vector3(0.0, -0.055, -0.052), Vector3(-0.32, 0, 0))
	# Swing-out crane + 6-shot fluted cylinder
	var crane := Node3D.new(); crane.name = "Magnum_Crane"; crane.position = Vector3(-0.014, 0.002, -0.130)
	var cyl := Node3D.new(); cyl.name = "Magnum_Cyl"; cyl.position = Vector3(0.014, 0.022, 0.0)
	var cm := CylinderMesh.new(); cm.top_radius = 0.023; cm.bottom_radius = 0.023; cm.height = 0.056; cm.radial_segments = 18; cm.material = chrome
	_add_vm_mesh(cyl, cm, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	var fl_m := CylinderMesh.new(); fl_m.top_radius = 0.006; fl_m.bottom_radius = 0.006; fl_m.height = 0.058; fl_m.material = dark_st
	for k in range(6):
		var a := float(k) * TAU / 6.0
		_add_vm_mesh(cyl, fl_m, Vector3(cos(a) * 0.013, sin(a) * 0.013, 0.0), Vector3(PI * 0.5, 0, 0))
	crane.add_child(cyl)
	holder.add_child(crane)
	# External hammer
	var hm_m := BoxMesh.new(); hm_m.size = Vector3(0.009, 0.024, 0.020); hm_m.material = dark_st
	var hammer := _add_vm_mesh(holder, hm_m, Vector3(0.0, 0.044, -0.062), Vector3(-0.35, 0, 0), "Magnum_Hammer")

	parts["crane"] = [crane]
	parts["cylinder"] = [cyl]
	parts["hammer"] = [hammer]
	for n: Node3D in [crane, cyl, hammer]:
		_w_rest_pos[n.get_instance_id()] = n.position
		_w_rest_rot[n.get_instance_id()] = n.rotation


func _build_hunting_rifle_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var blued := _make_vm_mat(Color(0.26, 0.28, 0.32), 0.30, 0.86, 0.65, Color.BLACK, "metal_tactical")
	var walnut := _make_vm_mat(Color(0.56, 0.36, 0.22), 0.56, 0.02, 0.26, Color.BLACK, "wood_carved")
	var ebony := _make_vm_mat(Color(0.14, 0.12, 0.12), 0.45, 0.05, 0.25)
	var brass := _make_vm_mat(Color(0.78, 0.62, 0.26), 0.30, 0.88, 0.66)
	var bolt_st := _make_vm_mat(Color(0.80, 0.82, 0.84), 0.22, 0.92, 0.72, Color.BLACK, "metal_tactical")

	# Walnut stock, forend, ebony tip & cheek piece
	var stock := BoxMesh.new(); stock.size = Vector3(0.036, 0.056, 0.44); stock.material = walnut
	_add_vm_mesh(holder, stock, Vector3(0.0, -0.005, -0.18))
	var butt := BoxMesh.new(); butt.size = Vector3(0.038, 0.095, 0.20); butt.material = walnut
	_add_vm_mesh(holder, butt, Vector3(0.0, -0.024, 0.12))
	var tip := BoxMesh.new(); tip.size = Vector3(0.035, 0.040, 0.042); tip.material = ebony
	_add_vm_mesh(holder, tip, Vector3(0.0, -0.002, -0.415))
	# Steel receiver + 24" free-floating barrel
	var rec := CylinderMesh.new(); rec.top_radius = 0.017; rec.bottom_radius = 0.017; rec.height = 0.22; rec.material = blued
	_add_vm_mesh(holder, rec, Vector3(0.0, 0.028, -0.15), Vector3(PI * 0.5, 0, 0))
	var bbl := CylinderMesh.new(); bbl.top_radius = 0.0085; bbl.bottom_radius = 0.0125; bbl.height = 0.56; bbl.material = blued
	_add_vm_mesh(holder, bbl, Vector3(0.0, 0.030, -0.53), Vector3(PI * 0.5, 0, 0))
	# Animated bolt assembly + swept bolt knob
	var bolt_root := Node3D.new(); bolt_root.name = "M700_Bolt"; bolt_root.position = Vector3(0.0, 0.028, -0.085)
	var bbody := CylinderMesh.new(); bbody.top_radius = 0.011; bbody.bottom_radius = 0.011; bbody.height = 0.11; bbody.material = bolt_st
	_add_vm_mesh(bolt_root, bbody, Vector3(0.0, 0.0, -0.02), Vector3(PI * 0.5, 0, 0))
	var bstem := CylinderMesh.new(); bstem.top_radius = 0.004; bstem.bottom_radius = 0.004; bstem.height = 0.042; bstem.material = bolt_st
	_add_vm_mesh(bolt_root, bstem, Vector3(0.026, -0.008, 0.018), Vector3(0, 0, -1.25))
	var bknob := SphereMesh.new(); bknob.radius = 0.0095; bknob.height = 0.019; bknob.material = bolt_st
	_add_vm_mesh(bolt_root, bknob, Vector3(0.046, -0.016, 0.018))
	holder.add_child(bolt_root)
	# 4x Telescopic hunting scope with brass rings
	var sc_tube := CylinderMesh.new(); sc_tube.top_radius = 0.015; sc_tube.bottom_radius = 0.015; sc_tube.height = 0.24; sc_tube.material = blued
	_add_vm_mesh(holder, sc_tube, Vector3(0.0, 0.088, -0.17), Vector3(PI * 0.5, 0, 0))
	var sc_obj := CylinderMesh.new(); sc_obj.top_radius = 0.023; sc_obj.bottom_radius = 0.015; sc_obj.height = 0.075; sc_obj.material = blued
	_add_vm_mesh(holder, sc_obj, Vector3(0.0, 0.088, -0.32), Vector3(PI * 0.5, 0, 0))
	var sc_eye := CylinderMesh.new(); sc_eye.top_radius = 0.015; sc_eye.bottom_radius = 0.020; sc_eye.height = 0.055; sc_eye.material = blued
	_add_vm_mesh(holder, sc_eye, Vector3(0.0, 0.088, -0.03), Vector3(PI * 0.5, 0, 0))
	var ring := CylinderMesh.new(); ring.top_radius = 0.0185; ring.bottom_radius = 0.0185; ring.height = 0.014; ring.material = brass
	_add_vm_mesh(holder, ring, Vector3(0.0, 0.088, -0.11), Vector3(PI * 0.5, 0, 0))
	_add_vm_mesh(holder, ring, Vector3(0.0, 0.088, -0.23), Vector3(PI * 0.5, 0, 0))

	parts["bolt"] = [bolt_root]
	_w_rest_pos[bolt_root.get_instance_id()] = bolt_root.position
	_w_rest_rot[bolt_root.get_instance_id()] = bolt_root.rotation


func _build_single_weapon_rig(i: int) -> void:
	var w: Dictionary = WEAPONS[i]
	var glb_path: String = w["glb"]
	var holder := Node3D.new()
	holder.name = "WeaponRig_%d" % i
	holder.visible = false
	weapon_rig_holder.add_child(holder)
	var parts := {}
	var custom_rig := str(w.get("custom_rig", ""))
	if bool(w.get("is_melee", false)):
		_build_melee_viewmodel_rig(holder)
	elif custom_rig == "bow":
		_build_bow_viewmodel_rig(holder, parts)
	elif custom_rig == "mp5":
		_build_mp5_viewmodel_rig(holder, parts)
	elif custom_rig == "magnum":
		_build_magnum_viewmodel_rig(holder, parts)
	elif custom_rig == "hunting":
		_build_hunting_rifle_viewmodel_rig(holder, parts)
	elif glb_path != "":
		if not _glb_cache.has(glb_path):
			_glb_cache[glb_path] = load(glb_path)
		var packed: PackedScene = _glb_cache[glb_path]
		if packed:
			var inst := packed.instantiate()
			_prep_viewmodel_node(inst)
			_split_weapon_rig_meshes(inst, i)
			holder.add_child(inst)
			_collect_weapon_parts(inst, parts)
			if i == 1:
				_attach_ar_top_cartridge(inst, parts)
	if i == 2:
		_shotgun_shell_rig = _build_shotgun_shell_rig()
		holder.add_child(_shotgun_shell_rig)
	_weapon_rigs.append(holder)
	_w_parts_by_idx.append(parts)
	var s_a: AudioStream = load(w["audio"]) if ResourceLoader.exists(w["audio"]) else null
	var s_b_path := str(w.get("audio_b", ""))
	var s_b: AudioStream = load(s_b_path) if (s_b_path != "" and ResourceLoader.exists(s_b_path)) else null
	_weapon_audio.append(s_a)
	var v_arr: Array[AudioStream] = []
	if s_a: v_arr.append(s_a)
	if s_b: v_arr.append(s_b)
	_weapon_audio_vars.append(v_arr)


func _prebuild_weapon_rigs() -> void:
	_weapon_rigs.clear()
	_w_parts_by_idx.clear()
	_weapon_audio.clear()
	_weapon_audio_vars.clear()
	_shotgun_shell_rig = null
	for i in range(WEAPONS.size()):
		_build_single_weapon_rig(i)


func prebuild_weapon_rigs_web_async(hud: BodycamHUD = null) -> void:
	_weapon_rigs.clear()
	_w_parts_by_idx.clear()
	_weapon_audio.clear()
	_weapon_audio_vars.clear()
	_shotgun_shell_rig = null
	var tree := get_tree()
	for i in range(WEAPONS.size()):
		if hud:
			hud.set_loading_status("BODYCAM-04 // PREPARING WEAPON RIGS (%d/%d)..." % [i + 1, WEAPONS.size()])
		_build_single_weapon_rig(i)
		await tree.process_frame
	_equip_weapon(0)


func _pose_part(grp: String, delta_pos: Vector3, delta_rot := Vector3.ZERO, pivot := Vector3.ZERO, is_vis := true) -> void:
	if not _w_parts.has(grp):
		return
	var rot_off := Vector3.ZERO
	if delta_rot != Vector3.ZERO and pivot != Vector3.ZERO:
		rot_off = pivot - Basis.from_euler(delta_rot) * pivot
	for p: Node3D in _w_parts[grp]:
		if is_instance_valid(p):
			var iid := p.get_instance_id()
			p.position = _w_rest_pos.get(iid, Vector3.ZERO) + delta_pos + rot_off
			p.rotation = _w_rest_rot.get(iid, Vector3.ZERO) + delta_rot
			p.visible = is_vis


func _move_part_group(grp: String, delta_pos: Vector3, delta_rot := Vector3.ZERO, is_vis := true) -> void:
	_pose_part(grp, delta_pos, delta_rot, Vector3.ZERO, is_vis)


func _apply_idle_bolt_and_cover() -> void:
	if current_weapon == 0:
		var empty_g17 := ammo_in_mag[0] <= 0
		var locked_back := 1.0 if empty_g17 else 0.0
		var slide_z := maxf(bolt_blowback, locked_back) * 0.034
		_pose_part("slide", Vector3(0.0, 0.0, slide_z))
		_pose_part("slidestop", Vector3.ZERO, Vector3(-0.22 * locked_back, 0.0, 0.0), PIVOT_G17_SLIDESTOP)
		_pose_part("trigger", Vector3.ZERO, Vector3(-0.22 * clampf(bolt_blowback, 0.0, 1.0), 0.0, 0.0), PIVOT_G17_TRIGGER)
		_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, not empty_g17)
	elif current_weapon == 1:
		_pose_part("slide", Vector3(0.0, 0.0, bolt_blowback * 0.052))
		_pose_part("dust_cover", Vector3.ZERO, Vector3.ZERO if _m16_dust_open else Vector3(0.0, 0.0, 1.48), PIVOT_AR_DUST)


func _reset_weapon_parts() -> void:
	if is_instance_valid(_shotgun_shell_rig):
		_shotgun_shell_rig.visible = false
	for grp in _w_parts.keys():
		for p: Node3D in _w_parts[grp]:
			if is_instance_valid(p):
				var iid := p.get_instance_id()
				p.position = _w_rest_pos.get(iid, Vector3.ZERO)
				p.rotation = _w_rest_rot.get(iid, Vector3.ZERO)
				p.visible = true
	_apply_idle_bolt_and_cover()


func _equip_weapon(idx: int) -> void:
	if idx < 0 or idx >= WEAPONS.size() or not unlocked_weapons[idx]:
		return
	current_weapon = idx
	is_reloading = false
	reload_cancel_req = false
	_shotgun_fire_on_cancel = false
	reload_pos_off = Vector3.ZERO
	reload_rot_off = Vector3.ZERO
	shotgun_pump_timer = 0.0
	bolt_blowback = 0.0
	_bow_drawing = false
	_bow_draw = 0.0
	_bow_hold_time = 0.0
	_bow_nock_timer = 0.0
	_hunting_bolt_timer = 0.0
	_hunting_bolt_did_sfx = false

	var w: Dictionary = WEAPONS[idx]
	for i in range(_weapon_rigs.size()):
		if is_instance_valid(_weapon_rigs[i]):
			_weapon_rigs[i].visible = (i == idx)
	_w_parts = _w_parts_by_idx[idx] if idx < _w_parts_by_idx.size() else {}
	_reset_weapon_parts()

	holo_quad.visible = w["has_holo"]
	holo_quad.position = w["holo_pos"]
	muzzle_light.position = w["muzzle"]
	muzzle_vm_light.position = w["muzzle"]
	muzzle_flash_rig.position = w["muzzle"]
	muzzle_smoke.position = w["muzzle"]
	if idx < _weapon_audio.size() and _weapon_audio[idx]:
		sfx_gun.stream = _weapon_audio[idx]
	emit_signal("weapon_changed", idx, w["name"])


func _fx_parent() -> Node:
	if game_manager and game_manager.zombies_root and game_manager.zombies_root.get_parent():
		return game_manager.zombies_root.get_parent()
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root


func _apply_deterministic_auto_iris() -> void:
	var flash_rim := 0.14 if muzzle_flash_timer > 0.0 else 0.0
	vm_rim.light_energy = (0.28 if is_ads else 0.22) + flash_rim
	camera.position.y = 0.065 if is_ads else 0.0
	camera.rotation.z = (-0.045 if is_ads else -0.061) + recoil_roll
	flashlight.light_volumetric_fog_energy = 0.18 if is_ads else 0.84
	var in_lit_lobby := global_position.z > -8.5
	var base_e := (145.0 if in_lit_lobby else 204.0) if is_ads else (26.0 if in_lit_lobby else 63.0)
	var on_snow := global_position.z < -28.3
	if on_snow and not is_ads:
		base_e = 8.6
	flashlight.spot_angle = 30.0 if is_ads else 58.0
	flashlight.spot_angle_attenuation = 0.52 if is_ads else 0.72
	flashlight.position = Vector3(0.09, -0.07, -0.44)
	flashlight.rotation.y = -0.043 if is_ads else 0.0
	flashlight.rotation.x = 0.063 if is_ads else (-0.74 if on_snow else -0.11)

	flashlight.light_color = Color(0.94, 0.96, 1.0)
	var nearest := 99.0
	var subject := Vector3.ZERO
	if game_manager and game_manager.zombies_root:
		var cam_pos := camera.global_position
		var fwd := -camera.global_transform.basis.z
		for z in game_manager.zombies_root.get_children():
			if z is ZombieAI and not z.dead:
				var v: Vector3 = (z.global_position + Vector3(0, 1.5, 0)) - cam_pos
				var d := v.length()
				if d < 4.5 and d > 0.2 and v.normalized().dot(fwd) > 0.35 and d < nearest:
					nearest = d
					subject = z.face_focus_position()

	var crowding := 0.0 if is_ads else (1.0 - smoothstep(1.1, 1.75, nearest))
	weapon_clearance.position = Vector3(0.022, -0.20, 0.05) * crowding
	weapon_clearance.rotation.x = -0.26 * crowding
	if nearest < 4.2:
		var t: float = clampf((nearest - 0.85) / 3.35, 0.0, 1.0)
		flashlight.light_energy = lerpf(0.24, base_e, t * t)
		flashlight.spot_angle = 57.0
		flashlight.rotation.x = 0.042
		if nearest < 2.2:
			flashlight.position = Vector3(-0.38, 0.25, -0.11)
			flashlight.look_at(subject, Vector3.UP)
			flashlight.light_color = Color(0.96, 0.96, 1.0)
			flashlight.light_energy *= 1.45
	else:
		flashlight.light_energy = base_e

	if game_manager and game_manager.hud and game_manager.hud.post_mat:
		if nearest < 2.4:
			var screen_point := camera.unproject_position(subject) / camera.get_viewport().get_visible_rect().size
			game_manager.hud.post_mat.set_shader_parameter("focus_uv", screen_point)
		game_manager.hud.post_mat.set_shader_parameter("near_focus", 1.0 - smoothstep(1.1, 2.4, nearest))
	if cam_attrs:
		cam_attrs.auto_exposure_enabled = false
		cam_attrs.exposure_multiplier = 1.0
		if nearest < 2.0:
			cam_attrs.dof_blur_far_enabled = true
			cam_attrs.dof_blur_far_distance = camera.global_position.distance_to(subject) + 0.16
			cam_attrs.dof_blur_far_transition = 1.0
			cam_attrs.dof_blur_amount = 0.014
		else:
			cam_attrs.dof_blur_far_enabled = false


func _update_flashlight_and_iris(delta: float) -> void:
	if deterministic_camera:
		_apply_deterministic_auto_iris()
		return

	var k := 1.0 - exp(-delta * 10.0)
	_ads_blend = lerpf(_ads_blend, 1.0 if is_ads else 0.0, 1.0 - exp(-delta * 14.0))
	camera.position.y = lerpf(0.0, 0.065, _ads_blend)

	var flash_rim := 0.14 if muzzle_elapsed < 0.05 else 0.0
	var base_rim := 0.46 if is_reloading else lerpf(0.22, 0.28, _ads_blend)
	vm_rim.light_energy = lerpf(vm_rim.light_energy, base_rim + flash_rim, k)
	var rim_pos_tgt := Vector3(-0.22, -0.06, -0.02) if is_reloading else Vector3(-0.24, 0.15, -0.04)
	vm_rim.position = vm_rim.position.lerp(rim_pos_tgt, k)
	if dust_motes:
		dust_motes.emitting = (global_position.z > -26.5)

	# Smooth zone transition weights (zero hard snaps at Z thresholds!)
	var tunnel_w := smoothstep(-6.5, -10.5, global_position.z) * (1.0 - smoothstep(-26.5, -30.5, global_position.z))
	var snow_w := smoothstep(-26.5, -30.5, global_position.z)
	var hip_e := lerpf(28.0, 52.0, tunnel_w)
	hip_e = lerpf(hip_e, 34.0, snow_w)
	var ads_e := lerpf(72.0, 118.0, tunnel_w)
	ads_e = lerpf(ads_e, 78.0, snow_w)
	var target_e := lerpf(hip_e, ads_e, _ads_blend)

	# Forward beam raycast for subtle bodycam exposure pump + physical wall bounce light
	var space := get_world_3d().direct_space_state
	var hit_dim := 1.0
	var beam_hit := {}
	if space and flashlight_on:
		var orig := camera.global_position
		var fwd := -camera.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(orig, orig + fwd * 12.0, 1 | 4)
		q.exclude = [get_rid()]
		beam_hit = space.intersect_ray(q)
		if beam_hit:
			var dist := orig.distance_to(beam_hit["position"])
			if dist < 2.8:
				hit_dim = lerpf(0.55, 1.0, smoothstep(0.65, 2.8, dist))

	_iris_wall_dim = lerpf(_iris_wall_dim, hit_dim, 1.0 - exp(-delta * 8.0))
	if cam_attrs:
		var exp_tgt := lerpf(0.84, 1.06, _iris_wall_dim)
		cam_attrs.exposure_multiplier = lerpf(cam_attrs.exposure_multiplier, exp_tgt, 1.0 - exp(-delta * 6.5))
	if flashlight.position.distance_squared_to(Vector3(0.09, -0.07, -0.44)) > 1e-6:
		flashlight.position = Vector3(0.09, -0.07, -0.44)
	var frot := Vector3(lerpf(-0.10, 0.04, _ads_blend), lerpf(0.0, -0.025, _ads_blend), 0.0)
	if flashlight.rotation.distance_squared_to(frot) > 1e-6:
		flashlight.rotation = frot
	var sang := lerpf(55.0, 32.0, _ads_blend)
	if absf(flashlight.spot_angle - sang) > 0.02:
		flashlight.spot_angle = sang
	var satt := lerpf(0.68, 0.52, _ads_blend)
	if absf(flashlight.spot_angle_attenuation - satt) > 0.002:
		flashlight.spot_angle_attenuation = satt
	var vfog_e := lerpf(0.72, 0.28, _ads_blend)
	if absf(flashlight.light_volumetric_fog_energy - vfog_e) > 0.002:
		flashlight.light_volumetric_fog_energy = vfog_e
	var fcol := Color(0.95, 0.97, 1.0).lerp(Color(1.0, 0.72, 0.40), _flash_shadow_boost * 0.75)
	if not flashlight.light_color.is_equal_approx(fcol):
		flashlight.light_color = fcol
	var fe := target_e * _iris_wall_dim * (1.0 + 0.28 * _flash_shadow_boost)
	if absf(flashlight.light_energy - fe) > 0.02:
		flashlight.light_energy = fe
	_update_flashlight_bounce(beam_hit, fe, k)
	var show_cone := _should_show_flashlight_cone()
	if flashlight_cone.visible != show_cone:
		flashlight_cone.visible = show_cone

	# Keep live zombies' crowding subtle weapon clearance without teleporting flashlight!
	var nearest := 99.0
	if game_manager and game_manager.zombies_root:
		var cam_pos := camera.global_position
		var fwd := -camera.global_transform.basis.z
		for z in game_manager.zombies_root.get_children():
			var zb := z as ZombieAI
			if zb and not zb.dead and zb.state != ZombieAI.State.SPAWNING:
				var d: float = zb.global_position.distance_to(cam_pos)
				if d < 2.2 and v_dot(zb.global_position - cam_pos, fwd) > 0.35:
					nearest = minf(nearest, d)
	var crowding := 0.0 if is_ads else (1.0 - smoothstep(0.95, 1.45, nearest))
	var cp := Vector3(0.015, -0.14, 0.06) * crowding
	if weapon_clearance.position.distance_squared_to(cp) > 1e-6:
		weapon_clearance.position = weapon_clearance.position.lerp(cp, k)
	var crx := -0.18 * crowding
	if absf(weapon_clearance.rotation.x - crx) > 0.001:
		weapon_clearance.rotation.x = lerpf(weapon_clearance.rotation.x, crx, k)

	if game_manager and game_manager.hud and game_manager.hud.post_mat and absf(_last_near_focus) > 0.001:
		_last_near_focus = 0.0
		game_manager.hud.post_mat.set_shader_parameter("near_focus", 0.0)
	if cam_attrs:
		if not cam_attrs.auto_exposure_enabled and RenderingServer.get_current_rendering_method() != "gl_compatibility":
			cam_attrs.auto_exposure_enabled = true
		if cam_attrs.dof_blur_far_enabled:
			cam_attrs.dof_blur_far_enabled = false


func v_dot(v: Vector3, fwd: Vector3) -> float:
	return v.normalized().dot(fwd) if v.length_squared() > 0.001 else 0.0


func get_current_weapon_name() -> String:
	if current_weapon == 3:
		var m: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
		return str(m["name"])
	return str(WEAPONS[current_weapon]["name"])


func acquire_melee_weapon(m_id: String) -> void:
	if not MELEE_CATALOG.has(m_id):
		return
	equipped_melee_id = m_id
	for k in _melee_nodes.keys():
		if is_instance_valid(_melee_nodes[k]):
			(_melee_nodes[k] as Node3D).visible = (str(k) == m_id)
	unlocked_weapons[3] = true
	_equip_weapon(3)


func unlock_and_equip(idx: int) -> void:
	if idx >= 0 and idx < WEAPONS.size():
		unlocked_weapons[idx] = true
		ammo_in_mag[idx] = WEAPONS[idx]["mag_size"]
		ammo_reserve[idx] = WEAPONS[idx]["reserve_max"]
		_equip_weapon(idx)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or dead or deterministic_camera:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sens * (0.62 if is_ads else 1.0)
		var dx: float = -event.relative.x * sens
		var dy: float = -event.relative.y * sens
		yaw += dx
		pitch = clamp(pitch + dy, -1.35, 1.35)
		sway_offset.x = clamp(sway_offset.x + dx * 2.5, -0.065, 0.065)
		sway_offset.y = clamp(sway_offset.y + dy * 2.5, -0.055, 0.055)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_1:
			_equip_weapon(0)
		elif event.physical_keycode == KEY_2:
			_equip_weapon(1)
		elif event.physical_keycode == KEY_3:
			_equip_weapon(2)
		elif event.physical_keycode == KEY_4:
			_equip_weapon(3)
		elif event.physical_keycode == KEY_5:
			_equip_weapon(4)
		elif event.physical_keycode == KEY_6:
			_equip_weapon(5)
		elif event.physical_keycode == KEY_7:
			_equip_weapon(6)
		elif event.physical_keycode == KEY_8:
			_equip_weapon(7)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_equip_weapon((current_weapon + 1) % WEAPONS.size())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_equip_weapon((current_weapon + WEAPONS.size() - 1) % WEAPONS.size())


func _should_show_flashlight_cone() -> bool:
	if not flashlight_on:
		return false
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return true
	if game_manager and game_manager.world:
		return not game_manager.world.user_vol_fog_enabled
	return false


func _surface_bounce_color(surf: String) -> Color:
	match surf:
		"brick":
			return Color(1.0, 0.68, 0.48)
		"snow":
			return Color(0.76, 0.86, 1.0)
		"wood":
			return Color(0.98, 0.80, 0.56)
		"mud":
			return Color(0.68, 0.62, 0.54)
		_:
			return Color(0.92, 0.88, 0.82)


func _update_flashlight_bounce(hit: Dictionary, flash_e: float, k: float) -> void:
	if flashlight_bounce == null:
		return
	if not flashlight_on or RenderingServer.get_current_rendering_method() == "gl_compatibility" or hit.is_empty():
		flashlight_bounce.light_energy = lerpf(flashlight_bounce.light_energy, 0.0, k)
		if flashlight_bounce.light_energy < 0.01:
			flashlight_bounce.visible = false
		return
	var hpos := hit["position"] as Vector3
	var hnrm := hit["normal"] as Vector3
	var dist := camera.global_position.distance_to(hpos)
	var pos := hpos + hnrm * 0.34
	var col_node = hit.get("collider")
	var surf := str(col_node.get_meta(&"surface", "")) if (col_node != null and col_node is Object and (col_node as Object).has_meta(&"surface")) else ""
	var tgt_col := _surface_bounce_color(surf)
	var tgt_e := clampf(flash_e / (1.0 + dist * dist * 0.42), 0.0, 2.4) * 0.34
	if not flashlight_bounce.visible:
		flashlight_bounce.global_position = pos
		flashlight_bounce.light_color = tgt_col
		flashlight_bounce.light_energy = tgt_e * 0.5
		flashlight_bounce.visible = true
	else:
		flashlight_bounce.global_position = flashlight_bounce.global_position.lerp(pos, k)
		flashlight_bounce.light_color = flashlight_bounce.light_color.lerp(tgt_col, k)
		flashlight_bounce.light_energy = lerpf(flashlight_bounce.light_energy, tgt_e, k)


func set_deterministic_view(pos: Vector3, look_yaw: float, look_pitch: float, weapon_idx: int,
		ads_state: bool, light_state: bool, flash_energy := 0.0) -> void:
	deterministic_camera = true
	global_position = pos
	yaw = look_yaw
	pitch = look_pitch
	rotation.y = yaw
	head.rotation = Vector3(pitch, 0.0, 0.0)
	_equip_weapon(weapon_idx)
	is_ads = ads_state
	flashlight_on = light_state
	flashlight.visible = flashlight_on
	flashlight_spill.visible = false
	flashlight_cone.visible = _should_show_flashlight_cone()
	if flashlight_bounce and not flashlight_on:
		flashlight_bounce.visible = false
		flashlight_bounce.light_energy = 0.0
	var w: Dictionary = WEAPONS[current_weapon]
	weapon_pivot.position = w["ads_pos"] if is_ads else w["hip_pos"]
	weapon_pivot.rotation = w["ads_rot"] if is_ads else w["hip_rot"]
	camera.fov = 60.5 if is_ads else 94.0
	muzzle_light.light_energy = flash_energy
	muzzle_light.visible = flash_energy > 0.05
	muzzle_vm_light.light_energy = minf(flash_energy * 0.45, 1.4)
	muzzle_vm_light.visible = flash_energy > 0.05
	muzzle_flash_timer = 0.025 if flash_energy > 0.1 else 0.0
	muzzle_flash_rig.visible = flash_energy > 0.1
	for fm in _flash_mats:
		fm.set_shader_parameter("cool_t", 0.0)
	if flash_energy > 0.1:
		var fs: float = w["flash_scale"]
		muzzle_flash_rig.scale = Vector3.ONE * fs
	damage_flash = 0.0
	_apply_deterministic_auto_iris()
	if game_manager and game_manager.world:
		game_manager.world.update_zone_culling(camera)


func _update_casings(delta: float) -> void:
	var i := _casings.size() - 1
	while i >= 0:
		var c: Dictionary = _casings[i]
		c["age"] += delta
		var mi: MeshInstance3D = c["node"]
		var max_age := 3.2 if bool(c.get("is_mag", false)) else 2.4
		if c["age"] > max_age or not is_instance_valid(mi):
			if is_instance_valid(mi):
				mi.queue_free()
			_casings.remove_at(i)
			i -= 1
			continue
		var vel: Vector3 = c["vel"]
		vel.y -= 13.5 * delta
		mi.global_position += vel * delta
		mi.rotation += (c["ang"] as Vector3) * delta
		var floor_y: float = float(c.get("floor_y", global_position.y + 0.012))
		if mi.global_position.y <= floor_y:
			mi.global_position.y = floor_y
			if not c["bounced"]:
				c["bounced"] = true
				vel.y = absf(vel.y) * (0.24 if bool(c.get("is_mag", false)) else 0.34)
				vel.x *= 0.55
				vel.z *= 0.55
				c["ang"] = (c["ang"] as Vector3) * 0.35
				if sfx_casing and not _sfx_shell_clink.is_empty():
					sfx_casing.stream = _sfx_shell_clink[randi() % _sfx_shell_clink.size()]
					if bool(c.get("is_mag", false)):
						sfx_casing.pitch_scale = randf_range(0.54, 0.68)
					else:
						sfx_casing.pitch_scale = randf_range(0.76, 0.92) if bool(c.get("is_hull", false)) else randf_range(0.92, 1.16)
					sfx_casing.play()
			else:
				vel = Vector3.ZERO
				c["ang"] = Vector3.ZERO
		c["vel"] = vel
		i -= 1


func _physics_process(delta: float) -> void:
	_update_casings(delta)
	_update_arrows(delta)
	if deterministic_camera or dead or not input_enabled:
		return

	is_crouching = Input.is_action_pressed("crouch")
	if ads_lockout > 0.0:
		ads_lockout -= delta
	is_ads = Input.is_action_pressed("aim") and not is_reloading and ads_lockout <= 0.0
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and not is_ads and not is_reloading and Input.get_vector("move_left", "move_right", "move_forward", "move_backward").length() > 0.1

	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var basis_fwd := -global_transform.basis.z
	var basis_right := global_transform.basis.x
	var move_dir := (basis_right * iv.x - basis_fwd * iv.y).normalized()
	var spd := 2.4 if is_crouching else (6.2 if is_sprinting else (2.7 if is_ads else 4.1))

	velocity.x = lerp(velocity.x, move_dir.x * spd, delta * 10.5)
	velocity.z = lerp(velocity.z, move_dir.z * spd, delta * 10.5)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
		_pre_land_vy = minf(_pre_land_vy, velocity.y)
		_was_on_floor = false
	else:
		if not _was_on_floor and _pre_land_vy < -2.2:
			var imp := clampf(-_pre_land_vy / 9.5, 0.08, 0.42)
			trauma = minf(1.0, trauma + imp * 0.45)
			_land_dip = minf(0.11, imp * 0.16)
			if sfx_step and sfx_step.stream:
				sfx_step.pitch_scale = randf_range(0.75, 0.90)
				sfx_step.play()
		_was_on_floor = true
		_pre_land_vy = 0.0
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = 5.4

	move_and_slide()

	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("melee"):
		trigger_melee()

	if _melee_timer > 0.0:
		_melee_timer = maxf(0.0, _melee_timer - delta)
		var m_elapsed := _melee_dur - _melee_timer
		if not _melee_hit_done and m_elapsed >= 0.11:
			_melee_hit_done = true
			_perform_melee_hit()

	if fire_cd > 0.0:
		fire_cd -= delta
	var w: Dictionary = WEAPONS[current_weapon]
	var wants_fire := Input.is_action_pressed("fire") if w["auto"] else Input.is_action_just_pressed("fire")
	if bool(w.get("is_melee", false)) and wants_fire:
		trigger_melee()
		wants_fire = false
	if bool(w.get("is_bow", false)):
		_update_bow_input(delta)
		wants_fire = false
	if is_reloading and current_weapon == 2 and ammo_in_mag[2] > 0 and wants_fire:
		reload_cancel_req = true
		_shotgun_fire_on_cancel = true
		if reload_shell_phase == 0 and not reload_was_empty:
			is_reloading = false
			reload_cancel_req = false
			_shotgun_fire_on_cancel = false
			reload_pos_off = Vector3.ZERO
			reload_rot_off = Vector3.ZERO
			_reset_weapon_parts()
		elif reload_shell_phase == 1 and ((reload_shell_timer < 0.16 and not reload_was_empty) or reload_shell_timer >= 0.22):
			reload_shell_phase = 2
			reload_shell_timer = 0.0
			reload_flags = 0
	if wants_fire and fire_cd <= 0.0 and not is_reloading:
		if _sprint_blend > 0.25 and _sprint_out_timer <= 0.0:
			_sprint_out_timer = 0.14 if current_weapon == 0 else (0.18 if current_weapon == 1 else 0.22)
		if _sprint_out_timer <= 0.0:
			fire_weapon()
	if _sprint_out_timer > 0.0:
		_sprint_out_timer = maxf(0.0, _sprint_out_timer - delta)

	if Input.is_action_just_pressed("interact"):
		try_interact()


func _process(delta: float) -> void:
	if deterministic_camera:
		_update_flashlight_and_iris(delta)
		return

	# Smooth muzzle exponential decay & 2-frame flash cooling
	_flash_shadow_boost = maxf(0.0, _flash_shadow_boost - delta * 24.0)
	if muzzle_elapsed < 0.065:
		muzzle_elapsed += delta
		var e := muzzle_peak_e * exp(-muzzle_elapsed / 0.017) if muzzle_elapsed < 0.060 else 0.0
		var active := e > 0.01
		muzzle_light.visible = active
		muzzle_light.light_energy = e
		muzzle_vm_light.visible = active
		muzzle_vm_light.light_energy = minf(e * 0.38, 1.25)
	else:
		muzzle_light.light_energy = 0.0
		muzzle_light.visible = false
		muzzle_vm_light.light_energy = 0.0
		muzzle_vm_light.visible = false

	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		var cool := clampf(1.0 - muzzle_flash_timer / 0.036, 0.0, 1.0)
		for fm in _flash_mats:
			fm.set_shader_parameter("cool_t", cool)
		if muzzle_flash_timer <= 0.0:
			muzzle_flash_rig.visible = false

	if _barrel_heat_timer > 0.0 and muzzle_smoke and not OS.has_feature("web"):
		_barrel_heat_timer -= delta
		_barrel_heat_step -= delta
		if _barrel_heat_step <= 0.0:
			_barrel_heat_step = 0.16
			var hxf := muzzle_smoke.global_transform
			var hv := Vector3(randf_range(-0.08, 0.08), randf_range(0.28, 0.45), randf_range(-0.08, 0.08))
			muzzle_smoke.emit_particle(hxf, hv, Color.WHITE, Color.WHITE, GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)

	damage_flash = maxf(0.0, damage_flash - delta * 1.4)
	damage_invuln = maxf(0.0, damage_invuln - delta)
	hit_glitch = maxf(0.0, hit_glitch - delta * 1.9)
	hit_ca_boost = maxf(0.0, hit_ca_boost - delta * 0.08)

	if dead:
		head.position.y = lerp(head.position.y, 0.28, delta * 4.0)
		head.rotation.z = lerp(head.rotation.z, 0.65, delta * 3.0)
		return

	# Compute yaw angular speed for subtle CMOS rolling shutter
	var d_yaw := yaw - _last_yaw
	_last_yaw = yaw
	yaw_vel = lerpf(yaw_vel, d_yaw / maxf(delta, 0.001), 1.0 - exp(-delta * 18.0))

	if not input_enabled:
		_update_flashlight_and_iris(delta)
		return

	rotation.y = yaw

	# Trauma noise shake
	trauma = maxf(0.0, trauma - delta * 2.1)
	var shake := trauma * trauma
	var t_now := Time.get_ticks_msec() * 0.001
	var shake_p := _noise.get_noise_1d(t_now * 19.0) * 0.042 * shake
	var shake_y := _noise.get_noise_1d(t_now * 23.0 + 40.0) * 0.036 * shake
	var shake_r := _noise.get_noise_1d(t_now * 29.0 + 90.0) * 0.055 * shake

	# Distance-based footstep cadence & head dip
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var horiz_spd := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_spd > 0.35:
		var stride := 1.65 if is_crouching else (2.65 if is_sprinting else 2.15)
		bob_phase += (horiz_spd * delta / stride) * PI
		step_dist += horiz_spd * delta
		if step_dist >= stride:
			step_dist -= stride
			step_side *= -1.0
			step_roll_impulse = step_side * (0.015 if is_sprinting else 0.007)
			_land_dip = maxf(_land_dip, 0.026 if is_sprinting else 0.012)
			trauma = minf(1.0, trauma + (0.055 if is_sprinting else 0.02))
			if sfx_step and sfx_step.stream:
				sfx_step.pitch_scale = randf_range(0.84, 1.16) * (0.85 if is_crouching else 1.0)
				sfx_step.play()
	else:
		bob_phase += delta * 1.3

	step_roll_impulse = lerpf(step_roll_impulse, 0.0, 1.0 - exp(-delta * 12.0))
	hit_roll_kick = lerpf(hit_roll_kick, 0.0, 1.0 - exp(-delta * 10.0))
	hit_pitch_kick = lerpf(hit_pitch_kick, 0.0, 1.0 - exp(-delta * 10.0))
	_land_dip = lerpf(_land_dip, 0.0, 1.0 - exp(-delta * 14.0))
	recoil_roll = lerpf(recoil_roll, 0.0, 1.0 - exp(-delta * 18.0))
	recoil_fov = lerpf(recoil_fov, 0.0, 1.0 - exp(-delta * 18.0))

	# ADS subtle breathing micro-sway
	var ads_sway_amp := (0.5 if is_crouching else 1.0) * (1.8 if horiz_spd > 0.4 else 1.0)
	var breath_x := (sin(t_now * 1.37) * 0.0022 + sin(t_now * 2.41) * 0.0011) * ads_sway_amp * _ads_blend
	var breath_y := (cos(t_now * 1.73) * 0.0018 + sin(t_now * 2.91) * 0.0009) * ads_sway_amp * _ads_blend

	var bob_amp := (0.042 if is_sprinting else 0.022) if horiz_spd > 0.35 else 0.005
	var target_h := (1.05 if is_crouching else 1.56) - _land_dip
	head.position.y = lerpf(head.position.y, target_h + sin(bob_phase * 2.0) * bob_amp, 1.0 - exp(-delta * 15.0))
	head.rotation.x = clampf(pitch + recoil_vel.y + hit_pitch_kick + shake_p + breath_y, -1.42, 1.42)
	head.rotation.y = shake_y + breath_x
	head.rotation.z = lerpf(head.rotation.z, -iv.x * 0.048 + sin(bob_phase) * bob_amp * 0.72 + step_roll_impulse, 1.0 - exp(-delta * 12.0)) + hit_roll_kick + shake_r
	camera.rotation.z = lerpf(-0.061, -0.042, _ads_blend) + recoil_roll

	# Update reloads, blowback, and sprint low-ready
	if is_reloading:
		_update_reload(delta)
	else:
		reload_pos_off = reload_pos_off.lerp(Vector3.ZERO, 1.0 - exp(-delta * 14.0))
		reload_rot_off = reload_rot_off.lerp(Vector3.ZERO, 1.0 - exp(-delta * 14.0))

	_update_weapon_mechanics(delta)

	var want_sprint := is_sprinting and not is_reloading and _sprint_out_timer <= 0.0
	_sprint_blend = lerpf(_sprint_blend, 1.0 if want_sprint else 0.0, 1.0 - exp(-delta * 11.0))

	sway_offset = sway_offset.lerp(Vector2.ZERO, 1.0 - exp(-delta * 9.0))
	recoil_vel = recoil_vel.lerp(Vector2.ZERO, 1.0 - exp(-delta * 12.0))
	recoil_z = lerpf(recoil_z, 0.0, 1.0 - exp(-delta * 15.0))

	var w: Dictionary = WEAPONS[current_weapon]
	var base_pos: Vector3 = (w["hip_pos"] as Vector3).lerp(w["ads_pos"] as Vector3, _ads_blend)
	var base_rot: Vector3 = (w["hip_rot"] as Vector3).lerp(w["ads_rot"] as Vector3, _ads_blend)

	var sway_scale := lerpf(1.0, 0.18, _ads_blend)
	var low_ready_pos := Vector3(-0.048, -0.062, 0.038) * _sprint_blend
	var low_ready_rot := Vector3(-0.36, 0.34, 0.24) * _sprint_blend

	var pump_off_p := Vector3.ZERO
	var pump_off_r := Vector3.ZERO
	if shotgun_pump_timer > 0.0 and current_weapon == 2 and not is_reloading:
		var pt := clampf(1.0 - shotgun_pump_timer / 0.36, 0.0, 1.0)
		var pulse := sin(pt * PI)
		pump_off_p = Vector3(0.014, -0.026, 0.036) * pulse
		pump_off_r = Vector3(-0.14, 0.08, 0.24) * pulse

	var target_pos := base_pos + reload_pos_off + low_ready_pos + pump_off_p + Vector3(
		-sway_offset.x * 0.72 * sway_scale + cos(bob_phase) * bob_amp * 0.45 * sway_scale,
		-sway_offset.y * 0.58 * sway_scale + absf(sin(bob_phase)) * -bob_amp * 0.65 * sway_scale - _land_dip * 0.35,
		recoil_z
	)
	var target_rot := base_rot + reload_rot_off + low_ready_rot + pump_off_r + Vector3(
		recoil_vel.y * 1.65,
		-sway_offset.x * 2.8 * sway_scale,
		sway_offset.x * 2.2 * sway_scale + (-iv.x * 0.06)
	)
	var melee_p := Vector3.ZERO
	var melee_r := Vector3.ZERO
	if _melee_timer > 0.0:
		var mu := clampf(1.0 - _melee_timer / maxf(_melee_dur, 0.01), 0.0, 1.0)
		var wind := sin(smoothstep(0.0, 0.24, mu) * PI * 0.5) * (1.0 - smoothstep(0.24, 0.44, mu))
		var slash := sin(smoothstep(0.20, 0.65, mu) * PI)
		melee_p = Vector3(0.09 * wind - 0.26 * slash, 0.07 * wind - 0.05 * slash, 0.06 * wind - 0.18 * slash)
		melee_r = Vector3(0.32 * wind - 0.65 * slash, -0.45 * wind + 1.15 * slash, -0.35 * wind + 0.72 * slash)
	weapon_pivot.position = weapon_pivot.position.lerp(target_pos + melee_p, 1.0 - exp(-delta * (28.0 if _melee_timer > 0.0 else 18.0)))
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rot + melee_r, 1.0 - exp(-delta * (26.0 if _melee_timer > 0.0 else 16.0)))

	var ads_fov_val := float(w.get("ads_fov", 60.5))
	var bow_fov_off := -7.5 * _bow_draw if bool(w.get("is_bow", false)) else 0.0
	var target_fov := lerpf(94.0, ads_fov_val, _ads_blend) + _sprint_blend * 5.5 + recoil_fov + bow_fov_off
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-delta * 14.0))

	_update_flashlight_and_iris(delta)


func _spawn_dropped_mag(weapon_idx: int) -> void:
	if _mag_mat_dark == null:
		_mag_mat_dark = StandardMaterial3D.new()
		_mag_mat_dark.albedo_color = Color(0.11, 0.12, 0.13)
		_mag_mat_dark.metallic = 0.28
		_mag_mat_dark.roughness = 0.54
	if _mag_mesh_g17 == null:
		_mag_mesh_g17 = BoxMesh.new()
		_mag_mesh_g17.size = Vector3(0.024, 0.112, 0.036)
		_mag_mesh_g17.material = _mag_mat_dark
	if _mag_mesh_ar == null:
		var ar_box := BoxMesh.new()
		ar_box.size = Vector3(0.026, 0.162, 0.066)
		ar_box.material = _mag_mat_dark
		_mag_mesh_ar = ar_box
	if _casings.size() >= 18:
		var old: Dictionary = _casings.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = _mag_mesh_g17 if weapon_idx == 0 else _mag_mesh_ar
	if weapon_idx == 1 and _mag_mat_ar != null:
		mi.set_surface_override_material(0, _mag_mat_ar)
	mi.layers = 1 | 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	var local_spawn := (Vector3(0.0, -0.04, -0.145) + EJECT_G17 * 0.20) if weapon_idx == 0 else (Vector3(0.0, -0.11, -0.135) + EJECT_AR * 0.20)
	var spawn_p := weapon_pivot.to_global(local_spawn)
	mi.global_position = spawn_p
	mi.global_rotation = weapon_pivot.global_rotation + Vector3(-0.36 if weapon_idx == 0 else -0.17, 0.0, 0.0)
	var local_eject := (EJECT_G17 if weapon_idx == 0 else EJECT_AR).normalized()
	var world_dir := (weapon_pivot.global_transform.basis * local_eject).normalized()
	var ej_vel := world_dir * randf_range(1.3, 1.85) + velocity * 0.35
	var floor_y := global_position.y + 0.020
	var space := get_world_3d().direct_space_state
	if space:
		var land_xz := spawn_p + Vector3(ej_vel.x, 0.0, ej_vel.z) * 0.25
		var fq := PhysicsRayQueryParameters3D.create(Vector3(land_xz.x, spawn_p.y + 0.2, land_xz.z), Vector3(land_xz.x, spawn_p.y - 4.0, land_xz.z), 1)
		var fhit := space.intersect_ray(fq)
		if fhit:
			floor_y = float(fhit["position"].y) + 0.018
	_casings.append({
		"node": mi,
		"vel": ej_vel,
		"ang": Vector3(randf_range(4.0, 9.0), randf_range(-6.0, 6.0), randf_range(-8.0, 8.0)),
		"age": 0.0,
		"bounced": false,
		"floor_y": floor_y,
		"is_hull": false,
		"is_mag": true,
	})


func _update_weapon_mechanics(delta: float) -> void:
	bolt_blowback = maxf(0.0, bolt_blowback - delta * (14.0 if current_weapon == 0 else 18.0))
	if shotgun_pump_timer > 0.0:
		shotgun_pump_timer = maxf(0.0, shotgun_pump_timer - delta)
		if not shotgun_pump_did_sfx and shotgun_pump_timer < 0.26:
			shotgun_pump_did_sfx = true
			_eject_brass_casing(WEAPONS[2], true)
			if sfx_reload and _sfx_bolt:
				sfx_reload.stream = _sfx_bolt
				sfx_reload.pitch_scale = 0.85
				sfx_reload.play()

	if _hunting_bolt_timer > 0.0:
		_hunting_bolt_timer = maxf(0.0, _hunting_bolt_timer - delta)
		if not _hunting_bolt_did_sfx and _hunting_bolt_timer < 0.50:
			_hunting_bolt_did_sfx = true
			_eject_brass_casing(WEAPONS[7], false)
			if sfx_reload and _sfx_bolt:
				sfx_reload.stream = _sfx_bolt
				sfx_reload.pitch_scale = 0.76
				sfx_reload.play()
	_revolver_hammer = maxf(0.0, _revolver_hammer - delta * 8.0)

	if is_reloading:
		return

	if current_weapon == 0 or current_weapon == 1:
		_apply_idle_bolt_and_cover()
	elif current_weapon == 2:
		var pump_pull := 0.0
		if shotgun_pump_timer > 0.0:
			var pt := clampf(1.0 - shotgun_pump_timer / 0.36, 0.0, 1.0)
			pump_pull = sin(pt * PI) * 0.068
		_pose_part("pump", Vector3(0, 0, pump_pull))
		_pose_part("arm_left", Vector3(0, 0, pump_pull))
		_pose_part("slide", Vector3(0, 0, maxf(bolt_blowback * 0.04, pump_pull)))
		_pose_part("charge", Vector3(0, 0, pump_pull))
		_pose_part("lifter", Vector3.ZERO)
	elif current_weapon == 4:
		_pose_bow_rig()
	elif current_weapon == 5:
		_pose_part("charge", Vector3(0, 0, bolt_blowback * 0.025))
	elif current_weapon == 6:
		_pose_part("crane", Vector3.ZERO)
		_pose_part("cylinder", Vector3.ZERO, Vector3(0.0, 0.0, _revolver_cyl_angle))
		_pose_part("hammer", Vector3.ZERO, Vector3(0.55 * _revolver_hammer, 0.0, 0.0))
	elif current_weapon == 7:
		if _hunting_bolt_timer > 0.0:
			var u := clampf(1.0 - _hunting_bolt_timer / 0.78, 0.0, 1.0)
			var lift := sin(smoothstep(0.0, 0.25, u) * PI * 0.5) * (1.0 - smoothstep(0.75, 1.0, u))
			var pull := sin(smoothstep(0.18, 0.82, u) * PI)
			_pose_part("bolt", Vector3(0.0, 0.0, pull * 0.082), Vector3(0.0, 0.0, lift * 1.05))
		else:
			_pose_part("bolt", Vector3.ZERO)


func _play_reload_sfx(stream: AudioStream, pitch_sc := 1.0) -> void:
	if sfx_reload and stream:
		sfx_reload.stream = stream
		sfx_reload.pitch_scale = pitch_sc
		sfx_reload.play()


func _commit_mag_ammo() -> void:
	var w: Dictionary = WEAPONS[current_weapon]
	var need: int = w["mag_size"] - ammo_in_mag[current_weapon]
	var take: int = mini(need, ammo_reserve[current_weapon])
	ammo_in_mag[current_weapon] += take
	ammo_reserve[current_weapon] -= take


func start_reload() -> bool:
	var w: Dictionary = WEAPONS[current_weapon]
	if bool(w.get("is_melee", false)) or bool(w.get("is_bow", false)):
		return false
	if is_reloading or ammo_in_mag[current_weapon] >= w["mag_size"] or ammo_reserve[current_weapon] <= 0:
		return false
	is_reloading = true
	reload_elapsed = 0.0
	reload_flags = 0
	reload_was_empty = (ammo_in_mag[current_weapon] <= 0)
	reload_shell_timer = 0.0
	reload_shell_phase = 0
	reload_cancel_req = false
	_shotgun_fire_on_cancel = false
	shotgun_pump_timer = 0.0
	_hunting_bolt_timer = 0.0

	if current_weapon == 0:
		reload_dur = 1.72 if reload_was_empty else 1.32
	elif current_weapon == 1:
		reload_dur = 2.42 if reload_was_empty else 1.96
	elif current_weapon == 5:
		reload_dur = 2.05 if reload_was_empty else 1.55
	elif current_weapon == 6:
		reload_dur = 2.15
	elif current_weapon == 7:
		reload_dur = 2.35
	else:
		reload_dur = 1.2 # Managed by shell loop phases
	return true


func _update_reload(delta: float) -> void:
	reload_elapsed += delta
	if current_weapon == 0:
		_update_reload_pistol()
	elif current_weapon == 1:
		_update_reload_rifle()
	elif current_weapon == 5:
		_update_reload_mp5()
	elif current_weapon == 6:
		_update_reload_magnum()
	elif current_weapon == 7:
		_update_reload_hunting()
	else:
		_update_reload_shotgun(delta)


func _update_reload_mp5() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.04, 0.09, -0.05)
	var cant_r := Vector3(0.24, 0.34, -0.45)
	if t < 0.22:
		var u := smoothstep(0.0, 0.22, t)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("charge", Vector3(0.0, 0.0, 0.065 * u) if reload_was_empty else Vector3.ZERO)
	elif t < 0.62:
		if not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_mag_out, 1.12)
		var u := smoothstep(0.22, 0.58, t)
		reload_pos_off = cant_p + Vector3(0, -0.015 * sin(u * PI), 0)
		reload_rot_off = cant_r
		_pose_part("mag", Vector3(0.0, -0.22 * u, 0.03 * u), Vector3(-0.25 * u, 0, 0), Vector3.ZERO, u < 0.92)
	elif t < 1.22:
		var u := smoothstep(0.75, 1.15, t)
		var slap := sin(smoothstep(1.10, 1.22, t) * PI)
		reload_pos_off = cant_p + Vector3(0, 0.022 * slap, 0)
		reload_rot_off = cant_r + Vector3(0.06 * slap, 0, 0)
		_pose_part("mag", Vector3(0.0, lerpf(-0.22, 0.0, u), 0.0), Vector3(lerpf(-0.25, 0.0, u), 0, 0), Vector3.ZERO, t >= 0.72)
		if t >= 1.02 and not (reload_flags & 2):
			reload_flags |= 2
			_play_reload_sfx(_sfx_mag_in, 1.14)
		if t >= 1.12 and not (reload_flags & 4):
			reload_flags |= 4
			_commit_mag_ammo()
			trauma = minf(1.0, trauma + 0.08)
	elif reload_was_empty and t < 1.72:
		# Iconic HK slap!
		var u := smoothstep(1.22, 1.62, t)
		var slap_hit := sin(smoothstep(1.42, 1.62, t) * PI)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u) + Vector3(0.018 * slap_hit, -0.024 * slap_hit, 0.0)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u) + Vector3(0.0, 0.0, -0.18 * slap_hit)
		_pose_part("charge", Vector3(0.0, 0.0, 0.065 * (1.0 - smoothstep(1.44, 1.54, t))))
		if t >= 1.44 and not (reload_flags & 8):
			reload_flags |= 8
			_play_reload_sfx(_sfx_bolt, 1.18)
			trauma = minf(1.0, trauma + 0.11)
	else:
		var s0 := 1.72 if reload_was_empty else 1.22
		var u := smoothstep(s0, reload_dur, t)
		reload_pos_off = (Vector3.ZERO if reload_was_empty else cant_p).lerp(Vector3.ZERO, u)
		reload_rot_off = (Vector3.ZERO if reload_was_empty else cant_r).lerp(Vector3.ZERO, u)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("charge", Vector3.ZERO)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_magnum() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.04, 0.075, -0.04)
	var cant_r := Vector3(0.32, 0.24, 0.58)
	if t < 0.28:
		var u := smoothstep(0.0, 0.28, t)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, -1.25 * u))
		if t >= 0.14 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_mag_out, 0.90)
	elif t < 0.72:
		# Tilt up to dump spent brass
		var u := smoothstep(0.28, 0.72, t)
		var dump := sin(u * PI)
		reload_pos_off = cant_p + Vector3(0, 0.03 * dump, 0.02 * dump)
		reload_rot_off = cant_r + Vector3(0.55 * dump, 0.0, 0.15 * dump)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, -1.25))
		if t >= 0.45 and not (reload_flags & 2):
			reload_flags |= 2
			for _c in range(3):
				_eject_brass_casing(WEAPONS[6], false)
	elif t < 1.50:
		# Speedloader insertion
		var u := smoothstep(0.72, 1.45, t)
		var seat := sin(smoothstep(1.10, 1.40, t) * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.02 + 0.022 * seat, 0.0)
		reload_rot_off = Vector3(-0.18, 0.20, 0.48)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, -1.25))
		_pose_part("cylinder", Vector3.ZERO, Vector3(0.0, 0.0, _revolver_cyl_angle + u * TAU))
		if t >= 1.15 and not (reload_flags & 4):
			reload_flags |= 4
			_play_reload_sfx(_sfx_shell_in, 0.88)
			_commit_mag_ammo()
	else:
		# Wrist flick snaps cylinder shut!
		var u := smoothstep(1.50, reload_dur, t)
		var snap := smoothstep(1.54, 1.72, t)
		var flick := sin(smoothstep(1.52, 1.78, t) * PI)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u) + Vector3(0.025 * flick, 0.0, 0.0)
		reload_rot_off = Vector3(-0.18, 0.20, 0.48).lerp(Vector3.ZERO, u) + Vector3(0.0, 0.0, -0.32 * flick)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, -1.25 * (1.0 - snap)))
		if t >= 1.66 and not (reload_flags & 8):
			reload_flags |= 8
			_play_reload_sfx(_sfx_mag_in, 0.92)
			trauma = minf(1.0, trauma + 0.12)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_hunting() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.045, 0.085, -0.05)
	var cant_r := Vector3(0.20, 0.28, -0.44)
	if t < 0.35:
		var u := smoothstep(0.0, 0.35, t)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085 * smoothstep(0.15, 0.35, t)), Vector3(0.0, 0.0, 1.05 * smoothstep(0.0, 0.22, t)))
		if t >= 0.14 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_bolt, 0.78)
	elif t < 1.65:
		var u := smoothstep(0.35, 1.65, t)
		var push := sin(u * PI * 3.0)
		reload_pos_off = cant_p + Vector3(0.0, 0.012 * absf(push), 0.0)
		reload_rot_off = cant_r
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085), Vector3(0.0, 0.0, 1.05))
		if t >= 0.65 and not (reload_flags & 2):
			reload_flags |= 2
			_play_reload_sfx(_sfx_shell_in, 1.06)
		if t >= 1.05 and not (reload_flags & 4):
			reload_flags |= 4
			_play_reload_sfx(_sfx_shell_in, 1.12)
		if t >= 1.45 and not (reload_flags & 8):
			reload_flags |= 8
			_play_reload_sfx(_sfx_shell_in, 1.16)
			_commit_mag_ammo()
	else:
		var u := smoothstep(1.65, reload_dur, t)
		var close_u := smoothstep(1.65, 1.98, t)
		var lock_u := smoothstep(1.92, 2.15, t)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u)
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085 * (1.0 - close_u)), Vector3(0.0, 0.0, 1.05 * (1.0 - lock_u)))
		if t >= 1.85 and not (reload_flags & 16):
			reload_flags |= 16
			_play_reload_sfx(_sfx_bolt, 0.88)
			trauma = minf(1.0, trauma + 0.10)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_rifle() -> void:
	var t := reload_elapsed
	var base_cant_p := Vector3(-0.056, 0.152, -0.088)
	var base_cant_r := Vector3(0.34, 0.48, -0.52)
	var hand_mag_p := Vector3(0.008, -0.172, 0.168)
	var hand_mag_r := Vector3(-0.64, 0.34, 0.52)
	var hand_drop_r := Vector3(-0.78, 0.42, 0.62)
	var hand_pouch_p := hand_mag_p + EJECT_AR * 0.25 + Vector3(-0.035, -0.065, 0.030)
	var hand_ch_p := Vector3(0.036, 0.055, 0.256)
	var hand_ch_r := Vector3(-0.14, 0.16, 0.20)
	var round_vis := (not reload_was_empty) if t < 0.80 else true
	_pose_part("dust_cover", Vector3.ZERO, Vector3.ZERO if _m16_dust_open else Vector3(0.0, 0.0, 1.48), PIVOT_AR_DUST)
	_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, round_vis)

	if t < 0.22:
		var u := smoothstep(0.0, 0.22, t)
		reload_pos_off = base_cant_p * u
		reload_rot_off = base_cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("arm_left", hand_mag_p * u, hand_mag_r * u, PIVOT_AR_HAND)
	elif t < 0.66:
		if t >= 0.24 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_mag_out, 1.0)
		var u := smoothstep(0.24, 0.62, t)
		if t >= 0.58 and not (reload_flags & 32):
			reload_flags |= 32
			_spawn_dropped_mag(1)
		reload_pos_off = base_cant_p + Vector3(0.0, -0.022 * sin(u * PI), 0.012)
		reload_rot_off = base_cant_r + Vector3(0.06 * sin(u * PI), 0.0, -0.08 * sin(u * PI))
		var mp := EJECT_AR * (0.25 * u)
		_pose_part("mag", mp, Vector3(-0.22 * u, 0.0, 0.0), PIVOT_AR_MAG, u < 0.96)
		_pose_part("arm_left", hand_mag_p + mp, hand_mag_r.lerp(hand_drop_r, u), PIVOT_AR_HAND)
	elif t < 0.92:
		var u := smoothstep(0.66, 0.92, t)
		var dip := sin(u * PI)
		reload_pos_off = base_cant_p + Vector3(-0.008 * dip, -0.024 * dip, 0.012)
		reload_rot_off = base_cant_r + Vector3(-0.05 * dip, 0.03, 0.04)
		_pose_part("mag", EJECT_AR * 0.25, Vector3.ZERO, PIVOT_AR_MAG, false)
		var fetch_p := hand_pouch_p.lerp(hand_mag_p + EJECT_AR * 0.24, smoothstep(0.55, 1.0, u))
		_pose_part("arm_left", fetch_p + Vector3(-0.015 * dip, -0.028 * dip, 0.012 * dip), hand_drop_r, PIVOT_AR_HAND)
	elif t < 1.40:
		var mp := Vector3.ZERO
		var mrot := Vector3.ZERO
		var slap := 0.0
		if t < 1.12:
			var u_align := smoothstep(0.92, 1.12, t)
			mp = EJECT_AR * lerpf(0.24, 0.085, u_align)
			mrot = Vector3(lerpf(-0.22, -0.07, u_align), 0.0, 0.0)
			_pose_part("arm_left", hand_mag_p + mp, hand_drop_r.lerp(hand_mag_r, u_align), PIVOT_AR_HAND)
		else:
			var u_seat := smoothstep(1.12, 1.29, t)
			slap = sin(smoothstep(1.27, 1.40, t) * PI)
			mp = EJECT_AR * lerpf(0.085, 0.0, u_seat)
			mrot = Vector3(lerpf(-0.07, 0.0, u_seat), 0.0, 0.0)
			_pose_part("arm_left", hand_mag_p + mp + Vector3(0.0, 0.018 * slap, 0.0), hand_mag_r, PIVOT_AR_HAND)
		reload_pos_off = base_cant_p + Vector3(0.0, 0.026 * slap, -0.012 * slap)
		reload_rot_off = base_cant_r + Vector3(0.09 * slap, 0.0, 0.07 * slap)
		_pose_part("mag", mp, mrot, PIVOT_AR_MAG, true)
		if t >= 1.16 and not (reload_flags & 2):
			reload_flags |= 2
			_play_reload_sfx(_sfx_mag_in, 1.0)
		if t >= 1.27 and not (reload_flags & 4):
			reload_flags |= 4
			_commit_mag_ammo()
			trauma = minf(1.0, trauma + 0.09)
	elif reload_was_empty and t < 1.90:
		_m16_dust_open = true
		_pose_part("dust_cover", Vector3.ZERO)
		if t >= 1.48 and not (reload_flags & 8):
			reload_flags |= 8
			_play_reload_sfx(_sfx_bolt, 1.0)
		if t >= 1.64 and not (reload_flags & 16):
			reload_flags |= 16
			trauma = minf(1.0, trauma + 0.11)
		var u := smoothstep(1.40, 1.90, t)
		var reach := smoothstep(0.0, 0.24, u)
		var pull := sin(smoothstep(0.20, 0.78, u) * PI)
		var latch_u := sin(smoothstep(0.14, 0.72, u) * PI)
		var fa_tap := sin(smoothstep(0.72, 0.96, u) * PI)
		reload_pos_off = base_cant_p.lerp(Vector3(-0.02, 0.03, -0.02), u) + Vector3(-0.012 * pull, 0.012 * pull, 0.032 * pull)
		reload_rot_off = base_cant_r.lerp(Vector3(0.10, 0.18, -0.24), smoothstep(0.0, 0.35, u))
		var ch := pull * 0.068
		_pose_part("charge", Vector3(0.0, 0.0, ch))
		_pose_part("charge_latch", Vector3(0.0, 0.0, ch), Vector3(0.0, 0.26 * latch_u, 0.0), PIVOT_AR_LATCH)
		_pose_part("slide", Vector3(0.0, 0.0, ch))
		_pose_part("bolt_catch", Vector3.ZERO, Vector3(0.0, 0.0, 0.22 * pull), PIVOT_AR_CATCH)
		_pose_part("fwd_assist", AXIS_AR_ASSIST * (0.012 * fa_tap))
		var h_eff_start := hand_mag_p + (PIVOT_AR_HAND - Basis.from_euler(hand_mag_r) * PIVOT_AR_HAND)
		_pose_part("arm_left", h_eff_start.lerp(hand_ch_p, reach) + Vector3(0.0, 0.0, ch), hand_mag_r.lerp(hand_ch_r, reach))
	else:
		var start_s := 1.90 if reload_was_empty else 1.40
		var u := smoothstep(start_s, reload_dur, t)
		var prev_p := Vector3(-0.02, 0.03, -0.02) if reload_was_empty else base_cant_p
		var prev_r := Vector3(0.10, 0.18, -0.24) if reload_was_empty else base_cant_r
		reload_pos_off = prev_p.lerp(Vector3.ZERO, u)
		reload_rot_off = prev_r.lerp(Vector3.ZERO, u)
		_pose_part("charge", Vector3.ZERO)
		_pose_part("charge_latch", Vector3.ZERO)
		_pose_part("slide", Vector3.ZERO)
		_pose_part("bolt_catch", Vector3.ZERO)
		_pose_part("fwd_assist", Vector3.ZERO)
		_pose_part("mag", Vector3.ZERO)
		if reload_was_empty:
			_pose_part("arm_left", hand_ch_p.lerp(Vector3.ZERO, u), hand_ch_r.lerp(Vector3.ZERO, u))
		else:
			_pose_part("arm_left", hand_mag_p.lerp(Vector3.ZERO, u), hand_mag_r.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)

	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_pistol() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.032, 0.095, -0.068)
	var cant_r := Vector3(0.26, 0.36, 0.56)
	var hand_drop_p := Vector3(-0.115, -0.175, 0.065)
	var hand_drop_r := Vector3(-0.28, 0.22, 0.26)
	var hand_seat_p := Vector3(-0.018, -0.072, 0.036)
	var hand_seat_r := Vector3(-0.14, 0.10, 0.14)
	var snap_t := 1.0 - smoothstep(1.16, 1.24, t) if reload_was_empty else 0.0
	_pose_part("slide", Vector3(0.0, 0.0, (0.034 if t < 1.16 else 0.034 * snap_t) if reload_was_empty else 0.0))
	_pose_part("slidestop", Vector3.ZERO, Vector3(-0.22 * (1.0 if t < 1.12 else (1.0 - smoothstep(1.12, 1.20, t))) if reload_was_empty else 0.0, 0.0, 0.0), PIVOT_G17_SLIDESTOP)
	var bullet_vis := (not reload_was_empty) or t >= 0.76

	if t < 0.16:
		var u := smoothstep(0.0, 0.16, t)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, not reload_was_empty)
		_pose_part("arm_left", hand_drop_p * u, hand_drop_r * u)
	elif t < 0.46:
		if not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_mag_out, 1.18)
		var u := smoothstep(0.16, 0.44, t)
		if t >= 0.42 and reload_was_empty and not (reload_flags & 32):
			reload_flags |= 32
			_spawn_dropped_mag(0)
		reload_pos_off = cant_p + Vector3(0.0, -0.015 * sin(u * PI), 0.0)
		reload_rot_off = cant_r + Vector3(0.06 * sin(u * PI), 0.0, 0.0)
		var mp := EJECT_G17 * (0.22 * u)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, u < 0.90)
		_pose_part("mag_bullet", mp, Vector3.ZERO, Vector3.ZERO, (not reload_was_empty) and u < 0.90)
		_pose_part("arm_left", hand_drop_p + Vector3(-0.025 * u, -0.065 * u, 0.02 * u), hand_drop_r)
	elif t < 0.76:
		var u := smoothstep(0.46, 0.76, t)
		var dip := sin(u * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.028 * dip, 0.01)
		reload_rot_off = cant_r
		_pose_part("mag", EJECT_G17 * 0.22, Vector3.ZERO, Vector3.ZERO, false)
		_pose_part("mag_bullet", EJECT_G17 * 0.22, Vector3.ZERO, Vector3.ZERO, false)
		var fetch_p := (hand_drop_p + Vector3(-0.025, -0.065, 0.02)).lerp(hand_seat_p + EJECT_G17 * 0.20, u)
		_pose_part("arm_left", fetch_p, hand_drop_r.lerp(hand_seat_r, u))
	elif t < 1.02:
		var u := smoothstep(0.76, 0.96, t)
		var slap := sin(smoothstep(0.90, 1.02, t) * PI)
		reload_pos_off = cant_p + Vector3(0.0, 0.022 * slap, 0.0)
		reload_rot_off = cant_r + Vector3(0.08 * slap, 0.0, 0.0)
		var mp := EJECT_G17 * lerpf(0.20, 0.0, u)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, true)
		_pose_part("mag_bullet", mp, Vector3.ZERO, Vector3.ZERO, bullet_vis)
		_pose_part("arm_left", hand_seat_p + mp + Vector3(0.0, 0.016 * slap, 0.0), hand_seat_r)
		if t >= 0.84 and not (reload_flags & 2):
			reload_flags |= 2
			_play_reload_sfx(_sfx_mag_in, 1.16)
		if t >= 0.92 and not (reload_flags & 4):
			reload_flags |= 4
			_commit_mag_ammo()
			trauma = minf(1.0, trauma + 0.08)
	elif reload_was_empty and t < 1.40:
		if t >= 1.16 and not (reload_flags & 8):
			reload_flags |= 8
			_play_reload_sfx(_sfx_bolt, 1.24)
			trauma = minf(1.0, trauma + 0.09)
		var u := smoothstep(1.02, 1.40, t)
		var dip := sin(u * PI)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u) + Vector3(0.0, -0.014 * dip, 0.014 * dip)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u) + Vector3(-0.08 * dip, 0.0, -0.10 * dip)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO)
		_pose_part("arm_left", hand_seat_p.lerp(Vector3.ZERO, u), hand_seat_r.lerp(Vector3.ZERO, u))
	else:
		var start_s := 1.40 if reload_was_empty else 1.02
		var u := smoothstep(start_s, reload_dur, t)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO)
		var prev_hp := Vector3.ZERO if reload_was_empty else hand_seat_p
		var prev_hr := Vector3.ZERO if reload_was_empty else hand_seat_r
		_pose_part("arm_left", prev_hp.lerp(Vector3.ZERO, u), prev_hr.lerp(Vector3.ZERO, u))

	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_shotgun(delta: float) -> void:
	reload_shell_timer += delta
	var cant_p := Vector3(-0.026, 0.092, -0.048)
	var cant_r := Vector3(0.28, 0.22, -1.18)
	var hand_caddy_p := Vector3(-0.015, -0.155, 0.165)
	var hand_caddy_r := Vector3(0.22, 0.08, 0.22)
	var hand_port_p := Vector3(0.032, -0.058, 0.160)
	var hand_port_r := Vector3(0.14, 0.06, 0.16)
	var hand_push_p := Vector3(0.036, -0.026, 0.118)
	var hand_push_r := Vector3(0.06, 0.04, 0.08)

	if reload_shell_phase == 0:
		if is_instance_valid(_shotgun_shell_rig):
			_shotgun_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		if reload_cancel_req and ammo_in_mag[2] > 0:
			reload_shell_phase = 2
			reload_shell_timer = 0.0
			reload_flags = 0
			return
		var u := smoothstep(0.0, 0.26, reload_shell_timer)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("arm_left", hand_caddy_p * u, hand_caddy_r * u)
		if reload_shell_timer >= 0.26:
			reload_shell_phase = 1
			reload_shell_timer = 0.0
			reload_flags = 0
	elif reload_shell_phase == 1:
		var st := reload_shell_timer
		var u := smoothstep(0.0, 0.42, st)
		var push := sin(smoothstep(0.14, 0.34, st) * PI)
		reload_pos_off = cant_p + Vector3(0.0, 0.018 * push, -0.012 * push)
		reload_rot_off = cant_r + Vector3(-0.06 * push, 0.0, 0.08 * push)

		# Lifter opens inward (+Y) strictly while shell enters the 24mm loading port
		var lift_u := 0.0
		if st >= 0.14 and st < 0.34:
			lift_u = sin(smoothstep(0.14, 0.34, st) * PI)
		_pose_part("lifter", Vector3(0.0, 0.012 * lift_u, 0.0), Vector3(-0.16 * lift_u, 0.0, 0.0), PIVOT_M870_LIFTER)

		# Left hand & 12ga shell choreography: approach strictly below receiver belly (y < -0.046),
		# align under port, push cleanly through open lifter slot into mag tube, hide inside tube
		if st < 0.16:
			var a := smoothstep(0.0, 0.16, st)
			_pose_part("arm_left", hand_caddy_p.lerp(hand_port_p, a), hand_caddy_r.lerp(hand_port_r, a))
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = true
				_shotgun_shell_rig.position = SHELL_M870_START.lerp(PORT_M870, a)
				_shotgun_shell_rig.rotation = Vector3(0.42, 0.22, 0.18).lerp(Vector3(0.26, 0.0, 0.0), a)
		elif st < 0.25:
			var b := smoothstep(0.16, 0.25, st)
			_pose_part("arm_left", hand_port_p.lerp(hand_push_p, b * 0.55), hand_port_r.lerp(hand_push_r, b * 0.55))
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = true
				_shotgun_shell_rig.position = PORT_M870.lerp(SHELL_M870_ENTER, b)
				_shotgun_shell_rig.rotation = Vector3(lerpf(0.26, 0.10, b), 0.0, 0.0)
		elif st < 0.33:
			var c := smoothstep(0.25, 0.33, st)
			_pose_part("arm_left", hand_port_p.lerp(hand_push_p, lerpf(0.55, 1.0, c)), hand_port_r.lerp(hand_push_r, lerpf(0.55, 1.0, c)))
			if is_instance_valid(_shotgun_shell_rig):
				var vis := c < 0.90
				_shotgun_shell_rig.visible = vis
				_shotgun_shell_rig.position = SHELL_M870_ENTER.lerp(SHELL_M870_SEAT, c)
				_shotgun_shell_rig.rotation = Vector3(lerpf(0.10, 0.0, c), 0.0, 0.0)
		else:
			var d := smoothstep(0.33, 0.42, st)
			_pose_part("arm_left", hand_push_p.lerp(hand_caddy_p, d), hand_push_r.lerp(hand_caddy_r, d))
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = false

		if st >= 0.18 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_shell_in, randf_range(0.96, 1.04))
		if st >= 0.24 and not (reload_flags & 2):
			reload_flags |= 2
			if ammo_in_mag[2] < WEAPONS[2]["mag_size"] and ammo_reserve[2] > 0:
				ammo_in_mag[2] += 1
				ammo_reserve[2] -= 1
				trauma = minf(1.0, trauma + 0.05)
		if reload_cancel_req and ammo_in_mag[2] > 0 and ((st < 0.16 and not reload_was_empty) or st >= 0.24):
			reload_shell_phase = 2
			reload_shell_timer = 0.0
			reload_flags = 0
			_pose_part("lifter", Vector3.ZERO)
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = false
			return
		if st >= 0.42:
			reload_shell_timer = 0.0
			reload_flags = 0
			if reload_cancel_req or ammo_in_mag[2] >= WEAPONS[2]["mag_size"] or ammo_reserve[2] <= 0:
				reload_shell_phase = 2
	elif reload_shell_phase == 2:
		if is_instance_valid(_shotgun_shell_rig):
			_shotgun_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		var exit_dur := (0.22 if reload_cancel_req else 0.40) if reload_was_empty else (0.11 if reload_cancel_req else 0.26)
		var u := smoothstep(0.0, exit_dur, reload_shell_timer)
		var hand_ret := smoothstep(0.0, exit_dur * 0.45, reload_shell_timer)
		var arm_p := hand_caddy_p.lerp(Vector3.ZERO, hand_ret)
		var arm_r := hand_caddy_r.lerp(Vector3.ZERO, hand_ret)
		if reload_was_empty:
			var pull := sin(smoothstep(exit_dur * 0.20, exit_dur * 0.88, reload_shell_timer) * PI)
			var pz := pull * 0.072
			_pose_part("pump", Vector3(0, 0, pz))
			_pose_part("slide", Vector3(0, 0, pull * 0.060))
			_pose_part("charge", Vector3(0, 0, pull * 0.060))
			arm_p += Vector3(0, 0, pz)
			if reload_shell_timer >= exit_dur * 0.38 and not (reload_flags & 4):
				reload_flags |= 4
				_play_reload_sfx(_sfx_bolt, 0.84)
				trauma = minf(1.0, trauma + 0.12)
		_pose_part("arm_left", arm_p, arm_r)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u)
		if reload_shell_timer >= exit_dur:
			is_reloading = false
			reload_cancel_req = false
			_reset_weapon_parts()
			if _shotgun_fire_on_cancel:
				_shotgun_fire_on_cancel = false
				reload_pos_off = Vector3.ZERO
				reload_rot_off = Vector3.ZERO
				if ammo_in_mag[2] > 0 and fire_cd <= 0.0:
					fire_weapon()


func _align_bow_string_segment(seg: Node3D, p0: Vector3, p1: Vector3) -> void:
	if not is_instance_valid(seg):
		return
	var diff := p1 - p0
	var length := diff.length()
	if length < 0.001:
		return
	var y_axis := diff / length
	var ref := Vector3.RIGHT if absf(y_axis.x) < 0.9 else Vector3.FORWARD
	var z_axis := ref.cross(y_axis).normalized()
	var x_axis := y_axis.cross(z_axis).normalized()
	seg.position = (p0 + p1) * 0.5
	seg.basis = Basis(x_axis, y_axis, z_axis).scaled_local(Vector3(1.0, length, 1.0))


func _pose_bow_rig() -> void:
	if _bow_parts.is_empty():
		return
	var d := _bow_draw
	var limb_top: Node3D = _bow_parts.get("limb_top")
	var limb_bot: Node3D = _bow_parts.get("limb_bot")
	var str_top: Node3D = _bow_parts.get("str_top")
	var str_bot: Node3D = _bow_parts.get("str_bot")
	var arrow: Node3D = _bow_parts.get("arrow")
	if is_instance_valid(limb_top):
		limb_top.rotation.x = 0.18 * d
	if is_instance_valid(limb_bot):
		limb_bot.rotation.x = -0.18 * d
	var nock_pos := Vector3(-0.018, 0.030, -0.115 + 0.195 * d)
	var top_cam_p := limb_top.transform * Vector3(0.0, 0.220, 0.062) if is_instance_valid(limb_top) else Vector3(-0.028, 0.37, -0.118)
	var bot_cam_p := limb_bot.transform * Vector3(0.0, -0.220, 0.062) if is_instance_valid(limb_bot) else Vector3(-0.028, -0.37, -0.118)
	_align_bow_string_segment(str_top, top_cam_p, nock_pos)
	_align_bow_string_segment(str_bot, bot_cam_p, nock_pos)
	if is_instance_valid(arrow):
		var has_arrow := (ammo_in_mag[4] > 0) and (_bow_nock_timer <= 0.0)
		arrow.visible = has_arrow
		arrow.position = Vector3(-0.012, 0.030, -0.23 + 0.195 * d)


func _update_bow_input(delta: float) -> void:
	if _bow_nock_timer > 0.0:
		_bow_nock_timer = maxf(0.0, _bow_nock_timer - delta)
		if _bow_nock_timer <= 0.0 and ammo_in_mag[4] <= 0 and ammo_reserve[4] > 0:
			ammo_in_mag[4] = 1
			ammo_reserve[4] -= 1
	var holding := Input.is_action_pressed("fire")
	if holding and not _bow_drawing and ammo_in_mag[4] > 0 and _bow_nock_timer <= 0.0 and fire_cd <= 0.0:
		_bow_drawing = true
		_bow_draw = 0.0
		_bow_hold_time = 0.0
		if sfx_reload and _sfx_bow_draw:
			sfx_reload.stream = _sfx_bow_draw
			sfx_reload.pitch_scale = randf_range(0.95, 1.05)
			sfx_reload.play()
	elif _bow_drawing:
		if holding:
			_bow_draw = minf(1.0, _bow_draw + delta / 0.60)
			if _bow_draw >= 0.99:
				_bow_hold_time += delta
				sway_offset.x = clampf(sway_offset.x + sin(_bow_hold_time * 3.4) * delta * 0.022, -0.065, 0.065)
				sway_offset.y = clampf(sway_offset.y + cos(_bow_hold_time * 2.7) * delta * 0.018, -0.055, 0.055)
		else:
			var power := _bow_draw
			_bow_drawing = false
			_bow_draw = 0.0
			_bow_hold_time = 0.0
			if power >= 0.16:
				_fire_bow_arrow(power)


func _build_world_arrow_node() -> Node3D:
	var root := Node3D.new()
	var sh_m := CylinderMesh.new(); sh_m.top_radius = 0.004; sh_m.bottom_radius = 0.004; sh_m.height = 0.62
	var sh_mat := _make_vm_mat(Color(0.08, 0.09, 0.10), 0.36, 0.35, 0.45)
	sh_m.material = sh_mat
	var sh := MeshInstance3D.new(); sh.mesh = sh_m; sh.rotation.x = PI * 0.5; sh.position.z = 0.18
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sh)
	var bh_m := CylinderMesh.new(); bh_m.top_radius = 0.0006; bh_m.bottom_radius = 0.011; bh_m.height = 0.048; bh_m.radial_segments = 4
	bh_m.material = _make_vm_mat(Color(0.76, 0.78, 0.82), 0.22, 0.92, 0.75)
	var bh := MeshInstance3D.new(); bh.mesh = bh_m; bh.rotation.x = -PI * 0.5; bh.position.z = -0.14
	bh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bh)
	var fl_m := BoxMesh.new(); fl_m.size = Vector3(0.0025, 0.020, 0.078)
	fl_m.material = _make_vm_mat(Color(0.84, 0.12, 0.10), 0.50, 0.0, 0.25)
	for rz: float in [0.0, 2.09, -2.09]:
		var fl := MeshInstance3D.new(); fl.mesh = fl_m; fl.position = Vector3(0, 0.010, 0.44); fl.rotation.z = rz
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(fl)
	return root


func _fire_bow_arrow(power: float) -> void:
	ammo_in_mag[4] = maxi(0, ammo_in_mag[4] - 1)
	_bow_nock_timer = 0.38
	fire_cd = 0.36
	recoil_vel.y += 0.024 * power
	recoil_z += 0.022 * power
	trauma = minf(1.0, trauma + 0.07 * power)
	if sfx_gun and _sfx_bow_release:
		sfx_gun.stream = _sfx_bow_release
		sfx_gun.pitch_scale = lerpf(0.88, 1.06, power)
		sfx_gun.play()

	if _arrows.size() >= 24:
		var old: Dictionary = _arrows.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()

	var arrow_node := _build_world_arrow_node()
	_fx_parent().add_child(arrow_node)
	var fwd := -camera.global_transform.basis.z
	var start_pos := camera.global_position + fwd * 0.48 + camera.global_transform.basis.x * 0.04 - camera.global_transform.basis.y * 0.03
	var speed := lerpf(22.0, 56.0, power)
	var vel := fwd * speed
	arrow_node.global_position = start_pos
	arrow_node.look_at(start_pos + fwd, Vector3.UP)
	_arrows.append({
		"node": arrow_node,
		"vel": vel,
		"dmg": lerpf(48.0, 165.0, power),
		"stuck": false,
		"stuck_zombie": null,
		"stuck_local_pos": Vector3.ZERO,
		"stuck_local_rot": Basis.IDENTITY,
		"age": 0.0,
	})


func _update_arrows(delta: float) -> void:
	if _arrows.is_empty():
		return
	var space := get_world_3d().direct_space_state
	var i := _arrows.size() - 1
	while i >= 0:
		var a: Dictionary = _arrows[i]
		a["age"] = float(a["age"]) + delta
		var node: Node3D = a["node"]
		if not is_instance_valid(node) or float(a["age"]) > 35.0:
			if is_instance_valid(node):
				node.queue_free()
			_arrows.remove_at(i)
			i -= 1
			continue
		if bool(a["stuck"]):
			var sz: ZombieAI = a["stuck_zombie"]
			if sz != null:
				if is_instance_valid(sz):
					node.global_position = sz.global_transform * (a["stuck_local_pos"] as Vector3)
					node.global_transform.basis = sz.global_transform.basis * (a["stuck_local_rot"] as Basis)
				else:
					node.queue_free()
					_arrows.remove_at(i)
					i -= 1
					continue
			# Walk-over arrow retrieval!
			if float(a["age"]) > 0.65 and node.global_position.distance_to(global_position + Vector3(0, 0.9, 0)) < 1.85:
				if ammo_in_mag[4] <= 0:
					ammo_in_mag[4] = 1
				else:
					ammo_reserve[4] = mini(WEAPONS[4]["reserve_max"], ammo_reserve[4] + 1)
				if sfx_misc and _sfx_shell_in:
					sfx_misc.stream = _sfx_shell_in
					sfx_misc.pitch_scale = 1.35
					sfx_misc.play()
				node.queue_free()
				_arrows.remove_at(i)
			i -= 1
			continue

		var prev_pos := node.global_position
		var vel: Vector3 = a["vel"]
		vel.y -= 9.8 * delta
		var next_pos := prev_pos + vel * delta
		var step_v := next_pos - prev_pos
		var step_len := step_v.length()
		var dir := step_v / maxf(step_len, 1e-5)

		var max_d := step_len
		var wall_hit := {}
		if space:
			var wq := PhysicsRayQueryParameters3D.create(prev_pos, next_pos, 1)
			wq.exclude = [get_rid()]
			wall_hit = space.intersect_ray(wq)
			if not wall_hit.is_empty():
				max_d = prev_pos.distance_to(wall_hit["position"])

		var z_hit := ZombieAI.raycast_all_zombies(prev_pos, dir, max_d)
		if not z_hit.is_empty():
			var z := z_hit["zombie"] as ZombieAI
			if is_instance_valid(z):
				var hpos: Vector3 = z_hit["pos"]
				var res := z.apply_shot([{"zone": str(z_hit["zone"]), "pos": hpos, "dir": dir, "dmg": float(a["dmg"]), "dist": float(z_hit["dist"])}], 4)
				var is_hs := bool(res.get("headshot", false))
				var killed := bool(res.get("killed", false))
				if not bool(res.get("corpse_hit", false)):
					emit_signal("hit_confirmed", is_hs, killed)
					if sfx_hit_tick and _sfx_hit_confirm:
						sfx_hit_tick.stream = _sfx_hit_confirm
						sfx_hit_tick.pitch_scale = 1.18 if is_hs else 0.96
						sfx_hit_tick.play()
				if sfx_hit and _sfx_arrow_impact:
					sfx_hit.stream = _sfx_arrow_impact
					sfx_hit.pitch_scale = randf_range(0.92, 1.08)
					sfx_hit.play()
				node.global_position = hpos - dir * 0.04
				node.look_at(node.global_position + dir, Vector3.UP)
				a["stuck"] = true
				a["stuck_zombie"] = z
				a["stuck_local_pos"] = z.global_transform.affine_inverse() * node.global_position
				a["stuck_local_rot"] = z.global_transform.basis.inverse() * node.global_transform.basis
				i -= 1
				continue

		if not wall_hit.is_empty():
			node.global_position = (wall_hit["position"] as Vector3) - dir * 0.04
			node.look_at(node.global_position + dir, Vector3.UP)
			a["stuck"] = true
			if VFXManager.instance:
				VFXManager.instance.spawn_surface_impact(wall_hit["position"], wall_hit["normal"], dir, wall_hit["collider"], 4)
			if sfx_misc and _sfx_arrow_impact:
				sfx_misc.stream = _sfx_arrow_impact
				sfx_misc.pitch_scale = randf_range(0.86, 1.04)
				sfx_misc.play()
			i -= 1
			continue

		a["vel"] = vel
		node.global_position = next_pos
		if step_len > 0.001:
			node.look_at(next_pos + dir, Vector3.UP)
		i -= 1


func toggle_flashlight() -> void:
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	flashlight_spill.visible = false
	flashlight_cone.visible = _should_show_flashlight_cone()
	if flashlight_bounce and not flashlight_on:
		flashlight_bounce.visible = false
		flashlight_bounce.light_energy = 0.0
	if sfx_misc:
		if _sfx_flashlight_click == null:
			_sfx_flashlight_click = load("res://assets/audio/flashlight_click.wav")
		sfx_misc.stream = _sfx_flashlight_click
		sfx_misc.play()


func _eject_brass_casing(w: Dictionary, is_hull := false) -> void:
	if _casings.size() >= 18:
		var old: Dictionary = _casings.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = _hull_mesh if is_hull else _casing_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	var spawn_p := weapon_pivot.to_global(w["ejection"])
	mi.global_position = spawn_p
	mi.global_rotation = weapon_pivot.global_rotation + Vector3(PI * 0.5, 0, 0)
	var right := weapon_pivot.global_transform.basis.x
	var up := weapon_pivot.global_transform.basis.y
	var back := weapon_pivot.global_transform.basis.z
	var ej_vel := right * randf_range(2.0, 3.2) + up * randf_range(1.6, 2.5) + back * randf_range(0.35, 1.0)
	var floor_y := global_position.y + 0.012
	var space := get_world_3d().direct_space_state
	if space:
		var land_xz := spawn_p + Vector3(ej_vel.x, 0.0, ej_vel.z) * 0.25
		var fq := PhysicsRayQueryParameters3D.create(Vector3(land_xz.x, spawn_p.y + 0.2, land_xz.z), Vector3(land_xz.x, spawn_p.y - 4.0, land_xz.z), 1)
		var fhit := space.intersect_ray(fq)
		if fhit:
			floor_y = float(fhit["position"].y) + (0.012 if is_hull else 0.008)
	_casings.append({
		"node": mi,
		"vel": ej_vel,
		"ang": Vector3(randf_range(14, 28), randf_range(12, 26), randf_range(-20, 20)),
		"age": 0.0,
		"bounced": false,
		"floor_y": floor_y,
		"is_hull": is_hull,
	})


func trigger_melee() -> bool:
	if _melee_timer > 0.08 or dead:
		return false
	if is_reloading:
		is_reloading = false
		reload_cancel_req = false
		_shotgun_fire_on_cancel = false
		reload_pos_off = Vector3.ZERO
		reload_rot_off = Vector3.ZERO
		_reset_weapon_parts()
	var m: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
	_melee_dur = float(m["dur"]) if current_weapon == 3 else minf(0.42, float(m["dur"]))
	_melee_timer = _melee_dur
	_melee_hit_done = false
	fire_cd = maxf(fire_cd, _melee_dur * 0.85)
	recoil_roll += -0.055
	trauma = minf(1.0, trauma + 0.08)
	if sfx_misc and _sfx_melee_swing:
		sfx_misc.stream = _sfx_melee_swing
		sfx_misc.pitch_scale = randf_range(0.92, 1.08)
		sfx_misc.play()
	return true


func _perform_melee_hit() -> void:
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var m: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
	var reach: float = float(m["reach"])
	var dmg: float = float(m["damage"])
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var z_hits := {}

	for ang_deg: float in [0.0, -7.0, 7.0, -14.0, 14.0]:
		var rad := deg_to_rad(ang_deg)
		var dir := (fwd * cos(rad) + right * sin(rad)).normalized()
		var wq := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, 1)
		wq.exclude = [get_rid()]
		var wh := space.intersect_ray(wq)
		var max_d := origin.distance_to(wh["position"]) if not wh.is_empty() else reach
		var zh := ZombieAI.raycast_all_zombies(origin, dir, max_d)
		if not zh.is_empty():
			var z := zh["zombie"] as ZombieAI
			if is_instance_valid(z) and not z_hits.has(z):
				z_hits[z] = [{
					"zone": str(zh["zone"]),
					"pos": zh["pos"],
					"dir": dir,
					"dmg": dmg,
					"dist": float(zh["dist"]),
				}]

	if z_hits.is_empty():
		return

	var any_live := false
	var any_live_hs := false
	for z_key in z_hits.keys():
		var z := z_key as ZombieAI
		var res := z.apply_shot(z_hits[z_key], 2)
		var is_hs := bool(res.get("headshot", false))
		var killed := bool(res.get("killed", false))
		if not bool(res.get("corpse_hit", false)):
			any_live = true
			any_live_hs = any_live_hs or is_hs
			emit_signal("hit_confirmed", is_hs, killed)
			# Extra melee shove so quick-melee reliably creates breathing room!
			if not z.dead:
				z.velocity += fwd * 4.2

	trauma = minf(1.0, trauma + 0.14)
	if sfx_hit and _sfx_melee_cleave:
		sfx_hit.stream = _sfx_melee_cleave
		sfx_hit.pitch_scale = randf_range(0.90, 1.08)
		sfx_hit.play()
	if any_live and sfx_hit_tick and _sfx_hit_confirm:
		sfx_hit_tick.stream = _sfx_hit_confirm
		sfx_hit_tick.pitch_scale = 1.18 if any_live_hs else 0.96
		sfx_hit_tick.play()


func fire_weapon() -> bool:
	var w: Dictionary = WEAPONS[current_weapon]
	if ammo_in_mag[current_weapon] <= 0:
		start_reload()
		return false
	ammo_in_mag[current_weapon] -= 1
	fire_cd = w["fire_rate"]

	# Smooth exponential muzzle flash pulse (clamped inside close corridors, no volumetric fog flood!)
	muzzle_elapsed = 0.0
	muzzle_peak_e = 2.8 * float(w["flash_scale"]) * randf_range(0.88, 1.15)
	muzzle_light.visible = true
	muzzle_light.light_energy = muzzle_peak_e
	muzzle_vm_light.visible = true
	muzzle_vm_light.light_energy = minf(muzzle_peak_e * 0.38, 1.25)
	_flash_shadow_boost = 1.0
	_barrel_heat_timer = 1.4
	_barrel_heat_step = 0.22

	var m_dist: float = absf((w["muzzle"] as Vector3).z)
	var space := get_world_3d().direct_space_state
	if space:
		var wq := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * (m_dist + 0.25), 1)
		var whit := space.intersect_ray(wq)
		if whit:
			var safe_d := maxf(0.18, camera.global_position.distance_to(whit["position"]) - 0.16)
			muzzle_light.position = Vector3(0.0, 0.03, -safe_d)
		else:
			muzzle_light.position = w["muzzle"]
		muzzle_vm_light.position = muzzle_light.position

	muzzle_flash_timer = 0.036
	muzzle_flash_rig.visible = true
	muzzle_flash_rig.rotation.z = randf() * TAU
	var fscale: float = float(w["flash_scale"]) * randf_range(0.86, 1.18)
	muzzle_flash_rig.scale = Vector3.ONE * fscale
	var seed_v := randf() * 100.0
	for fm in _flash_mats:
		fm.set_shader_parameter("flash_seed", seed_v)
		fm.set_shader_parameter("cool_t", 0.0)

	if VFXManager.instance:
		VFXManager.instance.spawn_muzzle_sparks(muzzle_flash_rig.global_position, -camera.global_transform.basis.z, current_weapon == 2)

	if muzzle_smoke:
		if OS.has_feature("web"):
			muzzle_smoke.restart()
			muzzle_smoke.emitting = true
		else:
			var smoke_xf := muzzle_smoke.global_transform.translated_local(Vector3(0.0, 0.02, -0.08))
			for _s in range(2):
				var sv := -camera.global_transform.basis.z * randf_range(0.25, 0.58) + camera.global_transform.basis.x * randf_range(0.08, 0.26) + Vector3(0.0, randf_range(0.36, 0.72), 0.0)
				muzzle_smoke.emit_particle(smoke_xf, sv, Color.WHITE, Color.WHITE, GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)

	if current_weapon != 2 and current_weapon != 6 and current_weapon != 7:
		_eject_brass_casing(w, false)
	bolt_blowback = 1.0
	if current_weapon == 1:
		_m16_dust_open = true
	if current_weapon == 2:
		shotgun_pump_timer = 0.42
		shotgun_pump_did_sfx = false
	if current_weapon == 6:
		_revolver_cyl_angle += TAU / 6.0
		_revolver_hammer = 1.0
	if current_weapon == 7:
		_hunting_bolt_timer = 0.78
		_hunting_bolt_did_sfx = false

	recoil_vel.y += w["recoil_pitch"] * (0.65 if is_ads else 1.0)
	recoil_z += w["recoil_kick"]
	recoil_roll += randf_range(-0.018, 0.018) * (0.5 if is_ads else 1.0)
	recoil_fov = 1.15
	trauma = minf(1.0, trauma + (0.28 if current_weapon == 2 else (0.14 if current_weapon == 1 else 0.11)))
	pitch = clamp(pitch + w["recoil_pitch"] * 0.32, -1.35, 1.35)

	if sfx_gun:
		if current_weapon < _weapon_audio_vars.size():
			var vars_arr: Array = _weapon_audio_vars[current_weapon]
			if not vars_arr.is_empty():
				_gun_alt_flip = (_gun_alt_flip + 1) % vars_arr.size()
				sfx_gun.stream = vars_arr[_gun_alt_flip]
		if sfx_gun.stream:
			sfx_gun.pitch_scale = randf_range(0.95, 1.04)
			sfx_gun.play()

	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var spread_mult := (0.55 if is_ads else 1.0) if current_weapon == 2 else (0.14 if is_ads else 0.72)
	var spread: float = w["spread"] * spread_mult
	var impact_fx_budget := 3 if int(w["pellets"]) > 1 else 1
	var z_hits := {}

	for _p in range(w["pellets"]):
		var dir := (fwd + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
		# Step 1: World wall raycast to find exact solid occlusion distance (pass through window barricades!)
		var wall_excl: Array[RID] = [get_rid()]
		var wall_hit := {}
		for _retry in range(3):
			var wq_hit := PhysicsRayQueryParameters3D.create(origin, origin + dir * 75.0, 1)
			wq_hit.collide_with_areas = false
			wq_hit.collide_with_bodies = true
			wq_hit.exclude = wall_excl
			wall_hit = space.intersect_ray(wq_hit)
			if wall_hit.is_empty():
				break
			var wc = wall_hit["collider"]
			if wc is InteractableObject and (wc as InteractableObject).kind == InteractableObject.Kind.BARRICADE:
				wall_excl.append((wc as CollisionObject3D).get_rid())
				wall_hit = {}
				continue
			break
		var max_dist := origin.distance_to(wall_hit["position"]) if not wall_hit.is_empty() else 75.0

		# Step 2: Exact analytical bone-capsule raycast against all live, dying, AND dead zombies (zero physics lag!)
		var z_hit := ZombieAI.raycast_all_zombies(origin, dir, max_dist)
		if not z_hit.is_empty():
			var z := z_hit["zombie"] as ZombieAI
			if is_instance_valid(z):
				var hz := str(z_hit["zone"])
				var hpos: Vector3 = z_hit["pos"]
				if not z_hits.has(z):
					z_hits[z] = []
				(z_hits[z] as Array).append({
					"zone": hz,
					"pos": hpos,
					"dir": dir,
					"dmg": w["damage"],
					"dist": float(z_hit["dist"]),
				})
				continue

		if not wall_hit.is_empty():
			if impact_fx_budget > 0:
				impact_fx_budget -= 1
				if VFXManager.instance:
					VFXManager.instance.spawn_surface_impact(wall_hit["position"], wall_hit["normal"], dir, wall_hit["collider"], current_weapon)

	var any_zombie_hit := false
	var any_live_hit := false
	var any_live_headshot := false
	var any_gore_crunch := false
	for z_key in z_hits.keys():
		var z := z_key as ZombieAI
		var arr: Array = z_hits[z_key]
		var res := z.apply_shot(arr, current_weapon)
		var is_hs := bool(res.get("headshot", false))
		var killed := bool(res.get("killed", false))
		var corpse_hit := bool(res.get("corpse_hit", false))
		var did_dismember := bool(res.get("dismembered", false))
		any_zombie_hit = true
		any_gore_crunch = any_gore_crunch or is_hs or did_dismember
		if not corpse_hit:
			any_live_hit = true
			any_live_headshot = any_live_headshot or is_hs
			emit_signal("hit_confirmed", is_hs, killed)

	if any_zombie_hit:
		if sfx_hit:
			var pool := _sfx_hit_head if any_gore_crunch else _sfx_hit_flesh
			if not pool.is_empty():
				sfx_hit.stream = pool[randi() % pool.size()]
				sfx_hit.pitch_scale = randf_range(0.92, 1.08)
				sfx_hit.play()
		if any_live_hit and sfx_hit_tick and _sfx_hit_confirm:
			sfx_hit_tick.stream = _sfx_hit_confirm
			sfx_hit_tick.pitch_scale = 1.18 if any_live_headshot else 0.96
			sfx_hit_tick.play()
	return true


func get_looked_interactable() -> InteractableObject:
	if interact_ray and interact_ray.is_colliding():
		var c = interact_ray.get_collider()
		if c is InteractableObject:
			return c
	return null


func try_interact() -> String:
	var obj := get_looked_interactable()
	if obj:
		var msg := obj.interact(game_manager, self)
		if msg != "":
			emit_signal("status_message", msg)
		return msg
	return ""


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if dead or damage_invuln > 0.0:
		return
	damage_invuln = 0.35
	health = max(0.0, health - amount)
	damage_flash = min(1.0, damage_flash + 0.72)
	ads_lockout = 0.22
	trauma = minf(1.0, trauma + 0.52)
	hit_glitch = 0.34
	hit_ca_boost = 0.018

	var kick_side := 1.0
	if from_pos != Vector3.ZERO:
		var local_src := camera.global_transform.basis.inverse() * (from_pos - camera.global_position).normalized()
		hit_dir_screen = Vector2(clampf(local_src.x, -1.0, 1.0), clampf(-local_src.y, -1.0, 1.0))
		kick_side = -signf(local_src.x) if absf(local_src.x) > 0.08 else (1.0 if randf() < 0.5 else -1.0)
	else:
		hit_dir_screen = Vector2(0.0, 0.2)
		kick_side = 1.0 if randf() < 0.5 else -1.0

	hit_roll_kick += kick_side * 0.12
	hit_pitch_kick += randf_range(0.05, 0.09)

	if sfx_slash and not _sfx_player_slash.is_empty():
		sfx_slash.stream = _sfx_player_slash[randi() % _sfx_player_slash.size()]
		sfx_slash.pitch_scale = randf_range(0.92, 1.08)
		sfx_slash.play()
	if sfx_hurt and _sfx_player_hurt:
		sfx_hurt.stream = _sfx_player_hurt
		sfx_hurt.pitch_scale = randf_range(0.94, 1.06)
		sfx_hurt.play()

	if health <= 0.0:
		dead = true
		emit_signal("player_died")


func heal_full() -> void:
	health = max_health
	dead = false
	damage_flash = 0.0
	damage_invuln = 0.0
	hit_glitch = 0.0
	hit_ca_boost = 0.0
	head.rotation.z = 0.0
	for i in range(WEAPONS.size()):
		ammo_in_mag[i] = WEAPONS[i]["mag_size"]
		ammo_reserve[i] = WEAPONS[i]["reserve_max"]
