extends CharacterBody3D
class_name ZombieAI

enum Variant { TACTICAL_SOLDIER, ASYLUM_PATIENT, RUNNER, BRUISER, EXPLODER, SPITTER, SCREAMER }
enum State { SPAWNING, CHASE, WINDUP, STRIKE, RECOVER, STAGGER, TRIPPED, DEAD, KNOCKDOWN, GRAB, SPECIAL, CHARGE, LEAP }

@export var variant: Variant = Variant.TACTICAL_SOLDIER
@export var max_health: float = 110.0
@export var move_speed: float = 2.25
@export var attack_damage: float = 22.0

var health: float = 110.0
var dead: bool = false
var state: State = State.CHASE
var target: Node3D = null
var anim_phase: float = 0.0
var attack_cd: float = 0.0
var state_timer: float = 0.0
var growl_timer: float = 3.0
var pain_sfx_cd: float = 0.0
var deterministic_pose: bool = false

# Poise & locational damage state
var poise: float = 0.0
var poise_max: float = 60.0
var poise_immunity: float = 0.0
var head_dmg: float = 0.0
var l_arm_dmg: float = 0.0
var r_arm_dmg: float = 0.0
var left_leg_dmg: float = 0.0
var right_leg_dmg: float = 0.0
var dismembered: Dictionary = {} # zone -> true ("HEAD", "ARM_L", "ARM_R", "LEG_L", "LEG_R")
var _frozen_rest_rot: Dictionary = {} # bone_idx -> Quaternion
var crippled_side: int = 0 # -1 left, +1 right, 0 none
var is_crawler: bool = false
var disabled_arm_side: int = 0 # -1 left, +1 right
var disabled_arm_timer: float = 0.0
var burn_timer: float = 0.0
var burn_dps: float = 26.0
var _burn_tick: float = 0.0
var shock_timer: float = 0.0
var _shock_tick: float = 0.0
var bleed_timer: float = 0.0
var bleed_dps: float = 20.0
var _bleed_tick: float = 0.0
var _status_light: OmniLight3D = null
var _burn_fx_root: Node3D = null
var _burn_attachments: Array[Node3D] = []
var _burn_flame_mats: Array[ShaderMaterial] = []
var _burn_flame_nodes: Array[MeshInstance3D] = []
var _burn_smoke_entries: Array[Dictionary] = []
var _burn_char: float = 0.0
var _burn_char_mats: Array[ShaderMaterial] = []
var _burn_char_inited: bool = false
var _burn_panic_cd: float = 0.0
var _burn_heat_level: float = 0.0
var _corpse_smolder_timer: float = 0.0
static var _burn_fire_shader: Shader = null
static var _burn_fire_tex: Texture2D = null
static var _burn_smoke_tex: Texture2D = null


func _ensure_burn_fx() -> void:
	if not _burn_attachments.is_empty():
		return
	if _burn_fire_shader == null and ResourceLoader.exists("res://shaders/realistic_fire.gdshader"):
		_burn_fire_shader = load("res://shaders/realistic_fire.gdshader") as Shader
	if _burn_fire_tex == null and ResourceLoader.exists("res://assets/textures/fire_plume_sheet.png"):
		_burn_fire_tex = load("res://assets/textures/fire_plume_sheet.png") as Texture2D
	if _burn_smoke_tex == null and ResourceLoader.exists("res://assets/textures/gunsmoke_wisp.png"):
		_burn_smoke_tex = load("res://assets/textures/gunsmoke_wisp.png") as Texture2D
	if _burn_fire_shader == null:
		return

	# Anchor photoreal 4x4 flipbook flames directly to skeleton bones so fire moves 1:1 with torso, head, arms & ragdoll!
	var slots: Array[Dictionary] = [
		{"bone": spine2_bone, "pos": Vector3(0.0, 0.06, 0.14), "size": Vector2(0.58, 0.86), "fps": 18.0, "flip": 1.0},
		{"bone": spine2_bone, "pos": Vector3(0.02, 0.10, -0.14), "size": Vector2(0.54, 0.82), "fps": 16.0, "flip": -1.0},
		{"bone": head_bone, "pos": Vector3(0.0, 0.14, 0.04), "size": Vector2(0.44, 0.68), "fps": 21.0, "flip": 1.0},
		{"bone": l_arm_bone, "pos": Vector3(0.0, 0.08, 0.04), "size": Vector2(0.40, 0.62), "fps": 19.5, "flip": -1.0},
		{"bone": r_arm_bone, "pos": Vector3(0.0, 0.08, 0.04), "size": Vector2(0.40, 0.62), "fps": 20.5, "flip": 1.0},
	]
	if OS.has_feature("web"):
		slots = [slots[0], slots[2], slots[3]]

	for si in range(slots.size()):
		var cfg: Dictionary = slots[si]
		var b_idx: int = int(cfg["bone"])
		var holder: Node3D = null
		if skeleton != null and b_idx >= 0 and b_idx < skeleton.get_bone_count():
			var ba := BoneAttachment3D.new()
			ba.name = "BurnBoneFX_%d" % si
			ba.bone_idx = b_idx
			ba.visible = false
			skeleton.add_child(ba)
			holder = ba
		else:
			if _burn_fx_root == null or not is_instance_valid(_burn_fx_root):
				_burn_fx_root = Node3D.new()
				_burn_fx_root.name = "BurnFireFX"
				_burn_fx_root.visible = false
				add_child(_burn_fx_root)
			holder = _burn_fx_root
		var sm := ShaderMaterial.new()
		sm.shader = _burn_fire_shader
		if _burn_fire_tex:
			sm.set_shader_parameter("fire_tex", _burn_fire_tex)
			sm.set_shader_parameter("has_fire_tex", 1.0)
		sm.set_shader_parameter("atlas_fps", float(cfg["fps"]))
		sm.set_shader_parameter("flip_x", float(cfg["flip"]))
		sm.set_shader_parameter("flame_speed", 3.2 + float(si) * 0.42)
		sm.set_shader_parameter("phase_seed", float(si) * 3.17 + randf() * 6.0)
		sm.set_shader_parameter("intensity", 1.38)
		sm.set_shader_parameter("smoke_mix", 0.58)
		sm.set_shader_parameter("fade_alpha", 1.0)
		sm.set_shader_parameter("billboard_y", 1.0)
		sm.set_shader_parameter("jet_mode", 0.0)
		var qm := QuadMesh.new()
		qm.size = cfg["size"] as Vector2
		qm.material = sm
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		mi.position = (cfg["pos"] as Vector3) if holder is BoneAttachment3D else Vector3(0.0, 1.32, 0.16)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		if not _burn_attachments.has(holder):
			_burn_attachments.append(holder)
		_burn_flame_mats.append(sm)
		_burn_flame_nodes.append(mi)

	# Rising dark oily smoke wisps anchored to upper spine so burning zombies trail black soot
	if _burn_smoke_tex != null and not _burn_attachments.is_empty():
		var smoke_host: Node3D = _burn_attachments[0]
		var sm_cnt := 1 if OS.has_feature("web") else 2
		for ki in range(sm_cnt):
			var smat := StandardMaterial3D.new()
			smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			smat.albedo_texture = _burn_smoke_tex
			smat.albedo_color = Color(0.04, 0.036, 0.034, 0.44)
			var sqm := QuadMesh.new()
			sqm.size = Vector2(0.72, 0.72)
			sqm.material = smat
			var smi := MeshInstance3D.new()
			smi.mesh = sqm
			smi.position = Vector3(0.0, 0.45 + float(ki) * 0.35, 0.0)
			smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			smoke_host.add_child(smi)
			_burn_smoke_entries.append({
				"node": smi,
				"mat": smat,
				"phase": float(ki) / float(sm_cnt),
				"speed": randf_range(0.65, 0.95),
			})


func _set_burn_fx_visible(vis: bool) -> void:
	for h in _burn_attachments:
		if is_instance_valid(h):
			h.visible = vis
	if _burn_fx_root and is_instance_valid(_burn_fx_root):
		_burn_fx_root.visible = vis


func _update_burn_fx_visuals(delta: float, strength: float) -> void:
	var s := clampf(strength, 0.0, 1.45)
	for fi in range(_burn_flame_mats.size()):
		var sm := _burn_flame_mats[fi]
		if sm:
			sm.set_shader_parameter("intensity", lerpf(0.55, 1.52, clampf(s, 0.0, 1.25)))
			sm.set_shader_parameter("fade_alpha", clampf(s * 1.15, 0.0, 1.0))
			sm.set_shader_parameter("smoke_mix", lerpf(0.85, 0.48, clampf(s, 0.0, 1.0)))
	for fn in _burn_flame_nodes:
		if is_instance_valid(fn):
			var sc := lerpf(0.45, 1.18, clampf(s, 0.0, 1.25))
			fn.scale = Vector3(lerpf(0.70, 1.08, clampf(s, 0.0, 1.2)), sc, 1.0)
	for se: Dictionary in _burn_smoke_entries:
		var snode := se.get("node") as MeshInstance3D
		var smat := se.get("mat") as StandardMaterial3D
		if is_instance_valid(snode) and smat:
			se["phase"] = fmod(float(se["phase"]) + delta * float(se["speed"]), 1.0)
			var cyc: float = float(se["phase"])
			snode.position = Vector3(sin(cyc * TAU) * 0.14, 0.34 + cyc * 1.15, cos(cyc * TAU) * 0.12)
			var sc_s := lerpf(0.55, 1.45, cyc)
			snode.scale = Vector3(sc_s, sc_s, 1.0)
			smat.albedo_color.a = sin(cyc * PI) * 0.44 * clampf(s * 1.25, 0.0, 1.0)


func _apply_burn_char(target_char: float) -> void:
	_burn_char = clampf(maxf(_burn_char, target_char), 0.0, 1.0)
	if not _burn_char_inited:
		_burn_char_inited = true
		_burn_char_mats.clear()
		for bmi in _body_meshes:
			if not is_instance_valid(bmi) or bmi.mesh == null:
				continue
			for s in range(bmi.mesh.get_surface_count()):
				var mat := bmi.get_active_material(s)
				if mat is ShaderMaterial:
					var dup := (mat as ShaderMaterial).duplicate() as ShaderMaterial
					bmi.set_surface_override_material(s, dup)
					_burn_char_mats.append(dup)
	for cm in _burn_char_mats:
		if cm:
			cm.set_shader_parameter("burn_char", _burn_char)
var _body_col: CollisionShape3D = null
var _exploder_light: OmniLight3D = null
var _exploder_sac: Node3D = null
var _exploder_attach: BoneAttachment3D = null
var _exploder_detonated: bool = false
var _knockback_vel: Vector3 = Vector3.ZERO

# Attack variety, reactions and per-variant identity
var kill_points: int = 100
var attack_kind: String = "swipe" # "swipe" or "grab"
var _special: String = "" # "slam", "charge", "leap", "spit", "scream_wind", "scream"
var _special_dur: float = 0.0
var _special_cd: float = 0.0
var _slam_cd: float = 0.0
var _combo_left: int = 0
var _react_local: Vector3 = Vector3.ZERO # last hit direction in the zombie's own space (drives directional staggers)
var _knock_t: float = 0.0
var _knock_lay: float = 0.0 # 0 upright .. 1 flat on the floor
var _knock_dur_down: float = 0.9
var _knock_face_down: bool = false
var _grab_bite_t: float = 0.0
var _grab_time: float = 0.0
var _enrage_timer: float = 0.0
var _helmet_hp: float = 0.0
var _armor_broken: bool = false
var _kit_attachments: Array[BoneAttachment3D] = []
var _kit_parts: Dictionary = {} # "<BoneKey>__<Part>" -> MeshInstance3D
var _strafe_sign: float = 1.0
var _strafe_flip: float = 2.0
var _los_timer: float = 0.0
var _los_ok: bool = false
var _nav_path: PackedVector3Array = PackedVector3Array()
var _nav_idx: int = 0
var _nav_timer: float = 0.0
var _nav_goal: Vector3 = Vector3.ZERO
static var nav_map: RID = RID()
static var nav_enabled: bool = false

# Melee telegraph state
var attack_side: int = 1 # -1 left arm, +1 right arm
var strike_hit_done: bool = false
var strike_dir: Vector3 = Vector3.FORWARD
var has_attack_token: bool = false
var _windup_dur: float = 0.48
var _strike_dur: float = 0.15
var _recover_dur: float = 0.58
var _trigger_range: float = 1.90
var _lunge_speed: float = 4.2
var _chest_armor_mult: float = 1.0
var _impulse_scale: float = 1.0
var _model_scale_val: float = 1.0
var _is_tactical: bool = false

# Staggered navigation & stuck-recovery state
var _nav_ray_tick: int = 0
var _cached_steer_dir: Vector3 = Vector3.FORWARD
var _stuck_timer: float = 0.0
var _stuck_anchor: Vector3 = Vector3.ZERO
var _barricade_cd: float = 0.0
var _runner_telegraphed: bool = false

# Ragdoll & corpse settlement state
var death_floor_y: float = 0.0
var death_floor_normal: Vector3 = Vector3.UP
var death_landed: bool = false
var death_settled: bool = false
var dead_age: float = 0.0
var _ragdoll_active: bool = false
var _ragdoll_age: float = 0.0
var _ragdoll_settle_timer: float = 0.0
var _ragdoll_sim: PhysicalBoneSimulator3D = null
var _pb_entries: Array[Dictionary] = []
var _pb_hips: PhysicalBone3D = null
var _pb_spine2: PhysicalBone3D = null
var _pb_head: PhysicalBone3D = null
var _pb_l_arm: PhysicalBone3D = null
var _pb_r_arm: PhysicalBone3D = null
var _pb_l_leg: PhysicalBone3D = null
var _pb_r_leg: PhysicalBone3D = null
var _pending_impulse_frames: int = 0
var _pending_impulses: Dictionary = {}

var rig_root: Node3D
var model_inst: Node3D
var anim_player: AnimationPlayer
var skeleton: Skeleton3D
var sk_mod: SkeletonModifier3D
var _ragdoll_unstuck_done: bool = false
var _merged_mesh_inst: MeshInstance3D = null

var root_joint_bone := -1
var hips_bone := -1
var spine_bone := -1
var spine1_bone := -1
var spine2_bone := -1
var neck_bone := -1
var head_bone := -1
var l_shoulder_bone := -1
var l_arm_bone := -1
var l_forearm_bone := -1
var l_hand_bone := -1
var r_shoulder_bone := -1
var r_arm_bone := -1
var r_forearm_bone := -1
var r_hand_bone := -1
var l_upleg_bone := -1
var l_leg_bone := -1
var l_foot_bone := -1
var r_upleg_bone := -1
var r_leg_bone := -1
var r_foot_bone := -1

var growl_player: AudioStreamPlayer3D
var impact_audio: AudioStreamPlayer3D
var _pellet_impulse_accum: float = 0.0

signal died(zombie: ZombieAI, was_headshot: bool)

const MAX_CORPSES := 10
const MAX_ACTIVE_RAGDOLLS := 4
const BAKED_PATHS := {
	Variant.TACTICAL_SOLDIER: "res://assets/baked/zombie_tactical.scn",
	Variant.ASYLUM_PATIENT: "res://assets/baked/zombie_patient.scn",
	Variant.RUNNER: "res://assets/baked/zombie_runner.scn",
	Variant.BRUISER: "res://assets/baked/zombie_tactical.scn",
	Variant.EXPLODER: "res://assets/baked/zombie_patient.scn",
	Variant.SPITTER: "res://assets/baked/zombie_patient.scn",
	Variant.SCREAMER: "res://assets/baked/zombie_patient.scn",
}

var _shadow_meshes: Array[GeometryInstance3D] = []
var _body_meshes: Array[MeshInstance3D] = []
var _shadow_tick: int = 0

static var _baked_scene_cache: Dictionary = {}

static var _scene_cache: Dictionary = {}
static var _norm_cache: Dictionary = {} # Variant -> {meshes, skins, bone_rests, anims}
static var _growl_streams: Array[AudioStream] = []
static var _snarl_streams: Array[AudioStream] = []
static var _pain_streams: Array[AudioStream] = []
static var _death_stream: AudioStream = null
static var _body_fall_stream: AudioStream = null
static var _audio_loaded: bool = false
static var _all_zombies: Array[ZombieAI] = []
static var _corpses: Array[ZombieAI] = []
static var _active_ragdolls: Array[ZombieAI] = []
static var _stump_flesh_mat: StandardMaterial3D = null
static var _stump_bone_mat: StandardMaterial3D = null


