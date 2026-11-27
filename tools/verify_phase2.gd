extends SceneTree

const OUT_DIR := "C:/Users/trayn/.t3/scratch/deadcam_cc0_cache/verify_phase2"

func _init() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	push_error("PHASE2_FAIL: " + msg)
	print("PHASE2_FAIL: ", msg)
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

func _render_studio(glb_path: String, out_name: String) -> void:
	var svp := SubViewport.new()
	svp.size = Vector2i(640, 360)
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.own_world_3d = true
	svp.msaa_3d = Viewport.MSAA_4X
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.90, 0.92, 0.96)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	svp.add_child(we)
	var key_l := DirectionalLight3D.new()
	key_l.light_energy = 2.5
	key_l.rotation_degrees = Vector3(-34, 42, 0)
	svp.add_child(key_l)
	var fill_l := DirectionalLight3D.new()
	fill_l.light_energy = 1.2
	fill_l.rotation_degrees = Vector3(-18, -130, 0)
	svp.add_child(fill_l)
	var cam := Camera3D.new()
	cam.fov = 34.0
	svp.add_child(cam)
	root.add_child(svp)
	var pk: PackedScene = load(glb_path)
	_assert(pk != null, "GLB load failed: " + glb_path)
	var inst := pk.instantiate()
	svp.add_child(inst)
	await process_frame
	var aabb := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		var b := m.global_transform * m.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	var center := aabb.get_center()
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var dist := maxf(0.28, max_dim * 1.55)
	cam.position = center + Vector3(dist * 0.88, dist * 0.22, dist * 0.44)
	cam.look_at(center, Vector3.UP)
	await process_frame
	await process_frame
	var simg := svp.get_texture().get_image()
	if simg:
		simg.save_png(OUT_DIR + "/" + out_name)
	svp.queue_free()
	await process_frame

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

	# 1. Studio 3/4 + FPS Hip + 4-Phase Melee Swing captures on Forward+
	if not is_compat:
		for spec in [
			["bat", "res://assets/models/weapon_melee_bat.glb"],
			["bat_spiked", "res://assets/models/weapon_melee_bat_spiked.glb"],
			["crowbar", "res://assets/models/weapon_melee_crowbar.glb"],
		]:
			await _render_studio(spec[1], "studio_%s.png" % spec[0])
			p.acquire_melee_weapon(spec[0])
			p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, 3, false, true)
			p.vm_rim.light_energy = 1.85
			await _snap(gm, "fps_%s.png" % spec[0])
		# 4-phase swing inspection on Spiked Bat (windup, combo 0, combo 1, heavy cleave)
		p.acquire_melee_weapon("bat_spiked")
		p.set_deterministic_view(Vector3(-1.2, 0.05, 3.6), -0.35, 0.0, 3, false, true)
		p.deterministic_camera = false
		p.input_enabled = true
		p._melee_dur = 0.52
		p._melee_is_gun_bash = false
		for ph in [
			["swing_windup.png", false, 0, 0.44],
			["swing_combo0.png", false, 0, 0.28],
			["swing_combo1.png", false, 1, 0.28],
			["swing_heavy.png", true, 0, 0.28],
		]:
			p._melee_is_heavy = ph[1]
			p._melee_combo_idx = ph[2]
			p._melee_timer = ph[3]
			p._process(0.05)
			p._process(0.05)
			await _snap(gm, ph[0])
		p._melee_timer = 0.0
		p.deterministic_camera = true

	gm.deterministic_mode = false
	gm.start_game()
	p.deterministic_camera = false

	# 2. Verify Bat -> Spiked Bat upgrade at Upgrade Bench (replaces bat in owned_melee!) + Bleed DoT kill awards points!
	var gen: InteractableObject = null
	var bench: InteractableObject = null
	for inter: InteractableObject in w.interactables:
		if inter.kind == InteractableObject.Kind.GENERATOR: gen = inter
		elif inter.kind == InteractableObject.Kind.UPGRADE_BENCH: bench = inter
	_assert(gen != null and bench != null, "Missing gen/bench")
	gen.interact(gm, p)
	gm.points = 2000
	p.owned_melee = ["knife", "bat"]
	p.select_melee_weapon("bat")
	p.equip_melee_slot()
	var upg_msg := bench.interact(gm, p)
	_assert(p.equipped_melee_id == "bat_spiked" and not p.owned_melee.has("bat") and gm.points == 1250, "Bat -> Spiked Bat bench upgrade failed: " + upg_msg)
	var z_bleed := gm.spawn_zombie_at(Vector3(-1.2, 0.05, 2.0), ZombieAI.Variant.ASYLUM_PATIENT, 0.0, false)
	z_bleed.health = 15.0
	var pts0 := gm.points
	z_bleed.apply_bleed(4.0, 45.0)
	z_bleed._tick_status_effects(0.45)
	_assert(z_bleed.dead and gm.points > pts0, "Bleed DoT kill failed to kill or award points!")
	print("MELEE_SPIKES_AND_BLEED_OK")

	# 3. Verify Leg-Shot -> Live Crawler stays prone across TRIPPED & WINDUP!
	var z_leg := gm.spawn_zombie_at(Vector3(1.5, 0.05, 1.5), ZombieAI.Variant.TACTICAL_SOLDIER, 0.0, false)
	z_leg.apply_shot([{"zone": "LEG_L", "pos": z_leg.global_position + Vector3(0, 0.5, 0), "dir": Vector3.FORWARD, "dmg": 78.0, "dist": 3.0}], 1)
	_assert(not z_leg.dead and z_leg.is_crawler, "Leg shot did not drop zombie into live Crawler!")
	var cap := z_leg._body_col.shape as CapsuleShape3D
	_assert(cap != null and cap.height < 1.0, "Crawler collision capsule did not shrink!")
	for _f in range(15):
		await physics_frame
	_assert(z_leg.rig_root.rotation.x > 1.05 and z_leg.rig_root.position.z < -0.5, "Crawler popped upright or failed capsule centering! rot=%s pos=%s" % [str(z_leg.rig_root.rotation), str(z_leg.rig_root.position)])
	z_leg.queue_free()
	print("CRAWLER_DISMEMBERMENT_OK")

	# 4. Verify Heavy Bruiser (uniform scale ragdoll ZERO Jolt errors!) & Volatile Exploder (body blast vs headshot defuse!)
	var z_bruiser := gm.spawn_zombie_at(Vector3(3.0, 0.05, 0.5), ZombieAI.Variant.BRUISER, 0.0, false)
	_assert(z_bruiser.max_health >= 350.0 and z_bruiser.poise_max >= 150.0, "Bruiser stats wrong")
	z_bruiser.apply_shot([{"zone": "HEAD", "pos": z_bruiser.global_position + Vector3(0, 1.8, 0), "dir": Vector3.FORWARD, "dmg": 999.0, "dist": 4.0}], 7)
	for _rf in range(5):
		await physics_frame
	_assert(z_bruiser.dead, "Bruiser ragdoll step failed")
	z_bruiser.queue_free()

	# Exploder body-shot death -> detonates & harms nearby bystander zombie!
	var z_exp1 := gm.spawn_zombie_at(Vector3(-3.0, 0.05, -2.0), ZombieAI.Variant.EXPLODER, 0.0, false)
	var z_near1 := gm.spawn_zombie_at(Vector3(-3.0, 0.05, -3.5), ZombieAI.Variant.TACTICAL_SOLDIER, 0.0, false)
	var hp_near1 := z_near1.health
	z_exp1.apply_shot([{"zone": "CHEST", "pos": z_exp1.global_position + Vector3(0, 1.1, 0), "dir": Vector3.FORWARD, "dmg": 150.0, "dist": 5.0}], 1)
	_assert(z_exp1.dead and z_exp1._exploder_detonated, "Exploder body kill did not detonate!")
	_assert(z_near1.dead or z_near1.health < hp_near1, "Exploder blast did not damage adjacent zombie!")

	# Exploder headshot death -> defuses cleanly (adjacent zombie untouched!)
	var z_exp2 := gm.spawn_zombie_at(Vector3(4.0, 0.05, -2.0), ZombieAI.Variant.EXPLODER, 0.0, false)
	var z_near2 := gm.spawn_zombie_at(Vector3(4.0, 0.05, -3.2), ZombieAI.Variant.TACTICAL_SOLDIER, 0.0, false)
	var hp_near2 := z_near2.health
	z_exp2.apply_shot([{"zone": "HEAD", "pos": z_exp2.global_position + Vector3(0, 1.55, 0), "dir": Vector3.FORWARD, "dmg": 120.0, "dist": 5.0}], 1)
	_assert(z_exp2.dead and z_near2.health == hp_near2, "Exploder headshot kill MUST defuse without harming bystander!")
	print("BRUISER_AND_EXPLODER_OK")

	print("PHASE2_VERIFY_PASS compat=", is_compat)
	gm.queue_free()
	await process_frame
	quit(0)
