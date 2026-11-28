shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D detail_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;

uniform bool has_albedo_tex = true;
uniform bool has_normal_tex = true;
uniform bool is_head = false;

uniform vec4 skin_tint : source_color = vec4(1.06, 1.02, 0.98, 1.0);
uniform float albedo_gamma = 0.86;
uniform float detail_uv_scale = 11.0;
uniform float detail_strength = 0.72;
uniform float blood_wetness = 0.90;
uniform float gore_seed = 0.0;
uniform float burn_char : hint_range(0.0, 1.0) = 0.0;

// Locked bind-pose rest coordinates decoded from UV2 (x, y) + COLOR (z, normal.y) so gore/veins NEVER swim!
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
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

void vertex() {
	rest_pos = vec3(UV2.x, UV2.y, COLOR.r * 3.0 - 1.5);
	rest_ny = COLOR.g * 2.0 - 1.0;
}

void fragment() {
	vec3 src_col = has_albedo_tex ? texture(albedo_tex, UV).rgb : vec3(0.45, 0.42, 0.40);
	float lum_raw = dot(src_col, vec3(0.299, 0.587, 0.114));
	vec3 lifted = pow(max(src_col, vec3(0.002)), vec3(albedo_gamma)) * skin_tint.rgb;

	// Detect crimson open wounds & mouth/socket wetness only on dark saturated reds
	float red_excess = smoothstep(0.18, 0.36, src_col.r - max(src_col.g, src_col.b)) * (1.0 - smoothstep(0.18, 0.42, lum_raw));

	// Locked 3D anatomical mottling & coagulating arterial blood smears
	vec3 gp = rest_pos * 4.4 + vec3(gore_seed * 3.1, 0.0, gore_seed * 1.7);
	float mottle = vnoise3(gp * 1.7);
	float veins = smoothstep(0.64, 0.88, 1.0 - abs(vnoise3(gp * 4.1) - 0.5) * 2.0);
	float blood_noise = vnoise3(gp * vec3(3.2, 1.5, 3.2)) * 0.65 + vnoise3(gp * 8.0) * 0.35;
	float jaw_zone = is_head ? smoothstep(1.62, 1.44, rest_pos.y) : smoothstep(0.75, 1.48, rest_pos.y);
	float proc_gore = smoothstep(0.58, 0.79, blood_noise + jaw_zone * 0.22 - 0.22);
	float wet_blood = clamp(max(red_excess, proc_gore * blood_wetness), 0.0, 1.0);

	vec3 dead_skin = mix(lifted * vec3(0.92, 0.96, 1.02), lifted * vec3(0.66, 0.60, 0.64), mottle * 0.40);
	dead_skin = mix(dead_skin, dead_skin * vec3(0.52, 0.44, 0.50), veins * 0.34);
	dead_skin = clamp(dead_skin, vec3(0.01), vec3(0.64));

	vec3 blood_col = mix(vec3(0.18, 0.012, 0.010), vec3(0.055, 0.004, 0.004), smoothstep(0.45, 0.95, blood_noise));
	vec3 col = mix(dead_skin, blood_col, wet_blood * 0.86);

	vec3 n_base = has_normal_tex ? unpack_nrm(texture(normal_tex, UV).rgb) : vec3(0.0, 0.0, 1.0);
	vec3 n_pore = unpack_nrm(texture(detail_normal_tex, UV * detail_uv_scale).rgb);
	vec3 n_comb = normalize(vec3(n_base.xy + n_pore.xy * detail_strength, n_base.z));
	n_comb = normalize(mix(n_comb, vec3(n_base.xy * 0.72, n_base.z), wet_blood * 0.55));

	float cavity = clamp(0.45 + 0.55 * n_comb.z, 0.22, 1.0) * smoothstep(0.01, 0.14, lum_raw + 0.05);

	// Progressive fire charring & smouldering fissure seams when burning
	// Scorch front: blistered seared skin first, spreading to near-total blackening at full char.
	// Flames climb, so torso/arms/head char first; legs catch up only at high burn_char.
	float char_w = clamp(burn_char, 0.0, 1.0);
	float upper_bias = smoothstep(0.45, 1.25, rest_pos.y);
	float char_local = char_w * mix(0.30 + 0.55 * smoothstep(0.45, 1.0, char_w), 1.0, upper_bias);
	float cn = vnoise3(gp * 6.0) * 0.50 + vnoise3(gp * 15.0 + 3.7) * 0.32 + mottle * 0.18;
	float char_pat = smoothstep(0.0, 0.30, char_local * 1.30 - (1.0 - cn) * 0.80 + 0.12) * smoothstep(0.0, 0.10, char_local);
	vec3 seared_col = vec3(0.17, 0.065, 0.040);
	vec3 char_col = vec3(0.032, 0.024, 0.022);
	col = mix(col, col * 0.55 + seared_col * 0.45, smoothstep(0.0, 0.45, char_local) * (1.0 - char_pat));
	col = mix(col, char_col, char_pat * 0.95);
	// Smouldering seams: low-frequency, domain-warped ridge lines read as long organic fissures in the
	// crust (never a field of bright speckles), and only glow where the skin is fully charred
	vec3 wp = gp + vec3(vnoise3(gp * 1.1 + 2.3), vnoise3(gp * 1.1 + 5.9), vnoise3(gp * 1.1 + 9.4)) * 1.4;
	float ridge_a = 1.0 - abs(vnoise3(wp * 4.6) - 0.5) * 2.0;
	float ridge_b = 1.0 - abs(vnoise3(wp * 9.5 + 7.1) - 0.5) * 2.0;
	float seam = ridge_a * 0.78 + ridge_b * 0.22;
	// Seams smoulder in scattered patches of the crust, not as an even net over the whole body
	float seam_patch = smoothstep(0.36, 0.68, vnoise3(gp * 0.75 + vec3(11.0, gore_seed * 2.3, 4.0)));
	float ember_crack = smoothstep(0.84, 0.965, pow(seam, 1.4)) * seam_patch * smoothstep(0.55, 0.95, char_pat);
	float ember_pulse = 0.72 + 0.28 * sin(TIME * 4.5 + gore_seed * 6.0 + rest_pos.y * 3.0);
	EMISSION = vec3(0.95, 0.16, 0.015) * ember_crack * ember_pulse * (0.30 + 0.55 * char_w);

	ALBEDO = col;
	ROUGHNESS = mix(mix(0.72, 0.08, wet_blood), 0.94, char_pat);
	SPECULAR = mix(mix(0.40, 0.68, wet_blood), 0.12, char_pat);
	CLEARCOAT = wet_blood * 0.92 * (1.0 - char_pat * 0.9);
	CLEARCOAT_ROUGHNESS = 0.06;
	AO = clamp(cavity, 0.18, 1.0);
	AO_LIGHT_AFFECT = 0.78;
	NORMAL_MAP = n_comb * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.48;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float wet_w = 1.0 - smoothstep(0.12, 0.44, ROUGHNESS);

	// Wrapped dermal diffuse + warm sub-dermal crimson terminator scatter for co-axial flashlight!
	float wrap_nl = clamp((ndotl + 0.26) / 1.26, 0.0, 1.0);
	float term = smoothstep(-0.14, 0.24, ndotl) * (1.0 - smoothstep(0.18, 0.64, ndotl));
	vec3 sss_tint = vec3(0.26, 0.032, 0.022) * term * (1.0 - wet_w * 0.55);
	DIFFUSE_LIGHT += (wrap_nl * 0.95 + sss_tint) * (1.0 / 3.14159265) * ATTENUATION * LIGHT_COLOR;

	// Dual-lobe Schlick-GGX specular: broad sebaceous pore sheen + crisp wet blood glint
	if (ndotl > 0.0 && SPECULAR_AMOUNT > 0.001) {
		vec3 H = normalize(VIEW + LIGHT);
		float ndoth = max(dot(NORMAL, H), 0.0);
		float ndotv = max(dot(NORMAL, VIEW), 0.04);
		float alpha1 = max(ROUGHNESS * ROUGHNESS, 0.012);
		float a1sq = alpha1 * alpha1;
		float d_den1 = ndoth * ndoth * (a1sq - 1.0) + 1.0;
		float d1 = a1sq / max(3.14159265 * d_den1 * d_den1, 1e-4);
		float alpha2 = 0.045;
		float a2sq = alpha2 * alpha2;
		float d_den2 = ndoth * ndoth * (a2sq - 1.0) + 1.0;
		float d2 = a2sq / max(3.14159265 * d_den2 * d_den2, 1e-4);
		float f1 = clamp(1.0 - max(dot(H, VIEW), 0.0), 0.0, 1.0);
		float f2 = f1 * f1;
		float fres = mix(0.035, 1.0, f2 * f2 * f1);
		float spec = min((d1 * mix(0.14, 0.35, wet_w) + d2 * wet_w * 0.65) * fres / max(4.0 * ndotv * ndotl, 0.15), 10.0);
		SPECULAR_LIGHT += spec * ndotl * ATTENUATION * LIGHT_COLOR * SPECULAR_AMOUNT;
	}
}