class ZombieSkeletonModifier extends SkeletonModifier3D:
	var zombie: ZombieAI
	var _bones_ready: bool = false
	var _pelvis_spring_y: float = 0.0
	var _pelvis_vel_y: float = 0.0
	var _spring_rot: Dictionary = {} # bone_idx -> Vector3
	var _spring_vel: Dictionary = {} # bone_idx -> Vector3

	func setup(owner_z: ZombieAI) -> void:
		zombie = owner_z
		_bones_ready = true

	func add_spring_impulse(bone_idx: int, char_rot_vel: Vector3) -> void:
		if bone_idx < 0:
			return
		var v: Vector3 = _spring_vel.get(bone_idx, Vector3.ZERO)
		v += char_rot_vel
		_spring_vel[bone_idx] = v.limit_length(16.0)

	func add_pelvis_drop(vel_y: float) -> void:
		_pelvis_vel_y = clampf(_pelvis_vel_y + vel_y, -3.5, 1.5)

	func _rotate_bone_char(sk: Skeleton3D, rig_basis: Basis, sk_world_basis: Basis, bone_idx: int, angles: Vector3) -> void:
		if bone_idx < 0 or angles.length_squared() < 1e-6:
			return
		var parent_idx := sk.get_bone_parent(bone_idx)
		var p_world_basis: Basis
		if parent_idx >= 0:
			p_world_basis = (sk_world_basis * sk.get_bone_global_pose(parent_idx).basis).orthonormalized()
		else:
			p_world_basis = sk_world_basis
		var inv_p := p_world_basis.inverse()

		var delta_q := Quaternion.IDENTITY
		if absf(angles.x) > 0.0005:
			var ax := (inv_p * (rig_basis * Vector3.RIGHT)).normalized()
			delta_q = Quaternion(ax, angles.x) * delta_q
		if absf(angles.y) > 0.0005:
			var ay := (inv_p * (rig_basis * Vector3.UP)).normalized()
			delta_q = Quaternion(ay, angles.y) * delta_q
		if absf(angles.z) > 0.0005:
			var az := (inv_p * (rig_basis * Vector3.FORWARD)).normalized()
			delta_q = Quaternion(az, angles.z) * delta_q
		sk.set_bone_pose_rotation(bone_idx, delta_q * sk.get_bone_pose_rotation(bone_idx))

	func _process_modification_with_delta(delta: float) -> void:
		if not _bones_ready or zombie == null or zombie.dead or zombie.deterministic_pose:
			return
		var sk := get_skeleton()
		if sk == null:
			return

		var has_springs := not _spring_vel.is_empty() or not _spring_rot.is_empty() or absf(_pelvis_spring_y) > 0.002 or absf(_pelvis_vel_y) > 0.01
		var is_attack := zombie.state == State.WINDUP or zombie.state == State.STRIKE or zombie.state == State.RECOVER or zombie.state == State.SPECIAL or zombie.state == State.GRAB or zombie.state == State.CHARGE or zombie.state == State.LEAP or zombie.state == State.KNOCKDOWN
		var is_burning := zombie.burn_timer > 0.0
		var has_limp := zombie.crippled_side != 0 or zombie.disabled_arm_timer > 0.0 or zombie.is_crawler
		var has_dismember := not zombie.dismembered.is_empty()
		if not has_springs and not is_attack and not is_burning and not has_limp and not has_dismember:
			return

		var d := clampf(delta, 0.0001, 0.05)

		if has_springs:
			var k_stiff := 320.0
			var k_damp := 14.5
			var to_erase: Array[int] = []
			for b_key in _spring_vel.keys():
				var b: int = b_key
				var pos_v: Vector3 = _spring_rot.get(b, Vector3.ZERO)
				var vel_v: Vector3 = _spring_vel[b]
				var acc := -k_stiff * pos_v - k_damp * vel_v
				vel_v += acc * d
				pos_v += vel_v * d
				pos_v = Vector3(
					clampf(pos_v.x, -0.95, 0.95),
					clampf(pos_v.y, -0.95, 0.95),
					clampf(pos_v.z, -0.95, 0.95)
				)
				if pos_v.length_squared() < 1e-5 and vel_v.length_squared() < 1e-4:
					to_erase.append(b)
				else:
					_spring_rot[b] = pos_v
					_spring_vel[b] = vel_v
			for eb in to_erase:
				_spring_rot.erase(eb)
				_spring_vel.erase(eb)

			var p_acc := -220.0 * _pelvis_spring_y - 16.0 * _pelvis_vel_y
			_pelvis_vel_y += p_acc * d
			_pelvis_spring_y = clampf(_pelvis_spring_y + _pelvis_vel_y * d, -0.28, 0.12)

		if zombie.hips_bone >= 0 and (absf(_pelvis_spring_y) > 0.002 or zombie.crippled_side != 0):
			var hp := sk.get_bone_pose_position(zombie.hips_bone)
			var m_drop := _pelvis_spring_y
			if zombie.crippled_side != 0:
				m_drop -= (0.065 + 0.055 * maxf(0.0, sin(zombie.anim_phase)))
			sk.set_bone_pose_position(zombie.hips_bone, Vector3(0.0, hp.y + m_drop, 0.0))

		var atk_spine := Vector3.ZERO
		var atk_arm_r := Vector3.ZERO
		var atk_arm_l := Vector3.ZERO
		var atk_fore_r := Vector3.ZERO
		var atk_fore_l := Vector3.ZERO
		var atk_head := Vector3.ZERO

		if zombie.state == State.WINDUP and zombie.attack_kind == "grab":
			# Two-handed grab telegraph: both arms come up and open wide before the lunge
			var wg := sin(clampf(1.0 - zombie.state_timer / maxf(zombie._windup_dur * 1.25, 0.01), 0.0, 1.0) * PI * 0.5)
			atk_spine = Vector3(-0.16 * wg, 0.0, 0.0)
			atk_arm_r = Vector3(-0.22 * wg, -0.80 * wg, 0.20 * wg)
			atk_arm_l = Vector3(-0.22 * wg, 0.80 * wg, -0.20 * wg)
			atk_head = Vector3(0.20 * wg, 0.0, 0.0)
		elif zombie.state == State.STRIKE and zombie.attack_kind == "grab":
			var sg := smoothstep(0.0, 0.7, clampf(1.0 - zombie.state_timer / maxf(zombie._strike_dur, 0.01), 0.0, 1.0))
			atk_spine = Vector3(0.36 * sg, 0.0, 0.0)
			atk_arm_r = Vector3(-0.30, lerpf(-0.80, 0.22, sg), 0.20)
			atk_arm_l = Vector3(-0.30, lerpf(0.80, -0.22, sg), -0.20)
		elif zombie.state == State.GRAB:
			# Clamped on: arms locked forward, head snapping in on each bite
			var bite := maxf(0.0, sin(zombie._grab_time * 8.1))
			atk_spine = Vector3(0.30 + 0.10 * bite, 0.0, 0.0)
			atk_arm_r = Vector3(-0.28, 0.24, 0.16)
			atk_arm_l = Vector3(-0.28, -0.24, -0.16)
			atk_fore_r = Vector3(-0.45, 0.0, 0.0)
			atk_fore_l = Vector3(-0.45, 0.0, 0.0)
			atk_head = Vector3(0.42 * bite, sin(zombie._grab_time * 13.0) * 0.16, 0.0)
		elif zombie.state == State.SPECIAL:
			var su := clampf(1.0 - zombie.state_timer / maxf(zombie._special_dur, 0.01), 0.0, 1.0)
			var se := sin(su * PI * 0.5)
			match zombie._special:
				"slam":
					# Both fists hauled overhead, hanging for a beat, then driven into the floor in the last 15%
					var drop := smoothstep(0.84, 1.0, su)
					atk_spine = Vector3(lerpf(-0.42 * se, 0.60, drop), 0.0, 0.0)
					atk_arm_r = Vector3(lerpf(-2.65 * se, -0.55, drop), -0.10, 0.12)
					atk_arm_l = Vector3(lerpf(-2.65 * se, -0.55, drop), 0.10, -0.12)
					atk_head = Vector3(-0.25 * se * (1.0 - drop), 0.0, 0.0)
				"charge":
					atk_spine = Vector3(0.38 * se, 0.0, 0.0)
					atk_arm_r = Vector3(0.55 * se, -0.20 * se, 0.0)
					atk_arm_l = Vector3(0.55 * se, 0.20 * se, 0.0)
					atk_head = Vector3(-0.30 * se, 0.0, 0.0)
				"leap":
					atk_spine = Vector3(0.50 * se, 0.0, 0.0)
					atk_arm_r = Vector3(0.70 * se, -0.25 * se, 0.0)
					atk_arm_l = Vector3(0.70 * se, 0.25 * se, 0.0)
				"spit":
					# Rear back and swell, then whip the head forward at release
					var snap := smoothstep(0.86, 1.0, su)
					atk_spine = Vector3(lerpf(-0.48 * se, 0.34, snap), 0.0, 0.0)
					atk_head = Vector3(lerpf(-0.52 * se, 0.40, snap), 0.0, 0.0)
					atk_arm_r = Vector3(0.25 * se, -0.25 * se, 0.0)
					atk_arm_l = Vector3(0.25 * se, 0.25 * se, 0.0)
				"scream_wind":
					atk_spine = Vector3(0.34 * se, 0.0, 0.0)
					atk_arm_r = Vector3(0.20 * se, -0.30 * se, 0.0)
					atk_arm_l = Vector3(0.20 * se, 0.30 * se, 0.0)
				"scream":
					# Thrown open: chest out, head back, arms flung wide and shaking
					var shake := sin(su * 95.0) * 0.045
					atk_spine = Vector3(-0.46 + shake, 0.0, 0.0)
					atk_head = Vector3(-0.50 + shake * 2.0, 0.0, 0.0)
					atk_arm_r = Vector3(0.35, -0.95 + shake, 0.25)
					atk_arm_l = Vector3(0.35, 0.95 - shake, -0.25)
		elif zombie.state == State.CHARGE:
			atk_spine = Vector3(0.42, 0.0, 0.0)
			atk_arm_r = Vector3(-0.55, -0.35, 0.0)
			atk_arm_l = Vector3(0.75, 0.25, 0.0)
			atk_head = Vector3(-0.35, 0.0, 0.0)
		elif zombie.state == State.LEAP:
			atk_spine = Vector3(0.25, 0.0, 0.0)
			atk_arm_r = Vector3(-1.75, -0.30, 0.2)
			atk_arm_l = Vector3(-1.75, 0.30, -0.2)
			atk_head = Vector3(-0.30, 0.0, 0.0)
		elif zombie.state == State.KNOCKDOWN:
			var kd := zombie._knock_lay
			var sprawl := -1.0 if zombie._knock_face_down else 1.0
			atk_arm_r = Vector3(-0.9 * kd * sprawl, -0.7 * kd, 0.0)
			atk_arm_l = Vector3(-0.9 * kd * sprawl, 0.7 * kd, 0.0)
			atk_head = Vector3(-0.25 * kd * sprawl, 0.0, 0.0)
		elif zombie.state == State.WINDUP:
			var wu := clampf(1.0 - zombie.state_timer / maxf(zombie._windup_dur, 0.01), 0.0, 1.0)
			var e := sin(wu * PI * 0.5)
			var s := float(zombie.attack_side)
			atk_spine = Vector3(-0.30 * e, -0.40 * s * e, -0.10 * s * e)
			if s > 0:
				atk_arm_r = Vector3(-0.88 * e, -0.25 * e, 0.35 * e)
				atk_fore_r = Vector3(-0.55 * e, 0.0, 0.0)
				atk_arm_l = Vector3(-0.20 * e, 0.12 * e, -0.18 * e)
			else:
				atk_arm_l = Vector3(-0.88 * e, 0.25 * e, -0.35 * e)
				atk_fore_l = Vector3(-0.55 * e, 0.0, 0.0)
				atk_arm_r = Vector3(-0.20 * e, -0.12 * e, 0.18 * e)
		elif zombie.state == State.STRIKE:
			var st := clampf(1.0 - zombie.state_timer / maxf(zombie._strike_dur, 0.01), 0.0, 1.0)
			var s := float(zombie.attack_side)
			var swing := lerpf(-1.0, 1.15, smoothstep(0.0, 0.72, st))
			atk_spine = Vector3(0.42 * maxf(0.0, swing), 0.55 * s * swing, 0.18 * s)
			if s > 0:
				atk_arm_r = Vector3(-1.15 + swing * 1.95, 0.45 * swing, 0.30 - swing * 0.65)
				atk_fore_r = Vector3(-0.35, 0.0, 0.0)
			else:
				atk_arm_l = Vector3(-1.15 + swing * 1.95, -0.45 * swing, -0.30 + swing * 0.65)
				atk_fore_l = Vector3(-0.35, 0.0, 0.0)
		elif zombie.state == State.RECOVER:
			var rc := clampf(zombie.state_timer / maxf(zombie._recover_dur, 0.01), 0.0, 1.0)
			var s := float(zombie.attack_side)
			atk_spine = Vector3(0.32 * rc, 0.35 * s * rc, 0.0)
			if s > 0:
				atk_arm_r = Vector3(0.75 * rc, 0.25 * rc, -0.25 * rc)
			else:
				atk_arm_l = Vector3(0.75 * rc, -0.25 * rc, 0.25 * rc)
		if is_burning and zombie.state != State.KNOCKDOWN and zombie.state != State.GRAB:
			# Frantic burning flail & writhing upper body when engulfed in fire!
			var bt := float(Time.get_ticks_msec()) * 0.011 + zombie.anim_phase * 1.4
			var b_amp := 1.0 if zombie.state == State.STAGGER else 0.55
			atk_spine += Vector3(-0.18 * b_amp + sin(bt * 1.3) * 0.14 * b_amp, sin(bt * 1.7) * 0.24 * b_amp, cos(bt * 1.4) * 0.12 * b_amp)
			atk_head += Vector3(-0.34 * b_amp + sin(bt * 2.3) * 0.22 * b_amp, cos(bt * 2.1) * 0.34 * b_amp, 0.0)
			atk_arm_r += Vector3(-1.05 * b_amp + sin(bt * 2.2) * 0.55 * b_amp, -0.42 * b_amp, 0.35 * b_amp)
			atk_arm_l += Vector3(-1.05 * b_amp + cos(bt * 2.4) * 0.55 * b_amp, 0.42 * b_amp, -0.35 * b_amp)
			atk_fore_r += Vector3(-0.62 * b_amp, 0.0, 0.0)
			atk_fore_l += Vector3(-0.62 * b_amp, 0.0, 0.0)

		var leg_l_mod := Vector3.ZERO
		var leg_r_mod := Vector3.ZERO
		if zombie.is_crawler:
			# Trail legs flat behind crawler instead of bicycle-pedaling underground!
			leg_l_mod = Vector3(-0.35, 0.0, -0.10)
			leg_r_mod = Vector3(-0.35, 0.0, 0.10)
		elif zombie.crippled_side < 0:
			var drag := maxf(0.0, sin(zombie.anim_phase))
			leg_l_mod = Vector3(0.28 + 0.35 * drag, 0.0, -0.14)
		elif zombie.crippled_side > 0:
			var drag := maxf(0.0, sin(zombie.anim_phase))
			leg_r_mod = Vector3(0.28 + 0.35 * drag, 0.0, 0.14)

		var arm_droop_l := Vector3(0.65, 0.0, 0.45) if (zombie.dismembered.has("ARM_L") or (zombie.disabled_arm_timer > 0.0 and zombie.disabled_arm_side < 0)) else Vector3.ZERO
		var arm_droop_r := Vector3(0.65, 0.0, -0.45) if (zombie.dismembered.has("ARM_R") or (zombie.disabled_arm_timer > 0.0 and zombie.disabled_arm_side > 0)) else Vector3.ZERO
		if zombie.is_crawler:
			var cp := sin(zombie.anim_phase * 1.45)
			arm_droop_l += Vector3(-1.35 + cp * 0.55, 0.15, 0.18)
			arm_droop_r += Vector3(-1.35 - cp * 0.55, -0.15, -0.18)
			atk_spine += Vector3(-0.32, cp * 0.14, 0.0)

		var rig_basis := zombie.rig_root.global_transform.basis.orthonormalized()
		var sk_world_basis := sk.global_transform.basis.orthonormalized()

		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.spine_bone, _spring_rot.get(zombie.spine_bone, Vector3.ZERO) + atk_spine * 0.35)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.spine1_bone, _spring_rot.get(zombie.spine1_bone, Vector3.ZERO) + atk_spine * 0.45)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.spine2_bone, _spring_rot.get(zombie.spine2_bone, Vector3.ZERO) + atk_spine * 0.65)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.neck_bone, _spring_rot.get(zombie.neck_bone, Vector3.ZERO))
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.head_bone, _spring_rot.get(zombie.head_bone, Vector3.ZERO) + atk_head)

		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.l_shoulder_bone, _spring_rot.get(zombie.l_shoulder_bone, Vector3.ZERO) * 0.45)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.l_arm_bone, _spring_rot.get(zombie.l_arm_bone, Vector3.ZERO) + atk_arm_l + arm_droop_l)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.l_forearm_bone, _spring_rot.get(zombie.l_forearm_bone, Vector3.ZERO) * 0.5 + atk_fore_l)

		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.r_shoulder_bone, _spring_rot.get(zombie.r_shoulder_bone, Vector3.ZERO) * 0.45)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.r_arm_bone, _spring_rot.get(zombie.r_arm_bone, Vector3.ZERO) + atk_arm_r + arm_droop_r)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.r_forearm_bone, _spring_rot.get(zombie.r_forearm_bone, Vector3.ZERO) * 0.5 + atk_fore_r)

		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.l_upleg_bone, _spring_rot.get(zombie.l_upleg_bone, Vector3.ZERO) + leg_l_mod * 0.4)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.l_leg_bone, _spring_rot.get(zombie.l_leg_bone, Vector3.ZERO) * 1.15 + leg_l_mod)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.r_upleg_bone, _spring_rot.get(zombie.r_upleg_bone, Vector3.ZERO) + leg_r_mod * 0.4)
		_rotate_bone_char(sk, rig_basis, sk_world_basis, zombie.r_leg_bone, _spring_rot.get(zombie.r_leg_bone, Vector3.ZERO) * 1.15 + leg_r_mod)

		if not zombie.dismembered.is_empty():
			zombie._apply_dismembered_local_scales()


static func preload_baked_assets() -> void:
	_ensure_audio_loaded()
	for v in BAKED_PATHS.keys():
		var bp: String = BAKED_PATHS[v]
		if not _baked_scene_cache.has(v) and ResourceLoader.exists(bp):
			_baked_scene_cache[v] = load(bp)


static func _get_scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]


static func _ensure_audio_loaded() -> void:
	if _audio_loaded:
		return
	_audio_loaded = true
	for p in ["res://assets/audio/zombie_growl_a.wav", "res://assets/audio/zombie_growl_b.wav", "res://assets/audio/zombie_growl.wav"]:
		if ResourceLoader.exists(p):
			_growl_streams.append(load(p))
			if _growl_streams.size() >= 2:
				break
	for p in ["res://assets/audio/zombie_attack_snarl_a.wav", "res://assets/audio/zombie_attack_snarl_b.wav"]:
		if ResourceLoader.exists(p):
			_snarl_streams.append(load(p))
	for p in ["res://assets/audio/zombie_pain_a.wav", "res://assets/audio/zombie_pain_b.wav"]:
		if ResourceLoader.exists(p):
			_pain_streams.append(load(p))
	if ResourceLoader.exists("res://assets/audio/zombie_death.wav"):
		_death_stream = load("res://assets/audio/zombie_death.wav")
	if ResourceLoader.exists("res://assets/audio/body_fall.wav"):
		_body_fall_stream = load("res://assets/audio/body_fall.wav")


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	_nav_ray_tick = int(get_instance_id()) & 3
	match variant:
		Variant.TACTICAL_SOLDIER:
			_is_tactical = true
			max_health = 155.0
			move_speed = 2.05
			attack_damage = 22.0
			poise_max = 90.0
			_windup_dur = 0.55
			_strike_dur = 0.16
			_recover_dur = 0.70
			_trigger_range = 1.95
			_lunge_speed = 3.8
			_chest_armor_mult = 0.75
			_impulse_scale = 0.62
			_model_scale_val = 1.14
		Variant.ASYLUM_PATIENT:
			_is_tactical = false
			max_health = 100.0
			move_speed = 2.35
			attack_damage = 18.0
			poise_max = 55.0
			_windup_dur = 0.45
			_strike_dur = 0.14
			_recover_dur = 0.55
			_trigger_range = 1.85
			_lunge_speed = 4.3
			_chest_armor_mult = 1.0
			_impulse_scale = 1.0
			_model_scale_val = 1.02
		Variant.RUNNER:
			_is_tactical = false
			max_health = 72.0
			move_speed = 3.60
			attack_damage = 14.0
			poise_max = 35.0
			_windup_dur = 0.34
			_strike_dur = 0.12
			_recover_dur = 0.48
			_trigger_range = 2.25
			_lunge_speed = 6.2
			_chest_armor_mult = 1.0
			_impulse_scale = 1.35
			_model_scale_val = 0.99
		Variant.BRUISER:
			_is_tactical = true
			max_health = 380.0
			move_speed = 1.68
			attack_damage = 36.0
			poise_max = 175.0
			_windup_dur = 0.68
			_strike_dur = 0.20
			_recover_dur = 0.85
			_trigger_range = 2.15
			_lunge_speed = 4.6
			_chest_armor_mult = 0.52
			_impulse_scale = 0.32
			_model_scale_val = 1.14 * 1.18
		Variant.EXPLODER:
			_is_tactical = false
			max_health = 82.0
			move_speed = 2.95
			attack_damage = 28.0
			poise_max = 42.0
			_windup_dur = 0.42
			_strike_dur = 0.14
			_recover_dur = 0.55
			_trigger_range = 2.10
			_lunge_speed = 4.8
			_chest_armor_mult = 1.15
			_impulse_scale = 1.10
			_model_scale_val = 1.05
			kill_points = 120
		Variant.SPITTER:
			_is_tactical = false
			max_health = 88.0
			move_speed = 2.25
			attack_damage = 14.0
			poise_max = 40.0
			_windup_dur = 0.50
			_strike_dur = 0.14
			_recover_dur = 0.60
			_trigger_range = 1.80
			_lunge_speed = 3.6
			_chest_armor_mult = 1.0
			_impulse_scale = 1.05
			_model_scale_val = 1.02
			kill_points = 130
			_special_cd = randf_range(0.8, 2.0)
		Variant.SCREAMER:
			_is_tactical = false
			max_health = 78.0
			move_speed = 3.05
			attack_damage = 15.0
			poise_max = 38.0
			_windup_dur = 0.36
			_strike_dur = 0.12
			_recover_dur = 0.50
			_trigger_range = 2.05
			_lunge_speed = 5.4
			_chest_armor_mult = 1.0
			_impulse_scale = 1.25
			_model_scale_val = 1.02
			kill_points = 150
			_special_cd = randf_range(0.4, 1.2)
	if variant == Variant.BRUISER:
		kill_points = 250
		_special_cd = randf_range(0.8, 2.0)
	elif variant == Variant.RUNNER:
		kill_points = 110
		_special_cd = randf_range(1.0, 3.0)
	_strafe_sign = 1.0 if (int(get_instance_id()) % 2 == 0) else -1.0
	health = max_health
	anim_phase = randf() * TAU
	growl_timer = randf_range(1.2, 4.5)
	_build_body()
	_setup_audio()
	if not _all_zombies.has(self):
		_all_zombies.append(self)


func _find_node_of_type(root: Node, type_name: String) -> Node:
	if root.get_class() == type_name:
		return root
	for c in root.get_children():
		var f := _find_node_of_type(c, type_name)
		if f:
			return f
	return null


func _strip_junk_nodes(n: Node) -> void:
	for c in n.get_children():
		if c is Camera3D or c is Light3D:
			c.queue_free()
		else:
			_strip_junk_nodes(c)


func _accum_local_to(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != ancestor:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _reset_node_transforms_to_sk(cur: Node, sk: Skeleton3D) -> void:
	if cur is Node3D:
		(cur as Node3D).transform = Transform3D.IDENTITY
	if cur == sk:
		return
	for c in cur.get_children():
		_reset_node_transforms_to_sk(c, sk)


static func _upgrade_zombie_material(mat: Material, zv: int = Variant.TACTICAL_SOLDIER) -> Material:
	if mat is ShaderMaterial:
		return mat
	if not (mat is StandardMaterial3D):
		return mat
	var src := mat as StandardMaterial3D
	var id := src.resource_name.to_lower()
	if "necroticdermis" in id or "leozombieflesh" in id:
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/zombie_necrotic_skin.gdshader")
		sm.set_shader_parameter("detail_normal_tex", load("res://assets/textures/zombie_pores_normal.png"))
		if "necroticdermis" in id:
			sm.set_shader_parameter("albedo_tex", load("res://assets/textures/tactical_dermis_clean.jpg"))
			sm.set_shader_parameter("has_albedo_tex", true)
			sm.set_shader_parameter("is_head", true)
			sm.set_shader_parameter("albedo_gamma", 0.85)
			sm.set_shader_parameter("skin_tint", Color(0.96, 0.94, 0.92))
			sm.set_shader_parameter("blood_wetness", 0.86)
		else:
			if src.albedo_texture:
				sm.set_shader_parameter("albedo_tex", src.albedo_texture)
				sm.set_shader_parameter("has_albedo_tex", true)
			else:
				sm.set_shader_parameter("has_albedo_tex", false)
			sm.set_shader_parameter("is_head", false)
			sm.set_shader_parameter("albedo_gamma", 0.84)
			sm.set_shader_parameter("skin_tint", Color(0.96, 0.94, 0.92))
			sm.set_shader_parameter("blood_wetness", 0.84 if zv == Variant.ASYLUM_PATIENT else 0.88)
		if src.normal_texture:
			sm.set_shader_parameter("normal_tex", src.normal_texture)
			sm.set_shader_parameter("has_normal_tex", true)
		else:
			sm.set_shader_parameter("has_normal_tex", false)
		sm.set_shader_parameter("detail_uv_scale", 11.0)
		sm.set_shader_parameter("detail_strength", 0.72)
		sm.set_shader_parameter("gore_seed", float(zv) * 1.73)
		return sm
	elif "oldivory" in id:
		var jm := ShaderMaterial.new()
		jm.shader = load("res://shaders/zombie_jaw_gums.gdshader")
		jm.set_shader_parameter("has_albedo_tex", src.albedo_texture != null)
		if src.albedo_texture:
			jm.set_shader_parameter("albedo_tex", src.albedo_texture)
		jm.set_shader_parameter("has_normal_tex", src.normal_texture != null)
		if src.normal_texture:
			jm.set_shader_parameter("normal_tex", src.normal_texture)
		return jm
	elif "soddenfieldcoat" in id or "leozombierags" in id or "zombiewinterparka" in id or "oilskinwebbing" in id or "ribbedfieldcollar" in id or "foldedparkahood" in id or "coat" in id or "parka" in id or "rags" in id or "collar" in id or "webbing" in id:
		var gm := ShaderMaterial.new()
		gm.shader = load("res://shaders/zombie_tactical_gear.gdshader")
		gm.set_shader_parameter("weave_normal_tex", load("res://assets/textures/tactical_cloth_normal.jpg"))
		if "soddenfieldcoat" in id:
			gm.set_shader_parameter("albedo_tex", load("res://assets/textures/torn_field_canvas.jpg"))
			gm.set_shader_parameter("normal_tex", load("res://assets/textures/torn_field_canvas_normal.jpg"))
			gm.set_shader_parameter("has_albedo_tex", true)
			gm.set_shader_parameter("has_normal_tex", true)
			gm.set_shader_parameter("uv_scale", Vector2.ONE)
			gm.set_shader_parameter("uv_offset", Vector2.ZERO)
			gm.set_shader_parameter("albedo_gamma", 0.88)
			gm.set_shader_parameter("fabric_tint", Color(0.62, 0.66, 0.58))
			gm.set_shader_parameter("blood_stain_strength", 0.72)
		elif "leozombierags" in id:
			gm.set_shader_parameter("albedo_tex", load("res://assets/textures/zombie_cloth_albedo.jpg"))
			gm.set_shader_parameter("normal_tex", src.normal_texture if src.normal_texture else load("res://assets/textures/tactical_cloth_normal.jpg"))
			gm.set_shader_parameter("has_albedo_tex", true)
			gm.set_shader_parameter("has_normal_tex", true)
			gm.set_shader_parameter("uv_scale", Vector2(2.2, 2.2))
			gm.set_shader_parameter("uv_offset", Vector2.ZERO)
			gm.set_shader_parameter("albedo_gamma", 0.90)
			if zv == Variant.ASYLUM_PATIENT:
				gm.set_shader_parameter("fabric_tint", Color(0.58, 0.56, 0.52))
				gm.set_shader_parameter("blood_stain_strength", 0.88)
			else:
				gm.set_shader_parameter("fabric_tint", Color(0.52, 0.50, 0.46))
				gm.set_shader_parameter("blood_stain_strength", 0.78)
		else:
			gm.set_shader_parameter("albedo_tex", src.albedo_texture if src.albedo_texture else load("res://assets/textures/tactical_cloth_normal.jpg"))
			gm.set_shader_parameter("normal_tex", src.normal_texture if src.normal_texture else load("res://assets/textures/tactical_cloth_normal.jpg"))
			gm.set_shader_parameter("has_albedo_tex", src.albedo_texture != null)
			gm.set_shader_parameter("has_normal_tex", true)
			gm.set_shader_parameter("uv_scale", Vector2(src.uv1_scale.x, src.uv1_scale.y))
			gm.set_shader_parameter("uv_offset", Vector2(src.uv1_offset.x, src.uv1_offset.y))
			if "oilskinwebbing" in id:
				gm.set_shader_parameter("albedo_gamma", 0.82)
				gm.set_shader_parameter("fabric_tint", Color(0.56, 0.58, 0.52))
				gm.set_shader_parameter("blood_stain_strength", 0.58)
			elif "zombiewinterparka" in id or "parka" in id:
				gm.set_shader_parameter("albedo_gamma", 0.56)
				gm.set_shader_parameter("fabric_tint", Color(0.86, 0.90, 0.84))
				gm.set_shader_parameter("blood_stain_strength", 0.64)
			else:
				gm.set_shader_parameter("albedo_gamma", 0.80)
				gm.set_shader_parameter("fabric_tint", Color(0.66, 0.68, 0.62))
				gm.set_shader_parameter("blood_stain_strength", 0.68)
		gm.set_shader_parameter("seed_offset", float(zv) * 2.11)
		return gm

	var m := src.duplicate() as StandardMaterial3D
	if "foggedeye0" in id:
		m.albedo_color = Color(0.015, 0.015, 0.020)
		m.roughness = 0.02
		m.metallic = 0.0
		m.metallic_specular = 0.85
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.02
	elif "foggedeye1" in id:
		m.albedo_color = Color(0.28, 0.34, 0.32)
		m.roughness = 0.025
		m.metallic = 0.0
		m.metallic_specular = 0.82
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.025
	elif "foggedeye" in id:
		m.albedo_color = Color(0.66, 0.54, 0.48)
		m.roughness = 0.035
		m.metallic = 0.0
		m.metallic_specular = 0.78
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.03
	elif "smokedvisor" in id:
		m.albedo_color = Color(0.06, 0.07, 0.08)
		m.roughness = 0.12
		m.metallic = 0.12
		m.metallic_specular = 0.70
		m.clearcoat_enabled = true
		m.clearcoat = 0.85
		m.clearcoat_roughness = 0.05
	elif "frostedpile" in id:
		m.albedo_color = Color(0.56, 0.58, 0.62)
		m.roughness = 0.94
		m.metallic = 0.0
		m.metallic_specular = 0.08
		m.rim_enabled = true
		m.rim = 0.32
		m.rim_tint = 0.45
	elif "visor" in id or "goog" in id or "rubber" in id:
		m.albedo_color = Color(0.24, 0.24, 0.25)
		m.roughness = 0.74
		m.metallic = 0.0
		m.metallic_specular = 0.14
	return m


static func _bake_unit_mesh(src: Mesh, scl: float, zv: int, to_sk: Transform3D) -> ArrayMesh:
	var im := ImporterMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
		var vc := verts.size()
		var uv2 := PackedVector2Array()
		uv2.resize(vc)
		var cols := PackedColorArray()
		cols.resize(vc)
		var n_basis := to_sk.basis.orthonormalized()
		for i in vc:
			var vs := verts[i] * scl
			verts[i] = vs
			var r_p := to_sk * vs
			var ny := 1.0
			if norms.size() == vc:
				ny = (n_basis * norms[i]).normalized().y
			uv2[i] = Vector2(r_p.x, r_p.y)
			cols[i] = Color(clampf((r_p.z + 1.5) / 3.0, 0.0, 1.0), clampf(ny * 0.5 + 0.5, 0.0, 1.0), 1.0, 1.0)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_TEX_UV2] = uv2
		arrays[Mesh.ARRAY_COLOR] = cols
		var stride := (bones.size() / vc) if (vc > 0 and not bones.is_empty()) else 0
		var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if stride == 8 else 0
		var mat := _upgrade_zombie_material(src.surface_get_material(s), zv)
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mat, "", flags)
	im.generate_lods(45.0, 25.0, [])
	return im.get_mesh()


