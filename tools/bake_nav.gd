extends SceneTree
## Bakes the zombie navigation mesh from the procedurally built world and saves it to assets/baked/navmesh.res.
## Re-run after any change to world geometry:  godot --path . --script tools/bake_nav.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var gm: GameManager = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	gm.deterministic_mode = true
	root.add_child(gm)
	current_scene = gm
	for _i in range(6):
		await process_frame
	var w: WorldBuilder = gm.world
	if w == null:
		push_error("World failed to build")
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var nm := w.bake_navigation_mesh()
	var ms := Time.get_ticks_msec() - t0
	var polys := nm.get_polygon_count()
	print("NAV_BAKE polygons=", polys, " vertices=", nm.get_vertices().size(), " ms=", ms, " sig=", nm.get_meta("geo_sig", 0))
	if polys == 0:
		push_error("Navigation bake produced no polygons")
		quit(2)
		return
	var err := ResourceSaver.save(nm, WorldBuilder.NAV_PATH, ResourceSaver.FLAG_COMPRESS)
	print("NAV_SAVED err=", err, " bytes=", FileAccess.get_file_as_bytes(WorldBuilder.NAV_PATH).size())
	quit(0 if err == OK else 3)
