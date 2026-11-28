extends StaticBody3D
class_name InteractableObject

enum Kind { GENERATOR, MYSTERY_BOX, BARRICADE, MELEE_PICKUP, BREACH_GATE, UPGRADE_BENCH, AMMO_CRATE, WALL_BUY, TRAP, PERK }
enum BoxState { IDLE, CYCLING, READY_CLAIM, CLOSING }
enum TrapState { READY, ACTIVE, COOLDOWN }

@export var kind: Kind = Kind.GENERATOR
@export var prompt_text: String = "Press [E] to Interact"
@export var cost: int = 0
@export var melee_id: String = "fire_axe"
@export var weapon_label: String = "FIRE AXE"
@export var weapon_index: int = 2
@export var ammo_cost: int = 250
@export var gate_id: String = "sawmill"
@export var gate_label: String = "SAWMILL BREACH GATE"
@export var gate_open_yaw: float = 1.65
@export var trap_type: String = "flame" # "flame", "electric", "sawblade"
@export var trap_label: String = "FLAME JET TRAP"
@export var trap_duration: float = 16.0
@export var trap_cooldown: float = 32.0
@export var trap_zone_center: Vector3 = Vector3.ZERO
@export var trap_zone_half_extents: Vector3 = Vector3(2.4, 2.2, 2.4)
@export var perk_id: String = "vitality"
@export var perk_label: String = "VITALITY SERUM"
var lamp_mat: StandardMaterial3D = null
var drawer_node: Node3D = null
var _drawer_t: float = 0.0
# Perk cabinet status-lamp omni is kept gentle so it never washes out the enamel at close range
const PERK_GLOW_SCALE := 0.55

const PERK_INFO := {
	"vitality": "+50 MAXIMUM HEALTH FOR THIS RUN",
	"quickhands": "35% FASTER RELOADS AND WEAPON HANDLING",
	"adrenal": "+25% MELEE DAMAGE  ·  FASTER SPRINT  ·  HEALTH RECOVERS SOONER",
}

var activated: bool = false
var plank_count: int = 4
var max_planks: int = 4
var lid_node: Node3D = null
var glow_light: OmniLight3D = null
var plank_nodes: Array[Node3D] = []
var cooldown: float = 0.0
var gate_visual: Node3D = null
var trap_state: TrapState = TrapState.READY
var trap_timer: float = 0.0
var _trap_tick: float = 0.0
var trap_fx_node: Node3D = null
var trap_blade_node: Node3D = null
var trap_light: OmniLight3D = null
var _trap_owner_player: Node = null

# Explicit Mystery Box state machine (IDLE -> CYCLING -> READY_CLAIM -> CLOSING)
var box_state: BoxState = BoxState.IDLE
var _box_timer: float = 0.0
var _cycle_tick: float = 0.0
var _preview_holder: Node3D = null
var _rolled_weapon_idx: int = -1
var _rolled_lucky_mod: String = ""
var _rolled_owner_player: Node = null
var _box_audio: AudioStreamPlayer3D = null

static var _sfx_latch: AudioStream = null
static var _sfx_cycle: AudioStream = null
static var _sfx_reveal: AudioStream = null
static var _preview_scene_cache: Dictionary = {}

