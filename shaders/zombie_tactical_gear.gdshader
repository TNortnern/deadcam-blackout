shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D weave_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;

uniform bool has_albedo_tex = true;
uniform bool has_normal_tex = true;

uniform vec4 fabric_tint : source_color = vec4(0.55, 0.56, 0.52, 1.0);
uniform float albedo_gamma = 1.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform float weave_scale = 12.0;
uniform float weave_strength = 0.65;
uniform float blood_stain_strength = 0.70;
uniform float mud_strength = 0.62;
uniform float wet_rain_strength = 0.45;
uniform float seed_offset = 0.0;

// Locked bind-pose coordinates so garment mud/blood/moisture NEVER swim during walking or ragdoll!
varying vec3 rest_pos;
varying float rest_ny;

vec3 unpack_nrm(vec3 c) {
	vec2 xy = c.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.01)));
}

float hash31(vec3 p) {
	p = fract(p * vec3(127.1, 311.7, 74.7));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash31(i), hash31(i + vec3(1,0,0)), f.x), mix(hash31(i + vec3(0,1,0)), hash31(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash31(i + vec3(0,0,1)), hash31(i + vec3(1,0,1)), f.x), mix(hash31(i + vec3(0,1,1)), hash31(i + vec3(1,1,1)), f.x), f.y),
		f.z
	);
}

void vertex() {
	rest_pos = vec3(UV2.x, UV2.y, COLOR.r * 3.0 - 1.5);
	rest_ny = COLOR.g * 2.0 - 1.0;
}

void fragment() {
	vec2 f_uv = UV * uv_scale + uv_offset;
	vec3 base_col = has_albedo_tex ? pow(max(texture(albedo_tex, f_uv).rgb, vec3(0.003)), vec3(albedo_gamma)) : vec3(0.32, 0.34, 0.31);
	vec3 col = base_col * fabric_tint.rgb;

	vec3 gp = rest_pos * 3.5 + vec3(seed_offset * 2.3, 0.0, seed_offset * 1.9);
	float n_macro = vnoise3(gp * 1.3);
	float n_fine = vnoise3(gp * 5.4);

	float lower_hem = clamp(1.0 - smoothstep(0.10, 0.78, rest_pos.y + n_macro * 0.24), 0.0, 1.0);
	float mud_mask = clamp(lower_hem * (0.55 + 0.45 * n_fine) * mud_strength, 0.0, 1.0);
	col = mix(col, vec3(0.09, 0.075, 0.062), mud_mask * 0.78);

	float chest_zone = smoothstep(0.75, 1.40, rest_pos.y);
	float blood_n = vnoise3(gp * 2.5) * 0.6 + n_fine * 0.4;
	float dried_blood = smoothstep(0.55, 0.78, blood_n + chest_zone * 0.14) * blood_stain_strength;
	float fresh_blood = smoothstep(0.68, 0.86, blood_n + chest_zone * 0.14) * blood_stain_strength;
	col = mix(col, vec3(0.11, 0.022, 0.018), dried_blood * 0.72);
	col = mix(col, vec3(0.16, 0.010, 0.008), fresh_blood * 0.65);

	float damp_shoulders = smoothstep(0.25, 0.85, rest_ny) * wet_rain_strength * (0.5 + 0.5 * n_macro);
	col *= mix(1.0, 0.66, damp_shoulders);

	vec3 n_fold = has_normal_tex ? unpack_nrm(texture(normal_tex, f_uv).rgb) : vec3(0.0, 0.0, 1.0);
	vec3 n_weave = unpack_nrm(texture(weave_normal_tex, UV * weave_scale).rgb);
	vec3 n_comb = normalize(vec3(n_fold.xy + n_weave.xy * weave_strength, n_fold.z));

	float rough = mix(0.91, 0.42, damp_shoulders * 0.65);
	rough = mix(rough, 0.76, mud_mask);
	rough = mix(rough, 0.18, fresh_blood);

	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = mix(0.07, 0.34, max(damp_shoulders * 0.4, fresh_blood));
	CLEARCOAT = fresh_blood * 0.42;
	CLEARCOAT_ROUGHNESS = 0.14;
	AO = clamp(0.45 + 0.55 * n_fold.z - mud_mask * 0.18, 0.20, 1.0);
	AO_LIGHT_AFFECT = 0.75;
	RIM = 0.0;
	RIM_TINT = 0.30;
	NORMAL_MAP = n_comb * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.45;
}
