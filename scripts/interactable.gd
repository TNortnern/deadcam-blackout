extends StaticBody3D
class_name InteractableObject

enum Kind { GENERATOR, MYSTERY_BOX, BARRICADE, MELEE_PICKUP, BREACH_GATE, UPGRADE_BENCH, AMMO_CRATE }
enum BoxState { IDLE, CYCLING, READY_CLAIM, CLOSING }

@export var kind: Kind = Kind.GENERATOR
@export var prompt_text: String = "Press [E] to Interact"
@export var cost: int = 0
@export var melee_id: String = "fire_axe"
@export var weapon_label: String = "FIRE AXE"

var activated: bool = false
var plank_count: int = 4
var max_planks: int = 4
var lid_node: Node3D = null
var glow_light: OmniLight3D = null
var plank_nodes: Array[Node3D] = []
var cooldown: float = 0.0
var gate_visual: Node3D = null

# Explicit Mystery Box state machine (IDLE -> CYCLING -> READY_CLAIM -> CLOSING)
var box_state: BoxState = BoxState.IDLE
var _box_timer: float = 0.0
var _cycle_tick: float = 0.0
var _preview_holder: Node3D = null
var _rolled_weapon_idx: int = -1
var _rolled_owner_player: Node = null
var _box_audio: AudioStreamPlayer3D = null

static var _sfx_latch: AudioStream = null
static var _sfx_cycle: AudioStream = null
static var _sfx_reveal: AudioStream = null
static var _preview_scene_cache: Dictionary = {}

const BOX_POOL := [1, 2, 7, 4, 5, 6, 8, 9, 10]
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
	if kind == Kind.MYSTERY_BOX or kind == Kind.UPGRADE_BENCH or kind == Kind.BREACH_GATE:
		_box_audio = AudioStreamPlayer3D.new()
		_box_audio.unit_size = 5.0
		_box_audio.max_distance = 22.0
		_box_audio.volume_db = -2.0
		_box_audio.position = Vector3(0.0, 0.75, 0.0)
		add_child(_box_audio)


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
			if _rolled_owner_player and is_instance_valid(_rolled_owner_player) and _rolled_weapon_idx >= 0:
				var p_ref := _rolled_owner_player
				var is_spec := bool(PlayerBodycam.WEAPONS[_rolled_weapon_idx].get("is_special", false))
				var can_auto: bool = (is_spec and int(p_ref.special_slot) < 0) or (not is_spec and (p_ref.firearm_slots.size() < PlayerBodycam.MAX_FIREARM_SLOTS or p_ref.firearm_slots.has(_rolled_weapon_idx)))
				if can_auto and p_ref.has_method("unlock_weapon_silent"):
					p_ref.unlock_weapon_silent(_rolled_weapon_idx)
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
	_play_spatial(_sfx_latch, 0.78)


func reset_state() -> void:
	activated = false
	cooldown = 0.0
	box_state = BoxState.IDLE
	_box_timer = 0.0
	_rolled_weapon_idx = -1
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


func _strip_preview_arms(n: Node) -> void:
	var nl := n.name.to_lower()
	if "arm" in nl or "hand" in nl or "glove" in nl or "sleeve" in nl or "skeleton" in nl:
		n.queue_free()
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		mi.layers = 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_strip_preview_arms(c)


