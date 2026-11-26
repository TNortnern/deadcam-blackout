shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D disp_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D rough_tex : repeat_enable, filter_linear_mipmap;
varying vec2 rubble_uv;
varying vec3 w_pos;

vec3 unpack_nrm(vec3 c) {
	vec2 xy = c.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.01)));
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	rubble_uv = VERTEX.xz * 0.59;
	float bank = smoothstep(0.38, 2.20, abs(VERTEX.x));
	float heave = textureLod(disp_tex, rubble_uv * 0.27, 0.0).r;
	float height = textureLod(disp_tex, rubble_uv, 0.0).r;
	float ends = 1.0 - smoothstep(7.8, 8.98, abs(VERTEX.z));
	VERTEX.y += ends * (0.28 * height + bank * (0.12 + 0.88 * heave));
}

void fragment() {
	vec3 stone = texture(albedo_tex, rubble_uv).rgb;
	vec3 stone_det = texture(albedo_tex, rubble_uv * 2.35 + vec2(0.41, 0.19)).rgb;
	float h = texture(disp_tex, rubble_uv).r;
	float base_r = texture(rough_tex, rubble_uv).r;
	vec3 n_main = texture(normal_tex, rubble_uv).rgb;
	vec3 n_det = texture(normal_tex, rubble_uv * 2.35 + vec2(0.41, 0.19)).rgb;

	// Damp seepage trough down the worn center of the collapsed catacomb floor
	float center_trough = (1.0 - smoothstep(0.35, 1.35, abs(w_pos.x))) * smoothstep(0.25, 0.65, 1.0 - h);
	vec3 col = mix(stone, stone * (0.72 + 0.56 * stone_det), 0.35) * vec3(0.72, 0.67, 0.63);
	col *= mix(0.62, 1.06, smoothstep(0.15, 0.82, h));
	col *= mix(1.0, 0.58, center_trough);

	vec3 nm_u = unpack_nrm(n_main);
	vec3 nd_u = unpack_nrm(n_det);
	vec3 n_comb = normalize(vec3(nm_u.xy + nd_u.xy * 0.38, nm_u.z)) * 0.5 + 0.5;
	n_comb = mix(n_comb, vec3(0.5, 0.5, 1.0), center_trough * 0.65);

	ALBEDO = col;
	ROUGHNESS = mix(clamp(base_r * 0.92, 0.40, 0.95), 0.09, center_trough);
	SPECULAR = mix(0.42, 0.66, center_trough);
	AO = clamp(smoothstep(0.10, 0.72, h) * 0.85 + 0.15, 0.16, 1.0);
	AO_LIGHT_AFFECT = 0.82;
	NORMAL_MAP = n_comb;
	NORMAL_MAP_DEPTH = 1.65;
}
