extends StaticBody3D
class_name InteractableObject

enum Kind { GENERATOR, MYSTERY_BOX, BARRICADE, MELEE_PICKUP }

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

signal generator_activated
signal mystery_box_rolled(weapon_index: int, weapon_name: String)
signal barricade_rebuilt(planks: int)


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
			return "[E] PICK UP %s (SLOT 4 / [V] MELEE)" % weapon_label
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
			if game_manager:
				game_manager.add_points(-cost)
			cooldown = 2.6
			var roll := 1 if (player.current_weapon != 1) else 2
			var wname := "M16A2 REFLEX" if roll == 1 else "M16A2 BREACHER"
			if player.has_method("unlock_and_equip"):
				player.unlock_and_equip(roll)
			emit_signal("mystery_box_rolled", roll, wname)
			return "ACQUIRED: " + wname
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
			return "EQUIPPED MELEE: %s ([4] OR [V])" % weapon_label
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
