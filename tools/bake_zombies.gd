extends SceneTree

const OUT := {
	ZombieAI.Variant.TACTICAL_SOLDIER: "res://assets/baked/zombie_tactical.scn",
	ZombieAI.Variant.ASYLUM_PATIENT: "res://assets/baked/zombie_patient.scn",
	ZombieAI.Variant.RUNNER: "res://assets/baked/zombie_runner.scn",
}

func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		_own(c, o)

func _initialize() -> void:
	set_meta("baking_zombies", true)
	call_deferred("_run")

func _run() -> void:
	var dir_abs := ProjectSettings.globalize_path("res://assets/baked")
	DirAccess.make_dir_recursive_absolute(dir_abs)
	for v in OUT.keys():
		var z := ZombieAI.new()
		z.variant = v
		root.add_child(z)
		await process_frame
		await process_frame
		var m := z.model_inst
		if m == null:
			push_error("Failed to build model_inst for variant %d" % int(v))
			quit(1)
			return
		for sm in m.find_children("*", "SkeletonModifier3D", true, false):
			sm.get_parent().remove_child(sm)
			sm.free()
		m.get_parent().remove_child(m)
		m.owner = null
		_own(m, m)
		var ps := PackedScene.new()
		var err := ps.pack(m)
		if err != OK:
			push_error("Failed to pack baked zombie variant %d: %d" % [int(v), err])
			quit(2)
			return
		var save_err := ResourceSaver.save(ps, OUT[v], ResourceSaver.FLAG_COMPRESS)
		var abs_f := ProjectSettings.globalize_path(OUT[v])
		var sz := FileAccess.get_file_as_bytes(OUT[v]).size() if FileAccess.file_exists(OUT[v]) else -1
		print("BAKED ", OUT[v], " save_err=", save_err, " bytes=", sz, " abs=", abs_f)
		m.free()
		z.free()
	quit(0)
