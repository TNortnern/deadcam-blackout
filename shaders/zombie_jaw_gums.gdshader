shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic;
uniform bool has_albedo_tex = true;
uniform bool has_normal_tex = true;

void fragment() {
	vec3 tex_col = has_albedo_tex ? texture(albedo_tex, UV).rgb : vec3(0.65, 0.58, 0.46);
	float lum = dot(tex_col, vec3(0.299, 0.587, 0.114));
	float red_bias = clamp((tex_col.r - tex_col.b) * 3.0, 0.0, 1.0);
	// Bright ivory tooth crowns vs dark recessed wet necrotic crimson gingiva
	float tooth_mask = smoothstep(0.24, 0.42, lum) * (1.0 - red_bias * 0.45);
	vec3 tooth_col = clamp(tex_col * vec3(1.12, 1.04, 0.90), vec3(0.0), vec3(0.82));
	vec3 gum_col = mix(vec3(0.18, 0.018, 0.016), tex_col * vec3(0.65, 0.16, 0.14), 0.35);

	ALBEDO = mix(gum_col, tooth_col, tooth_mask);
	ROUGHNESS = mix(0.06, 0.18, tooth_mask);
	SPECULAR = mix(0.68, 0.52, tooth_mask);
	CLEARCOAT = mix(0.95, 0.72, tooth_mask);
	CLEARCOAT_ROUGHNESS = mix(0.04, 0.09, tooth_mask);
	if (has_normal_tex) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = 1.35;
	}
}