const BOX_POOL := [1, 2, 7, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
const BOX_CYCLE_DUR := 1.45
const BOX_CLAIM_DUR := 6.50
const BOX_CLOSE_DUR := 0.55

signal generator_activated
signal mystery_box_rolled(weapon_index: int, weapon_name: String)
signal barricade_rebuilt(planks: int)
signal gate_opened
signal weapon_upgraded(weapon_index: int, weapon_name: String)


func _ready() -> void:
	if _sfx_latch == null and ResourceLoader.exists("res://assets/audio/reload_bolt.wav"):
		_sfx_latch = load("res://assets/audio/reload_bolt.wav")
	if _sfx_cycle == null and ResourceLoader.exists("res://assets/audio/reload_shell_in.wav"):
		_sfx_cycle = load("res://assets/audio/reload_shell_in.wav")
	if _sfx_reveal == null and ResourceLoader.exists("res://assets/audio/reload_mag_in.wav"):
		_sfx_reveal = load("res://assets/audio/reload_mag_in.wav")
	if kind == Kind.MYSTERY_BOX or kind == Kind.UPGRADE_BENCH or kind == Kind.BREACH_GATE or kind == Kind.WALL_BUY or kind == Kind.TRAP or kind == Kind.PERK:
		_box_audio = AudioStreamPlayer3D.new()
		_box_audio.unit_size = 5.0
		_box_audio.max_distance = 22.0
		_box_audio.volume_db = -2.0
		_box_audio.position = Vector3(0.0, 0.75, 0.0)
		add_child(_box_audio)


var _perk_powered: bool = false
var _drawer_rest_z: float = 0.0


func set_powered(on: bool) -> void:
	_perk_powered = on


func _play_spatial(stream: AudioStream, pitch := 1.0) -> void:
	if _box_audio and stream:
		_box_audio.stream = stream
		_box_audio.pitch_scale = pitch
		_box_audio.play()


func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = maxf(0.0, cooldown - delta)

	if kind == Kind.MYSTERY_BOX:
		_update_mystery_box(delta)
	elif kind == Kind.UPGRADE_BENCH and glow_light:
		var pulse := 0.15 * sin(Time.get_ticks_msec() * 0.005)
		glow_light.light_energy = (2.2 + pulse) if activated else 0.25
	elif kind == Kind.TRAP:
		_update_trap(delta)
	elif kind == Kind.PERK:
		# Lamp: red while unpowered, pulsing green when ready, steady amber once taken
		var col := Color(1.0, 0.22, 0.12)
		var e := 0.5
		if activated:
			col = Color(1.0, 0.70, 0.22)
			e = 0.7
		elif _perk_powered:
			col = Color(0.30, 1.0, 0.45)
			e = 1.0 + 0.3 * sin(Time.get_ticks_msec() * 0.005)
		if glow_light and is_instance_valid(glow_light):
			glow_light.light_color = col
			glow_light.light_energy = e * PERK_GLOW_SCALE
		if lamp_mat:
			lamp_mat.emission = col
			lamp_mat.emission_energy_multiplier = e * 1.6
		if _drawer_t > 0.0 and drawer_node and is_instance_valid(drawer_node):
			_drawer_t = maxf(0.0, _drawer_t - delta)
			drawer_node.position.z = _drawer_rest_z + sin(clampf(_drawer_t / 1.2, 0.0, 1.0) * PI) * 0.16


func _update_trap(delta: float) -> void:
	if trap_state == TrapState.ACTIVE:
		trap_timer -= delta
		var msec := float(Time.get_ticks_msec()) * 0.001
		if trap_blade_node and is_instance_valid(trap_blade_node):
			trap_blade_node.rotation.z += delta * 24.0
		if trap_fx_node and is_instance_valid(trap_fx_node):
			trap_fx_node.visible = true
			if trap_type == "electric":
				# High-voltage plasma arc jitter
				for ci in range(trap_fx_node.get_child_count()):
					var ch := trap_fx_node.get_child(ci)
					if ch is MeshInstance3D:
						(ch as Node3D).scale.x = 0.7 + 0.6 * absf(sin(msec * 52.0 + float(ci) * 2.1))
		if trap_light and is_instance_valid(trap_light):
			var flk := 0.78 + 0.36 * sin(msec * (42.0 if trap_type == "electric" else 25.0))
			trap_light.visible = true
			trap_light.light_energy = (5.5 if trap_type == "sawblade" else 7.2) * flk
		_trap_tick += delta
		if _trap_tick >= 0.22:
			_trap_tick = 0.0
			_apply_trap_damage_tick()
		if trap_timer <= 0.0:
			trap_state = TrapState.COOLDOWN
			trap_timer = trap_cooldown
			if trap_fx_node and is_instance_valid(trap_fx_node):
				trap_fx_node.visible = false
			if trap_light and is_instance_valid(trap_light):
				trap_light.visible = false
				trap_light.light_energy = 0.0
			if glow_light and is_instance_valid(glow_light):
				glow_light.light_color = Color(1.0, 0.62, 0.12)
				glow_light.light_energy = 0.45
			_play_spatial(_sfx_latch, 0.72)
	elif trap_state == TrapState.COOLDOWN:
		trap_timer -= delta
		if glow_light and is_instance_valid(glow_light):
			glow_light.light_color = Color(1.0, 0.62, 0.12)
			glow_light.light_energy = 0.45
		if trap_timer <= 0.0:
			trap_state = TrapState.READY
			trap_timer = 0.0
			if glow_light and is_instance_valid(glow_light):
				glow_light.light_color = Color(0.28, 0.96, 0.42)
				glow_light.light_energy = 1.4
	else:
		if glow_light and is_instance_valid(glow_light):
			glow_light.light_color = Color(0.28, 0.96, 0.42)
			glow_light.light_energy = 1.15 + 0.2 * sin(Time.get_ticks_msec() * 0.004)


func _apply_trap_damage_tick() -> void:
	if _trap_owner_player and is_instance_valid(_trap_owner_player) and _trap_owner_player.dead:
		return
	var c := trap_fx_node.global_position if (trap_fx_node and is_instance_valid(trap_fx_node)) else trap_zone_center
	var he := trap_zone_half_extents
	var any_hit := false
	for z_raw in ZombieAI._all_zombies.duplicate():
		var z := z_raw as ZombieAI
		if not is_instance_valid(z) or z.dead:
			continue
		var d := (z.global_position + Vector3(0.0, 0.9, 0.0)) - c
		if absf(d.x) <= he.x and absf(d.y) <= he.y and absf(d.z) <= he.z:
			any_hit = true
			if trap_type == "flame":
				z.apply_burn(4.0, 52.0)
				z.apply_status_damage(34.0)
			elif trap_type == "electric":
				z.apply_shock(2.4)
				z.apply_status_damage(42.0)
			else:
				# Spinning Sawmill Blade shreds & dismembers zombies!
				var hit_zone := "HEAD" if randf() < 0.45 else "CHEST"
				var res := z.apply_shot([{"zone": hit_zone, "pos": z.global_position + Vector3(0.0, 1.15, 0.0), "dir": Vector3.FORWARD, "dmg": 92.0, "dist": 1.2}], 3)
				if _trap_owner_player and is_instance_valid(_trap_owner_player) and not bool(res.get("corpse_hit", false)):
					_trap_owner_player.emit_signal("hit_confirmed", bool(res.get("headshot", false)), bool(res.get("killed", false)))
	if any_hit and _box_audio and _sfx_cycle:
		_box_audio.global_position = c
		_play_spatial(_sfx_cycle, 1.45 if trap_type == "electric" else (0.72 if trap_type == "flame" else 1.18))
	# Reckless player hazard check (respects god_mode inside take_damage!)
	if _trap_owner_player and is_instance_valid(_trap_owner_player) and not _trap_owner_player.dead:
		var pd: Vector3 = (_trap_owner_player.global_position + Vector3(0.0, 0.9, 0.0)) - c
		if absf(pd.x) <= he.x * 0.82 and absf(pd.y) <= he.y and absf(pd.z) <= he.z * 0.82:
			if _trap_owner_player.has_method("take_damage"):
				_trap_owner_player.take_damage(12.0, c)


func _update_mystery_box(delta: float) -> void:
	var lid_target := 0.0
	if box_state == BoxState.CYCLING:
		lid_target = -1.25
		_box_timer -= delta
		_cycle_tick -= delta
		if _cycle_tick <= 0.0:
			_cycle_tick = 0.14
			var fake_idx: int = BOX_POOL[randi() % BOX_POOL.size()]
			_set_box_preview(fake_idx, 0.56)
			_play_spatial(_sfx_cycle, randf_range(1.18, 1.38))
		if _preview_holder and is_instance_valid(_preview_holder):
			_preview_holder.rotation.y += delta * 5.2
			_preview_holder.position.y = lerpf(_preview_holder.position.y, 0.92, delta * 5.0)
		if _box_timer <= 0.0:
			box_state = BoxState.READY_CLAIM
			_box_timer = BOX_CLAIM_DUR
			_set_box_preview(_rolled_weapon_idx, 0.96)
			_play_spatial(_sfx_reveal, 0.92)
	elif box_state == BoxState.READY_CLAIM:
		lid_target = -1.25
		_box_timer -= delta
		if _preview_holder and is_instance_valid(_preview_holder):
			_preview_holder.rotation.y += delta * 1.8
			_preview_holder.position.y = 0.96 + sin(Time.get_ticks_msec() * 0.004) * 0.045
		if _box_timer <= 0.0:
			# Auto-secure ONLY when an open slot exists (or already owned for ammo top-off) — NEVER overwrite a capped loadout!
			if _rolled_owner_player and is_instance_valid(_rolled_owner_player) and not _rolled_owner_player.dead and _rolled_weapon_idx >= 0:
				var p_ref := _rolled_owner_player
				var is_spec := bool(PlayerBodycam.WEAPONS[_rolled_weapon_idx].get("is_special", false))
				var can_auto: bool = (is_spec and int(p_ref.special_slot) < 0) or (not is_spec and (p_ref.firearm_slots.size() < PlayerBodycam.MAX_FIREARM_SLOTS or p_ref.firearm_slots.has(_rolled_weapon_idx)))
				if can_auto and p_ref.has_method("unlock_weapon_silent"):
					p_ref.unlock_weapon_silent(_rolled_weapon_idx)
					if _rolled_lucky_mod != "" and p_ref.has_method("add_attachment"):
						p_ref.add_attachment(_rolled_weapon_idx, _rolled_lucky_mod)
			_begin_box_close()
	elif box_state == BoxState.CLOSING:
		lid_target = 0.0
		_box_timer -= delta
		if _preview_holder and is_instance_valid(_preview_holder):
			_preview_holder.position.y = lerpf(_preview_holder.position.y, 0.35, delta * 9.0)
			_preview_holder.scale = _preview_holder.scale.lerp(Vector3.ONE * 0.05, delta * 10.0)
		if _box_timer <= 0.0:
			if _preview_holder and is_instance_valid(_preview_holder):
				_preview_holder.queue_free()
				_preview_holder = null
			_rolled_weapon_idx = -1
			_rolled_owner_player = null
			box_state = BoxState.IDLE

	if lid_node and is_instance_valid(lid_node):
		lid_node.rotation.x = lerpf(lid_node.rotation.x, lid_target, delta * (7.5 if lid_target < -0.1 else 6.0))
	if glow_light and is_instance_valid(glow_light):
		var base_e := 2.8 if box_state == BoxState.READY_CLAIM else (2.2 if box_state == BoxState.CYCLING else 0.95)
		glow_light.light_energy = base_e + sin(Time.get_ticks_msec() * 0.0045) * 0.22


func _begin_box_close() -> void:
	box_state = BoxState.CLOSING
	_box_timer = BOX_CLOSE_DUR
	_rolled_lucky_mod = ""
	_play_spatial(_sfx_latch, 0.78)


func reset_state() -> void:
	activated = false
	cooldown = 0.0
	box_state = BoxState.IDLE
	_box_timer = 0.0
	_rolled_weapon_idx = -1
	_rolled_lucky_mod = ""
	_rolled_owner_player = null
	if _preview_holder and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
		_preview_holder = null
	if lid_node and is_instance_valid(lid_node):
		lid_node.rotation.x = 0.0
	if kind == Kind.MELEE_PICKUP:
		visible = true
		collision_layer = 16
	elif kind == Kind.BREACH_GATE:
		visible = true
		collision_layer = 1 | 16
		if gate_visual and is_instance_valid(gate_visual):
			gate_visual.rotation.y = 0.0
	elif kind == Kind.BARRICADE:
		plank_count = max_planks
		_refresh_planks()
	elif kind == Kind.GENERATOR and glow_light:
		glow_light.light_color = Color(1.0, 0.25, 0.15)
		glow_light.light_energy = 1.1
	elif kind == Kind.UPGRADE_BENCH and glow_light:
		glow_light.light_color = Color(0.24, 0.88, 1.0)
		glow_light.light_energy = 0.25
	elif kind == Kind.PERK:
		_perk_powered = false
	elif kind == Kind.TRAP:
		trap_state = TrapState.READY
		trap_timer = 0.0
		_trap_tick = 0.0
		_trap_owner_player = null
		if trap_fx_node and is_instance_valid(trap_fx_node):
			trap_fx_node.visible = false
		if trap_light and is_instance_valid(trap_light):
			trap_light.visible = false
			trap_light.light_energy = 0.0
		if glow_light and is_instance_valid(glow_light):
			glow_light.light_color = Color(0.28, 0.96, 0.42)
			glow_light.light_energy = 1.2


func _strip_preview_arms(n: Node) -> void:
	var nl := n.name.to_lower()
	if "arm" in nl or "hand" in nl or "glove" in nl or "sleeve" in nl or "skeleton" in nl or nl == "feedround" or nl == "speedloader" or nl == "bullet_pack" or nl == "object_86_hero" or nl == "object_67_hero":
		if n is Node3D:
			(n as Node3D).visible = false
		if n.get_parent():
			n.get_parent().remove_child(n)
		n.queue_free()
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		mi.layers = 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children().duplicate():
		_strip_preview_arms(c)


func _compute_local_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var has_box := false
	for mn in root.find_children("*", "MeshInstance3D", true, false):
		var mi := mn as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var a := mi.mesh.get_aabb()
		var xf := mi.transform
		var cur: Node = mi.get_parent()
		while cur != null and cur != root:
			if cur is Node3D:
				xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		for i in range(8):
			var pt := xf * a.get_endpoint(i)
			if not has_box:
				box = AABB(pt, Vector3.ZERO)
				has_box = true
			else:
				box = box.expand(pt)
	return box


func _set_box_preview(weapon_idx: int, target_y: float) -> void:
	var prev_yaw := _preview_holder.rotation.y if (_preview_holder and is_instance_valid(_preview_holder)) else 0.0
	var prev_y := _preview_holder.position.y if (_preview_holder and is_instance_valid(_preview_holder)) else 0.44
	if _preview_holder and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
		_preview_holder = null
	if weapon_idx < 0 or weapon_idx >= PlayerBodycam.WEAPONS.size():
		return
	var glb_p := str(PlayerBodycam.WEAPONS[weapon_idx].get("glb", ""))
	if glb_p == "" or not ResourceLoader.exists(glb_p):
		return
	if not _preview_scene_cache.has(glb_p):
		_preview_scene_cache[glb_p] = load(glb_p)
	var packed := _preview_scene_cache[glb_p] as PackedScene
	if packed == null:
		return
	_preview_holder = Node3D.new()
	_preview_holder.position = Vector3(0.0, lerpf(prev_y, target_y, 0.35), 0.0)
	_preview_holder.rotation.y = prev_yaw
	var inst := packed.instantiate() as Node3D
	_strip_preview_arms(inst)
	if weapon_idx == 13:
		# Hide & detach M1 Garand's reload-only en-bloc clip immediately BEFORE _compute_local_aabb()!
		var g_mag := inst.find_child("Mag", true, false)
		if g_mag:
			if g_mag is Node3D: (g_mag as Node3D).visible = false
			if g_mag.get_parent(): g_mag.get_parent().remove_child(g_mag)
			g_mag.queue_free()
	# Normalize preview size & center cleanly inside the 1.2m chest display envelope!
	var aabb := _compute_local_aabb(inst)
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var norm_scale := clampf(0.88 / maxf(max_dim, 0.15), 0.55, 1.35)
	inst.scale = Vector3.ONE * norm_scale
	inst.position = -aabb.get_center() * norm_scale
	# Display sideways along chest width
	var pivot := Node3D.new()
	pivot.rotation.y = PI * 0.5
	pivot.add_child(inst)
	_preview_holder.add_child(pivot)
	add_child(_preview_holder)


func _get_box_action(player: Node) -> Dictionary:
	if box_state == BoxState.CYCLING or box_state == BoxState.CLOSING:
		return {"action": "busy", "price": 0, "label": "MYSTERY BOX CYCLING..."}
	if box_state == BoxState.READY_CLAIM and _rolled_weapon_idx >= 0:
		var wd: Dictionary = PlayerBodycam.WEAPONS[_rolled_weapon_idx]
		var wname := str(wd.get("name", "WEAPON"))
		if player != null and player.has_method("get_claim_prompt_label"):
			return {"action": "claim", "price": 0, "label": player.get_claim_prompt_label(_rolled_weapon_idx)}
		return {"action": "claim", "price": 0, "label": "[E] CLAIM %s" % wname}
	if player == null:
		return {"action": "roll", "price": cost, "label": "[E] OPEN EVIDENCE CHEST (%d PTS)" % cost}
	var unowned: Array[int] = []
	for idx: int in BOX_POOL:
		if idx < player.unlocked_weapons.size() and not player.unlocked_weapons[idx]:
			unowned.append(idx)
	if not unowned.is_empty():
		return {"action": "roll", "price": cost, "unowned": unowned, "label": "[E] OPEN EVIDENCE CHEST (%d PTS)" % cost}
	# All pool weapons owned -> offer 250 PTS ammo refill ONLY if current weapon actually needs ammo!
	var cur: int = player.current_weapon
	var is_melee := bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false))
	var no_refill: bool = player.has_method("is_no_refill_weapon") and player.is_no_refill_weapon(cur)
	var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
	var full_mag: bool = player.ammo_in_mag[cur] >= max_m
	var full_res: bool = player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
	if is_melee or no_refill or (full_mag and full_res):
		return {"action": "full", "price": 0, "label": "SPECIAL AMMO CANNOT BE REFILLED" if no_refill else "ARSENAL COMPLETE — AMMO FULL"}
	var refill_cost := mini(cost, 250)
	return {"action": "refill", "price": refill_cost, "label": "[E] REFILL AMMO (%d PTS)" % refill_cost}


