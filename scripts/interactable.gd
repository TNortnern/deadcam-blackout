extends StaticBody3D
class_name InteractableObject

enum Kind { GENERATOR, MYSTERY_BOX, BARRICADE, MELEE_PICKUP, BREACH_GATE }

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
var _preview_holder: Node3D = null
var _preview_timer: float = 0.0
var _rolled_weapon_idx: int = -1

signal generator_activated
signal mystery_box_rolled(weapon_index: int, weapon_name: String)
signal barricade_rebuilt(planks: int)
signal gate_opened


func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = max(0.0, cooldown - delta)
	if lid_node and cooldown > 0.0:
		lid_node.rotation.x = lerp(lid_node.rotation.x, -1.15, delta * 6.0)
	elif lid_node:
		lid_node.rotation.x = lerp(lid_node.rotation.x, 0.0, delta * 4.0)
	if glow_light and kind == Kind.MYSTERY_BOX:
		var base_e := 2.4 if cooldown > 0.0 else 0.75
		glow_light.light_energy = base_e + sin(Time.get_ticks_msec() * 0.004) * 0.2
	if _preview_holder and is_instance_valid(_preview_holder):
		_preview_timer -= delta
		_preview_holder.rotation.y += delta * 2.2
		_preview_holder.position.y = lerpf(_preview_holder.position.y, 0.92, delta * 4.5)
		if _preview_timer <= 0.0:
			_preview_holder.queue_free()
			_preview_holder = null


func reset_state() -> void:
	activated = false
	cooldown = 0.0
	_rolled_weapon_idx = -1
	if _preview_holder and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
		_preview_holder = null
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


func _spawn_box_preview(weapon_idx: int) -> void:
	if _preview_holder and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
	if weapon_idx < 0 or weapon_idx >= PlayerBodycam.WEAPONS.size():
		return
	var glb_p := str(PlayerBodycam.WEAPONS[weapon_idx].get("glb", ""))
	if glb_p == "" or not ResourceLoader.exists(glb_p):
		return
	var packed := load(glb_p) as PackedScene
	if packed == null:
		return
	_preview_holder = Node3D.new()
	_preview_holder.position = Vector3(0.0, 0.42, 0.0)
	var inst := packed.instantiate()
	inst.scale = Vector3.ONE * 1.15
	_preview_holder.add_child(inst)
	add_child(_preview_holder)
	_preview_timer = 2.6


func get_prompt(player_points: int) -> String:
	match kind:
		Kind.GENERATOR:
			if activated:
				return "GENERATOR ONLINE [POWER RESTORED]"
			return "[E] START ASYLUM GENERATOR"
		Kind.MYSTERY_BOX:
			if cooldown > 0.0:
				return "MYSTERY BOX CYCLING..."
			if player_points < cost:
				return "[E] MYSTERY BOX (%d PTS NEEDED)" % cost
			return "[E] OPEN MYSTERY BOX (%d PTS)" % cost
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
			return "GENERATOR ONLINE — ASYLUM POWER RESTORED"
		Kind.MYSTERY_BOX:
			if cooldown > 0.0:
				return "Wait for Mystery Box..."
			if game_manager and game_manager.points < cost:
				return "Need %d points!" % cost
			var all_box_pool := [1, 2, 7, 4, 5, 6, 8, 9, 10]
			var unowned: Array[int] = []
			for idx: int in all_box_pool:
				if idx < player.unlocked_weapons.size() and not player.unlocked_weapons[idx]:
					unowned.append(idx)
			if unowned.is_empty():
				# All 9 Mystery Box weapons unlocked -> refill ammo for current firearm!
				if game_manager:
					game_manager.add_points(-mini(cost, 250))
				cooldown = 1.6
				var cur: int = player.current_weapon
				player.ammo_in_mag[cur] = PlayerBodycam.WEAPONS[cur]["mag_size"]
				player.ammo_reserve[cur] = PlayerBodycam.WEAPONS[cur]["reserve_max"]
				return "ARSENAL COMPLETE — REFILLED AMMO!"
			if game_manager:
				game_manager.add_points(-cost)
			cooldown = 2.2
			var roll: int = unowned[randi() % unowned.size()]
			_rolled_weapon_idx = roll
			_spawn_box_preview(roll)
			var w_dict: Dictionary = PlayerBodycam.WEAPONS[roll]
			var wname: String = str(w_dict["name"])
			var wkey: String = str(w_dict.get("key", ""))
			if player.has_method("unlock_and_equip"):
				player.unlock_and_equip(roll)
			emit_signal("mystery_box_rolled", roll, wname)
			return "MYSTERY BOX UNLOCKED: [%s] %s (%d/%d)" % [wkey, wname, 9 - unowned.size() + 1, 9]
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
			emit_signal("gate_opened")
			if game_manager and game_manager.has_method("on_sawmill_gate_opened"):
				game_manager.on_sawmill_gate_opened()
			return "SAWMILL PERIMETER BREACHED — WATCHTOWER & BOX 2 UNLOCKED!"
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
