shader_type spatial;
render_mode cull_disabled;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float height = clamp((local_position.y - 0.36) / 0.22, 0.0, 1.0);
	float angle = atan(local_position.z, local_position.x);
	float pleats = 0.5 + 0.5 * cos(angle * 40.0);
	float weave = 0.94 + 0.035 * cos(height * 386.0) + 0.022 * cos(angle * 272.0);
	float hems = smoothstep(0.006, 0.039, min(height, 1.0 - height));
	float transmission = (0.48 + 0.52 * sin(0.35 + height * 2.40)) * (0.77 + 0.23 * pleats);
	ALBEDO = vec3(0.52, 0.35, 0.21) * weave;
	EMISSION = vec3(3.30, 2.33, 1.36) * transmission * weave * mix(0.11, 1.0, hems);
	SPECULAR = 0.1;
	ROUGHNESS = 0.93;
}