func _build_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.48 if variant == Variant.BRUISER else (0.40 if _is_tactical else 0.38)
	cap.height = 2.08 if variant == Variant.BRUISER else (1.88 if _is_tactical else 1.78)
	col.shape = cap
	col.position = Vector3(0, cap.height * 0.5, 0)
	add_child(col)
	_body_col = col

	rig_root = Node3D.new()
	add_child(rig_root)

	var is_baking: bool = Engine.get_main_loop() != null and Engine.get_main_loop().has_meta("baking_zombies")
	var packed: PackedScene = null
	var used_baked := false
	if not is_baking:
		if _baked_scene_cache.has(variant):
			packed = _baked_scene_cache[variant]
			used_baked = (packed != null)
		elif ResourceLoader.exists(BAKED_PATHS[variant]):
			packed = load(BAKED_PATHS[variant])
			if packed:
				_baked_scene_cache[variant] = packed
				used_baked = true
	if variant == Variant.BRUISER and used_baked:
		# Uniform scale (natively supported by Jolt CapsuleShape3D with ZERO physics errors!)
		rig_root.scale = Vector3.ONE * 1.18
	elif variant == Variant.SCREAMER and used_baked:
		rig_root.scale = Vector3.ONE * 0.95 # slighter frame (kept uniform: ragdoll bodies cannot take a non-uniform scale)
	elif variant == Variant.SPITTER and used_baked:
		rig_root.scale = Vector3.ONE * 1.03
	if packed == null:
		var glb_path := "res://assets/models/zombie_tactical.glb" if _is_tactical else "res://assets/models/zombie_runner.glb"
		packed = _get_scene(glb_path)
	if packed:
		model_inst = packed.instantiate()
		if not used_baked:
			_strip_junk_nodes(model_inst)
		rig_root.add_child(model_inst)

		anim_player = _find_node_of_type(model_inst, "AnimationPlayer") as AnimationPlayer
		skeleton = _find_node_of_type(model_inst, "Skeleton3D") as Skeleton3D
		if skeleton:
			if not used_baked:
				_apply_unit_meter_rig()
			_resolve_bones()
			_collect_shadow_meshes()
			var mod := ZombieSkeletonModifier.new()
			mod.name = "LocationalReactionMod"
			mod.setup(self)
			skeleton.add_child(mod)
			sk_mod = mod
		_play_horror_anim("walk", randf() * 1.4)
		_setup_variant_identity()


func _attach_exploder_visuals() -> void:
	var cluster := Node3D.new()
	cluster.name = "ExploderPustules"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.84, 0.30, 0.06)
	mat.roughness = 0.32
	if ResourceLoader.exists("res://assets/textures/zombie_pores_normal.png"):
		mat.normal_enabled = true
		mat.normal_texture = load("res://assets/textures/zombie_pores_normal.png")
		mat.normal_scale = 1.6
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.42, 0.06)
	mat.emission_energy_multiplier = 2.6
	for spec in [
		[Vector3(0.0, 0.02, 0.14), Vector3(0.19, 0.24, 0.16)],
		[Vector3(-0.11, -0.05, 0.11), Vector3(0.13, 0.15, 0.12)],
		[Vector3(0.10, 0.08, 0.10), Vector3(0.12, 0.14, 0.11)],
	]:
		var lob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5; sm.height = 1.0; sm.radial_segments = 14; sm.rings = 8
		sm.material = mat
		lob.mesh = sm
		lob.position = spec[0]
		lob.scale = spec[1]
		lob.layers = 8
		lob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cluster.add_child(lob)
	if skeleton and spine2_bone >= 0:
		var ba := BoneAttachment3D.new()
		ba.bone_name = skeleton.get_bone_name(spine2_bone)
		ba.add_child(cluster)
		skeleton.add_child(ba)
		_exploder_attach = ba
	else:
		cluster.position = Vector3(0.0, 1.16, 0.14)
		rig_root.add_child(cluster)
	_exploder_sac = cluster

func _collect_shadow_meshes() -> void:
	_shadow_meshes.clear()
	_body_meshes.clear()
	if model_inst == null:
		return
	for mn in model_inst.find_children("*", "GeometryInstance3D", true, false):
		var gi := mn as GeometryInstance3D
		if gi is MeshInstance3D:
			_body_meshes.append(gi as MeshInstance3D)
		gi.layers = 8
		gi.lod_bias = 1.0
		gi.visibility_range_end = 0.0
		gi.extra_cull_margin = 0.5
		gi.custom_aabb = AABB(Vector3(-1.4, -0.4, -1.4), Vector3(2.8, 2.8, 2.8))
		var lname := str(gi.name).to_lower()
		if lname.begins_with("skigoggle") or "winterhelmet" in lname:
			gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			_shadow_meshes.append(gi)


func _set_shadow_casting(enabled: bool) -> void:
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for gi in _shadow_meshes:
		if is_instance_valid(gi) and gi.cast_shadow != mode:
			gi.cast_shadow = mode


func _exit_tree() -> void:
	_all_zombies.erase(self)
	_active_ragdolls.erase(self)
	_corpses.erase(self)


func _apply_unit_meter_rig() -> void:
	var sk := skeleton
	var bc := sk.get_bone_count()
	if not _norm_cache.has(variant):
		# First spawn of this variant computes and caches normalized meshes, skins, rests, and anims once
		if _is_tactical and bc > 0 and "_rootjoint" in sk.get_bone_name(0).to_lower():
			sk.set_bone_rest(0, Transform3D(Basis().scaled(Vector3(0.01, 0.01, 0.01)), Vector3.ZERO))
			sk.set_bone_pose_scale(0, Vector3(0.01, 0.01, 0.01))
			sk.set_bone_pose_position(0, Vector3.ZERO)

		var sk_rel := _accum_local_to(sk, rig_root)
		var sk_with_target := Transform3D(Basis().scaled(Vector3.ONE * _model_scale_val), Vector3.ZERO) * sk_rel

		var orig_in_rig: Array[Transform3D] = []
		orig_in_rig.resize(bc)
		var unit_in_rig: Array[Transform3D] = []
		unit_in_rig.resize(bc)
		var bone_scales: Array[Vector3] = []
		bone_scales.resize(bc)
		for b in bc:
			var p := sk.get_bone_parent(b)
			var lr := sk.get_bone_rest(b)
			var g_rig := (sk_with_target * lr) if p < 0 else (orig_in_rig[p] * lr)
			orig_in_rig[b] = g_rig
			bone_scales[b] = Vector3(g_rig.basis.x.length(), g_rig.basis.y.length(), g_rig.basis.z.length())
			unit_in_rig[b] = Transform3D(g_rig.basis.orthonormalized(), g_rig.origin)

		var rests: Array[Transform3D] = []
		rests.resize(bc)
		for b in bc:
			var p := sk.get_bone_parent(b)
			var new_rest := unit_in_rig[b] if p < 0 else (unit_in_rig[p].affine_inverse() * unit_in_rig[b])
			new_rest.basis = new_rest.basis.orthonormalized()
			rests[b] = new_rest

		var mesh_map := {} # orig Mesh -> normalized ArrayMesh
		var skin_map := {} # orig Skin -> normalized Skin
		var mesh_nodes := model_inst.find_children("*", "MeshInstance3D", true, false)
		for mn in mesh_nodes:
			var mi := mn as MeshInstance3D
			if "eyelash" in str(mi.name).to_lower():
				continue
			var m := mi.mesh
			var skin := mi.skin
			var v_scale := _model_scale_val
			var bone_s0 := bone_scales[0] if bc > 0 else Vector3.ONE * _model_scale_val
			var to_sk := Transform3D.IDENTITY
			if skin and skin.get_bind_count() > 0:
				var bp0 := skin.get_bind_pose(0)
				var bp_scl := bp0.basis.x.length()
				var b0 := skin.get_bind_bone(0)
				if b0 < 0 and not skin.get_bind_name(0).is_empty():
					b0 = sk.find_bone(skin.get_bind_name(0))
				if b0 >= 0 and b0 < bc:
					bone_s0 = bone_scales[b0]
					to_sk = unit_in_rig[b0] * Transform3D(bp0.basis.orthonormalized(), bp0.origin * bone_s0.x)
				v_scale = bone_s0.x * bp_scl

			if m and not mesh_map.has(m):
				mesh_map[m] = _bake_unit_mesh(m, v_scale, variant, to_sk)
			if skin and not skin_map.has(skin):
				var new_skin := Skin.new()
				for j in skin.get_bind_count():
					var b_name := skin.get_bind_name(j)
					var b_idx := skin.get_bind_bone(j)
					if b_idx < 0 and not b_name.is_empty():
						b_idx = sk.find_bone(b_name)
					var bp := skin.get_bind_pose(j)
					var bs := bone_scales[b_idx] if (b_idx >= 0 and b_idx < bc) else bone_s0
					var new_bp := Transform3D(bp.basis.orthonormalized(), bp.origin * bs.x)
					if b_name.is_empty():
						new_skin.add_bind(b_idx, new_bp)
					else:
						new_skin.add_named_bind(b_name, new_bp)
				skin_map[skin] = new_skin

		var norm_lib := AnimationLibrary.new()
		if anim_player:
			var sk_raw_s := sk_rel.basis.x.length() * _model_scale_val
			var sk_path_str := str(model_inst.get_path_to(sk))
			for a_name in anim_player.get_animation_list():
				var src_anim := anim_player.get_animation(a_name)
				if src_anim == null:
					continue
				var anim := src_anim.duplicate() as Animation
				for t in anim.get_track_count():
					var tp := str(anim.track_get_path(t))
					var tt := anim.track_get_type(t)
					var colon := tp.find(":")
					if colon < 0:
						continue
					var bone_name := tp.substr(colon + 1)
					var b_idx := sk.find_bone(bone_name)
					if b_idx < 0:
						continue
					anim.track_set_path(t, NodePath(sk_path_str + ":" + bone_name))
					if tt == Animation.TYPE_SCALE_3D:
						for k in anim.track_get_key_count(t):
							anim.track_set_key_value(t, k, Vector3.ONE)
					elif tt == Animation.TYPE_POSITION_3D:
						var p := sk.get_bone_parent(b_idx)
						var ps := sk_raw_s if p < 0 else bone_scales[p].x
						var is_rj := "_rootjoint" in bone_name.to_lower()
						var is_hips := "hips" in bone_name.to_lower()
						for k in anim.track_get_key_count(t):
							var v: Vector3 = anim.track_get_key_value(t, k)
							if is_rj:
								anim.track_set_key_value(t, k, Vector3.ZERO)
							else:
								var sv := v * ps
								if is_hips:
									sv.x = 0.0; sv.z = 0.0
								anim.track_set_key_value(t, k, sv)
				norm_lib.add_animation(a_name, anim)

		_norm_cache[variant] = {
			"rests": rests,
			"meshes": mesh_map,
			"skins": skin_map,
			"lib": norm_lib,
		}

	var cache: Dictionary = _norm_cache[variant]
	var cached_rests: Array = cache["rests"]
	var cached_meshes: Dictionary = cache["meshes"]
	var cached_skins: Dictionary = cache["skins"]
	var cached_lib: AnimationLibrary = cache["lib"]

	var all_meshes := model_inst.find_children("*", "MeshInstance3D", true, false)
	_reset_node_transforms_to_sk(model_inst, sk)
	model_inst.transform = Transform3D.IDENTITY

	for b in bc:
		sk.set_bone_rest(b, cached_rests[b])
		sk.set_bone_pose(b, cached_rests[b])

	_body_meshes.clear()
	for mn in all_meshes:
		var mi := mn as MeshInstance3D
		if "eyelash" in str(mi.name).to_lower():
			if mi.get_parent():
				mi.get_parent().remove_child(mi)
			mi.free()
			continue
		if mi.get_parent() != sk:
			var kname := mi.name
			mi.get_parent().remove_child(mi)
			sk.add_child(mi)
			mi.name = kname
		mi.transform = Transform3D.IDENTITY
		if mi.mesh and cached_meshes.has(mi.mesh):
			mi.mesh = cached_meshes[mi.mesh]
		if mi.skin and cached_skins.has(mi.skin):
			mi.skin = cached_skins[mi.skin]
		mi.layers = 8
		mi.lod_bias = 1.0
		mi.visibility_range_end = 0.0
		mi.extra_cull_margin = 0.5
		mi.custom_aabb = AABB(Vector3(-1.4, -0.4, -1.4), Vector3(2.8, 2.8, 2.8))
		_body_meshes.append(mi)
		var lname := str(mi.name).to_lower()
		if lname.begins_with("skigoggle") or "winterhelmet" in lname:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if anim_player:
		anim_player.root_node = anim_player.get_path_to(model_inst)
		for lib_name in anim_player.get_animation_library_list():
			anim_player.remove_animation_library(lib_name)
		anim_player.add_animation_library("", cached_lib)


func _resolve_bones() -> void:
	for bone in skeleton.get_bone_count():
		var bn := skeleton.get_bone_name(bone).to_lower()
		if root_joint_bone < 0 and ("_rootjoint" in bn or bn == "rootjoint"):
			root_joint_bone = bone
		elif hips_bone < 0 and "hips" in bn:
			hips_bone = bone
		elif spine2_bone < 0 and "spine2" in bn:
			spine2_bone = bone
		elif spine1_bone < 0 and "spine1" in bn:
			spine1_bone = bone
		elif spine_bone < 0 and "spine" in bn:
			spine_bone = bone
		elif neck_bone < 0 and "neck" in bn:
			neck_bone = bone
		elif head_bone < 0 and "head" in bn and "end" not in bn and "top" not in bn:
			head_bone = bone
		elif l_shoulder_bone < 0 and "leftshoulder" in bn:
			l_shoulder_bone = bone
		elif l_arm_bone < 0 and "leftarm" in bn:
			l_arm_bone = bone
		elif l_forearm_bone < 0 and "leftforearm" in bn:
			l_forearm_bone = bone
		elif l_hand_bone < 0 and "lefthand" in bn and "index" not in bn and "middle" not in bn and "ring" not in bn and "pinky" not in bn and "thumb" not in bn:
			l_hand_bone = bone
		elif r_shoulder_bone < 0 and "rightshoulder" in bn:
			r_shoulder_bone = bone
		elif r_arm_bone < 0 and "rightarm" in bn:
			r_arm_bone = bone
		elif r_forearm_bone < 0 and "rightforearm" in bn:
			r_forearm_bone = bone
		elif r_hand_bone < 0 and "righthand" in bn and "index" not in bn and "middle" not in bn and "ring" not in bn and "pinky" not in bn and "thumb" not in bn:
			r_hand_bone = bone
		elif l_upleg_bone < 0 and "leftupleg" in bn:
			l_upleg_bone = bone
		elif l_leg_bone < 0 and "leftleg" in bn:
			l_leg_bone = bone
		elif l_foot_bone < 0 and "leftfoot" in bn:
			l_foot_bone = bone
		elif r_upleg_bone < 0 and "rightupleg" in bn:
			r_upleg_bone = bone
		elif r_leg_bone < 0 and "rightleg" in bn:
			r_leg_bone = bone
		elif r_foot_bone < 0 and "rightfoot" in bn:
			r_foot_bone = bone


static func _ray_capsule_hit(ro: Vector3, rd: Vector3, a: Vector3, b: Vector3, radius: float, max_t: float) -> float:
	# Exact analytical ray vs capsule (line segment a..b with radius) returning closest t in [0, max_t], or -1.0
	var ab := b - a
	var ab_len_sq := ab.length_squared()
	var r2 := radius * radius
	# Check if ray origin starts inside capsule (only register if pointing forward into capsule & max_t > 0)
	var ao := ro - a
	var proj0 := clampf(ao.dot(ab) / maxf(ab_len_sq, 1e-6), 0.0, 1.0) if ab_len_sq > 1e-6 else 0.0
	var closest0 := a + ab * proj0
	if max_t > 0.0 and (ro - closest0).length_squared() <= r2:
		if (closest0 - ro).dot(rd) > 0.0:
			return minf(0.01, max_t)

	var best_t := -1.0
	# 1. Endpoint spheres (a and b)
	for c: Vector3 in ([a] if ab_len_sq <= 1e-6 else [a, b]):
		var oc := ro - c
		var hb := oc.dot(rd)
		var cc := oc.length_squared() - r2
		var disc := hb * hb - cc
		if disc >= 0.0:
			var t := -hb - sqrt(disc)
			if t >= 0.0 and t <= max_t and (best_t < 0.0 or t < best_t):
				best_t = t

	# 2. Infinite cylinder around segment a..b, clamped to [0, 1]
	if ab_len_sq > 1e-6:
		var m := ro - a
		var md := m.dot(ab)
		var nd := rd.dot(ab)
		var qa := ab_len_sq - nd * nd
		if qa > 1e-6:
			var qb := ab_len_sq * m.dot(rd) - nd * md
			var qc := ab_len_sq * (m.length_squared() - r2) - md * md
			var disc := qb * qb - qa * qc
			if disc >= 0.0:
				var t := (-qb - sqrt(disc)) / qa
				if t >= 0.0 and t <= max_t and (best_t < 0.0 or t < best_t):
					var s := md + t * nd
					if s >= 0.0 and s <= ab_len_sq:
						best_t = t
	return best_t