func _compute_local_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var has_box := false
	for mn in root.find_children("*", "MeshInstance3D", true, false):
		var mi := mn as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var a := mi.mesh.get_aabb()
		var xf := root.transform.affine_inverse() * mi.transform
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
	var full_mag: bool = player.ammo_in_mag[cur] >= int(PlayerBodycam.WEAPONS[cur]["mag_size"])
	var full_res: bool = player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
	if is_melee or (full_mag and full_res):
		return {"action": "full", "price": 0, "label": "ARSENAL COMPLETE — AMMO FULL"}
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
				return "[E] UNLOCK SAWMILL BREACH GATE (%d PTS NEEDED)" % cost
			return "[E] UNLOCK SAWMILL BREACH GATE (%d PTS)" % cost
		Kind.UPGRADE_BENCH:
			if not activated:
				return "ARMORY UPGRADE BENCH [RESTORE ASYLUM POWER FIRST]"
			if player != null:
				var cur: int = player.current_weapon
				var is_melee := bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false))
				if is_melee:
					return "EQUIP A FIREARM OR BOW TO UPGRADE"
				var already_up: bool = player.has_method("is_weapon_upgraded") and player.is_weapon_upgraded(cur)
				if already_up:
					var full_a: bool = player.ammo_in_mag[cur] >= player.get_weapon_mag_size(cur) and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
					if full_a:
						return "%s MK-II [AMMO FULL]" % PlayerBodycam.WEAPONS[cur]["name"]
					if player_points < 250:
						return "[E] REFILL MK-II AMMO (250 PTS NEEDED)"
					return "[E] REFILL MK-II AMMO (250 PTS)"
				if player_points < cost:
					return "[E] UPGRADE %s TO MK-II (%d PTS NEEDED)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
				return "[E] UPGRADE %s TO MK-II (%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
			return "[E] ARMORY UPGRADE BENCH (%d PTS)" % cost
		Kind.AMMO_CRATE:
			if player != null:
				var cur: int = player.current_weapon
				if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
					return "EQUIP A FIREARM OR BOW TO RESUPPLY AMMO"
				var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				var full_a: bool = player.ammo_in_mag[cur] >= max_m and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
				if full_a:
					return "%s [AMMO FULL]" % PlayerBodycam.WEAPONS[cur]["name"]
				if player_points < cost:
					return "[E] RESUPPLY %s AMMO (%d PTS NEEDED)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
				return "[E] RESUPPLY %s AMMO (%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
			return "[E] AMMO CRATE (%d PTS)" % cost
	return prompt_text


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
				var wd: Dictionary = PlayerBodycam.WEAPONS[claimed]
				var wname := str(wd["name"])
				var slot_lbl := ""
				if player and player.has_method("acquire_weapon"):
					var info: Dictionary = player.acquire_weapon(claimed, true)
					slot_lbl = str(info.get("slot_key", ""))
				elif player and player.has_method("unlock_and_equip"):
					player.unlock_and_equip(claimed)
				_begin_box_close()
				return "CLAIMED: [%s] %s" % [slot_lbl, wname] if slot_lbl != "" else ("CLAIMED: %s" % wname)
			var price := int(act["price"])
			if game_manager and game_manager.points < price:
				return "Need %d points!" % price
			if mode == "refill":
				if game_manager:
					game_manager.add_points(-price)
				var cur: int = player.current_weapon
				player.ammo_in_mag[cur] = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				player.ammo_reserve[cur] = int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
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
			var wname: String = str(w_dict["name"])
			box_state = BoxState.CYCLING
			_box_timer = BOX_CYCLE_DUR
			_cycle_tick = 0.0
			_play_spatial(_sfx_latch, 1.05)
			emit_signal("mystery_box_rolled", roll, wname)
			return "MYSTERY BOX ROLLING: %s — PRESS [E] TO CLAIM!" % wname
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
				return "Need %d points to unlock Sawmill Gate!" % cost
			if game_manager:
				game_manager.add_points(-cost)
			activated = true
			collision_layer = 0
			if gate_visual and is_instance_valid(gate_visual):
				gate_visual.rotation.y = 1.65
			_play_spatial(_sfx_latch, 0.72)
			emit_signal("gate_opened")
			if game_manager and game_manager.has_method("on_sawmill_gate_opened"):
				game_manager.on_sawmill_gate_opened()
			return "SAWMILL PERIMETER BREACHED — WATCHTOWER & ARMORY BENCH UNLOCKED!"
		Kind.UPGRADE_BENCH:
			if not activated:
				return "Restore Asylum Generator power first!"
			if player == null:
				return ""
			var cur: int = player.current_weapon
			if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
				return "Equip a firearm or bow to upgrade!"
			var already_up: bool = player.has_method("is_weapon_upgraded") and player.is_weapon_upgraded(cur)
			if already_up:
				var max_m: int = player.get_weapon_mag_size(cur) if player.has_method("get_weapon_mag_size") else int(PlayerBodycam.WEAPONS[cur]["mag_size"])
				if player.ammo_in_mag[cur] >= max_m and player.ammo_reserve[cur] >= int(PlayerBodycam.WEAPONS[cur]["reserve_max"]):
					return "MK-II ammo is already full."
				if game_manager and game_manager.points < 250:
					return "Need 250 points for MK-II ammo!"
				if game_manager:
					game_manager.add_points(-250)
				player.ammo_in_mag[cur] = max_m
				player.ammo_reserve[cur] = int(PlayerBodycam.WEAPONS[cur]["reserve_max"])
				_play_spatial(_sfx_reveal, 1.12)
				return "MK-II AMMO REFILLED (-250 PTS)"
			if game_manager and game_manager.points < cost:
				return "Need %d points to upgrade!" % cost
			if game_manager:
				game_manager.add_points(-cost)
			if player.has_method("upgrade_weapon"):
				player.upgrade_weapon(cur)
			_play_spatial(_sfx_reveal, 0.85)
			var wname := str(PlayerBodycam.WEAPONS[cur]["name"])
			emit_signal("weapon_upgraded", cur, wname)
			return "UPGRADED: %s MK-II (+45%% DMG & EXTENDED MAG!)" % wname
		Kind.AMMO_CRATE:
			if player == null:
				return ""
			var cur: int = player.current_weapon
			if bool(PlayerBodycam.WEAPONS[cur].get("is_melee", false)):
				return "Equip a firearm or bow to resupply ammo!"
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
			_play_spatial(_sfx_reveal, 1.08)
			return "RESUPPLIED %s AMMO (-%d PTS)" % [PlayerBodycam.WEAPONS[cur]["name"], cost]
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