func get_prompt(player_points: int, player: Node = null) -> String:
	match kind:
		Kind.GENERATOR:
			if activated:
				return "GENERATOR ONLINE [POWER RESTORED]"
			return "[E] START ASYLUM GENERATOR"
		Kind.MYSTERY_BOX:
			var act := _get_box_action(player)
			var price := int(act.get("price", 0))
			if price > 0 and player_points < price:
				return "%s (%d PTS NEEDED)" % [str(act["label"]).split("(")[0].strip_edges(), price]
			return str(act["label"])
		Kind.BARRICADE:
			if plank_count >= max_planks:
				return "BARRICADE INTACT (%d/%d)" % [plank_count, max_planks]
			return "[E] REBUILD BARRICADE (%d/%d)" % [plank_count, max_planks]
		Kind.MELEE_PICKUP:
			if activated:
				return ""
			return "[E] PICK UP %s ([V] QUICK MELEE)" % weapon_label
		Kind.BREACH_GATE:
			if activated:
				return ""
			if player_points < cost:
				return "[E] UNLOCK %s (%d PTS NEEDED)" % [gate_label, cost]
			return "[E] UNLOCK %s (%d PTS)" % [gate_label, cost]
		Kind.UPGRADE_BENCH:
			if not activated:
				return "ARMORY UPGRADE BENCH [RESTORE ASYLUM POWER FIRST]"
			if player != null:
				var cur: int = player.current_weapon
				var is_melee := bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false))
				if is_melee:
					if str(player.equipped_melee_id) == "bat" and not player.owned_melee.has("bat_spiked"):
						if player_points < 750:
							return "[E] DRIVE SPIKES INTO BASEBALL BAT (750 PTS NEEDED)"
						return "[E] DRIVE SPIKES INTO BASEBALL BAT (750 PTS — +40% DMG & BLEED)"
					return "EQUIP A FIREARM, BOW, OR BASEBALL BAT TO UPGRADE"
				var already_up: bool = player.has_method("is_weapon_upgraded") and player.is_weapon_upgraded(cur)
				var no_refill: bool = player.has_method("is_no_refill_weapon") and player.is_no_refill_weapon(cur)
				var is_spec := bool(PlayerBodycam.WEAPONS[cur].get("is_special", false))
				if already_up:
					if not is_spec and cur != 7 and cur != 13 and cur != 14 and not bool(PlayerBodycam.WEAPONS[cur].get("has_holo", false)) and not player.has_attachment(cur, "optic"):
						if player_points < 500:
							return "[E] INSTALL TACTICAL RED-DOT OPTIC (500 PTS NEEDED)"
						return "[E] INSTALL TACTICAL RED-DOT OPTIC (500 PTS)"
					if not is_spec and not bool(PlayerBodycam.WEAPONS[cur].get("is_crossbow", false)) and cur != 6 and not player.has_attachment(cur, "suppressor"):
						if player_points < 600:
							return "[E] INSTALL SUPPRESSOR (600 PTS NEEDED)"
						return "[E] INSTALL SUPPRESSOR (600 PTS — -35% RECOIL)"
					if no_refill:
						return "%s MK-II [LIMITED SPECIAL AMMO — NO REFILL]" % PlayerBodycam.WEAPONS[cur]["name"]
					var full_a: bool = player.ammo_in_mag[cur] >= player.get_weapon_mag_size(cur) and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
					if full_a:
						return "%s MK-II [AMMO FULL]" % PlayerBodycam.WEAPONS[cur]["name"]
					if player_points < 250:
						return "[E] REFILL MK-II AMMO (250 PTS NEEDED)"
					return "[E] REFILL MK-II AMMO (250 PTS)"
				if no_refill and player.ammo_in_mag[cur] <= 0 and player.ammo_reserve[cur] <= 0:
					return "%s DEPLETED (NO AMMO LEFT TO UPGRADE)" % PlayerBodycam.WEAPONS[cur]["name"]
				if player_points < cost:
					return "[E] UPGRADE %s TO MK-II (%d PTS NEEDED)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
				return "[E] UPGRADE %s TO MK-II (%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
			return "[E] ARMORY UPGRADE BENCH (%d PTS)" % cost
		Kind.AMMO_CRATE:
			if player != null:
				var cur: int = player.current_weapon
				if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
					return "EQUIP A FIREARM OR BOW TO RESUPPLY AMMO"
				if player.has_method("is_no_refill_weapon") and player.is_no_refill_weapon(cur):
					return "%s — SPECIAL WEAPON (NO NORMAL AMMO REFILL)" % PlayerBodycam.WEAPONS[cur]["name"]
				var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				var full_a: bool = player.ammo_in_mag[cur] >= max_m and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
				if full_a:
					return "%s [AMMO FULL]" % PlayerBodycam.WEAPONS[cur]["name"]
				if player_points < cost:
					return "[E] RESUPPLY %s AMMO (%d PTS NEEDED)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
				return "[E] RESUPPLY %s AMMO (%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
			return "[E] AMMO CRATE (%d PTS)" % cost
		Kind.WALL_BUY:
			var wname := str(PlayerBodycam.WEAPONS[weapon_index]["name"]) if (weapon_index >= 0 and weapon_index < PlayerBodycam.WEAPONS.size()) else weapon_label
			if player != null and weapon_index >= 0 and weapon_index < player.unlocked_weapons.size() and player.unlocked_weapons[weapon_index]:
				var max_m: int = player.get_weapon_mag_size(weapon_index) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[weapon_index]["mag_size"])
				var full_w: bool = player.ammo_in_mag[weapon_index] >= max_m and player.ammo_reserve[weapon_index] >= int(PlayerBodycam.WEAPONS[weapon_index]["reserve_max"])
				if full_w:
					return "%s WALL MOUNT [AMMO FULL]" % wname
				if player_points < ammo_cost:
					return "[E] BUY %s AMMO (%d PTS NEEDED)" % [wname, ammo_cost]
				return "[E] BUY %s AMMO (%d PTS)" % [wname, ammo_cost]
			var swap_note := ""
			if player != null and player.firearm_slots.size() >= PlayerBodycam.MAX_FIREARM_SLOTS:
				var rep_slot: int = player.firearm_slots.find(player.current_weapon)
				if rep_slot < 0:
					rep_slot = player.firearm_slots.size() - 1
				var rep_name := str(PlayerBodycam.WEAPONS[player.firearm_slots[rep_slot]]["name"])
				swap_note = " — SWAP [%d] %s" % [rep_slot + 1, rep_name]
			if player_points < cost:
				return "[E] BUY %s%s (%d PTS NEEDED)" % [wname, swap_note, cost]
			return "[E] BUY %s%s (%d PTS)" % [wname, swap_note, cost]
		Kind.PERK:
			if activated:
				return "%s — ALREADY ADMINISTERED" % perk_label
			if not _perk_powered:
				return "%s [RESTORE ASYLUM POWER FIRST]" % perk_label
			if player_points < cost:
				return "[E] TAKE %s (%d PTS NEEDED)" % [perk_label, cost]
			return "[E] TAKE %s (%d PTS)" % [perk_label, cost]
		Kind.TRAP:
			if trap_state == TrapState.ACTIVE:
				return "%s ACTIVE (%ds)" % [trap_label, ceili(trap_timer)]
			if trap_state == TrapState.COOLDOWN:
				return "%s RECHARGING (%ds)" % [trap_label, ceili(trap_timer)]
			if player_points < cost:
				return "[E] ACTIVATE %s (%d PTS NEEDED)" % [trap_label, cost]
			return "[E] ACTIVATE %s (%d PTS)" % [trap_label, cost]
	return prompt_text