func raycast_skeleton(ray_orig: Vector3, ray_dir: Vector3, max_dist: float) -> Dictionary:
	var rd := ray_dir.normalized()
	var center := _bone_world_pos(hips_bone, Vector3(0.0, 0.95, 0.0)) if skeleton != null else (global_position + Vector3(0.0, 0.95, 0.0))
	# Fast broadphase sphere reject (2.3m radius covers full outstretched / ragdolled body)
	var oc := ray_orig - center
	var b_proj := oc.dot(rd)
	var c_val := oc.length_squared() - 5.29
	if c_val > 0.0 and b_proj > 0.0:
		return {}
	var disc := b_proj * b_proj - c_val
	if disc < 0.0:
		return {}
	if (-b_proj - sqrt(disc)) > max_dist:
		return {}

	var s := _model_scale_val * (0.72 if dead else 1.0)
	var best_t := max_dist
	var best_zone := ""

	if skeleton == null:
		var t_fb := _ray_capsule_hit(ray_orig, rd, global_position + Vector3(0, 0.35, 0), global_position + Vector3(0, 1.65, 0), 0.38 * s, best_t)
		if t_fb >= 0.0:
			var hp := ray_orig + rd * t_fb
			return {"t": t_fb, "pos": hp, "zone": "HEAD" if (hp.y - global_position.y) > 1.38 else "CHEST"}
		return {}

	var p_hips := _bone_world_pos(hips_bone, Vector3(0, 0.92, 0))
	var p_spine2 := _bone_world_pos(spine2_bone, Vector3(0, 1.32, 0))
	var p_neck := _bone_world_pos(neck_bone, Vector3(0, 1.46, 0))
	var p_head := _bone_world_pos(head_bone, Vector3(0, 1.60, 0))

	# Head (skip if dismembered)
	if not dismembered.has("HEAD"):
		var head_dir := (p_head - p_neck).normalized() if p_head.distance_squared_to(p_neck) > 1e-4 else Vector3.UP
		var t_h := _ray_capsule_hit(ray_orig, rd, p_neck + head_dir * 0.04, p_head + head_dir * (0.14 * s), 0.21 * s, best_t)
		if t_h >= 0.0 and t_h < best_t:
			best_t = t_h
			best_zone = "HEAD"

	# Chest / Torso / Pelvis
	var t_c1 := _ray_capsule_hit(ray_orig, rd, p_hips, p_spine2, 0.26 * s, best_t)
	if t_c1 >= 0.0 and t_c1 < best_t:
		best_t = t_c1
		best_zone = "CHEST"
	var t_c2 := _ray_capsule_hit(ray_orig, rd, p_spine2, p_neck, 0.25 * s, best_t)
	if t_c2 >= 0.0 and t_c2 < best_t:
		best_t = t_c2
		best_zone = "CHEST"
	if variant == Variant.EXPLODER and _exploder_sac and is_instance_valid(_exploder_sac) and _exploder_sac.visible:
		var sp := _part_world_center(_exploder_sac)
		var t_sac := _ray_capsule_hit(ray_orig, rd, sp - Vector3(0, 0.08, 0), sp + Vector3(0, 0.08, 0), 0.26, best_t)
		if t_sac >= 0.0 and t_sac < best_t:
			best_t = t_sac
			best_zone = "CHEST"
	elif variant == Variant.SPITTER and _kit_parts.has("Neck__GoitreSac") and not dismembered.has("HEAD"):
		# The bile sac is the spitter's weak point: a hit there counts as a headshot
		var gp_sac := _part_world_center(_kit_parts["Neck__GoitreSac"])
		var t_g := _ray_capsule_hit(ray_orig, rd, gp_sac - Vector3(0, 0.05, 0), gp_sac + Vector3(0, 0.05, 0), 0.17, best_t)
		if t_g >= 0.0 and t_g < best_t:
			best_t = t_g
			best_zone = "HEAD"

	# Left Arm (upper always, forearm+hand unless dismembered)
	var p_la := _bone_world_pos(l_arm_bone, Vector3(-0.24, 1.32, 0))
	var p_lf := _bone_world_pos(l_forearm_bone, Vector3(-0.30, 1.08, 0.06))
	var t_la1 := _ray_capsule_hit(ray_orig, rd, p_la, p_lf, 0.135 * s, best_t)
	if t_la1 >= 0.0 and t_la1 < best_t:
		best_t = t_la1
		best_zone = "ARM_L"
	if not dismembered.has("ARM_L"):
		var p_lh := _bone_world_pos(l_hand_bone if l_hand_bone >= 0 else l_forearm_bone, Vector3(-0.34, 0.88, 0.12))
		var t_la2 := _ray_capsule_hit(ray_orig, rd, p_lf, p_lh, 0.13 * s, best_t)
		if t_la2 >= 0.0 and t_la2 < best_t:
			best_t = t_la2
			best_zone = "ARM_L"

	# Right Arm
	var p_ra := _bone_world_pos(r_arm_bone, Vector3(0.24, 1.32, 0))
	var p_rf := _bone_world_pos(r_forearm_bone, Vector3(0.30, 1.08, 0.06))
	var t_ra1 := _ray_capsule_hit(ray_orig, rd, p_ra, p_rf, 0.135 * s, best_t)
	if t_ra1 >= 0.0 and t_ra1 < best_t:
		best_t = t_ra1
		best_zone = "ARM_R"
	if not dismembered.has("ARM_R"):
		var p_rh := _bone_world_pos(r_hand_bone if r_hand_bone >= 0 else r_forearm_bone, Vector3(0.34, 0.88, 0.12))
		var t_ra2 := _ray_capsule_hit(ray_orig, rd, p_rf, p_rh, 0.13 * s, best_t)
		if t_ra2 >= 0.0 and t_ra2 < best_t:
			best_t = t_ra2
			best_zone = "ARM_R"

	# Left Leg
	var p_ll1 := _bone_world_pos(l_upleg_bone, Vector3(-0.14, 0.90, 0))
	var p_ll2 := _bone_world_pos(l_leg_bone, Vector3(-0.14, 0.48, 0))
	var t_ll1 := _ray_capsule_hit(ray_orig, rd, p_ll1, p_ll2, 0.165 * s, best_t)
	if t_ll1 >= 0.0 and t_ll1 < best_t:
		best_t = t_ll1
		best_zone = "LEG_L"
	if not dismembered.has("LEG_L"):
		var p_ll3 := _bone_world_pos(l_foot_bone if l_foot_bone >= 0 else l_leg_bone, Vector3(-0.14, 0.08, 0))
		var t_ll2 := _ray_capsule_hit(ray_orig, rd, p_ll2, p_ll3, 0.145 * s, best_t)
		if t_ll2 >= 0.0 and t_ll2 < best_t:
			best_t = t_ll2
			best_zone = "LEG_L"

	# Right Leg
	var p_rl1 := _bone_world_pos(r_upleg_bone, Vector3(0.14, 0.90, 0))
	var p_rl2 := _bone_world_pos(r_leg_bone, Vector3(0.14, 0.48, 0))
	var t_rl1 := _ray_capsule_hit(ray_orig, rd, p_rl1, p_rl2, 0.165 * s, best_t)
	if t_rl1 >= 0.0 and t_rl1 < best_t:
		best_t = t_rl1
		best_zone = "LEG_R"
	if not dismembered.has("LEG_R"):
		var p_rl3 := _bone_world_pos(r_foot_bone if r_foot_bone >= 0 else r_leg_bone, Vector3(0.14, 0.08, 0))
		var t_rl2 := _ray_capsule_hit(ray_orig, rd, p_rl2, p_rl3, 0.145 * s, best_t)
		if t_rl2 >= 0.0 and t_rl2 < best_t:
			best_t = t_rl2
			best_zone = "LEG_R"

	if best_zone == "":
		return {}
	return {"t": best_t, "pos": ray_orig + rd * best_t, "zone": best_zone}


static func raycast_all_zombies(ray_orig: Vector3, ray_dir: Vector3, max_dist: float, exclude: Array = []) -> Dictionary:
	var best_t := max_dist
	var best_res := {}
	for z in _all_zombies:
		if not is_instance_valid(z) or not z.is_inside_tree():
			continue
		if not exclude.is_empty() and exclude.has(z):
			continue
		var r := z.raycast_skeleton(ray_orig, ray_dir, best_t)
		if not r.is_empty():
			var t := float(r["t"])
			if t < best_t:
				best_t = t
				best_res = {"zombie": z, "zone": str(r["zone"]), "pos": r["pos"], "dist": t}
	return best_res


func _dismember_bone_for_zone(zone: String) -> int:
	match zone:
		"HEAD": return head_bone
		"ARM_L": return l_forearm_bone if l_forearm_bone >= 0 else l_arm_bone
		"ARM_R": return r_forearm_bone if r_forearm_bone >= 0 else r_arm_bone
		"LEG_L": return l_leg_bone if l_leg_bone >= 0 else l_upleg_bone
		"LEG_R": return r_leg_bone if r_leg_bone >= 0 else r_upleg_bone
	return -1


func _apply_dismembered_local_scales() -> void:
	if skeleton == null or dismembered.is_empty():
		return
	for z_key in dismembered.keys():
		var b := _dismember_bone_for_zone(str(z_key))
		if b >= 0:
			skeleton.set_bone_pose_scale(b, Vector3(0.001, 0.001, 0.001))


func _attach_stump_cap(parent_bone: int, child_bone: int, radius: float) -> void:
	if skeleton == null or parent_bone < 0:
		return
	if _stump_flesh_mat == null:
		_stump_flesh_mat = StandardMaterial3D.new()
		_stump_flesh_mat.albedo_color = Color(0.24, 0.014, 0.016)
		_stump_flesh_mat.roughness = 0.16
		_stump_flesh_mat.metallic_specular = 0.72
	if _stump_bone_mat == null:
		_stump_bone_mat = StandardMaterial3D.new()
		_stump_bone_mat.albedo_color = Color(0.84, 0.78, 0.66)
		_stump_bone_mat.roughness = 0.42
		_stump_bone_mat.metallic_specular = 0.35

	var ba := BoneAttachment3D.new()
	ba.name = "Stump_%d" % parent_bone
	ba.bone_name = skeleton.get_bone_name(parent_bone)
	skeleton.add_child(ba)
	ba.bone_idx = parent_bone

	var stump := Node3D.new()
	var flesh := MeshInstance3D.new()
	var fmesh := CylinderMesh.new()
	fmesh.top_radius = radius * 0.85
	fmesh.bottom_radius = radius
	fmesh.height = radius * 0.55
	fmesh.radial_segments = 10
	fmesh.material = _stump_flesh_mat
	flesh.mesh = fmesh
	flesh.layers = 8
	flesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stump.add_child(flesh)

	var bone_core := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = radius * 0.34
	bmesh.bottom_radius = radius * 0.38
	bmesh.height = radius * 0.85
	bmesh.radial_segments = 8
	bmesh.material = _stump_bone_mat
	bone_core.mesh = bmesh
	bone_core.position = Vector3(0.0, radius * 0.25, 0.0)
	bone_core.layers = 8
	bone_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stump.add_child(bone_core)

	if child_bone >= 0:
		var p_g := skeleton.get_bone_global_pose(parent_bone)
		var c_g := skeleton.get_bone_global_pose(child_bone)
		var local_c := p_g.affine_inverse() * c_g.origin
		var dir := local_c.normalized() if local_c.length_squared() > 1e-5 else Vector3.UP
		var ref_v := Vector3.FORWARD if absf(dir.y) > 0.92 else Vector3.UP
		var right_v := dir.cross(ref_v).normalized()
		var fwd_v := right_v.cross(dir).normalized()
		stump.transform = Transform3D(Basis(right_v, dir, fwd_v), local_c * 0.92)
	ba.add_child(stump)


func _dismember_zone(zone: String, hit_pos: Vector3, shot_dir: Vector3) -> bool:
	if skeleton == null or dismembered.has(zone):
		return false
	var child_b := _dismember_bone_for_zone(zone)
	if child_b < 0:
		return false
	var parent_b := skeleton.get_bone_parent(child_b)
	if zone == "HEAD" and neck_bone >= 0:
		parent_b = neck_bone
	dismembered[zone] = true
	skeleton.set_bone_pose_scale(child_b, Vector3(0.001, 0.001, 0.001))

	if zone == "HEAD":
		for bmi in _body_meshes:
			if is_instance_valid(bmi):
				var lname := str(bmi.name).to_lower()
				if lname.begins_with("skigoggle") or "winterhelmet" in lname or "helmet" in lname or (not _is_tactical and lname == "object_6"):
					bmi.visible = false

	# If dismembered during active ragdoll, remove the severed PhysicalBone3D so PhysicalBoneSimulator3D
	# stops overwriting the severed bone's 0.001 scale and stops propping the ragdoll on phantom limbs
	if _ragdoll_active:
		var idx := _pb_entries.size() - 1
		while idx >= 0:
			var entry: Dictionary = _pb_entries[idx]
			if int(entry["bone"]) == child_b:
				var pb := entry["pb"] as PhysicalBone3D
				if is_instance_valid(pb):
					pb.collision_layer = 0
					pb.collision_mask = 0
					if pb.get_parent():
						pb.get_parent().remove_child(pb)
					pb.queue_free()
				_pb_entries.remove_at(idx)
			idx -= 1
		if zone == "HEAD":
			_pb_head = null

	var rad := 0.075 * _model_scale_val if zone == "HEAD" else (0.055 * _model_scale_val if zone.begins_with("ARM") else 0.072 * _model_scale_val)
	_attach_stump_cap(parent_b, child_b, rad)

	if VFXManager.instance:
		VFXManager.instance.spawn_dismember_burst(hit_pos, shot_dir, zone == "HEAD")
	return true


func _bone_world_pos(b: int, fallback: Vector3) -> Vector3:
	if skeleton and b >= 0:
		return skeleton.to_global(skeleton.get_bone_global_pose(b).origin)
	return to_global(fallback)


func face_focus_position() -> Vector3:
	if skeleton and head_bone >= 0:
		return skeleton.to_global(skeleton.get_bone_global_pose(head_bone).origin) + Vector3.UP * 0.105
	return global_position + Vector3(0, 1.56 * _model_scale_val, 0)


func _play_horror_anim(kind: String, seek_time: float = -1.0) -> void:
	if anim_player == null:
		return
	var anims := anim_player.get_animation_list()
	if anims.is_empty():
		return
	var chosen := anims[0]
	for a in anims:
		var al := a.to_lower()
		if kind == "walk" and ("walk" in al or "run" in al):
			chosen = a
			break
		elif kind == "spot" and "spot" in al:
			chosen = a
			break
		elif kind == "skill" and "skill" in al:
			chosen = a
			break
		elif kind == "idle" and "idle" in al:
			chosen = a
			break
	if chosen == anims[0] and kind == "walk":
		for a in anims:
			if "spot" in a.to_lower():
				chosen = a
				break
	var anim_res := anim_player.get_animation(chosen)
	if anim_res:
		anim_res.loop_mode = Animation.LOOP_LINEAR
	anim_player.play(chosen)
	if seek_time >= 0.0:
		var dur := anim_res.length if anim_res and anim_res.length > 0.05 else 1.5
		anim_player.seek(fmod(seek_time, dur), true)
		if deterministic_pose:
			anim_player.pause()


func _setup_audio() -> void:
	_ensure_audio_loaded()
	growl_player = AudioStreamPlayer3D.new()
	if not _growl_streams.is_empty():
		growl_player.stream = _growl_streams[randi() % _growl_streams.size()]
	growl_player.unit_size = 4.5
	growl_player.max_distance = 24.0
	growl_player.volume_db = -4.0
	add_child(growl_player)

	impact_audio = AudioStreamPlayer3D.new()
	impact_audio.unit_size = 5.5
	impact_audio.max_distance = 24.0
	impact_audio.volume_db = -1.5
	add_child(impact_audio)


func set_cinematic_pose(phase: float, hunch: float = 0.22, head_yaw: float = 0.14) -> void:
	deterministic_pose = true
	anim_phase = phase
	var anim_kind: String = "spot" if hunch < 0.25 else "skill"
	var t_seek: float = 0.28 + fmod(abs(phase) * 0.35, 1.15)
	_play_horror_anim(anim_kind, t_seek)
	if rig_root:
		rig_root.position = Vector3(0.0, -0.05, 0.72 if hunch >= 0.25 else 0.17)
		rig_root.rotation = Vector3(hunch * 0.92, head_yaw * 0.52, sin(phase) * 0.085)
	if skeleton and hunch >= 0.25 and neck_bone >= 0:
		var neck := skeleton.get_bone_global_pose(neck_bone)
		neck.basis = Basis(Vector3.RIGHT, -0.28) * neck.basis
		skeleton.set_bone_global_pose(neck_bone, neck)
	if skeleton and hunch < 0.20 and neck_bone >= 0:
		rig_root.position += Vector3(0.015, -0.067, 0.39)
		rig_root.rotation.y -= 1.15
		var neck := skeleton.get_bone_global_pose(neck_bone)
		neck.basis = Basis(Vector3.UP, 0.27) * neck.basis
		skeleton.set_bone_global_pose(neck_bone, neck)


func enter_spawn_cue(duration := 0.95) -> void:
	state = State.SPAWNING
	state_timer = duration
	if growl_player and not _growl_streams.is_empty():
		growl_player.stream = _growl_streams[randi() % _growl_streams.size()]
		growl_player.pitch_scale = randf_range(0.84, 1.12)
		growl_player.volume_db = -5.5
		growl_player.play()


