@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	for item: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var geometry := item as MeshInstance3D
		for surface in geometry.mesh.get_surface_count():
			var material := geometry.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var id := material.resource_name.to_lower()
			material.metallic_specular = 0.10
			if "visor" in id or "goog" in id or "strap" in id:
				material.roughness = 0.87
				material.metallic = 0.0
				material.metallic_specular = 0.08
			if id == "soddenfieldcoat":
				material.albedo_color *= Color(0.70, 0.71, 0.74)
				material.metallic_specular = 0.045
			if id == "necroticdermis":
				material.subsurf_scatter_enabled = false
				material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
				material.backlight_enabled = true
				material.backlight = Color(0.14, 0.03, 0.025)
			if id == "fern_02":
				material.albedo_color = Color(0.52, 0.36, 0.25)
	return scene