func get_prompt_detail(player: Node = null) -> String:
	# Second line under the prompt: what the thing actually does, so a purchase is an informed one
	match kind:
		Kind.WALL_BUY:
			if weapon_index >= 0 and weapon_index < PlayerBodycam.WEAPONS.size():
				return PlayerBodycam.describe_weapon(weapon_index)
		Kind.MELEE_PICKUP:
			if not activated and PlayerBodycam.MELEE_CATALOG.has(melee_id):
				var m: Dictionary = PlayerBodycam.MELEE_CATALOG[melee_id]
				return "DMG %d  ·  REACH %.1fm  ·  %s" % [int(m["damage"]), float(m["reach"]), str(m.get("trait", ""))]
		Kind.MYSTERY_BOX:
			if box_state == BoxState.READY_CLAIM and _rolled_weapon_idx >= 0:
				return PlayerBodycam.describe_weapon(_rolled_weapon_idx)
			if box_state == BoxState.IDLE:
				return "RANDOM WEAPON  ·  25% CHANCE OF A PRE-FITTED ATTACHMENT"
		Kind.UPGRADE_BENCH:
			if activated:
				return "MK-II: +45% DAMAGE, LARGER MAGAZINE  ·  THEN OPTIC 500  ·  SUPPRESSOR 600"
			return "NEEDS POWER — START THE GENERATOR IN THE LOBBY"
		Kind.AMMO_CRATE:
			return "REFILLS THE WEAPON IN YOUR HANDS"
		Kind.PERK:
			return str(PERK_INFO.get(perk_id, ""))
		Kind.TRAP:
			if trap_state == TrapState.READY:
				var what := "BURNS" if trap_type == "flame" else ("SHOCKS AND STUNS" if trap_type == "electric" else "SHREDS")
				return "%s EVERYTHING IN THE KILL ZONE FOR %ds  ·  IT WILL HURT YOU TOO" % [what, int(trap_duration)]
		Kind.BREACH_GATE:
			if not activated:
				return "OPENS A NEW WING  ·  MORE ROUTES, MORE SPAWNS"
		Kind.GENERATOR:
			if not activated:
				return "POWERS THE LIGHTS AND THE ARMORY UPGRADE BENCH  ·  +200 PTS"
		Kind.BARRICADE:
			if plank_count < max_planks:
				return "+25 PTS PER PLANK"
	return ""