func _sample_walkable_floor(xz_pos: Vector3, start_y: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	if space == null:
		return {"hit": false, "y": start_y, "normal": Vector3.UP}
	var origin := Vector3(xz_pos.x, start_y + 1.1, xz_pos.z)
	for _attempt in range(3):
		var q := PhysicsRayQueryParameters3D.create(origin, Vector3(xz_pos.x, start_y - 5.5, xz_pos.z), 1)
		var res := space.intersect_ray(q)
		if not res:
			break
		var n: Vector3 = res["normal"]
		if n.y >= 0.45:
			return {"hit": true, "y": res["position"].y, "normal": n}
		origin.y = res["position"].y - 0.08
	return {"hit": false, "y": start_y, "normal": Vector3.UP}


func get_corpse_ground_report() -> Dictionary:
	var hips_w := skeleton.to_global(skeleton.get_bone_global_pose(hips_bone).origin) if (skeleton and hips_bone >= 0) else global_position
	var spine_w := skeleton.to_global(skeleton.get_bone_global_pose(spine2_bone).origin) if (skeleton and spine2_bone >= 0) else global_position
	var head_w := skeleton.to_global(skeleton.get_bone_global_pose(head_bone).origin) if (skeleton and head_bone >= 0) else global_position
	var f_hips := _sample_walkable_floor(hips_w, hips_w.y + 0.8)
	var f_head := _sample_walkable_floor(head_w, head_w.y + 0.8)
	var fy_h: float = f_hips["y"] if f_hips["hit"] else death_floor_y
	var fy_hd: float = f_head["y"] if f_head["hit"] else fy_h
	return {
		"hips_gap": hips_w.y - fy_h,
		"spine_gap": spine_w.y - fy_h,
		"head_gap": head_w.y - fy_hd,
		"floor_y": fy_h,
		"settled": death_settled,
		"sk_mod_freed": (sk_mod == null or not is_instance_valid(sk_mod)),
		"anim_freed": (anim_player == null or not is_instance_valid(anim_player)),
	}


func _get_game_manager() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("request_attack_token"):
			return n
		n = n.get_parent()
	return null


func _release_token() -> void:
	if has_attack_token:
		has_attack_token = false
		var gm := _get_game_manager()
		if gm:
			gm.release_attack_token(self)


func _request_token() -> bool:
	if has_attack_token:
		return true
	var gm := _get_game_manager()
	if gm:
		has_attack_token = gm.request_attack_token(self)
		return has_attack_token
	return true


func apply_burn(dur: float, dps: float = 26.0, from_stream: bool = false) -> void:
	if dead:
		return
	var was_burning := burn_timer > 0.05
	burn_timer = maxf(burn_timer, dur)
	if from_stream:
		_burn_heat_level = minf(1.35, _burn_heat_level + 0.22)
		burn_dps = maxf(burn_dps, dps * (1.0 + _burn_heat_level * 0.25))
		_apply_burn_char(_burn_char + 0.12)
	else:
		_burn_heat_level = maxf(_burn_heat_level, 0.72)
		burn_dps = maxf(burn_dps, dps)
		_apply_burn_char(_burn_char + 0.14)
	_ensure_status_light()
	_ensure_burn_fx()
	_set_burn_fx_visible(true)
	_update_burn_fx_visuals(0.0, maxf(0.85, _burn_heat_level))
	if _status_light and is_instance_valid(_status_light):
		_status_light.visible = true
		_status_light.light_color = Color(1.0, 0.42, 0.08)
		_status_light.light_energy = 2.2
	# Fire-panic stagger & burning agony shriek on ignition and periodic sustained roasting!
	if (not was_burning or (from_stream and _burn_panic_cd <= 0.0)):
		_burn_panic_cd = 0.95
		if growl_player and _death_stream and not growl_player.playing:
			growl_player.stream = _death_stream
			growl_player.pitch_scale = 0.78 if variant == Variant.BRUISER else randf_range(1.16, 1.38)
			growl_player.volume_db = -3.0
			growl_player.play()
		if variant != Variant.BRUISER and (state == State.CHASE or state == State.WINDUP or state == State.SPECIAL or state == State.GRAB):
			_drop_grab()
			_release_token()
			state = State.STAGGER
			state_timer = maxf(state_timer, 0.44 if not was_burning else 0.30)
		elif sk_mod and spine2_bone >= 0:
			sk_mod.add_spring_impulse(spine2_bone, Vector3(-1.8, randf_range(-1.2, 1.2), 0.0))


func apply_shock(dur: float) -> void:
	if dead:
		return
	shock_timer = maxf(shock_timer, dur)
	if state == State.CHASE or state == State.WINDUP or state == State.GRAB or state == State.SPECIAL:
		_drop_grab()
		_release_token()
		state = State.STAGGER
		state_timer = maxf(state_timer, 0.35)
	_ensure_status_light()


func apply_bleed(dur: float, dps: float = 22.0) -> void:
	if dead:
		return
	bleed_timer = maxf(bleed_timer, dur)
	bleed_dps = maxf(bleed_dps, dps)


func enter_crawler() -> void:
	if dead or is_crawler or variant == Variant.BRUISER:
		return
	is_crawler = true
	move_speed = minf(move_speed, 1.18)
	_lunge_speed = 2.6
	_trigger_range = 1.65
	if _body_col and is_instance_valid(_body_col) and _body_col.shape is CapsuleShape3D:
		var cap := (_body_col.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
		cap.radius = 0.34
		cap.height = 0.72
		_body_col.shape = cap
		_body_col.position = Vector3(0.0, 0.36, 0.0)
	if state == State.CHASE or state == State.WINDUP or state == State.GRAB or state == State.SPECIAL or state == State.LEAP or state == State.CHARGE:
		_drop_grab()
		_release_token()
		floor_snap_length = 0.1
		state = State.TRIPPED
		state_timer = 0.45


func _detonate_exploder(was_headshot: bool) -> void:
	if _exploder_detonated or variant != Variant.EXPLODER:
		return
	_exploder_detonated = true
	for ka in _kit_attachments:
		if is_instance_valid(ka):
			ka.queue_free()
	if not _kit_attachments.is_empty():
		_kit_attachments.clear()
		_kit_parts.clear()
		_exploder_sac = null
	if _exploder_attach and is_instance_valid(_exploder_attach):
		_exploder_attach.queue_free()
		_exploder_attach = null
		_exploder_sac = null
		_exploder_light = null
	elif _exploder_sac and is_instance_valid(_exploder_sac):
		_exploder_sac.visible = false
	if _exploder_light and is_instance_valid(_exploder_light):
		_exploder_light.visible = false
	if was_headshot:
		# Precision headshot defuses the volatile chest sac cleanly!
		if VFXManager.instance:
			VFXManager.instance.spawn_blood_impact(global_position + Vector3(0, 1.2, 0), Vector3.UP, 1.1, true, true)
		return
	# Audible heavy blast SFX on Exploder detonation!
	if impact_audio and _death_stream:
		impact_audio.stream = _death_stream
		impact_audio.pitch_scale = 0.45
		impact_audio.volume_db = 4.0
		impact_audio.play()
	if target and is_instance_valid(target) and target.has_method("_play_gun_sfx") and "_weapon_audio" in target:
		var wa: Array = target._weapon_audio
		if wa.size() > 2 and wa[2]:
			target._play_gun_sfx(wa[2], 0.52)
	var pos := global_position + Vector3(0.0, 1.0, 0.0)
	var radius := 4.8
	var space := get_world_3d().direct_space_state
	if VFXManager.instance:
		VFXManager.instance.spawn_blood_impact(pos, Vector3.UP, 2.0, true, true)
	# Blast nearby zombies (chain reactions!)
	for z_raw in _all_zombies.duplicate():
		var oz := z_raw as ZombieAI
		if oz == self or not is_instance_valid(oz) or oz.dead:
			continue
		var d := oz.global_position.distance_to(global_position)
		if d <= radius and absf(oz.global_position.y - global_position.y) <= 2.5:
			var clear := true
			if space:
				var q := PhysicsRayQueryParameters3D.create(pos, oz.global_position + Vector3(0.0, 0.9, 0.0), 1)
				clear = space.intersect_ray(q).is_empty()
			if clear:
				var falloff := clampf(1.0 - (d / radius) * 0.65, 0.35, 1.0)
				var bdir := (oz.global_position + Vector3(0, 1.0, 0) - pos).normalized()
				var res := oz.apply_shot([{"zone": "CHEST", "pos": oz.global_position + Vector3(0, 1.0, 0), "dir": bdir, "dmg": 185.0 * falloff, "dist": d}], 2)
				if bool(res.get("killed", false)) and target and is_instance_valid(target) and target.has_signal("hit_confirmed"):
					target.emit_signal("hit_confirmed", false, true)
				if not oz.dead:
					oz.velocity += bdir * (7.5 * falloff)
	# Blast nearby player (respects LOS & god_mode)
	if target and is_instance_valid(target):
		var dp := target.global_position.distance_to(global_position)
		if dp <= radius and absf(target.global_position.y - global_position.y) <= 2.5:
			var clear_p := true
			if space:
				var qp := PhysicsRayQueryParameters3D.create(pos, target.global_position + Vector3(0.0, 1.1, 0.0), 1)
				clear_p = space.intersect_ray(qp).is_empty()
			if clear_p and target.has_method("take_damage"):
				var pdmg := clampf(44.0 * (1.0 - dp / radius), 12.0, 44.0)
				_stamp_killer(); target.take_damage(pdmg, pos)
		if "trauma" in target:
			target.trauma = minf(1.0, float(target.trauma) + clampf(1.0 - dp / 12.0, 0.15, 0.75))
	if target and is_instance_valid(target) and target.has_method("_spawn_hazard_pool"):
		target._spawn_hazard_pool("frag_flash", global_position, 0.32, 3.2)


func _ensure_status_light() -> void:
	if OS.has_feature("web"):
		return
	if _status_light == null or not is_instance_valid(_status_light):
		_status_light = OmniLight3D.new()
		_status_light.position = Vector3(0.0, 1.15, 0.0)
		_status_light.omni_range = 2.6
		_status_light.shadow_enabled = false
		_status_light.light_cull_mask = 0xFFFFD
		_status_light.light_volumetric_fog_energy = 0.0
		add_child(_status_light)


func apply_knockback(imp: Vector3) -> void:
	if dead:
		return
	var horiz := Vector3(imp.x, 0.0, imp.z) * _impulse_scale
	_knockback_vel = (_knockback_vel + horiz).limit_length(10.0)


func apply_status_damage(dmg: float) -> void:
	if dead or dmg <= 0.0:
		return
	health -= dmg
	if health <= 0.0:
		var died_burning := burn_timer > 0.05
		if died_burning:
			_corpse_smolder_timer = 1.80
			_apply_burn_char(maxf(_burn_char, 0.85))
		else:
			_set_burn_fx_visible(false)
		# Corpses never keep a dynamic status OmniLight: the self-lit smolder flames carry the glow
		if _status_light and is_instance_valid(_status_light):
			_status_light.visible = false
		burn_timer = 0.0
		shock_timer = 0.0
		bleed_timer = 0.0
		dead = true
		_drop_grab()
		state = State.DEAD
		_release_token()
		if variant == Variant.EXPLODER:
			_detonate_exploder(false)
		_death_extras()
		if growl_player and _death_stream:
			growl_player.stream = _death_stream
			growl_player.pitch_scale = 0.72 if variant == Variant.BRUISER else randf_range(0.90, 1.08)
			growl_player.volume_db = -1.5
			growl_player.play()
		if target and is_instance_valid(target) and target.has_signal("hit_confirmed"):
			target.emit_signal("hit_confirmed", false, true)
		emit_signal("died", self, false)
		_enter_ragdoll(Vector3(0.0, 0.15, -1.0).normalized(), dmg, "CHEST", 2.0, 1)
		_register_corpse(self)


func _tick_status_effects(delta: float) -> void:
	if _burn_panic_cd > 0.0:
		_burn_panic_cd = maxf(0.0, _burn_panic_cd - delta)
	if dead:
		if _exploder_light and is_instance_valid(_exploder_light):
			_exploder_light.visible = false
		if _corpse_smolder_timer > 0.0 and not death_settled:
			_corpse_smolder_timer = maxf(0.0, _corpse_smolder_timer - delta)
			var sm_u := clampf(_corpse_smolder_timer / 1.80, 0.0, 1.0)
			_set_burn_fx_visible(sm_u > 0.02)
			_update_burn_fx_visuals(delta, sm_u * 0.85)
			if _status_light and is_instance_valid(_status_light):
				_status_light.visible = false
			if _corpse_smolder_timer <= 0.0:
				_set_burn_fx_visible(false)
				if _status_light and is_instance_valid(_status_light):
					_status_light.visible = false
		else:
			if _status_light and is_instance_valid(_status_light):
				_status_light.visible = false
			_set_burn_fx_visible(false)
		return
	if variant == Variant.EXPLODER and _exploder_sac and is_instance_valid(_exploder_sac):
		var pulse := 1.0 + 0.14 * sin(Time.get_ticks_msec() * 0.012)
		if _kit_parts.is_empty():
			_exploder_sac.scale = Vector3.ONE * pulse
		if _exploder_light and is_instance_valid(_exploder_light):
			_exploder_light.light_energy = (0.6 + 0.35 * sin(Time.get_ticks_msec() * 0.012)) if not _kit_parts.is_empty() else (1.6 + 0.9 * sin(Time.get_ticks_msec() * 0.012))
	var any_fx := false
	if burn_timer > 0.0:
		any_fx = true
		_ensure_burn_fx()
		_set_burn_fx_visible(true)
		_burn_heat_level = maxf(0.75, _burn_heat_level - delta * 0.25)
		var fade_b := clampf(burn_timer / 0.85, 0.25, 1.0)
		_update_burn_fx_visuals(delta, _burn_heat_level * fade_b)
		_apply_burn_char(_burn_char + delta * 0.24)
		burn_timer = maxf(0.0, burn_timer - delta)
		_burn_tick += delta
		if _burn_tick >= 0.22:
			# Damage the burn time actually elapsed, so long frames never under-burn
			var burn_dt := _burn_tick
			_burn_tick = 0.0
			apply_status_damage(burn_dps * burn_dt)
			if dead:
				return
	else:
		_burn_heat_level = 0.0
		_set_burn_fx_visible(false)
	if shock_timer > 0.0:
		any_fx = true
		shock_timer = maxf(0.0, shock_timer - delta)
		_shock_tick += delta
		if _shock_tick >= 0.45:
			_shock_tick = 0.0
			apply_status_damage(12.0)
			if dead:
				return
	if bleed_timer > 0.0:
		bleed_timer = maxf(0.0, bleed_timer - delta)
		_bleed_tick += delta
		if _bleed_tick >= 0.40:
			_bleed_tick = 0.0
			if VFXManager.instance:
				VFXManager.instance.spawn_blood_impact(global_position + Vector3(0.0, 0.45 if is_crawler else 1.05, 0.0), Vector3.DOWN, 0.45, false, false)
			apply_status_damage(bleed_dps * 0.40)
			if dead:
				return
	if _status_light and is_instance_valid(_status_light):
		_status_light.visible = any_fx and not dead
		if any_fx and not dead:
			if shock_timer > 0.0:
				_status_light.light_color = Color(0.28, 0.78, 1.0)
				_status_light.light_energy = 1.6 + 0.8 * sin(Time.get_ticks_msec() * 0.045)
			else:
				_status_light.light_color = Color(1.0, 0.40, 0.08)
				_status_light.light_energy = (1.7 + 0.75 * sin(Time.get_ticks_msec() * 0.032)) * maxf(0.75, _burn_heat_level)


func get_bone_for_zone(zone: String) -> int:
	match zone:
		"HEAD": return head_bone if head_bone >= 0 else spine2_bone
		"ARM_L": return l_arm_bone if l_arm_bone >= 0 else spine2_bone
		"ARM_R": return r_arm_bone if r_arm_bone >= 0 else spine2_bone
		"LEG_L": return l_upleg_bone if l_upleg_bone >= 0 else hips_bone
		"LEG_R": return r_upleg_bone if r_upleg_bone >= 0 else hips_bone
		_: return spine2_bone if spine2_bone >= 0 else hips_bone


func _choose_nav_dir(to_target: Vector3) -> Vector3:
	var tp := target.global_position
	var gp := global_position
	var way := tp
	var p_saw := tp.z < -66.0
	var p_morgue := tp.x < -18.45 and tp.x > -40.7 and tp.z < -40.45 and tp.z > -56.55
	var p_out := tp.z < -27.5 and tp.z >= -66.0 and not p_morgue
	var p_tun := tp.z <= -8.0 and tp.z >= -27.5
	var p_boiler := tp.x > 10.35 and tp.z > -6.6 and tp.z < 9.6
	var p_in := tp.z > -8.0 and not p_boiler
	var z_saw := gp.z < -66.0
	var z_morgue := gp.x < -18.45 and gp.x > -40.7 and gp.z < -40.45 and gp.z > -56.55
	var z_out := gp.z < -27.5 and gp.z >= -66.0 and not z_morgue
	var z_tun := gp.z <= -8.0 and gp.z >= -27.5
	var z_boiler := gp.x > 10.35 and gp.z > -6.6 and gp.z < 9.6
	var z_in := gp.z > -8.0 and not z_boiler

	# Preferred: follow the baked navigation mesh. The hand-authored route graph below is the fallback.
	var nav_wp: Variant = _nav_waypoint(tp)
	if nav_wp != null:
		way = nav_wp
	# 0. Prioritize elevated balcony / Watchtower descent FIRST before cross-wing horizontal routing!
	elif z_in and gp.y > 2.2 and (not p_in or tp.y < 1.8):
		way = Vector3(-7.55, 0.0, -1.60) if (gp.z < -2.0 or gp.x > -4.8) else Vector3(-7.55, 0.0, 3.85)
	elif z_saw and gp.y > 4.2 and (not p_saw or tp.y < 2.2):
		if gp.z < -79.5 and gp.x > -15.6:
			way = Vector3(-15.8, 7.0, -81.4)
		else:
			way = Vector3(-17.0, 3.65, -72.5)
	elif z_saw and gp.y > 2.2 and gp.y <= 4.2 and (not p_saw or tp.y < 2.0):
		way = Vector3(-18.2, 0.2, -82.2)
	# 1. Cross-zone bidirectional route graph with 2-point doorway alignment (ZERO jamb snags!)
	elif z_boiler and not p_boiler:
		way = Vector3(11.6, 0.0, 3.25) if absf(gp.z - 3.25) > 1.1 else Vector3(9.4, 0.0, 3.25)
	elif not z_boiler and p_boiler:
		if z_in:
			way = Vector3(8.6, 0.0, 3.25) if absf(gp.z - 3.25) > 0.9 else Vector3(11.4, 0.0, 3.25)
		elif z_tun:
			way = Vector3(0.0, 0.0, -7.2)
		elif z_morgue:
			way = Vector3(-17.0, 0.0, -48.5)
		elif z_saw:
			way = Vector3(8.0, 0.0, -64.0)
		else:
			way = Vector3(0.0, 0.0, -28.0)
	elif z_morgue and not p_morgue:
		way = Vector3(-19.8, 0.0, -48.5) if absf(gp.z + 48.5) > 1.2 else Vector3(-12.6, 0.0, -48.5)
	elif not z_morgue and p_morgue:
		if z_out:
			way = Vector3(-12.8, 0.0, -48.5) if ((gp.x < -13.2 and absf(gp.z + 48.5) > 1.4) or absf(gp.z + 48.5) > 1.2) else Vector3(-19.8, 0.0, -48.5)
		elif z_saw:
			way = Vector3(8.0, 0.0, -64.0)
		elif z_tun:
			way = Vector3(0.0, 0.0, -28.5)
		else:
			way = Vector3(0.0, 0.0, -9.5)
	elif z_in and (p_out or p_saw):
		way = Vector3(0.0, 0.0, -9.5)
	elif z_in and p_tun:
		way = Vector3(0.0, 0.0, -8.5)
	elif (z_out or z_saw) and (p_in or p_tun):
		if z_saw:
			way = Vector3(8.0, 0.0, -64.0)
		else:
			way = Vector3(0.0, 0.0, -28.0)
	elif z_tun and p_in:
		way = Vector3(0.0, 0.0, -7.2)
	elif z_tun and (p_out or p_saw):
		way = Vector3(0.0, 0.0, -28.5)
	elif z_out and p_saw:
		# Route cleanly through Sawmill Breach Gate opening at X = 8.0, Z = -66.0
		way = Vector3(8.0, 0.0, -68.5)
	elif z_saw and p_out:
		way = Vector3(8.0, 0.0, -63.5)
	elif z_saw and p_saw:
		var z_shed := gp.x > 11.8 and gp.x < 23.2 and gp.z > -88.2 and gp.z < -75.8
		var p_shed := tp.x > 11.8 and tp.x < 23.2 and tp.z > -88.2 and tp.z < -75.8
		if (z_shed != p_shed) and (gp.z < -86.5 or tp.z < -86.5):
			# Route around solid Sawmill Shed north wall via its West door (10.0, -82.0)!
			way = Vector3(10.0, 0.0, -82.0)
		elif gp.y < 3.0 and tp.y > 3.2 and tp.x < -7.5:
			if gp.y < 1.4 and gp.z > -80.0 and gp.x > -16.5:
				way = Vector3(-18.2, 0.0, -82.2)
			elif gp.y < 3.2:
				way = Vector3(-17.8, 3.65, -72.5)
			else:
				way = Vector3(-15.8, 7.0, -81.4)
		elif gp.y >= 3.0 and tp.y > 4.8 and tp.x < -7.5 and gp.y < 6.2:
			way = Vector3(-15.8, 7.0, -81.4)
	elif z_in and gp.y < 1.8 and tp.y > 2.4:
		way = Vector3(-7.55, 0.0, 3.85) if gp.z > 2.8 else Vector3(-7.55, 0.0, -1.60)

	var d_vec := way - gp
	d_vec.y = 0.0
	if d_vec.length_squared() < 0.04:
		d_vec = to_target
	var dir := d_vec.normalized()

	# Local zombie-to-zombie avoidance + gentle flank spread when waiting for an attack token
	var sep := Vector3.ZERO
	for oz in _all_zombies:
		if oz == self or not is_instance_valid(oz) or oz.dead:
			continue
		var diff := gp - oz.global_position
		diff.y = 0.0
		var d2 := diff.length_squared()
		if d2 > 0.001 and d2 < 1.35:
			sep += diff.normalized() * (1.15 - sqrt(d2))
	if not has_attack_token and to_target.length_squared() < 20.0 and to_target.length_squared() > 1.8:
		var side_s := 1.0 if (int(get_instance_id()) % 2 == 0) else -1.0
		sep += Vector3(-dir.z, 0.0, dir.x) * (0.42 * side_s)
	if sep.length_squared() > 0.001:
		dir = (dir + sep * 0.72).normalized()

	# Stagger whisker raycasts to every 4th physics frame
	_nav_ray_tick = (_nav_ray_tick + 1) & 3
	if _nav_ray_tick == 0:
		var space := get_world_3d().direct_space_state
		if space:
			var eye := gp + Vector3(0, 0.42 if is_crawler else 1.05, 0)
			var q_fwd := PhysicsRayQueryParameters3D.create(eye, eye + dir * 1.45, 1)
			if space.intersect_ray(q_fwd):
				var l_dir := dir.rotated(Vector3.UP, 0.78)
				var r_dir := dir.rotated(Vector3.UP, -0.78)
				var l_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye + l_dir * 1.75, 1))
				var r_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye + r_dir * 1.75, 1))
				if not l_hit and r_hit:
					dir = l_dir
				elif not r_hit and l_hit:
					dir = r_dir
				else:
					dir = l_dir if (int(get_instance_id()) % 2 == 0) else r_dir
		_cached_steer_dir = dir
	elif _cached_steer_dir.length_squared() > 0.1:
		dir = _cached_steer_dir
	return dir


func _add_pbone(sim: PhysicalBoneSimulator3D, b_idx: int, end_idx: int, radius: float, min_len: float, is_hips: bool, is_hinge: bool, cone_swing: float, mass: float) -> PhysicalBone3D:
	if skeleton == null or b_idx < 0:
		return null
	var pb := PhysicalBone3D.new()
	pb.bone_name = skeleton.get_bone_name(b_idx)
	pb.mass = mass
	pb.friction = 0.86
	pb.bounce = 0.04
	pb.collision_layer = 32
	pb.collision_mask = 1
	pb.can_sleep = true

	var b_g := skeleton.get_bone_global_pose(b_idx)
	var b_pos := b_g.origin
	var e_pos := skeleton.get_bone_global_pose(end_idx).origin if end_idx >= 0 else (b_pos + Vector3(0, min_len, 0))
	var diff := e_pos - b_pos
	var blen := maxf(diff.length(), min_len)

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(blen, radius * 2.15)
	cs.shape = cap

	var mid_skel := (b_pos + e_pos) * 0.5
	var dir_skel := diff.normalized() if diff.length_squared() > 1e-5 else Vector3.UP
	var ref_v := Vector3.FORWARD if absf(dir_skel.y) > 0.92 else Vector3.UP
	var right_v := dir_skel.cross(ref_v).normalized()
	var fwd_v := right_v.cross(dir_skel).normalized()
	var cap_in_skel := Transform3D(Basis(right_v, dir_skel, fwd_v), mid_skel)

	pb.body_offset = b_g.affine_inverse() * cap_in_skel
	pb.joint_offset = pb.body_offset.affine_inverse()
	pb.transform = cap_in_skel
	pb.add_child(cs)

	if is_hips:
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
	elif is_hinge:
		# Permissive cone constraint avoids arbitrary GLB bone-roll axis locking on knees/elbows under Jolt
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
		pb.set("joint_constraints/swing_span", 1.15)
		pb.set("joint_constraints/twist_span", 0.20)
		pb.set("joint_constraints/bias", 0.3)
		pb.set("joint_constraints/relaxation", 1.0)
	else:
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
		pb.set("joint_constraints/swing_span", cone_swing)
		pb.set("joint_constraints/twist_span", 0.45)
		pb.set("joint_constraints/bias", 0.3)
		pb.set("joint_constraints/relaxation", 1.0)

	sim.add_child(pb)
	_pb_entries.append({"pb": pb, "bone": b_idx, "inv_bo": pb.body_offset.affine_inverse()})
	return pb


func _sync_bones_from_jolt() -> void:
	if skeleton == null or _pb_entries.is_empty():
		return
	var sk_inv := skeleton.global_transform.affine_inverse()
	for entry in _pb_entries:
		var pb := entry["pb"] as PhysicalBone3D
		if is_instance_valid(pb):
			var b_idx: int = entry["bone"]
			var inv_bo: Transform3D = entry["inv_bo"]
			var b_xf := sk_inv * pb.global_transform * inv_bo
			b_xf.basis = b_xf.basis.orthonormalized()
			skeleton.set_bone_global_pose(b_idx, b_xf)
	if not dismembered.is_empty():
		for z_key in dismembered.keys():
			var b := _dismember_bone_for_zone(str(z_key))
			if b >= 0:
				var p := skeleton.get_bone_parent(b)
				var base_xf := skeleton.get_bone_global_pose(p) if p >= 0 else skeleton.get_bone_global_pose(b)
				var rest := skeleton.get_bone_rest(b)
				var joint_pos := (base_xf * rest.origin) if p >= 0 else base_xf.origin
				var joint_basis := (base_xf.basis * rest.basis).orthonormalized() if p >= 0 else base_xf.basis.orthonormalized()
				skeleton.set_bone_global_pose(b, Transform3D(joint_basis.scaled(Vector3(0.001, 0.001, 0.001)), joint_pos))


func _freeze_ragdoll_to_static() -> void:
	if not _ragdoll_active:
		return
	_ragdoll_active = false
	_active_ragdolls.erase(self)
	if skeleton:
		_sync_bones_from_jolt()
		# Bake final global poses into local poses cleanly so freeing PhysicalBoneSimulator3D keeps exact corpse pose!
		var bc := skeleton.get_bone_count()
		var globals: Array[Transform3D] = []
		globals.resize(bc)
		for b in bc:
			globals[b] = skeleton.get_bone_global_pose(b)
		if _ragdoll_sim and is_instance_valid(_ragdoll_sim):
			_ragdoll_sim.physical_bones_stop_simulation()
			_ragdoll_sim.queue_free()
		_ragdoll_sim = null
		_frozen_rest_rot.clear()
		for b in bc:
			var p := skeleton.get_bone_parent(b)
			var lp := globals[b] if p < 0 else (globals[p].affine_inverse() * globals[b])
			skeleton.set_bone_pose(b, lp)
			_frozen_rest_rot[b] = skeleton.get_bone_pose_rotation(b)
		_apply_dismembered_local_scales()
		if hips_bone >= 0 and hips_bone < bc:
			var hips_l := globals[hips_bone].origin
			var rag_box := AABB(hips_l - Vector3(1.6, 0.9, 1.6), Vector3(3.2, 2.0, 3.2))
			for bmi in _body_meshes:
				if is_instance_valid(bmi):
					bmi.custom_aabb = rag_box
	elif _ragdoll_sim and is_instance_valid(_ragdoll_sim):
		_ragdoll_sim.physical_bones_stop_simulation()
		_ragdoll_sim.queue_free()
		_ragdoll_sim = null

	_pb_entries.clear()
	_pb_hips = null
	_pb_spine2 = null
	_pb_head = null
	_pb_l_arm = null
	_pb_r_arm = null
	_pb_l_leg = null
	_pb_r_leg = null
	if sk_mod and is_instance_valid(sk_mod):
		sk_mod.queue_free()
	sk_mod = null
	if anim_player and is_instance_valid(anim_player):
		anim_player.queue_free()
	anim_player = null
	if _status_light and is_instance_valid(_status_light):
		_status_light.visible = false
	_set_burn_fx_visible(false)
	burn_timer = 0.0
	_corpse_smolder_timer = 0.0
	if _exploder_attach and is_instance_valid(_exploder_attach):
		_exploder_attach.queue_free()
		_exploder_attach = null
		_exploder_sac = null
		_exploder_light = null
	_set_shadow_casting(false)
	death_settled = true
	set_physics_process(false)
	set_process(false)


