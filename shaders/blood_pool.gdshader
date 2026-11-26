shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float growth : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;
uniform vec3 core_color : source_color = vec3(0.055, 0.003, 0.004);
uniform vec3 rim_color : source_color = vec3(0.165, 0.010, 0.012);
uniform float wet_roughness : hint_range(0.02, 0.35) = 0.042;
uniform float rim_roughness : hint_range(0.05, 0.6) = 0.22;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);

	vec2 uv_a = UV * 1.35 + vec2(seed * 0.37, seed * 0.61);
	vec2 uv_b = UV * 2.85 - vec2(seed * 0.53, seed * 0.19);
	float n1 = texture(noise_tex, uv_a).r;
	float n2 = texture(noise_tex, uv_b).r;
	float organic = (n1 * 0.68 + n2 * 0.32);

	// Grow radially over time with organic creeping fingers along floor micro-lows
	float target_radius = mix(0.14, 0.88, sqrt(clamp(growth, 0.0, 1.0)));
	float edge_r = r - (organic - 0.45) * 0.34;
	float pool_mask = 1.0 - smoothstep(target_radius - 0.07, target_radius + 0.03, edge_r);
	float inner_depth = 1.0 - smoothstep(target_radius * 0.35, target_radius * 0.92, edge_r);

	// Outer bounding fade so quad corners can never appear even at full growth
	pool_mask *= 1.0 - smoothstep(0.84, 0.98, r);
	if (pool_mask < 0.01) {
		discard;
	}

	// Convex meniscus lip bump around perimeter
	float lip = smoothstep(target_radius - 0.12, target_radius - 0.03, edge_r) * pool_mask;
	vec2 grad_n = vec2(
		dFdx(organic * 0.15 + lip * 0.25),
		dFdy(organic * 0.15 + lip * 0.25)
	);
	vec3 local_n = normalize(vec3(-grad_n.x * 4.0, -grad_n.y * 4.0, 1.0));
	NORMAL = normalize(NORMAL + (TANGENT * local_n.x + BINORMAL * local_n.y) * 0.38);

	ALBEDO = mix(rim_color, core_color, inner_depth);
	ROUGHNESS = mix(rim_roughness, wet_roughness, inner_depth);
	SPECULAR = mix(0.60, 0.85, inner_depth);
	METALLIC = 0.0;
	ALPHA = pool_mask * mix(0.76, 0.96, inner_depth);
}
