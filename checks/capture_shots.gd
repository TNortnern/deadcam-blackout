extends SceneTree
## Deterministic multi-state screenshot capturer for DEADCAM: BLACKOUT hill-climb.

var out_dir: String = ""
var mode: String = "visible"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--out" and i + 1 < args.size():
			out_dir = args[i + 1]
		elif args[i] == "--mode" and i + 1 < args.size():
			mode = args[i + 1]
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://.hill-climb/bodycam-aaa/shots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")


func _settle(frames: int = 8) -> void:
	for _i in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw


func _snap(filename: String) -> void:
	await _settle(10)
	var img := root.get_viewport().get_texture().get_image()
	var full := out_dir.path_join(filename)
	var err := img.save_jpg(full, 0.92)
	if err != OK:
		push_error("Failed saving shot: " + full)
		quit(2)
	print("CAPTURED:", filename, " ", img.get_width(), "x", img.get_height())


func _run() -> void:
	seed(1337)
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		push_error("Failed loading res://scenes/main.tscn")
		quit(1)
		return
	var gm: GameManager = scene.instantiate()
	root.add_child(gm)
	current_scene = gm
	await _settle(6)

	gm.deterministic_mode = true
	gm.hud.set_capture_mode(true)
	gm.clear_zombies()
	gm.world.set_asylum_power(false)
	gm.world.moon_light.light_energy = 0.045

	if mode == "holdout":
		await _capture_holdout(gm)
	else:
		await _capture_visible(gm)

	print("CAPTURE_COMPLETE mode=", mode)
	gm.queue_free()
	await process_frame
	quit(0)


func _capture_visible(gm: GameManager) -> void:
	# 1. Asylum Grand Lobby & Reception Desk (compare ref #16)
	gm.clear_zombies()
	gm.player.set_deterministic_view(Vector3(0.15, 0.05, 0.65), -0.78, -0.05, 0, false, false)
	await _snap("01_asylum_lobby.jpg")

	# 2. Vaulted Brick Catacomb Tunnel + Flashlight Cone + Lurking Zombie (compare ref #13)
	gm.clear_zombies()
	var zt := gm.spawn_zombie_at(Vector3(0.42, 0.02, -18.5), ZombieAI.Variant.TACTICAL_SOLDIER, 0.25)
	zt.set_cinematic_pose(1.1, 0.28, -0.22)
	gm.player.set_deterministic_view(Vector3(-0.32, 0.05, -12.0), -0.05, -0.10, 0, false, true)
	await _snap("02_tunnel_flashlight.jpg")

	# 3. Snowy Mud Night Path + Distant Warm Lantern Oasis + Pine Silhouettes (compare ref #12)
	gm.clear_zombies()
	gm.player.set_deterministic_view(Vector3(0.4, 0.05, -31.5), -0.24, -0.10, 0, false, true)
	await _snap("03_snow_courtyard.jpg")

	# 4. ADS Holographic Sight at Zombie Emerging from Wooden Cabin Porch (compare ref #15)
	gm.clear_zombies()
	var zc := gm.spawn_zombie_at(Vector3(0.05, 0.12, -52.4), ZombieAI.Variant.TACTICAL_SOLDIER, 0.08)
	zc.set_cinematic_pose(0.6, 0.24, 0.05)
	var zc2 := gm.spawn_zombie_at(Vector3(-0.85, 0.12, -53.8), ZombieAI.Variant.ASYLUM_PATIENT, 0.2)
	zc2.set_cinematic_pose(2.0, 0.30, -0.1)
	gm.player.set_deterministic_view(Vector3(0.0, 0.05, -45.5), 0.0, 0.03, 1, true, true)
	await _snap("04_ads_cabin_combat.jpg")

	# 5. Close-Up Tactical Zombie Horde in Dark Pine Forest (compare ref #4 — lead zombie close to lens!)
	gm.clear_zombies()
	var z1 := gm.spawn_zombie_at(Vector3(-12.05, 0.02, -36.55), ZombieAI.Variant.TACTICAL_SOLDIER, 0.55)
	z1.set_cinematic_pose(0.4, 0.14, -0.52)
	var z2 := gm.spawn_zombie_at(Vector3(-12.85, 0.02, -37.55), ZombieAI.Variant.TACTICAL_SOLDIER, 0.22)
	z2.set_cinematic_pose(1.8, 0.24, 0.10)
	var z3 := gm.spawn_zombie_at(Vector3(-11.15, 0.02, -37.95), ZombieAI.Variant.RUNNER, -0.18)
	z3.set_cinematic_pose(2.7, 0.30, 0.15)
	var z4 := gm.spawn_zombie_at(Vector3(-13.60, 0.02, -38.60), ZombieAI.Variant.TACTICAL_SOLDIER, 0.30)
	z4.set_cinematic_pose(0.9, 0.22, -0.10)
	gm.player.set_deterministic_view(Vector3(-12.0, 0.05, -35.35), 0.08, 0.02, 1, false, true)
	await _snap("05_zombie_closeup.jpg")

	# 6. Decaying Asylum Grand Wooden Staircase Looking Up (compare ref #3 — close to carved newel & balusters!)
	gm.clear_zombies()
	gm.player.set_deterministic_view(Vector3(-5.9, 0.05, 3.85), 0.28, 0.38, 0, false, false)
	await _snap("06_grand_staircase.jpg")


func _capture_holdout(gm: GameManager) -> void:
	# H1. Storage Alcove Stacked Oak Barrels & Glass Door (compare ref #18)
	gm.clear_zombies()
	gm.player.set_deterministic_view(Vector3(-6.4, 0.05, 2.8), PI + 0.08, -0.08, 0, false, true)
	await _snap("h1_storage_barrels.jpg")

	# H2. Deep Tunnel Archway & Rubble with Close Zombie (compare ref #5)
	gm.clear_zombies()
	var zh := gm.spawn_zombie_at(Vector3(0.55, 0.02, -23.0), ZombieAI.Variant.ASYLUM_PATIENT, 0.4)
	zh.set_cinematic_pose(1.5, 0.32, -0.25)
	gm.player.set_deterministic_view(Vector3(-0.25, 0.05, -18.2), -0.04, -0.12, 0, false, true)
	await _snap("h2_tunnel_ambush.jpg")

	# H3. Snowy Fence & Pine Forest Fog Edge (compare ref #8)
	gm.clear_zombies()
	gm.player.set_deterministic_view(Vector3(-3.8, 0.05, -32.2), 0.42, -0.06, 0, false, true)
	await _snap("h3_fence_forest.jpg")