func _enter_ragdoll(shot_dir: Vector3, _total_dmg: float, primary_zone: String, hit_dist: float, weapon_idx: int) -> void:
	if _ragdoll_active or skeleton == null:
		return
	_ragdoll_active = true
	_ragdoll_age = 0.0
	_ragdoll_settle_timer = 0.0
	_ragdoll_unstuck_done = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO

	# Free AnimationPlayer and SkeletonModifier3D so Skeleton3D holds live pose cleanly for ragdoll takeover
	if sk_mod and is_instance_valid(sk_mod):
		sk_mod.queue_free()
	sk_mod = null
	if anim_player and is_instance_valid(anim_player):
		anim_player.stop()
		anim_player.queue_free()
	anim_player = null

	# Enforce active ragdoll cap (4) -> freeze oldest settled/tumbling corpse cleanly
	_active_ragdolls.append(self)
	while _active_ragdolls.size() > MAX_ACTIVE_RAGDOLLS:
		var oldest := _active_ragdolls.pop_front() as ZombieAI
		if is_instance_valid(oldest) and oldest != self:
			oldest._freeze_ragdoll_to_static()

	_pb_entries.clear()
	var sim := PhysicalBoneSimulator3D.new()
	sim.name = "RagdollSim"
	_ragdoll_sim = sim

	_pb_hips = _add_pbone(sim, hips_bone, spine2_bone, 0.16, 0.28, true, false, 0.35, 16.0)
	_pb_spine2 = _add_pbone(sim, spine2_bone, head_bone, 0.18, 0.34, false, false, 0.55, 18.0)
	_pb_head = null if dismembered.has("HEAD") else _add_pbone(sim, head_bone, -1, 0.13, 0.24, false, false, 0.65, 5.5)
	_pb_l_arm = _add_pbone(sim, l_arm_bone, l_forearm_bone, 0.075, 0.26, false, false, 1.35, 3.5)
	if not dismembered.has("ARM_L"):
		_add_pbone(sim, l_forearm_bone, l_hand_bone, 0.065, 0.24, false, true, 0.25, 2.5)
	_pb_r_arm = _add_pbone(sim, r_arm_bone, r_forearm_bone, 0.075, 0.26, false, false, 1.35, 3.5)
	if not dismembered.has("ARM_R"):
		_add_pbone(sim, r_forearm_bone, r_hand_bone, 0.065, 0.24, false, true, 0.25, 2.5)
	_pb_l_leg = _add_pbone(sim, l_upleg_bone, l_leg_bone, 0.10, 0.40, false, false, 1.05, 8.0)
	if not dismembered.has("LEG_L"):
		_add_pbone(sim, l_leg_bone, l_foot_bone, 0.085, 0.38, false, true, 0.20, 5.5)
	_pb_r_leg = _add_pbone(sim, r_upleg_bone, r_leg_bone, 0.10, 0.40, false, false, 1.05, 8.0)
	if not dismembered.has("LEG_R"):
		_add_pbone(sim, r_leg_bone, r_foot_bone, 0.085, 0.38, false, true, 0.20, 5.5)

	skeleton.add_child(sim)
	sim.active = true
	sim.physical_bones_start_simulation()

	# Stage directional ballistic impulse 1 physics tick after bodies enter Jolt world
	var sd := shot_dir.normalized()
	if sd.length_squared() < 0.01:
		sd = -global_transform.basis.z
	var sd_horiz := Vector3(sd.x, 0.0, sd.z).normalized()
	_pending_impulses.clear()
	var is_close_shotgun := ((weapon_idx == 2 or weapon_idx == 9 or weapon_idx == 11) and hit_dist < 5.8)
	var dist_att := clampf(1.25 - hit_dist * 0.11, 0.45, 1.25)

	if is_close_shotgun:
		var blast := 48.0 * dist_att * _chest_armor_mult
		if _pb_spine2: _pending_impulses[_pb_spine2] = sd_horiz * blast + Vector3(0.0, 2.8 * dist_att, 0.0)
		if _pb_hips: _pending_impulses[_pb_hips] = sd_horiz * (blast * 0.45) + Vector3(0.0, 1.2, 0.0)
		if _pb_head: _pending_impulses[_pb_head] = sd * (16.0 * dist_att) + Vector3(0.0, 1.5, 0.0)
	elif primary_zone == "HEAD":
		if _pb_head: _pending_impulses[_pb_head] = sd * 18.0 + Vector3(0.0, 3.0, 0.0)
		if _pb_spine2: _pending_impulses[_pb_spine2] = sd_horiz * 16.0 - Vector3(0.0, 6.0, 0.0)
		if _pb_hips: _pending_impulses[_pb_hips] = Vector3(0.0, -18.0, 0.0)
	elif primary_zone == "ARM_L" and _pb_l_arm:
		_pending_impulses[_pb_l_arm] = sd * 24.0
		if _pb_spine2: _pending_impulses[_pb_spine2] = sd_horiz * 32.0 * _impulse_scale
	elif primary_zone == "ARM_R" and _pb_r_arm:
		_pending_impulses[_pb_r_arm] = sd * 24.0
		if _pb_spine2: _pending_impulses[_pb_spine2] = sd_horiz * 32.0 * _impulse_scale
	elif primary_zone == "LEG_L" and _pb_l_leg:
		_pending_impulses[_pb_l_leg] = sd * 26.0
		if _pb_hips: _pending_impulses[_pb_hips] = sd_horiz * 24.0 - Vector3(0.0, 10.0, 0.0)
	elif primary_zone == "LEG_R" and _pb_r_leg:
		_pending_impulses[_pb_r_leg] = sd * 26.0
		if _pb_hips: _pending_impulses[_pb_hips] = sd_horiz * 24.0 - Vector3(0.0, 10.0, 0.0)
	else:
		if _pb_spine2: _pending_impulses[_pb_spine2] = sd_horiz * (48.0 * _impulse_scale) + Vector3(0.0, 6.0, 0.0)
		if _pb_hips: _pending_impulses[_pb_hips] = sd_horiz * (24.0 * _impulse_scale)
	_pending_impulse_frames = 1


func _physics_process(delta: float) -> void:
	if deterministic_pose:
		return

	_shadow_tick = (_shadow_tick + 1) & 3
	if _shadow_tick == (_nav_ray_tick & 3) and target and is_instance_valid(target):
		var vp := get_viewport()
		var cam := vp.get_camera_3d() if vp else null
		if cam:
			var to_z := global_position - cam.global_position
			var dist_sq := to_z.length_squared()
			var fwd := -cam.global_transform.basis.z
			var in_cone := (dist_sq < 484.0) and (dist_sq < 4.0 or to_z.normalized().dot(fwd) > 0.20)
			_set_shadow_casting(in_cone)
			# Skip skeletal animation for bodies well outside the view cone (a big CPU saving on the web build)
			if not dead and anim_player and is_instance_valid(anim_player):
				var want_anim := dist_sq < 36.0 or to_z.normalized().dot(fwd) > -0.15
				if anim_player.active != want_anim:
					anim_player.active = want_anim

	_pellet_impulse_accum = maxf(0.0, _pellet_impulse_accum - delta * 6.0)
	if pain_sfx_cd > 0.0:
		pain_sfx_cd -= delta
	if poise_immunity > 0.0:
		poise_immunity -= delta
	if poise > 0.0:
		poise = maxf(0.0, poise - delta * 38.0)
	if disabled_arm_timer > 0.0:
		disabled_arm_timer -= delta
		if disabled_arm_timer <= 0.0:
			disabled_arm_side = 0
	_tick_status_effects(delta)

	if dead:
		dead_age += delta
		if _ragdoll_active:
			_ragdoll_age += delta
			if _pending_impulse_frames > 0:
				_pending_impulse_frames -= 1
				if _pending_impulse_frames == 0:
					for pb_key in _pending_impulses.keys():
						var pb := pb_key as PhysicalBone3D
						if is_instance_valid(pb):
							pb.apply_central_impulse(_pending_impulses[pb_key])
					_pending_impulses.clear()
			if _ragdoll_age < 0.28:
				for entry in _pb_entries:
					var pb_c := entry["pb"] as PhysicalBone3D
					if is_instance_valid(pb_c) and pb_c.linear_velocity.length_squared() > 23.04:
						pb_c.linear_velocity = pb_c.linear_velocity.limit_length(4.8)

			_sync_bones_from_jolt()
			if is_instance_valid(_pb_hips) and skeleton:
				var hips_loc := skeleton.to_local(_pb_hips.global_position)
				var rag_box := AABB(hips_loc - Vector3(1.6, 1.1, 1.6), Vector3(3.2, 2.4, 3.2))
				for bmi in _body_meshes:
					if is_instance_valid(bmi):
						bmi.custom_aabb = rag_box

			if not death_landed and _ragdoll_age > 0.14 and is_instance_valid(_pb_hips):
				var hp := _pb_hips.global_position
				var fl := _sample_walkable_floor(hp, hp.y + 0.35)
				if fl["hit"] and (hp.y - float(fl["y"])) <= 0.36:
					death_landed = true
					death_floor_y = float(fl["y"])
					death_floor_normal = fl["normal"]
					if impact_audio and _body_fall_stream:
						impact_audio.stream = _body_fall_stream
						impact_audio.pitch_scale = randf_range(0.88, 1.08)
						impact_audio.play()
					if VFXManager.instance:
						VFXManager.instance.spawn_blood_pool(Vector3(hp.x, death_floor_y, hp.z), death_floor_normal)
				elif not _ragdoll_unstuck_done and _ragdoll_age > 1.8:
					_ragdoll_unstuck_done = true
					_pb_hips.apply_central_impulse(Vector3(0.0, -14.0, 3.5))

			var max_vel := 0.0
			for check_pb in [_pb_hips, _pb_spine2, _pb_head, _pb_l_leg, _pb_r_leg]:
				if is_instance_valid(check_pb):
					max_vel = maxf(max_vel, (check_pb as PhysicalBone3D).linear_velocity.length())
			if max_vel < 0.22 and death_landed and _ragdoll_age > 1.10:
				_ragdoll_settle_timer += delta
			else:
				_ragdoll_settle_timer = 0.0

			if _ragdoll_settle_timer >= 0.38 or (death_landed and _ragdoll_age >= 2.8) or _ragdoll_age >= 6.5:
				_freeze_ragdoll_to_static()
		return

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif state != State.LEAP:
		velocity.y = 0.0

	if attack_cd > 0.0:
		attack_cd -= delta
	if _special_cd > 0.0:
		_special_cd -= delta
	if _slam_cd > 0.0:
		_slam_cd -= delta
	if _enrage_timer > 0.0:
		_enrage_timer -= delta

	if state == State.SPAWNING:
		state_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if state_timer <= 0.0:
			state = State.CHASE
		return

	if _knockback_vel.length_squared() > 0.002:
		_knockback_vel = _knockback_vel.lerp(Vector3.ZERO, minf(1.0, delta * 9.5))
	else:
		_knockback_vel = Vector3.ZERO

	if state == State.KNOCKDOWN:
		_tick_knockdown(delta)
		return

	if state == State.STAGGER or state == State.TRIPPED:
		state_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, delta * 8.5) + _knockback_vel.x
		velocity.z = lerp(velocity.z, 0.0, delta * 8.5) + _knockback_vel.z
		if is_crawler:
			rig_root.rotation.x = lerp(rig_root.rotation.x, 1.28 if state == State.STAGGER else 1.44, delta * 12.0)
			rig_root.position = rig_root.position.lerp(Vector3(0.0, 0.24, -0.92), delta * 10.0)
		else:
			# Reel away from the blow: pitch along the hit's front/back component, roll along its sideways component
			var lean_x := -0.34
			if state == State.STAGGER:
				lean_x = clampf(_react_local.z * 0.32, -0.32, 0.30) if absf(_react_local.z) > 0.25 else -0.20
			rig_root.rotation.x = lerp(rig_root.rotation.x, lean_x, delta * 12.0)
			rig_root.rotation.z = lerp(rig_root.rotation.z, clampf(-_react_local.x * 0.36, -0.36, 0.36), delta * 12.0)
		move_and_slide()
		if state_timer <= 0.0:
			state = State.CHASE
		return

	growl_timer -= delta
	if growl_timer <= 0.0 and state == State.CHASE and target and global_position.distance_to(target.global_position) < 18.0:
		growl_timer = randf_range(4.2, 8.5)
		if growl_player and not _growl_streams.is_empty():
			growl_player.stream = _growl_streams[randi() % _growl_streams.size()]
			growl_player.pitch_scale = randf_range(0.66, 0.78) if variant == Variant.BRUISER else (randf_range(1.18, 1.34) if variant == Variant.SCREAMER else randf_range(0.84, 1.16))
			growl_player.volume_db = -2.0 if variant == Variant.BRUISER else -4.0
			growl_player.play()

	if target and is_instance_valid(target):
		var raw_to := target.global_position - global_position
		var dy_player := raw_to.y
		var to_xz := Vector3(raw_to.x, 0.0, raw_to.z)
		var dist := to_xz.length()
		var dir_to_player := (to_xz / dist) if dist > 0.05 else -global_transform.basis.z
		var desired_yaw := atan2(dir_to_player.x, dir_to_player.z)

		if state == State.GRAB:
			_tick_grab(delta, dir_to_player, dist, dy_player, desired_yaw)
			return

		if state == State.CHARGE:
			_tick_charge(delta, dir_to_player, dist, dy_player)
			return

		if state == State.LEAP:
			_tick_leap(delta, dist, dy_player)
			return

		if state == State.SPECIAL:
			state_timer -= delta
			if _special != "scream":
				rotation.y = lerp_angle(rotation.y, desired_yaw, delta * (2.2 if _special == "slam" else 5.0))
			velocity.x = lerp(velocity.x, 0.0, delta * 10.0) + _knockback_vel.x
			velocity.z = lerp(velocity.z, 0.0, delta * 10.0) + _knockback_vel.z
			var sp_lean := -0.26 if (_special == "spit" or _special == "scream" or _special == "scream_wind" or _special == "slam") else 0.30
			rig_root.rotation.x = lerp(rig_root.rotation.x, sp_lean, delta * 9.0)
			move_and_slide()
			if state_timer <= 0.0:
				_finish_special(dir_to_player, dist)
			return

		if state == State.WINDUP:
			state_timer -= delta
			if state_timer > 0.14:
				rotation.y = lerp_angle(rotation.y, desired_yaw, delta * 2.4)
			velocity.x = dir_to_player.x * move_speed * 0.15 + _knockback_vel.x
			velocity.z = dir_to_player.z * move_speed * 0.15 + _knockback_vel.z
			rig_root.rotation.x = lerp(rig_root.rotation.x, 1.24 if is_crawler else -0.14, delta * 10.0)
			if is_crawler:
				rig_root.position = rig_root.position.lerp(Vector3(0.0, 0.24, -0.92), delta * 10.0)
			move_and_slide()
			if state_timer <= 0.0:
				state = State.STRIKE
				state_timer = _strike_dur
				strike_hit_done = false
				strike_dir = Vector3(sin(rotation.y), 0.0, cos(rotation.y)).normalized()
			return

		if state == State.STRIKE:
			state_timer -= delta
			var prog := 1.0 - (state_timer / maxf(_strike_dur, 0.01))
			velocity.x = strike_dir.x * _lunge_speed + _knockback_vel.x
			velocity.z = strike_dir.z * _lunge_speed + _knockback_vel.z
			rig_root.rotation.x = lerp(rig_root.rotation.x, 1.46 if is_crawler else 0.22, delta * 22.0)
			if is_crawler:
				rig_root.position = rig_root.position.lerp(Vector3(0.0, 0.24, -0.92), delta * 10.0)
			move_and_slide()
			if prog >= 0.50 and not strike_hit_done:
				strike_hit_done = true
				_attempt_melee_hit(raw_to, dist, dy_player)
				if dead or state == State.GRAB:
					return
			if state_timer <= 0.0:
				state = State.RECOVER
				state_timer = _recover_dur
				attack_cd = randf_range(0.95, 1.35)
			return

		if state == State.RECOVER:
			state_timer -= delta
			velocity.x = lerp(velocity.x, 0.0, delta * 11.0) + _knockback_vel.x
			velocity.z = lerp(velocity.z, 0.0, delta * 11.0) + _knockback_vel.z
			rig_root.rotation.x = lerp(rig_root.rotation.x, 1.38 if is_crawler else 0.05, delta * 8.0)
			if is_crawler:
				rig_root.position = rig_root.position.lerp(Vector3(0.0, 0.24, -0.92), delta * 10.0)
			move_and_slide()
			if state_timer <= 0.0:
				# Follow-up swipe with the other arm while the player is still in reach
				if _combo_left > 0 and not is_crawler and dist <= _trigger_range + 0.35 and absf(dy_player) < 1.35 and has_attack_token:
					_combo_left -= 1
					state = State.WINDUP
					state_timer = _windup_dur * 0.62
					attack_kind = "swipe"
					var other_bad := dismembered.has("ARM_L") if attack_side > 0 else dismembered.has("ARM_R")
					if not other_bad:
						attack_side = -attack_side
					attack_cd = 0.0
				else:
					_release_token()
					state = State.CHASE
			return

		if dist > 0.05:
			var steer_dir := _choose_nav_dir(to_xz)
			var steer_yaw := atan2(steer_dir.x, steer_dir.z)
			var has_los := _refresh_los(delta)

			var shock_mult := 0.22 if shock_timer > 0.0 else 1.0
			var enrage_mult := 1.32 if _enrage_timer > 0.0 else 1.0
			var effective_speed := (1.15 if is_crawler else move_speed * (0.34 if crippled_side != 0 else 1.0) * enrage_mult) * shock_mult

			# Spitters hold the mid-range: back off when crowded, circle while they have a shot, otherwise close in
			var kiting := false
			if variant == Variant.SPITTER and not is_crawler and absf(dy_player) < 1.6:
				if dist < 4.6 and not is_on_wall():
					steer_dir = (-dir_to_player + Vector3(-dir_to_player.z, 0.0, dir_to_player.x) * 0.45 * _strafe_sign).normalized()
					effective_speed *= 0.92
					kiting = true
				elif dist < 11.5 and has_los:
					steer_dir = Vector3(-dir_to_player.z, 0.0, dir_to_player.x) * _strafe_sign
					effective_speed *= 0.42
					kiting = true
					_strafe_flip -= delta
					if _strafe_flip <= 0.0 or is_on_wall():
						_strafe_flip = randf_range(1.4, 3.2)
						_strafe_sign = -_strafe_sign
			rotation.y = lerp_angle(rotation.y, desired_yaw if (dist < 4.0 or kiting) else steer_yaw, delta * 6.5)

			if anim_player and not deterministic_pose:
				anim_player.speed_scale = clampf(effective_speed / 2.15, 0.45, 1.85)
			# Runner approach telegraph snarl when closing inside 7.5m
			if variant == Variant.RUNNER and not _runner_telegraphed and dist < 7.5 and has_los:
				_runner_telegraphed = true
				if growl_player and not _snarl_streams.is_empty():
					growl_player.stream = _snarl_streams[randi() % _snarl_streams.size()]
					growl_player.pitch_scale = randf_range(1.12, 1.28)
					growl_player.volume_db = 0.5
					growl_player.play()
			# Periodically tear down nearby window barricade planks
			if _barricade_cd > 0.0:
				_barricade_cd -= delta
			elif global_position.z > -4.0 and global_position.x > 7.2:
				var gm_b := _get_game_manager()
				if gm_b and gm_b.world:
					for inter in gm_b.world.interactables:
						if inter is InteractableObject and inter.kind == InteractableObject.Kind.BARRICADE and inter.plank_count > 0:
							if global_position.distance_to(inter.global_position) < 2.6:
								inter.damage_barricade()
								_barricade_cd = 2.4
								break
			# Stuck-zombie watchdog -> relocate off-camera so waves NEVER stall!
			if dist > 2.8 and not kiting:
				if _stuck_anchor == Vector3.ZERO:
					_stuck_anchor = global_position
				elif global_position.distance_to(_stuck_anchor) > 0.65:
					_stuck_anchor = global_position
					_stuck_timer = 0.0
				else:
					_stuck_timer += delta
					if _stuck_timer >= 6.0:
						_stuck_timer = 0.0
						var gm_s := _get_game_manager()
						if gm_s and gm_s.has_method("relocate_stuck_zombie"):
							gm_s.relocate_stuck_zombie(self)
							_stuck_anchor = global_position

			# --- Ranged / special openers (telegraphed, on their own cooldown) ---
			var level := absf(dy_player) < 0.9
			if not is_crawler and _special_cd <= 0.0 and has_los and shock_timer <= 0.0:
				if variant == Variant.SPITTER and dist > 3.4 and dist < 15.0:
					_start_special("spit", 0.72)
					return
				if variant == Variant.SCREAMER and dist < 15.0 and dist > 2.5:
					_start_special("scream_wind", 0.45)
					_play_voice(_snarl_streams[0] if not _snarl_streams.is_empty() else null, 1.35, 1.0)
					return
				if variant == Variant.BRUISER and level and dist > 4.6 and dist < 13.0 and _request_token():
					_start_special("charge", 0.78)
					return
				if variant == Variant.RUNNER and level and dist > 3.4 and dist < 6.4 and is_on_floor() and crippled_side == 0 and _request_token():
					_start_special("leap", 0.36)
					return

			var can_windup := dist <= _trigger_range and absf(dy_player) < 1.35 and attack_cd <= 0.0
			if can_windup and has_los and _request_token():
				if variant == Variant.BRUISER and not is_crawler and _slam_cd <= 0.0 and randf() < 0.6:
					_start_special("slam", 0.85)
					return
				state = State.WINDUP
				state_timer = _windup_dur
				var l_bad := dismembered.has("ARM_L") or (disabled_arm_timer > 0.0 and disabled_arm_side == -1)
				var r_bad := dismembered.has("ARM_R") or (disabled_arm_timer > 0.0 and disabled_arm_side == 1)
				attack_side = 1 if (l_bad and not r_bad) else (-1 if (r_bad and not l_bad) else (1 if randf() < 0.5 else -1))
				# Two-handed grab instead of a swipe when both arms work and the player is not already held
				var can_grab: bool = not is_crawler and not l_bad and not r_bad and variant != Variant.BRUISER and variant != Variant.EXPLODER and variant != Variant.SPITTER
				can_grab = can_grab and target.get("grabbed_by") == null and float(target.get("grab_immunity")) <= 0.0
				attack_kind = "grab" if (can_grab and randf() < 0.26) else "swipe"
				_combo_left = 1 if (attack_kind == "swipe" and variant != Variant.BRUISER and variant != Variant.EXPLODER and randf() < 0.45) else 0
				if attack_kind == "grab":
					state_timer = _windup_dur * 1.25
				if growl_player and not _snarl_streams.is_empty():
					growl_player.stream = _snarl_streams[randi() % _snarl_streams.size()]
					growl_player.pitch_scale = randf_range(0.92, 1.12) * (1.18 if attack_kind == "grab" else 1.0)
					growl_player.volume_db = 0.0
					growl_player.play()
			elif dist < (1.05 if is_crawler else 0.88):
				velocity.x = -dir_to_player.x * 2.4 + _knockback_vel.x
				velocity.z = -dir_to_player.z * 2.4 + _knockback_vel.z
			else:
				velocity.x = steer_dir.x * effective_speed + _knockback_vel.x
				velocity.z = steer_dir.z * effective_speed + _knockback_vel.z
				anim_phase += delta * effective_speed * (4.8 if is_crawler else 3.4)
				if is_crawler:
					rig_root.rotation.z = lerpf(rig_root.rotation.z, sin(anim_phase * 1.45) * 0.16, delta * 9.0)
					rig_root.position = rig_root.position.lerp(Vector3(0.0, 0.24 + absf(sin(anim_phase * 1.45)) * 0.04, -0.92), delta * 10.0)
				else:
					var sway_amp := 0.14 if crippled_side != 0 else 0.055
					var cripple_drop := -0.14 if crippled_side != 0 else 0.0
					rig_root.rotation.z = lerpf(rig_root.rotation.z, sin(anim_phase) * sway_amp + float(crippled_side) * 0.10, delta * 8.0)
					rig_root.position = rig_root.position.lerp(Vector3(0.0, cripple_drop + absf(sin(anim_phase * 2.0)) * 0.032, 0.0), delta * 8.0)

	move_and_slide()
	var base_lean := 0.09
	if variant == Variant.SPITTER:
		base_lean = 0.20
	elif variant == Variant.SCREAMER:
		base_lean = 0.02
	rig_root.rotation.x = lerp(rig_root.rotation.x, 1.38 if is_crawler else base_lean, delta * (10.0 if is_crawler else 6.0))