func _cancel_player_reload(player: Node) -> void:
	if player == null:
		return
	player.is_reloading = false
	player.reload_cancel_req = false
	player._shotgun_fire_on_cancel = false
	player._burst_remaining = 0
	player._burst_timer = 0.0
	player.reload_pos_off = Vector3.ZERO
	player.reload_rot_off = Vector3.ZERO
	if player.has_method("_reset_weapon_parts"):
		player._reset_weapon_parts()


func interact(game_manager: Node, player: Node) -> String:
	match kind:
		Kind.GENERATOR:
			if activated:
				return "Power is already restored."
			activated = true
			if glow_light:
				glow_light.light_color = Color(0.35, 1.0, 0.45)
				glow_light.light_energy = 1.8
			emit_signal("generator_activated")
			if game_manager and game_manager.has_method("on_generator_activated"):
				game_manager.on_generator_activated()
			return "GENERATOR ONLINE — ASYLUM POWER & SAWMILL BENCH RESTORED"
		Kind.MYSTERY_BOX:
			var act := _get_box_action(player)
			var mode := str(act["action"])
			if mode == "busy":
				return "Evidence chest cycling..."
			if mode == "full":
				return "Ammo is already full."
			if mode == "claim":
				var claimed := _rolled_weapon_idx
				var lucky := _rolled_lucky_mod
				var wd: Dictionary = PlayerBodycam.WEAPONS[claimed]
				var wname := str(wd["name"])
				var slot_lbl := ""
				if player and player.has_method("acquire_weapon"):
					var info: Dictionary = player.acquire_weapon(claimed, true)
					slot_lbl = str(info.get("slot_key", ""))
					if lucky != "" and player.has_method("add_attachment"):
						player.add_attachment(claimed, lucky)
				elif player and player.has_method("unlock_and_equip"):
					player.unlock_and_equip(claimed)
				_rolled_lucky_mod = ""
				_begin_box_close()
				var lucky_lbl := lucky.replace("_", " ").to_upper()
				var lucky_tag := (" [LUCKY PRE-MOD: %s!]" % lucky_lbl) if lucky != "" else ""
				return ("CLAIMED: [%s] %s%s" % [slot_lbl, wname, lucky_tag]) if slot_lbl != "" else ("CLAIMED: %s%s" % [wname, lucky_tag])
			var price := int(act["price"])
			if game_manager and game_manager.points < price:
				return "Need %d points!" % price
			if mode == "refill":
				if game_manager:
					game_manager.add_points(-price)
				var cur: int = player.current_weapon
				player.ammo_in_mag[cur] = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				player.ammo_reserve[cur] = int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
				player.weapon_chambered[cur] = true
				_cancel_player_reload(player)
				_play_spatial(_sfx_reveal, 1.05)
				return "AMMO REFILLED (-%d PTS)" % price
			# Roll a new unowned weapon!
			var unowned: Array = act.get("unowned", [])
			if unowned.is_empty():
				return ""
			if game_manager:
				game_manager.add_points(-price)
			var roll: int = int(unowned[randi() % unowned.size()])
			_rolled_weapon_idx = roll
			_rolled_owner_player = player
			var w_dict: Dictionary = PlayerBodycam.WEAPONS[roll]
			# 25% Lucky Pre-Modded Mystery Box roll on standard firearms (only valid mods for this weapon!)
			_rolled_lucky_mod = ""
			if not bool(w_dict.get("is_special", false)) and randf() < 0.25:
				var mods: Array[String] = []
				if roll != 7 and roll != 13 and roll != 14 and not bool(w_dict.get("has_holo", false)):
					mods.append("optic")
				if roll != 6 and not bool(w_dict.get("is_crossbow", false)):
					mods.append("suppressor")
				if roll != 6 and roll != 11 and not bool(w_dict.get("is_crossbow", false)):
					mods.append("ext_mag")
				if not mods.is_empty():
					_rolled_lucky_mod = mods[randi() % mods.size()]
			var wname: String = str(w_dict["name"])
			box_state = BoxState.CYCLING
			_box_timer = BOX_CYCLE_DUR
			_cycle_tick = 0.0
			_play_spatial(_sfx_latch, 1.05)
			emit_signal("mystery_box_rolled", roll, wname)
			var mod_note := (" (LUCKY %s SPEC!)" % _rolled_lucky_mod.replace("_", " ").to_upper()) if _rolled_lucky_mod != "" else ""
			return "MYSTERY BOX ROLLING: %s%s — PRESS [E] TO CLAIM!" % [wname, mod_note]
		Kind.BARRICADE:
			if plank_count >= max_planks:
				return "Barricade fully reinforced."
			plank_count += 1
			_refresh_planks()
			if game_manager:
				game_manager.add_points(25)
			emit_signal("barricade_rebuilt", plank_count)
			return "REBUILT BARRICADE (+25 PTS)"
		Kind.MELEE_PICKUP:
			if activated:
				return ""
			activated = true
			visible = false
			collision_layer = 0
			if player and player.has_method("acquire_melee_weapon"):
				player.acquire_melee_weapon(melee_id)
			return "UPGRADED QUICK MELEE: %s ([V])" % weapon_label
		Kind.BREACH_GATE:
			if activated:
				return ""
			if game_manager and game_manager.points < cost:
				return "Need %d points to unlock %s!" % [cost, gate_label]
			if game_manager:
				game_manager.add_points(-cost)
			activated = true
			collision_layer = 0
			if gate_visual and is_instance_valid(gate_visual):
				gate_visual.rotation.y = gate_open_yaw
			_play_spatial(_sfx_latch, 0.72)
			emit_signal("gate_opened")
			if game_manager and game_manager.has_method("on_breach_gate_opened"):
				game_manager.on_breach_gate_opened(gate_id)
			elif game_manager and game_manager.has_method("on_sawmill_gate_opened"):
				game_manager.on_sawmill_gate_opened()
			return "%s BREACHED — NEW WING UNLOCKED!" % gate_label
		Kind.UPGRADE_BENCH:
			if not activated:
				return "Restore Asylum Generator power first!"
			if player == null:
				return ""
			var cur: int = player.current_weapon
			if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
				if str(player.equipped_melee_id) == "bat" and not player.owned_melee.has("bat_spiked"):
					if game_manager and game_manager.points < 750:
						return "Need 750 points to spike the Baseball Bat!"
					if game_manager:
						game_manager.add_points(-750)
					player.acquire_melee_weapon("bat_spiked")
					_play_spatial(_sfx_reveal, 0.90)
					return "UPGRADED: SPIKED BASEBALL BAT (+40% DMG & BLEED DOT!)"
				return "Equip a firearm, bow, or Baseball Bat to upgrade!"
			var already_up: bool = player.has_method("is_weapon_upgraded") and player.is_weapon_upgraded(cur)
			var is_spec := bool(PlayerBodycam.WEAPONS[cur].get("is_special", false))
			var no_refill: bool = player.has_method("is_no_refill_weapon") and player.is_no_refill_weapon(cur)
			if already_up:
				if not is_spec and cur != 7 and cur != 13 and cur != 14 and not bool(PlayerBodycam.WEAPONS[cur].get("has_holo", false)) and not player.has_attachment(cur, "optic"):
					if game_manager and game_manager.points < 500:
						return "Need 500 points for Tactical Red-Dot Optic!"
					if game_manager: game_manager.add_points(-500)
					player.add_attachment(cur, "optic")
					_play_spatial(_sfx_reveal, 1.15)
					return "INSTALLED TACTICAL RED-DOT OPTIC (-500 PTS)"
				if not is_spec and not bool(PlayerBodycam.WEAPONS[cur].get("is_crossbow", false)) and cur != 6 and not player.has_attachment(cur, "suppressor"):
					if game_manager and game_manager.points < 600:
						return "Need 600 points for Suppressor!"
					if game_manager: game_manager.add_points(-600)
					player.add_attachment(cur, "suppressor")
					_play_spatial(_sfx_reveal, 1.10)
					return "INSTALLED SUPPRESSOR (-600 PTS, -35%% RECOIL)"
				if no_refill:
					return "Special weapons have limited ammo — no normal refills!"
				var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				if player.ammo_in_mag[cur] >= max_m and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"]):
					return "MK-II ammo is already full."
				if game_manager and game_manager.points < 250:
					return "Need 250 points for MK-II ammo!"
				if game_manager:
					game_manager.add_points(-250)
				player.ammo_in_mag[cur] = max_m
				player.ammo_reserve[cur] = int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
				player.weapon_chambered[cur] = true
				_cancel_player_reload(player)
				_play_spatial(_sfx_reveal, 1.12)
				return "MK-II AMMO REFILLED (-250 PTS)"
			if no_refill and player.ammo_in_mag[cur] <= 0 and player.ammo_reserve[cur] <= 0:
				return "Special weapon depleted — no ammo left to upgrade!"
			if game_manager and game_manager.points < cost:
				return "Need %d points to upgrade!" % cost
			if game_manager:
				game_manager.add_points(-cost)
			if player.has_method("upgrade_weapon"):
				player.upgrade_weapon(cur)
			_cancel_player_reload(player)
			_play_spatial(_sfx_reveal, 0.85)
			var wname := str(PlayerBodycam.WEAPONS[cur]["name"])
			emit_signal("weapon_upgraded", cur, wname)
			var has_ext_m: bool = player.has_method("get_weapon_mag_size") and player.get_weapon_mag_size(cur) > int(PlayerBodycam.WEAPONS[cur]["mag_size"])
			return ("UPGRADED: %s MK-II (+45%% DMG & EXTENDED MAG!)" % wname) if has_ext_m else ("UPGRADED: %s MK-II (+45%% DAMAGE!)" % wname)
		Kind.AMMO_CRATE:
			if player == null:
				return ""
			var cur: int = player.current_weapon
			if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
				return "Equip a firearm or bow to resupply ammo!"
			if player.has_method("is_no_refill_weapon") and player.is_no_refill_weapon(cur):
				return "Special weapon — limited ammo (cannot buy ammo refills!)"
			var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
			if player.ammo_in_mag[cur] >= max_m and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"]):
				return "Ammo is already full."
			if game_manager and game_manager.points < cost:
				return "Need %d points for ammo resupply!" % cost
			if game_manager:
				game_manager.add_points(-cost)
			player.ammo_in_mag[cur] = max_m
			player.ammo_reserve[cur] = int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
			player.weapon_chambered[cur] = true
			_cancel_player_reload(player)
			_play_spatial(_sfx_reveal, 1.08)
			return "RESUPPLIED %s AMMO (-%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
		Kind.WALL_BUY:
			if player == null or weapon_index < 0 or weapon_index >= PlayerBodycam.WEAPONS.size():
				return ""
			var wname := str(PlayerBodycam.WEAPONS[weapon_index]["name"])
			if player.unlocked_weapons[weapon_index]:
				var max_m: int = player.get_weapon_mag_size(weapon_index) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[weapon_index]["mag_size"])
				if player.ammo_in_mag[weapon_index] >= max_m and player.ammo_reserve[weapon_index] >= int(PlayerBodycam.WEAPONS[weapon_index]["reserve_max"]):
					return "%s ammo is already full." % wname
				if game_manager and game_manager.points < ammo_cost:
					return "Need %d points for %s ammo!" % [ammo_cost, wname]
				if game_manager:
					game_manager.add_points(-ammo_cost)
				player.ammo_in_mag[weapon_index] = max_m
				player.ammo_reserve[weapon_index] = int(PlayerBodycam.WEAPONS[weapon_index]["reserve_max"])
				player.weapon_chambered[weapon_index] = true
				if player.current_weapon == weapon_index:
					_cancel_player_reload(player)
				_play_spatial(_sfx_reveal, 1.10)
				return "BOUGHT %s AMMO (-%d PTS)" % [wname, ammo_cost]
			if game_manager and game_manager.points < cost:
				return "Need %d points to buy %s!" % [cost, wname]
			if game_manager:
				game_manager.add_points(-cost)
			if player.has_method("acquire_weapon"):
				player.acquire_weapon(weapon_index, true)
			player.fire_cd = maxf(player.fire_cd, 0.25)
			_play_spatial(_sfx_reveal, 0.96)
			return "PURCHASED WALL WEAPON: %s (-%d PTS)" % [wname, cost]
		Kind.PERK:
			if activated:
				return "Already administered."
			if not _perk_powered:
				return "The dispensary has no power. Start the generator."
			if game_manager and game_manager.points < cost:
				return "Need %d points for %s!" % [cost, perk_label]
			if player == null or not player.has_method("grant_perk"):
				return ""
			if game_manager:
				game_manager.add_points(-cost)
			activated = true
			player.grant_perk(perk_id)
			if drawer_node and is_instance_valid(drawer_node):
				_drawer_rest_z = drawer_node.position.z
				_drawer_t = 1.2
			_play_spatial(_sfx_reveal, 0.8)
			return "%s ADMINISTERED — %s" % [perk_label, str(PERK_INFO.get(perk_id, ""))]
		Kind.TRAP:
			if trap_state == TrapState.ACTIVE:
				return "%s is already active (%ds left)!" % [trap_label, ceili(trap_timer)]
			if trap_state == TrapState.COOLDOWN:
				return "%s recharging (%ds left)..." % [trap_label, ceili(trap_timer)]
			if game_manager and game_manager.points < cost:
				return "Need %d points to activate %s!" % [cost, trap_label]
			if game_manager:
				game_manager.add_points(-cost)
			trap_state = TrapState.ACTIVE
			trap_timer = trap_duration
			_trap_tick = 0.0
			_trap_owner_player = player
			if trap_fx_node and is_instance_valid(trap_fx_node):
				trap_fx_node.visible = true
			if trap_light and is_instance_valid(trap_light):
				trap_light.visible = true
			if glow_light and is_instance_valid(glow_light):
				glow_light.light_color = Color(1.0, 0.25, 0.14)
				glow_light.light_energy = 2.0
			_play_spatial(_sfx_latch, 1.25)
			return "ACTIVATED %s (%ds) — CLEAR THE KILL ZONE!" % [trap_label, int(trap_duration)]
	return ""


func damage_barricade() -> bool:
	if kind != Kind.BARRICADE or plank_count <= 0:
		return false
	plank_count -= 1
	_refresh_planks()
	return true


func _refresh_planks() -> void:
	for i in range(plank_nodes.size()):
		plank_nodes[i].visible = i < plank_count
