extends SceneTree

const OUT_DIR := "C:/Users/trayn/.t3/scratch/deadcam_cc0_cache/verify_phase3_fps"

func _init() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("PHASE3_FAIL: " + msg)
	print("PHASE3_FAIL: ", msg)
	quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)

func _snap(gm: GameManager, fname: String) -> void:
	await process_frame
	await process_frame
	var img := gm.render_vp.get_texture().get_image()
	if img:
		img.save_png(OUT_DIR + "/" + fname)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var is_compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var scene := load("res://scenes/main.tscn")
	_assert(scene != null, "main.tscn load failed")
	var gm: GameManager = scene.instantiate()
	gm.deterministic_mode = true
	root.add_child(gm)
	current_scene = gm
	await process_frame
	await process_frame
	await process_frame

	var p: PlayerBodycam = gm.player
	var w: WorldBuilder = gm.world
	gm.hud.set_capture_mode(true)

	# 1. FPS Hip + ADS renders of all 7 Phase 3 weapons + 4-phase reload contact frames (Forward+)
	if not is_compat:
		var names := {
			11: "sawed_off",
			12: "famas",
			13: "garand",
			14: "kar98k",
			15: "crossbow",
			16: "flamethrower",
			17: "rpg7",
		}
		for wi in [11, 12, 13, 14, 15, 16, 17]:
			p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, wi, false, true)
			p.vm_rim.light_energy = 1.95
			await _snap(gm, "hip_%02d_%s.png" % [wi, names[wi]])
			p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, wi, true, true)
			p.vm_rim.light_energy = 1.95
			await _snap(gm, "ads_%02d_%s.png" % [wi, names[wi]])

		# Reload keyframe renders (mid-extract / open / insert) for 11, 12, 13, 14, 15, 17
		var reload_specs := [
			[11, "sawed_off", [0.36, 0.98, 1.32, 1.72]],
			[12, "famas", [0.42, 0.76, 1.16, 1.72]],
			[13, "garand", [0.32, 0.72, 1.08, 1.50]],
			[14, "kar98k", [0.34, 0.76, 1.18, 1.76]],
			[15, "crossbow", [0.24, 0.66, 0.98, 1.24]],
			[17, "rpg7", [0.42, 0.88, 1.32, 1.85]],
		]
		for rspec in reload_specs:
			var rwi: int = rspec[0]
			var rnm: String = rspec[1]
			var times: Array = rspec[2]
			p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, rwi, false, true)
			p.deterministic_camera = false
			p.input_enabled = true
			p.ammo_in_mag[rwi] = 0
			p.ammo_reserve[rwi] = 20
			p.weapon_chambered[rwi] = false
			var started := p.start_reload()
			_assert(started, "Reload failed to start for %s" % rnm)
			for ti in range(times.size()):
				p.reload_elapsed = float(times[ti]) - 0.016
				p._update_reload(0.016)
				p._process(0.016)
				await _snap(gm, "reload_%s_p%d.png" % [rnm, ti + 1])
			p.is_reloading = false
			p._reset_weapon_parts()
			p.deterministic_camera = true

	gm.deterministic_mode = false
	gm.start_game()
	p.deterministic_camera = false

	# 2. Verify FAMAS F1 (12) 3-round burst + burst-cancel on reload/melee + non-null audio!
	_assert(p._weapon_audio[12] != null, "FAMAS audio stream is null!")
	p.acquire_weapon(12, true)
	var famas_mag0: int = p.ammo_in_mag[12]
	_assert(p.fire_weapon(), "FAMAS trigger pull failed")
	for _bf in range(18):
		p._physics_process(0.016)
	_assert(p.ammo_in_mag[12] == famas_mag0 - 3, "FAMAS 3-round burst expended %d rounds instead of 3!" % (famas_mag0 - p.ammo_in_mag[12]))
	# Trigger another burst and immediately reload -> _burst_remaining MUST cancel to 0!
	p.fire_cd = 0.0
	_assert(p.fire_weapon(), "FAMAS second burst failed")
	_assert(p._burst_remaining > 0, "FAMAS burst did not queue remaining shots")
	_assert(p.start_reload(), "FAMAS reload cancel failed")
	_assert(p._burst_remaining == 0, "FAMAS burst did not clear on reload!")
	p.is_reloading = false
	p._reset_weapon_parts()
	print("FAMAS_BURST_OK")

	# 3. Verify M1 Garand (13) empty clip + reload & Kar98k (14) bolt throw + high damage!
	p.acquire_weapon(13, true)
	p.ammo_in_mag[13] = 1
	_assert(p.fire_weapon(), "Garand final shot failed")
	_assert(p.ammo_in_mag[13] == 0 and not p.weapon_chambered[13], "Garand empty state wrong")
	_assert(p.start_reload(), "Garand reload failed to start")
	p.is_reloading = false
	p._reset_weapon_parts()

	p.acquire_weapon(14, true)
	p.fire_cd = 0.0
	var z_kar := gm.spawn_zombie_at(p.camera.global_position - p.camera.global_transform.basis.z * 5.0, ZombieAI.Variant.BRUISER, 0.0, false)
	z_kar.global_position.y = p.global_position.y
	var hp_kar0 := z_kar.health
	_assert(p.fire_weapon(), "Kar98k fire failed")
	_assert(p._hunting_bolt_timer > 0.5, "Kar98k bolt timer did not start!")
	_assert(z_kar.dead or z_kar.health < hp_kar0 - 80.0, "Kar98k did not deal expected high rifle damage! hp0=%f hp1=%f" % [hp_kar0, z_kar.health])
	z_kar.queue_free()
	print("GARAND_KAR98K_OK")

	# 4. Verify Heavy Crossbow (15) launches physical bolt WITHOUT touching Compound Bow (4) ammo!
	p.ammo_in_mag[4] = 1
	p.ammo_reserve[4] = 12
	p.acquire_weapon(15, true)
	p.fire_cd = 0.0
	var arr0 := p._arrows.size()
	_assert(p.fire_weapon(), "Crossbow fire failed")
	_assert(p._arrows.size() == arr0 + 1, "Crossbow did not launch physical bolt!")
	_assert(p.ammo_in_mag[4] == 1 and p.ammo_reserve[4] == 12, "Crossbow corrupted Compound Bow [4] ammo!")
	_assert(p.ammo_in_mag[15] == 0, "Crossbow mag did not decrement!")
	var bolt_d: Dictionary = p._arrows[p._arrows.size() - 1]
	_assert(int(bolt_d.get("weapon_idx", -1)) == 15 and float(bolt_d.get("dmg", 0.0)) >= 180.0, "Crossbow bolt metadata wrong: " + str(bolt_d))
	print("CROSSBOW_OK")

	# 5. Verify M2 Flamethrower (16) Special Slot + Burn + Fire Pool + NO AMMO REFILL!
	var ammo_crate: InteractableObject = null
	var gen: InteractableObject = null
	var bench: InteractableObject = null
	for inter: InteractableObject in w.interactables:
		if inter.kind == InteractableObject.Kind.AMMO_CRATE: ammo_crate = inter
		elif inter.kind == InteractableObject.Kind.GENERATOR: gen = inter
		elif inter.kind == InteractableObject.Kind.UPGRADE_BENCH: bench = inter
	_assert(ammo_crate != null and gen != null and bench != null, "Missing crate/gen/bench")
	gen.interact(gm, p)
	gm.points = 5000

	p.acquire_weapon(16, true)
	_assert(p.special_slot == 16, "Flamethrower did not occupy Special Slot!")
	p.fire_cd = 0.0
	p._flame_pool_cd = 0.0
	var haz0 := p._hazards.size()
	var z_burn := gm.spawn_zombie_at(p.camera.global_position - p.camera.global_transform.basis.z * 4.5, ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_burn.global_position.y = p.global_position.y
	_assert(p.fire_weapon(), "Flamethrower fire failed")
	_assert(p._hazards.size() > haz0, "Flamethrower did not spawn burning floor pool!")
	_assert(z_burn.burn_timer > 0.0 or z_burn.dead, "Flamethrower did not ignite zombie!")
	z_burn.queue_free()
	var fuel_before: int = p.ammo_in_mag[16]
	var crate_msg := ammo_crate.interact(gm, p)
	_assert(p.ammo_in_mag[16] == fuel_before and "cannot buy ammo refills" in crate_msg.to_lower(), "Ammo Crate refilled no-refill Flamethrower! msg=" + crate_msg)
	print("FLAMETHROWER_AND_NO_REFILL_OK")

	# 6. Verify RPG-7 (17) Special Slot + Rocket Flight + AoE Detonation + NO AMMO REFILL!
	p.acquire_weapon(17, true)
	_assert(p.special_slot == 17, "RPG-7 did not occupy Special Slot!")
	p.fire_cd = 0.0
	var z_rpg := gm.spawn_zombie_at(p.camera.global_position - p.camera.global_transform.basis.z * 5.0, ZombieAI.Variant.TACTICAL_SOLDIER, 0.0, false)
	z_rpg.global_position.y = p.global_position.y
	var r0 := p._rockets.size()
	_assert(p.fire_weapon(), "RPG-7 fire failed")
	_assert(p._rockets.size() == r0 + 1, "RPG-7 did not spawn rocket!")
	for _rf in range(20):
		p._update_rockets(0.03)
		if p._rockets.is_empty():
			break
	_assert(p._rockets.is_empty() and z_rpg.dead, "RPG-7 rocket did not impact & kill target zombie!")
	var rpg_crate_msg := ammo_crate.interact(gm, p)
	_assert("cannot buy ammo refills" in rpg_crate_msg.to_lower(), "Ammo Crate refilled no-refill RPG-7! msg=" + rpg_crate_msg)
	print("RPG7_OK")

	# 7. Verify Armory Upgrade Bench Modular Attachments (MK-II -> OPTIC -> SUPPRESSOR) + Restart Cleanup!
	p.acquire_weapon(12, true)
	var m1 := bench.interact(gm, p) # MK-II
	_assert(p.is_weapon_upgraded(12), "MK-II upgrade failed: " + m1)
	var m2 := bench.interact(gm, p) # OPTIC
	_assert(p.has_attachment(12, "optic") and p.holo_quad.visible, "Optic attachment failed: " + m2)
	var m3 := bench.interact(gm, p) # SUPPRESSOR
	_assert(p.has_attachment(12, "suppressor"), "Suppressor attachment failed: " + m3)
	p.heal_full(true)
	_assert(p.weapon_attachments.is_empty() and p._rockets.is_empty() and p.upgraded_weapons.size() == PlayerBodycam.WEAPONS.size() and p.weapon_chambered.size() == PlayerBodycam.WEAPONS.size(), "heal_full(true) cleanup failed!")
	print("ATTACHMENTS_AND_CLEANUP_OK")

	print("PHASE3_VERIFY_PASS compat=", is_compat)
	gm.queue_free()
	await process_frame
	quit(0)
