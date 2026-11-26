extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir_abs := ProjectSettings.globalize_path("res://assets/baked")
	DirAccess.make_dir_recursive_absolute(dir_abs)
	var world := WorldBuilder.new()
	world.name = "WorldBake"
	root.add_child(world)
	world.build_world()
	for _i in range(4):
		await process_frame
	world.bake_voxel_gis(true)
	for _i in range(2):
		await process_frame
	world.queue_free()
	quit(0)
