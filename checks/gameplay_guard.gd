extends SceneTree
## Headless functional gameplay regression guard for DEADCAM: BLACKOUT.

func _init() -> void:
	call_deferred("_run")


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("GUARD_FAIL: " + msg)
		print("GUARD_FAIL: ", msg)
		quit(1)


func _run() -> void:
	var scene := load("res://scenes/main.tscn")
	_assert(scene != null, "main.tscn failed to load")
	var gm: GameManager = scene.instantiate()
	root.add_child(gm)
	current_scene = gm
	await process_frame
	await process_frame

	_assert(gm.world != null, "WorldBuilder missing")
	_assert(gm.player != null, "PlayerBodycam missing")
	_assert(gm.hud != null, "BodycamHUD missing")
	_assert(gm.world.spawn_points.size() >= 4, "Need >=4 spawn points")
	_assert(gm.world.interactables.size() == 3, "Need Generator, MysteryBox, Barricade")

	# Start game
	gm.start_game()
	_assert(gm.game_active, "Game did not activate")
	_assert(gm.wave == 1, "Wave should start at 1")

	# Flashlight toggle
	var fl0 := gm.player.flashlight_on
	gm.player.toggle_flashlight()
	_assert(gm.player.flashlight_on != fl0, "Flashlight toggle failed")
	gm.player.toggle_flashlight()

	# Weapon switch + fire + ammo decrement + reload
	gm.player._equip_weapon(1)
	_assert(gm.player.current_weapon == 1, "Equip MK18 failed")
	var mag0 := gm.player.ammo_in_mag[1]
	var fired := gm.player.fire_weapon()
	_assert(fired and gm.player.ammo_in_mag[1] == mag0 - 1, "Fire did not consume ammo")
	var rel := gm.player.start_reload()
	_assert(rel and gm.player.is_reloading, "Reload did not start")
	gm.player._finish_reload()
	_assert(not gm.player.is_reloading and gm.player.ammo_in_mag[1] == 30, "Reload did not refill mag")

	# Spawn zombie + damage + headshot kill + points
	gm.clear_zombies()
	var z := gm.spawn_zombie_at(Vector3(0, 0.1, 0), ZombieAI.Variant.TACTICAL_SOLDIER)
	await physics_frame
	var killed := z.take_damage(80.0, Vector3(0, 1.5, 0), Vector3(0, 0, -1), true)
	_assert(killed and z.dead, "Headshot did not kill zombie")
	_assert(gm.kills == 1 and gm.headshots == 1, "Kill/headshot counter wrong")

	# Interactables: Generator, Mystery Box, Barricade
	for obj in gm.world.interactables:
		if obj.kind == InteractableObject.Kind.GENERATOR:
			obj.interact(gm, gm.player)
			_assert(gm.power_restored and obj.activated, "Generator did not restore power")
		elif obj.kind == InteractableObject.Kind.MYSTERY_BOX:
			var pts_before := gm.points
			obj.interact(gm, gm.player)
			_assert(gm.points == pts_before - 500, "Mystery box did not deduct cost")
		elif obj.kind == InteractableObject.Kind.BARRICADE:
			var p0 := obj.plank_count
			obj.interact(gm, gm.player)
			_assert(obj.plank_count == p0 + 1, "Barricade rebuild failed")

	# Player damage, death, and clean restart
	gm.player.take_damage(120.0)
	_assert(gm.player.dead and gm.hud.defeat_panel.visible, "Player death/defeat screen failed")
	gm.restart_game()
	_assert(not gm.player.dead and gm.player.health == 100.0 and gm.kills == 0, "Restart did not reset cleanly")

	print("GAMEPLAY_GUARD_PASS")
	gm.queue_free()
	await process_frame
	quit(0)
