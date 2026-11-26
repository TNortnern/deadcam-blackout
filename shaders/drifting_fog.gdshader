shader_type fog;

uniform sampler3D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 fog_albedo : source_color = vec3(0.42, 0.49, 0.56);
uniform vec3 fog_emission : source_color = vec3(0.002, 0.003, 0.004);
uniform float base_density : hint_range(0.0, 1.5) = 0.14;
uniform float floor_hug : hint_range(0.0, 3.0) = 0.85;
uniform vec3 drift_speed = vec3(0.028, -0.006, 0.014);
uniform float noise_scale : hint_range(0.2, 4.0) = 1.25;
uniform float fade_edge : hint_range(0.05, 0.48) = 0.24;

void fog() {
	vec3 d_edge = min(UVW, 1.0 - UVW) / max(fade_edge, 0.02);
	float box_fade = clamp(d_edge.x, 0.0, 1.0) * clamp(d_edge.y, 0.0, 1.0) * clamp(d_edge.z, 0.0, 1.0);
	box_fade = box_fade * box_fade * (3.0 - 2.0 * box_fade);

	float n1 = texture(noise_tex, UVW * noise_scale + TIME * drift_speed).r;
	float wisp = smoothstep(0.24, 0.86, n1);

	// Thicker near damp lower floor, thinner near ceiling
	float low_bias = mix(1.0, 1.45 - UVW.y * 0.85, clamp(floor_hug, 0.0, 1.0));
	DENSITY = base_density * box_fade * (0.28 + 0.92 * wisp) * max(low_bias, 0.2);
	ALBEDO = fog_albedo;
	EMISSION = fog_emission;
}
