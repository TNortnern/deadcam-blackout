extends SceneTree
## Lists files under assets/models that nothing in the game loads, so an export can leave them out.
## The game loads most content by string path at runtime, which the exporter's dependency scan cannot see; this tool
## rebuilds the real set: every "res://" literal in scripts and shaders, the world prop list, and their dependencies.
## Usage: godot --headless --path . --script tools/list_unused_assets.gd -- <output txt>

var used := {}


func _initialize() -> void:
	call_deferred("_run")


func _add(path: String) -> void:
	if path == "" or used.has(path) or not path.begins_with("res://"):
		return
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return
	used[path] = true
	if not ResourceLoader.exists(path):
		return
	for dep in ResourceLoader.get_dependencies(path):
		var d := str(dep)
		var i := d.rfind("::")
		_add(d.substr(i + 2) if i >= 0 else d)


func _scan_literals(dir_path: String, exts: Array) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	var re := RegEx.new()
	re.compile("res://[A-Za-z0-9_./\\-]+")
	for f in da.get_files():
		if not exts.has(f.get_extension()):
			continue
		var txt := FileAccess.get_file_as_string(dir_path + "/" + f)
		for m in re.search_all(txt):
			_add(m.get_string())


func _run() -> void:
	_scan_literals("res://scripts", ["gd"])
	_scan_literals("res://shaders", ["gdshader"])
	_scan_literals("res://scenes", ["tscn"])
	for key in WorldBuilder.WORLD_GLB_LIST:
		_add("res://assets/models/%s.glb" % key)
	for w in PlayerBodycam.WEAPONS:
		_add(str((w as Dictionary).get("glb", "")))
	# Everything in these folders is addressed by formatted paths, so they ship whole
	var models_dir := DirAccess.open("res://assets/models")
	var unused: Array[String] = []
	var unused_bytes := 0
	var used_bytes := 0
	for f in models_dir.get_files():
		if f.ends_with(".import") or f.ends_with(".uid"):
			continue
		var p := "res://assets/models/" + f
		var sz := FileAccess.get_file_as_bytes(p).size()
		if used.has(p):
			used_bytes += sz
		else:
			unused.append(p)
			unused_bytes += sz
	unused.sort()
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var out := FileAccess.open(args[0], FileAccess.WRITE)
		out.store_string("\n".join(unused))
		out.close()
	print("ASSETS models used_files=", used.size(), " used_MB=", snappedf(used_bytes / 1048576.0, 0.1), " unused_files=", unused.size(), " unused_MB=", snappedf(unused_bytes / 1048576.0, 0.1))
	quit(0)