func _has_clear_los_to_player() -> bool:
	if target == null:
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var p0 := global_position + Vector3(0, 0.45 if is_crawler else 1.32, 0)
	var p1 := target.global_position + Vector3(0, 1.32, 0)
	var q := PhysicsRayQueryParameters3D.create(p0, p1, 1)
	return not space.intersect_ray(q)


func _attempt_melee_hit(raw_to: Vector3, dist_xz: float, dy_player: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if absf(dy_player) > 1.25 or dist_xz > (1.85 if variant == Variant.EXPLODER else 1.72):
		return
	var z_fwd := Vector3(sin(rotation.y), 0.0, cos(rotation.y)).normalized()
	var to_p_xz := Vector3(raw_to.x, 0.0, raw_to.z)
	if to_p_xz.length_squared() > 0.01 and z_fwd.dot(to_p_xz.normalized()) < 0.42:
		return
	if not _has_clear_los_to_player():
		return
	if variant == Variant.EXPLODER:
		# Exploder suicide-detonates on close contact!
		health = 0.0
		dead = true
		state = State.DEAD
		burn_timer = 0.0
		_corpse_smolder_timer = 0.0
		if _status_light and is_instance_valid(_status_light):
			_status_light.visible = false
		_set_burn_fx_visible(false)
		_release_token()
		_detonate_exploder(false)
		_enter_ragdoll(-z_fwd, 120.0, "CHEST", 1.5, 2)
		_register_corpse(self)
		emit_signal("died", self, false)
		return
	if attack_kind == "grab" and target.has_method("begin_grab") and target.begin_grab(self):
		state = State.GRAB
		_grab_time = 0.0
		_grab_bite_t = 0.45
		_play_voice(_sfx_grab, randf_range(0.95, 1.1), 2.0)
		if target.has_method("take_damage"):
			_stamp_killer(); target.take_damage(6.0, global_position + Vector3(0, 1.35, 0))
		return
	if target.has_method("take_damage"):
		_stamp_killer(); target.take_damage(attack_damage, global_position + Vector3(0, 0.55 if is_crawler else 1.35, 0))
	if is_crawler and target.has_method("apply_slow"):
		target.apply_slow(0.55, 1.3)


func _pb_for_zone(zone: String) -> PhysicalBone3D:
	match zone:
		"HEAD": return _pb_head if is_instance_valid(_pb_head) else _pb_spine2
		"ARM_L": return _pb_l_arm if is_instance_valid(_pb_l_arm) else _pb_spine2
		"ARM_R": return _pb_r_arm if is_instance_valid(_pb_r_arm) else _pb_spine2
		"LEG_L": return _pb_l_leg if is_instance_valid(_pb_l_leg) else _pb_hips
		"LEG_R": return _pb_r_leg if is_instance_valid(_pb_r_leg) else _pb_hips
		_: return _pb_spine2 if is_instance_valid(_pb_spine2) else _pb_hips


func apply_shot(hits: Array, weapon_idx: int) -> Dictionary:
	if hits.is_empty():
		return {"headshot": false, "killed": false, "corpse_hit": dead, "dismembered": false, "zone": "CHEST"}

	if dead:
		var any_hs_d := false
		var primary_z_d := str(hits[0].get("zone", "CHEST"))
		var avg_pos_d := Vector3.ZERO
		var avg_dir_d := Vector3.ZERO
		var total_d := 0.0
		var did_dismember_d := false
		var zone_pos_d: Dictionary = {}
		for h_raw in hits:
			var h: Dictionary = h_raw
			var hz := str(h.get("zone", "CHEST"))
			var amt := float(h.get("dmg", 30.0))
			var hp_d: Vector3 = h.get("pos", global_position)
			avg_pos_d += hp_d
			avg_dir_d += (h.get("dir", Vector3.FORWARD) as Vector3).normalized()
			total_d += amt
			if not zone_pos_d.has(hz):
				zone_pos_d[hz] = hp_d
			if hz == "HEAD":
				any_hs_d = true
				primary_z_d = "HEAD"
				head_dmg += amt
			elif hz == "ARM_L":
				l_arm_dmg += amt
			elif hz == "ARM_R":
				r_arm_dmg += amt
			elif hz == "LEG_L":
				left_leg_dmg += amt
			elif hz == "LEG_R":
				right_leg_dmg += amt
		avg_pos_d /= float(hits.size())
		var hd_d := (avg_dir_d / float(hits.size())).normalized()
		if hd_d.length_squared() < 0.01:
			hd_d = Vector3.FORWARD

		# Post-mortem dismemberment across ALL hit zones in the blast (handles multi-pellet shotguns!)
		for hz_k in zone_pos_d.keys():
			var hz_s := str(hz_k)
			var z_pt: Vector3 = zone_pos_d[hz_k]
			if hz_s == "HEAD" and not dismembered.has("HEAD") and (head_dmg >= 32.0 or weapon_idx == 2 or weapon_idx == 9 or weapon_idx == 11):
				did_dismember_d = _dismember_zone("HEAD", z_pt, hd_d) or did_dismember_d
			elif hz_s == "ARM_L" and not dismembered.has("ARM_L") and l_arm_dmg >= 38.0:
				did_dismember_d = _dismember_zone("ARM_L", z_pt, hd_d) or did_dismember_d
			elif hz_s == "ARM_R" and not dismembered.has("ARM_R") and r_arm_dmg >= 38.0:
				did_dismember_d = _dismember_zone("ARM_R", z_pt, hd_d) or did_dismember_d
			elif hz_s == "LEG_L" and not dismembered.has("LEG_L") and left_leg_dmg >= 42.0:
				did_dismember_d = _dismember_zone("LEG_L", z_pt, hd_d) or did_dismember_d
			elif hz_s == "LEG_R" and not dismembered.has("LEG_R") and right_leg_dmg >= 42.0:
				did_dismember_d = _dismember_zone("LEG_R", z_pt, hd_d) or did_dismember_d

		if not did_dismember_d and VFXManager.instance:
			var b_int := clampf(0.80 + 0.14 * float(hits.size()), 0.80, 1.45)
			VFXManager.instance.spawn_blood_impact(avg_pos_d, hd_d, b_int, any_hs_d, true)

		# Kick active ragdoll bone physically so shooting dying/ragdolling bodies jolts them!
		if _ragdoll_active:
			var pb := _pb_for_zone(primary_z_d)
			if is_instance_valid(pb):
				var imp := (24.0 if (weapon_idx == 2 or weapon_idx == 6 or weapon_idx == 7 or weapon_idx == 9 or weapon_idx == 11 or weapon_idx == 13 or weapon_idx == 14) else 11.0) * clampf(total_d / 35.0, 0.7, 2.2)
				pb.apply_central_impulse(hd_d * imp + Vector3(0.0, 2.2, 0.0))
				_ragdoll_settle_timer = 0.0
		elif skeleton:
			# Frozen corpse: bounded bone twitch around _frozen_rest_rot (never twists unboundedly!)
			var tb := head_bone if primary_z_d == "HEAD" else (l_arm_bone if primary_z_d == "ARM_L" else (r_arm_bone if primary_z_d == "ARM_R" else (l_upleg_bone if primary_z_d == "LEG_L" else (r_upleg_bone if primary_z_d == "LEG_R" else spine2_bone))))
			if tb >= 0 and not (primary_z_d == "HEAD" and dismembered.has("HEAD")):
				var base_r: Quaternion = _frozen_rest_rot.get(tb, skeleton.get_bone_pose_rotation(tb))
				var twitch := Quaternion(Vector3.RIGHT, randf_range(-0.18, 0.18)) * Quaternion(Vector3.UP, randf_range(-0.14, 0.14))
				skeleton.set_bone_pose_rotation(tb, twitch * base_r)
				_apply_dismembered_local_scales()

		return {"headshot": any_hs_d, "killed": false, "corpse_hit": true, "dismembered": did_dismember_d, "zone": primary_z_d}

	var any_hs := false
	var total_dmg := 0.0
	var primary_zone := str(hits[0].get("zone", "CHEST"))
	var avg_pos := Vector3.ZERO
	var avg_dir := Vector3.ZERO
	var min_dist := 99.0
	var rig_basis := global_transform.basis
	var inv_rig := rig_basis.inverse()
	var zone_pos: Dictionary = {}
	var armor_block := false
	var sever := float((hits[0] as Dictionary).get("sever", 1.0))

	for h_raw in hits:
		var h: Dictionary = h_raw
		var hz := str(h.get("zone", "CHEST"))
		var amt := float(h.get("dmg", 30.0))
		var hpos: Vector3 = h.get("pos", face_focus_position())
		var hdir: Vector3 = h.get("dir", -rig_basis.z)
		var hdist := float(h.get("dist", 6.0))
		min_dist = minf(min_dist, hdist)
		avg_pos += hpos
		avg_dir += hdir.normalized()
		if not zone_pos.has(hz):
			zone_pos[hz] = hpos

		var zone_mult := 1.0
		var poise_mult := 1.0
		match hz:
			"HEAD":
				if _helmet_hp > 0.0:
					# Riot helmet: the visor soaks the hit until it shatters; energy beyond what it can absorb
					# carries straight through as a headshot (a massive round never just bounces off)
					var soak_k := 2.2 if weapon_idx == 3 else 1.0
					var absorbed := minf(amt, _helmet_hp / soak_k)
					var overflow := amt - absorbed
					_helmet_hp -= amt * soak_k
					armor_block = true
					if _helmet_hp <= 0.0:
						_break_visor(hpos, hdir)
					if overflow > 0.001 and amt > 0.0:
						zone_mult = (absorbed * 0.22 + overflow * 2.65) / amt
						poise_mult = (absorbed * 0.9 + overflow * 2.4) / amt
						any_hs = true
						primary_zone = "HEAD"
						head_dmg += overflow
					else:
						zone_mult = 0.22
						poise_mult = 0.9
				else:
					zone_mult = 2.65
					poise_mult = 2.4
					any_hs = true
					primary_zone = "HEAD"
					head_dmg += amt
			"CHEST":
				zone_mult = 1.0 * _chest_armor_mult
				poise_mult = 1.0 * _chest_armor_mult
				if _chest_armor_mult < 0.7:
					armor_block = true
			"ARM_L", "ARM_R":
				zone_mult = 0.72
				poise_mult = 0.75
			"LEG_L", "LEG_R":
				zone_mult = 0.68
				poise_mult = 1.25

		var fd := amt * zone_mult
		total_dmg += fd
		health -= fd
		poise += amt * poise_mult

		if hz == "LEG_L":
			left_leg_dmg += amt
			if left_leg_dmg >= max_health * 0.28: crippled_side = -1
		elif hz == "LEG_R":
			right_leg_dmg += amt
			if right_leg_dmg >= max_health * 0.28: crippled_side = 1
		elif hz == "ARM_L":
			l_arm_dmg += amt
			if not dismembered.has("ARM_R"):
				disabled_arm_side = -1; disabled_arm_timer = 0.65
		elif hz == "ARM_R":
			r_arm_dmg += amt
			if not dismembered.has("ARM_L"):
				disabled_arm_side = 1; disabled_arm_timer = 0.65

	avg_pos /= float(hits.size())
	var hd_world := (avg_dir / float(hits.size())).normalized()
	if hd_world.length_squared() < 0.01:
		hd_world = -rig_basis.z
	var hd_char := (inv_rig * hd_world).normalized()
	_react_local = hd_char
	if armor_block and impact_audio and _sfx_armor and not impact_audio.playing:
		impact_audio.stream = _sfx_armor
		impact_audio.pitch_scale = randf_range(0.9, 1.15)
		impact_audio.volume_db = -1.0
		impact_audio.play()
	var bend_axis := Vector3.UP.cross(hd_char)
	if bend_axis.length_squared() < 0.002:
		bend_axis = Vector3.RIGHT
	bend_axis = bend_axis.normalized()

	# Weapon-weighted dismemberment & genuine leg-crippling (bow pins without popping heads on weak shots; leg hits cripple instead of instant-killing at 48 dmg!)
	var is_shotgun := (weapon_idx == 2 or weapon_idx == 9 or weapon_idx == 11)
	var is_heavy_melee := (weapon_idx == 3)
	var is_bow := (weapon_idx == 4)
	var head_thresh := 125.0 if is_bow else (44.0 if (is_shotgun and min_dist < 6.5) else 62.0)
	if is_heavy_melee:
		# Edged weapons take heads off; blunt ones only crush a skull on the killing blow
		head_thresh = 62.0 / maxf(sever, 0.05)
	var limb_thresh := 42.0 if (is_shotgun and min_dist < 6.5) else ((58.0 / maxf(sever, 0.05)) if is_heavy_melee else 78.0)
	var did_dismember := false
	for hz_k in zone_pos.keys():
		var hz_s := str(hz_k)
		var z_pt: Vector3 = zone_pos[hz_k]
		if hz_s == "HEAD" and not dismembered.has("HEAD") and ((health <= 0.0 and not is_bow) or head_dmg >= head_thresh):
			did_dismember = _dismember_zone("HEAD", z_pt, hd_world) or did_dismember
			health = 0.0
		elif hz_s == "ARM_L" and not dismembered.has("ARM_L") and l_arm_dmg >= limb_thresh:
			did_dismember = _dismember_zone("ARM_L", z_pt, hd_world) or did_dismember
			poise = poise_max
		elif hz_s == "ARM_R" and not dismembered.has("ARM_R") and r_arm_dmg >= limb_thresh:
			did_dismember = _dismember_zone("ARM_R", z_pt, hd_world) or did_dismember
			poise = poise_max
		elif hz_s == "LEG_L" and not dismembered.has("LEG_L") and left_leg_dmg >= limb_thresh and (is_shotgun or is_heavy_melee or left_leg_dmg >= max_health * 0.42 or health <= 0.0):
			did_dismember = _dismember_zone("LEG_L", z_pt, hd_world) or did_dismember
			crippled_side = -1
			if health > 0.0:
				enter_crawler()
		elif hz_s == "LEG_R" and not dismembered.has("LEG_R") and right_leg_dmg >= limb_thresh and (is_shotgun or is_heavy_melee or right_leg_dmg >= max_health * 0.42 or health <= 0.0):
			did_dismember = _dismember_zone("LEG_R", z_pt, hd_world) or did_dismember
			crippled_side = 1
			if health > 0.0:
				enter_crawler()
	if not is_crawler and health > 0.0 and (left_leg_dmg >= max_health * 0.45 or right_leg_dmg >= max_health * 0.45):
		enter_crawler()
	if dismembered.has("ARM_L") and dismembered.has("ARM_R"):
		health = 0.0

	var imp_allow := clampf(1.35 - _pellet_impulse_accum, 0.25, 1.0)
	_pellet_impulse_accum += 0.45
	var k := _impulse_scale * imp_allow * clampf(1.0 + 0.14 * float(hits.size() - 1), 1.0, 1.65)

	if sk_mod and sk_mod is ZombieSkeletonModifier:
		var sm := sk_mod as ZombieSkeletonModifier
		var offset_right := (inv_rig * (avg_pos - face_focus_position())).x
		match primary_zone:
			"HEAD":
				sm.add_spring_impulse(head_bone, bend_axis * (13.5 * k) + Vector3(0.0, -signf(offset_right) * 8.5 * k, 0.0))
				sm.add_spring_impulse(neck_bone, bend_axis * (7.5 * k))
				sm.add_spring_impulse(spine2_bone, bend_axis * (4.2 * k))
			"ARM_L":
				sm.add_spring_impulse(l_arm_bone, Vector3(-11.0 * k, 9.5 * k, -6.5 * k))
				sm.add_spring_impulse(l_forearm_bone, Vector3(-7.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(spine2_bone, Vector3(-2.5 * k, -9.5 * k, 3.0 * k))
				sm.add_spring_impulse(spine1_bone, Vector3(-1.5 * k, -4.5 * k, 0.0))
			"ARM_R":
				sm.add_spring_impulse(r_arm_bone, Vector3(-11.0 * k, -9.5 * k, 6.5 * k))
				sm.add_spring_impulse(r_forearm_bone, Vector3(-7.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(spine2_bone, Vector3(-2.5 * k, 9.5 * k, -3.0 * k))
				sm.add_spring_impulse(spine1_bone, Vector3(-1.5 * k, 4.5 * k, 0.0))
			"LEG_L":
				sm.add_spring_impulse(l_upleg_bone, bend_axis * (6.5 * k) + Vector3(-5.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(l_leg_bone, Vector3(13.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(spine_bone, Vector3(4.5 * k, -3.0 * k, -4.5 * k))
				sm.add_pelvis_drop(-2.2 * k)
			"LEG_R":
				sm.add_spring_impulse(r_upleg_bone, bend_axis * (6.5 * k) + Vector3(-5.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(r_leg_bone, Vector3(13.0 * k, 0.0, 0.0))
				sm.add_spring_impulse(spine_bone, Vector3(4.5 * k, 3.0 * k, 4.5 * k))
				sm.add_pelvis_drop(-2.2 * k)
			_:
				sm.add_spring_impulse(spine2_bone, bend_axis * (10.5 * k))
				sm.add_spring_impulse(spine1_bone, bend_axis * (6.2 * k))
				sm.add_spring_impulse(head_bone, -bend_axis * (5.5 * k))
				sm.add_pelvis_drop(-0.8 * k)

	# ONE aggregated pooled blood spray burst per hit zombie per blast (skip duplicate if dismember burst already fired)
	if not did_dismember and VFXManager.instance:
		var b_int := clampf(0.85 + 0.16 * float(hits.size()), 0.85, 1.55)
		VFXManager.instance.spawn_blood_impact(avg_pos, hd_world, b_int, any_hs, min_dist < 5.5)

	if health <= 0.0:
		var was_on_fire := burn_timer > 0.05
		dead = true
		_drop_grab()
		state = State.DEAD
		burn_timer = 0.0
		_release_token()
		if was_on_fire:
			_corpse_smolder_timer = 1.65
			_apply_burn_char(maxf(_burn_char, 0.78))
		else:
			_set_burn_fx_visible(false)
		if _status_light and is_instance_valid(_status_light):
			_status_light.visible = false
		if variant == Variant.EXPLODER:
			_detonate_exploder(any_hs and not zone_pos.has("CHEST"))
		_death_extras()
		if growl_player and _death_stream:
			growl_player.stream = _death_stream
			growl_player.pitch_scale = randf_range(0.90, 1.08)
			growl_player.volume_db = -1.5
			growl_player.play()
		_enter_ragdoll(hd_world, total_dmg, primary_zone, min_dist, weapon_idx)
		_register_corpse(self)
		emit_signal("died", self, any_hs)
		return {"headshot": any_hs, "killed": true, "corpse_hit": false, "dismembered": did_dismember, "zone": primary_zone, "armor_block": false}

	var runner_tripped: bool = ((variant == Variant.RUNNER or variant == Variant.SCREAMER) and primary_zone.begins_with("LEG") and state == State.CHASE and poise > 18.0)
	# A leap shot out of the air is a knockdown; a charging bruiser shrugs off anything but a poise break
	if state == State.LEAP and (any_hs or poise >= poise_max * 0.5):
		floor_snap_length = 0.1
		velocity = Vector3(0.0, minf(velocity.y, 0.0), 0.0)
		state = State.CHASE
		enter_knockdown(hd_world)
	elif (any_hs or poise >= poise_max or runner_tripped) and poise_immunity <= 0.0 and state != State.KNOCKDOWN and not (state == State.CHARGE and poise < poise_max):
		poise = 0.0
		poise_immunity = 0.60
		_drop_grab()
		_release_token()
		var heavy_break := weapon_idx == 3 or weapon_idx == 2 or weapon_idx == 9 or weapon_idx == 11
		state = State.TRIPPED if runner_tripped else State.STAGGER
		state_timer = 0.65 if runner_tripped else (0.34 if any_hs else (0.42 if heavy_break else 0.24))

	velocity += hd_world * ((3.0 if any_hs else 1.5) * _impulse_scale)
	if pain_sfx_cd <= 0.0 and growl_player and not _pain_streams.is_empty():
		pain_sfx_cd = 0.38
		growl_player.stream = _pain_streams[randi() % _pain_streams.size()]
		growl_player.pitch_scale = randf_range(0.90, 1.14)
		growl_player.volume_db = -2.5
		growl_player.play()
	return {"headshot": any_hs, "killed": false, "corpse_hit": false, "dismembered": did_dismember, "zone": primary_zone, "armor_block": armor_block}


func take_damage(amount: float, hit_pos: Vector3, hit_dir: Vector3, hit_info = "CHEST") -> bool:
	var hit_zone := "CHEST"
	if hit_info is bool:
		hit_zone = "HEAD" if hit_info else "CHEST"
	else:
		hit_zone = str(hit_info)
	var dist := global_position.distance_to(target.global_position) if (target and is_instance_valid(target)) else 5.0
	var res := apply_shot([{"zone": hit_zone, "pos": hit_pos, "dir": hit_dir, "dmg": amount, "dist": dist}], 0)
	return bool(res.get("killed", false))


static func _register_corpse(z: ZombieAI) -> void:
	_corpses.append(z)
	while _corpses.size() > MAX_CORPSES:
		var old := _corpses.pop_front() as ZombieAI
		if is_instance_valid(old):
			_active_ragdolls.erase(old)
			old.queue_free()


# ---------------------------------------------------------------------------------------------------------------------
# Variant kits, armour, special attacks, knockdowns and navigation
# ---------------------------------------------------------------------------------------------------------------------

const KIT_PATHS := {
	Variant.SPITTER: "res://assets/models/zombie_kit_spitter.glb",
	Variant.SCREAMER: "res://assets/models/zombie_kit_screamer.glb",
	Variant.BRUISER: "res://assets/models/zombie_kit_riot.glb",
	Variant.EXPLODER: "res://assets/models/zombie_kit_bloater.glb",
}
const VARIANT_LABELS := {
	Variant.TACTICAL_SOLDIER: "SOLDIER", Variant.ASYLUM_PATIENT: "PATIENT", Variant.RUNNER: "RUNNER",
	Variant.BRUISER: "RIOT BRUISER", Variant.EXPLODER: "BLOATER", Variant.SPITTER: "SPITTER", Variant.SCREAMER: "SCREAMER",
}

static var _kit_cache: Dictionary = {}
static var _sfx_spit: AudioStream = null
static var _sfx_scream: AudioStream = null
static var _sfx_grab: AudioStream = null
static var _sfx_pounce: AudioStream = null
static var _sfx_armor: AudioStream = null
static var _sfx_visor: AudioStream = null
static var _extra_audio_loaded: bool = false


static func _ensure_extra_audio() -> void:
	if _extra_audio_loaded:
		return
	_extra_audio_loaded = true
	var spec := {"zombie_spit": "_sfx_spit", "zombie_scream": "_sfx_scream", "zombie_grab": "_sfx_grab", "zombie_pounce": "_sfx_pounce", "armor_clank": "_sfx_armor", "visor_break": "_sfx_visor"}
	for k: String in spec.keys():
		var p := "res://assets/audio/%s.wav" % k
		if ResourceLoader.exists(p):
			match str(spec[k]):
				"_sfx_spit": _sfx_spit = load(p)
				"_sfx_scream": _sfx_scream = load(p)
				"_sfx_grab": _sfx_grab = load(p)
				"_sfx_pounce": _sfx_pounce = load(p)
				"_sfx_armor": _sfx_armor = load(p)
				"_sfx_visor": _sfx_visor = load(p)


static func preload_kits() -> void:
	_ensure_extra_audio()
	for v in KIT_PATHS.keys():
		var kp: String = KIT_PATHS[v]
		if not _kit_cache.has(v) and ResourceLoader.exists(kp):
			_kit_cache[v] = load(kp)


func variant_label() -> String:
	return str(VARIANT_LABELS.get(variant, "INFECTED"))


func _bone_for_kit_key(key: String) -> int:
	if skeleton == null:
		return -1
	var want := ("mixamorig_%s_" % key).to_lower()
	for b in skeleton.get_bone_count():
		if skeleton.get_bone_name(b).to_lower().begins_with(want):
			return b
	return -1


func _attach_variant_kit() -> bool:
	# Kit meshes are authored in rest-pose character space and named "<BoneKey>__<Part>"; each is parented rigidly to its bone.
	if skeleton == null or not KIT_PATHS.has(variant):
		return false
	if not _kit_cache.has(variant):
		var kp: String = KIT_PATHS[variant]
		if not ResourceLoader.exists(kp):
			return false
		_kit_cache[variant] = load(kp)
	var packed := _kit_cache[variant] as PackedScene
	if packed == null:
		return false
	var kit := packed.instantiate() as Node3D
	if kit == null:
		return false
	var sk_rel := _accum_local_to(skeleton, rig_root)
	var sk_rel_inv := sk_rel.affine_inverse()
	var attach_by_bone := {}
	var any := false
	for mn in kit.find_children("*", "MeshInstance3D", true, false):
		var mi := mn as MeshInstance3D
		var nm := str(mi.name)
		var sep := nm.find("__")
		if sep <= 0 or mi.mesh == null:
			continue
		var b := _bone_for_kit_key(nm.substr(0, sep))
		if b < 0:
			continue
		var node_xf := _accum_local_to(mi, kit)
		node_xf = kit.transform * node_xf
		if not attach_by_bone.has(b):
			var ba := BoneAttachment3D.new()
			ba.name = "Kit_%d" % b
			ba.bone_name = skeleton.get_bone_name(b)
			skeleton.add_child(ba)
			ba.bone_idx = b
			attach_by_bone[b] = ba
			_kit_attachments.append(ba)
		var holder := attach_by_bone[b] as BoneAttachment3D
		var piece := MeshInstance3D.new()
		piece.name = nm
		piece.mesh = mi.mesh
		piece.transform = skeleton.get_bone_global_rest(b).affine_inverse() * sk_rel_inv * node_xf
		piece.layers = 8
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.extra_cull_margin = 0.6
		for si in mi.mesh.get_surface_count():
			var src := mi.get_active_material(si)
			var tuned := _tune_kit_material(src)
			if tuned != src:
				piece.set_surface_override_material(si, tuned)
		holder.add_child(piece)
		_kit_parts[nm] = piece
		any = true
	kit.free()
	return any


static var _kit_mat_cache: Dictionary = {}

static func _tune_kit_material(mat: Material) -> Material:
	if mat == null or not (mat is BaseMaterial3D):
		return mat
	var key := mat.get_instance_id()
	if _kit_mat_cache.has(key):
		return _kit_mat_cache[key]
	var src := mat as BaseMaterial3D
	var nm := str(src.resource_name).to_lower()
	var out: Material = mat
	if "bilesac" in nm or "pustulesac" in nm:
		# Stretched fluid-filled tissue: wet clearcoat, light bleeding through the membrane, a faint inner glow
		var m := src.duplicate() as BaseMaterial3D
		m.roughness = minf(m.roughness, 0.30)
		m.clearcoat_enabled = true
		m.clearcoat = 0.75
		m.clearcoat_roughness = 0.12
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.7
		m.emission_enabled = true
		m.emission = Color(0.42, 0.50, 0.06) if "bile" in nm else Color(0.95, 0.40, 0.05)
		# Only a hint of light through the membrane; it should read as wet tissue, not a lamp
		m.emission_energy_multiplier = 0.07 if "bile" in nm else 0.16
		if m.albedo_texture:
			m.emission_texture = m.albedo_texture
		out = m
	elif "riotvisor" in nm:
		var v := src.duplicate() as BaseMaterial3D
		v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Scuffed smoked polycarbonate: the face shows through, the cracks and smears stay readable
		v.albedo_color = Color(0.46, 0.50, 0.53, 0.40)
		v.roughness = minf(v.roughness, 0.16)
		v.cull_mode = BaseMaterial3D.CULL_DISABLED
		out = v
	elif "riotarmor" in nm or "riotfabric" in nm:
		var ra := src.duplicate() as BaseMaterial3D
		ra.albedo_color = Color(0.62, 0.63, 0.66)
		out = ra
	_kit_mat_cache[key] = out
	return out


func _setup_variant_identity() -> void:
	# Runs once the body exists: bolt on the Blender-built kit for this variant and set up armour / tints / posture.
	_ensure_extra_audio()
	var has_kit := _attach_variant_kit()
	match variant:
		Variant.BRUISER:
			if has_kit:
				# The riot helmet replaces the tactical body's own headgear
				for bmi in _body_meshes:
					if is_instance_valid(bmi):
						var ln := str(bmi.name).to_lower()
						if ln.begins_with("skigoggle") or "winterhelmet" in ln or "helmet" in ln:
							bmi.visible = false
				_helmet_hp = 150.0
		Variant.EXPLODER:
			if has_kit:
				for pn in _kit_parts.keys():
					if _exploder_sac == null:
						_exploder_sac = _kit_parts[pn]
			else:
				_attach_exploder_visuals()
			if _exploder_sac != null and not OS.has_feature("web") and _exploder_light == null:
				var el := OmniLight3D.new()
				el.light_color = Color(1.0, 0.44, 0.08)
				el.light_energy = 0.7
				el.omni_range = 2.4
				el.shadow_enabled = false
				el.light_cull_mask = 0xFFFFD
				el.light_volumetric_fog_energy = 0.0
				el.position = Vector3(0.0, 1.25, 0.25)
				add_child(el)
				_exploder_light = el


func _part_world_center(n: Node3D) -> Vector3:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return n.global_transform * (n as MeshInstance3D).mesh.get_aabb().get_center()
	return n.global_position


func _death_extras() -> void:
	# Variant-specific pay-offs at the moment of death
	if variant == Variant.SPITTER and CombatDirector.instance:
		CombatDirector.instance.spawn_acid_pool(global_position, 1.15, 3.2)
	elif variant == Variant.SCREAMER and _special == "scream_wind" and target and is_instance_valid(target) and target.has_signal("score_event"):
		target.emit_signal("score_event", "SILENCED", 75)
	if _exploder_light and is_instance_valid(_exploder_light):
		_exploder_light.visible = false
	for ka in _kit_attachments:
		# The goitre and pustules burst with the body; armour and restraints stay on the corpse
		if is_instance_valid(ka) and (variant == Variant.SPITTER and str(ka.bone_name).to_lower().contains("neck")):
			ka.visible = false


func _stamp_killer() -> void:
	if target and is_instance_valid(target) and "last_hit_by" in target:
		target.last_hit_by = "CRAWLER" if is_crawler else variant_label()


func _drop_grab() -> void:
	if target and is_instance_valid(target) and target.get("grabbed_by") == self:
		target.end_grab(false)


func on_grab_broken(push_dir: Vector3) -> void:
	if dead:
		return
	_release_token()
	state = State.STAGGER
	state_timer = 0.95
	poise = 0.0
	poise_immunity = 0.3
	attack_cd = 2.2
	_react_local = Vector3(0.0, 0.0, -1.0)
	apply_knockback(Vector3(push_dir.x, 0.0, push_dir.z).normalized() * 6.5)


func enrage(dur: float) -> void:
	if dead:
		return
	_enrage_timer = maxf(_enrage_timer, dur)


func _can_be_knocked_down() -> bool:
	return not dead and not is_crawler and variant != Variant.BRUISER and state != State.KNOCKDOWN and state != State.SPAWNING


func enter_knockdown(world_dir: Vector3) -> bool:
	if not _can_be_knocked_down():
		return false
	_drop_grab()
	_release_token()
	state = State.KNOCKDOWN
	_knock_t = 0.0
	var loc := global_transform.basis.inverse() * world_dir
	_knock_face_down = loc.z > 0.25
	_knock_dur_down = randf_range(0.75, 1.15) * (0.8 if _is_tactical else 1.0)
	collision_layer = 0
	if anim_player and is_instance_valid(anim_player):
		anim_player.speed_scale = 0.10
	if sk_mod and sk_mod is ZombieSkeletonModifier:
		var sm := sk_mod as ZombieSkeletonModifier
		sm.add_spring_impulse(l_arm_bone, Vector3(-9.0, 6.0, -5.0))
		sm.add_spring_impulse(r_arm_bone, Vector3(-9.0, -6.0, 5.0))
		sm.add_spring_impulse(head_bone, Vector3(-8.0, 0.0, 0.0))
	return true


func _tick_knockdown(delta: float) -> void:
	const FALL := 0.34
	const GETUP := 0.80
	_knock_t += delta
	var t_down_end := FALL + _knock_dur_down
	var lay := 1.0
	if _knock_t < FALL:
		var f := _knock_t / FALL
		lay = f * f
	elif _knock_t > t_down_end:
		lay = 1.0 - smoothstep(0.0, 1.0, (_knock_t - t_down_end) / GETUP)
	_knock_lay = lay
	var sgn := 1.0 if _knock_face_down else -1.0
	rig_root.rotation.x = sgn * 1.46 * lay
	rig_root.rotation.z = sin(_knock_t * 7.0) * 0.09 * lay * (1.0 - lay) * 4.0
	rig_root.position = Vector3(0.0, 0.14 * lay, 0.0)
	velocity.x = lerpf(velocity.x, 0.0, delta * 7.0) + _knockback_vel.x
	velocity.z = lerpf(velocity.z, 0.0, delta * 7.0) + _knockback_vel.z
	move_and_slide()
	if _knock_t >= t_down_end + GETUP:
		state = State.CHASE
		_knock_lay = 0.0
		collision_layer = 4
		rig_root.position = Vector3.ZERO
		poise = 0.0
		poise_immunity = 0.8
		attack_cd = maxf(attack_cd, 0.5)


func is_downed() -> bool:
	return state == State.KNOCKDOWN and not dead


func _break_visor(hit_pos: Vector3, hit_dir: Vector3) -> void:
	_helmet_hp = 0.0
	if _kit_parts.has("Head__Visor") and is_instance_valid(_kit_parts["Head__Visor"]):
		(_kit_parts["Head__Visor"] as Node3D).visible = false
	if impact_audio and _sfx_visor:
		impact_audio.stream = _sfx_visor
		impact_audio.pitch_scale = randf_range(0.94, 1.06)
		impact_audio.volume_db = 2.0
		impact_audio.play()
	if VFXManager.instance:
		VFXManager.instance.spawn_tinted_mist(hit_pos, -hit_dir, Color(0.80, 0.86, 0.90, 0.55), 0.8)
	if state != State.KNOCKDOWN and state != State.CHARGE:
		_release_token()
		_drop_grab()
		state = State.STAGGER
		state_timer = 0.7
		_react_local = Vector3(0.0, 0.0, -1.0)


func _break_chest_armor() -> void:
	if _chest_armor_mult >= 1.0:
		return
	_chest_armor_mult = 1.0
	_armor_broken = true
	for pn in ["Spine2__ChestPlate"]:
		if _kit_parts.has(pn) and is_instance_valid(_kit_parts[pn]):
			(_kit_parts[pn] as Node3D).visible = false
	if impact_audio and _sfx_armor:
		impact_audio.stream = _sfx_armor
		impact_audio.pitch_scale = 0.72
		impact_audio.volume_db = 3.0
		impact_audio.play()


func _play_voice(stream: AudioStream, pitch := 1.0, vol_db := 0.0) -> void:
	if growl_player and stream:
		growl_player.stream = stream
		growl_player.pitch_scale = pitch
		growl_player.volume_db = vol_db
		growl_player.play()


func apply_melee(hit: Dictionary, opts: Dictionary) -> Dictionary:
	# Melee entry point: adds poise, armour interaction, knockback, knockdown and bleed on top of the shared damage model.
	if dead:
		return apply_shot([hit], 3)
	var zone := str(hit.get("zone", "CHEST"))
	var ap := float(opts.get("armor_pierce", 1.0))
	var armoured_chest := zone == "CHEST" and _chest_armor_mult < 1.0
	if ap > 1.0 and armoured_chest:
		hit["dmg"] = float(hit["dmg"]) * ap
	if bool(opts.get("armor_break", false)) and bool(opts.get("heavy", false)) and armoured_chest:
		_break_chest_armor()
	if state == State.KNOCKDOWN:
		hit["dmg"] = float(hit["dmg"]) * 2.5 # ground execution
	hit["sever"] = float(opts.get("sever", 1.0))
	var is_shove := bool(opts.get("shove", false))
	poise += float(opts.get("poise", 40.0)) * (0.35 if (variant == Variant.BRUISER and is_shove) else 1.0)
	var res := apply_shot([hit], 3)
	if dead:
		return res
	var kb: Vector3 = opts.get("kb", Vector3.ZERO)
	apply_knockback(kb)
	var b_dps := float(opts.get("bleed_dps", 0.0))
	if b_dps > 0.0:
		apply_bleed(float(opts.get("bleed_dur", 3.0)), b_dps)
	if bool(opts.get("knockdown", false)) and enter_knockdown(kb if kb.length_squared() > 0.01 else Vector3.FORWARD):
		res["knockdown"] = true
	elif is_shove and state != State.KNOCKDOWN and variant != Variant.BRUISER:
		_drop_grab()
		_release_token()
		state = State.STAGGER
		state_timer = maxf(state_timer, 0.62)
		_react_local = Vector3(0.0, 0.0, -1.0)
	return res


func _mouth_position() -> Vector3:
	return face_focus_position() + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.16


func _refresh_los(delta: float) -> bool:
	_los_timer -= delta
	if _los_timer <= 0.0:
		_los_timer = 0.22 + float(int(get_instance_id()) % 7) * 0.012
		_los_ok = _has_clear_los_to_player()
	return _los_ok


func _start_special(kind: String, dur: float) -> void:
	state = State.SPECIAL
	_special = kind
	_special_dur = dur
	state_timer = dur
	match kind:
		"slam":
			_play_voice(_snarl_streams[0] if not _snarl_streams.is_empty() else null, 0.58, 3.0)
		"charge":
			_play_voice(_growl_streams[0] if not _growl_streams.is_empty() else null, 0.55, 4.0)
		"leap":
			_play_voice(_sfx_pounce, randf_range(0.95, 1.1), 1.0)
		"spit":
			_play_voice(_sfx_spit, randf_range(0.92, 1.08), 2.0)
		"scream":
			_play_voice(_sfx_scream, randf_range(0.94, 1.04), 6.0)


func _finish_special(dir_to_player: Vector3, dist: float) -> void:
	var kind := _special
	_special = ""
	match kind:
		"slam":
			var fwd := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
			if CombatDirector.instance:
				CombatDirector.instance.ground_slam(global_position + fwd * 1.25, 3.0, attack_damage * 0.95, self)
			state = State.RECOVER
			state_timer = 1.05
			attack_cd = 1.5
			_slam_cd = 5.0
		"charge":
			state = State.CHARGE
			state_timer = 1.5
			strike_dir = dir_to_player
			strike_hit_done = false
			_special_cd = 9.0
		"leap":
			state = State.LEAP
			state_timer = 0.95
			strike_hit_done = false
			strike_dir = dir_to_player
			var sp := clampf(dist / 0.52, 5.0, 10.5)
			velocity = Vector3(dir_to_player.x * sp, 5.0, dir_to_player.z * sp)
			floor_snap_length = 0.0
			_special_cd = 5.5
			move_and_slide()
		"spit":
			if CombatDirector.instance and target and is_instance_valid(target):
				var lead := Vector3.ZERO
				if target is CharacterBody3D:
					var tv := (target as CharacterBody3D).velocity
					lead = Vector3(tv.x, 0.0, tv.z) * clampf(dist / 12.5, 0.4, 1.05) * 0.8
				CombatDirector.instance.spawn_acid_glob(_mouth_position(), target.global_position + lead + Vector3(0.0, 0.35, 0.0))
			state = State.RECOVER
			state_timer = 0.55
			_special_cd = randf_range(3.0, 4.4)
		"scream_wind":
			_start_special("scream", 1.25)
			if CombatDirector.instance:
				CombatDirector.instance.scream_wave(global_position, self)
			var gm := _get_game_manager()
			if gm and gm.has_method("spawn_reinforcements"):
				gm.spawn_reinforcements(self, 2)
		"scream":
			state = State.CHASE
			_special_cd = 15.0
			enrage(6.0)
		_:
			state = State.CHASE


func _tick_grab(delta: float, dir_to_player: Vector3, dist: float, dy_player: float, desired_yaw: float) -> void:
	_grab_time += delta
	rotation.y = lerp_angle(rotation.y, desired_yaw, delta * 10.0)
	var close_in := 1.4 if dist > 0.95 else 0.0
	velocity.x = dir_to_player.x * close_in + _knockback_vel.x
	velocity.z = dir_to_player.z * close_in + _knockback_vel.z
	rig_root.rotation.x = lerpf(rig_root.rotation.x, 0.30, delta * 12.0)
	move_and_slide()
	var held: bool = target != null and is_instance_valid(target) and target.get("grabbed_by") == self
	if not held or dist > 2.3 or absf(dy_player) > 1.4 or _grab_time > 5.0:
		_drop_grab()
		_release_token()
		state = State.RECOVER
		state_timer = _recover_dur
		attack_cd = 1.6
		return
	_grab_bite_t -= delta
	if _grab_bite_t <= 0.0:
		_grab_bite_t = 0.78
		if target.has_method("take_damage"):
			_stamp_killer(); target.take_damage(9.0, face_focus_position())
		if not _snarl_streams.is_empty():
			_play_voice(_snarl_streams[randi() % _snarl_streams.size()], randf_range(1.05, 1.2), 1.0)


func _tick_charge(delta: float, dir_to_player: Vector3, dist: float, dy_player: float) -> void:
	state_timer -= delta
	velocity.x = strike_dir.x * 8.0
	velocity.z = strike_dir.z * 8.0
	rotation.y = lerp_angle(rotation.y, atan2(strike_dir.x, strike_dir.z), delta * 14.0)
	rig_root.rotation.x = lerpf(rig_root.rotation.x, 0.36, delta * 9.0)
	if anim_player and is_instance_valid(anim_player):
		anim_player.speed_scale = 1.85
	anim_phase += delta * 14.0
	move_and_slide()
	if not strike_hit_done and dist < 1.6 and absf(dy_player) < 1.3 and strike_dir.dot(dir_to_player) > 0.25:
		strike_hit_done = true
		if target.has_method("take_damage"):
			_stamp_killer(); target.take_damage(attack_damage * 0.9, global_position + Vector3(0.0, 1.3, 0.0))
		if target.has_method("apply_external_impulse"):
			target.apply_external_impulse(strike_dir * 9.0 + Vector3(0.0, 3.0, 0.0))
		state = State.RECOVER
		state_timer = 0.95
		attack_cd = 1.6
		return
	# Missing the player and ploughing into a wall leaves the bruiser stunned and open
	for ci in range(get_slide_collision_count()):
		var col := get_slide_collision(ci)
		if col.get_collider() is StaticBody3D and col.get_normal().dot(strike_dir) < -0.6 and state_timer < 1.35:
			_release_token()
			state = State.STAGGER
			state_timer = 1.6
			_react_local = Vector3(0.0, 0.0, -1.0)
			if CombatDirector.instance:
				CombatDirector.instance._play_at(CombatDirector.instance._sfx_slam, global_position, 1.25, -2.0)
			return
	if state_timer <= 0.0:
		state = State.RECOVER
		state_timer = 0.7
		attack_cd = 1.2


func _tick_leap(delta: float, dist: float, dy_player: float) -> void:
	state_timer -= delta
	rig_root.rotation.x = lerpf(rig_root.rotation.x, 0.55, delta * 10.0)
	move_and_slide()
	if not strike_hit_done and dist < 1.35 and absf(dy_player) < 1.5:
		strike_hit_done = true
		if target.has_method("take_damage"):
			_stamp_killer(); target.take_damage(attack_damage, global_position + Vector3(0.0, 1.2, 0.0))
		if randf() < 0.55 and target.has_method("begin_grab") and target.begin_grab(self):
			floor_snap_length = 0.1
			state = State.GRAB
			_grab_time = 0.0
			_grab_bite_t = 0.6
			_play_voice(_sfx_grab, randf_range(0.95, 1.1), 2.0)
			return
	if (is_on_floor() and state_timer < 0.72) or state_timer <= 0.0:
		floor_snap_length = 0.1
		state = State.RECOVER
		state_timer = 0.5
		attack_cd = 1.2


func _nav_waypoint(tp: Vector3) -> Variant:
	# Baked navigation mesh path following. Returns the next corner to walk at, or null when no usable path exists.
	if not nav_enabled or not nav_map.is_valid():
		return null
	_nav_timer -= get_physics_process_delta_time()
	var gp := global_position
	if _nav_timer <= 0.0 or _nav_path.is_empty() or _nav_goal.distance_squared_to(tp) > 2.25:
		_nav_timer = 0.32 + float(int(get_instance_id()) % 9) * 0.02
		_nav_goal = tp
		_nav_path = NavigationServer3D.map_get_path(nav_map, gp, tp, true)
		_nav_idx = 0
	if _nav_path.size() < 2:
		return null
	# The path must actually end near the player, otherwise the target is off-mesh (e.g. standing on a prop)
	var last := _nav_path[_nav_path.size() - 1]
	if Vector2(last.x - tp.x, last.z - tp.z).length() > 2.2 or absf(last.y - tp.y) > 1.6:
		return null
	while _nav_idx < _nav_path.size() - 1:
		var c := _nav_path[_nav_idx]
		if Vector2(c.x - gp.x, c.z - gp.z).length() < 0.55 and absf(c.y - gp.y) < 1.2:
			_nav_idx += 1
		else:
			break
	return _nav_path[_nav_idx]
