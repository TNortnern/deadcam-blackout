shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D disp_tex : filter_linear_mipmap, repeat_enable;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float uv_scale = 0.34;
uniform float detail_scale = 0.85;
uniform float normal_depth = 1.95;
uniform float roughness_mult = 0.86;
uniform float grime_strength = 0.46;
uniform float floor_damp_height = 1.25;
uniform float wet_strength = 0.38;

uniform float pom_depth = 0.0;
uniform float pom_quality = 1.0;
uniform bool use_mesh_uv = false;
uniform bool is_brick = false;

varying vec3 w_pos;
varying vec3 w_norm;

vec3 unpack_nrm(vec3 c) {
	vec2 xy = c.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.01)));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm2(vec2 p) {
	return 0.65 * vnoise(p) + 0.35 * vnoise(p * 2.13 + vec2(4.2, 1.7));
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_norm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 wn = normalize(w_norm);
	vec3 an = abs(wn);
	// Vertical planar walls use -w_pos.y so right-side-up bricks/dados & OpenGL normal-Y align 100%!
	vec2 p_uv = use_mesh_uv ? UV : ((an.y > 0.65) ? w_pos.xz : ((an.x > an.z) ? vec2(w_pos.z, -w_pos.y) : vec2(w_pos.x, -w_pos.y)));
	vec2 base_uv = p_uv * uv_scale;

	if (!use_mesh_uv) {
		vec3 tw = (an.y > 0.65) ? vec3(1.0, 0.0, 0.0) : ((an.x > an.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0));
		vec3 bw = (an.y > 0.65) ? vec3(0.0, 0.0, -1.0) : vec3(0.0, 1.0, 0.0);
		tw = normalize(tw - wn * dot(tw, wn));
		bw = normalize(bw - wn * dot(bw, wn));
		TANGENT = normalize((VIEW_MATRIX * vec4(tw, 0.0)).xyz);
		BINORMAL = normalize((VIEW_MATRIX * vec4(bw, 0.0)).xyz);
	}

	vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
	float cam_dist = length(cam_pos - w_pos);
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
	vec3 v_vs = vec3(0.0);
	vec3 w_view = vec3(0.0);
	float raw_ndotv = 0.0;
	if (use_mesh_uv) {
		v_vs = normalize(VIEW);
		raw_ndotv = max(dot(NORMAL, v_vs), 0.0);
	} else {
		w_view = normalize(cam_pos - w_pos);
		raw_ndotv = max(abs(dot(w_view, wn)), 0.0);
	}
	float pom_grazing = smoothstep(0.18, 0.45, raw_ndotv);
	float eff_pom = pom_depth * pom_quality * pom_grazing * (1.0 - smoothstep(4.5, 8.5, cam_dist));

	if (eff_pom > 0.001) {
		int steps = (cam_dist < 4.5) ? 6 : 3;
		float fsteps = float(steps);
		float ndotv = max(raw_ndotv, 0.28);
		vec2 ray_step_uv = vec2(0.0);
		if (use_mesh_uv) {
			vec3 delta_vs = (-v_vs / ndotv) * (eff_pom * uv_scale / fsteps);
			// In Godot OpenGL normal-map basis, BINORMAL aligns with -V so dV = -dot(delta_vs, BINORMAL)
			ray_step_uv = vec2(dot(delta_vs, TANGENT), -dot(delta_vs, BINORMAL));
		} else {
			vec3 delta_w = (-w_view / ndotv) * (eff_pom / fsteps);
			vec2 dp = (an.y > 0.65) ? delta_w.xz : ((an.x > an.z) ? vec2(delta_w.z, -delta_w.y) : vec2(delta_w.x, -delta_w.y));
			ray_step_uv = dp * uv_scale;
		}
		vec2 uv_dx = dFdx(base_uv);
		vec2 uv_dy = dFdy(base_uv);
		float layer_d = 1.0 / fsteps;
		float cur_d = 0.0;
		vec2 cur_uv = base_uv;
		float h_sample = textureGrad(disp_tex, cur_uv, uv_dx, uv_dy).r;
		for (int i = 0; i < 6; i++) {
			if (i >= steps || cur_d >= (1.0 - h_sample)) {
				break;
			}
			cur_uv += ray_step_uv;
			cur_d += layer_d;
			h_sample = textureGrad(disp_tex, cur_uv, uv_dx, uv_dy).r;
		}
		vec2 prev_uv = cur_uv - ray_step_uv;
		float after_h = (1.0 - h_sample) - cur_d;
		float before_h = (1.0 - textureGrad(disp_tex, prev_uv, uv_dx, uv_dy).r) - (cur_d - layer_d);
		float denom = after_h - before_h;
		float w_lin = (abs(denom) > 1e-4) ? clamp(after_h / denom, 0.0, 1.0) : 0.5;
		base_uv = mix(cur_uv, prev_uv, w_lin);
	}
#endif

	vec3 base_col = texture(albedo_tex, base_uv).rgb;
	vec3 det_col = texture(albedo_tex, base_uv * (detail_scale / max(uv_scale, 0.05)) + vec2(3.7, 1.9)).rgb;
	float base_r = texture(rough_tex, base_uv).r;
	float base_ao = texture(ao_tex, base_uv).r;
	float disp_h = texture(disp_tex, base_uv).r;
	vec3 n_map = texture(normal_tex, base_uv).rgb;

	vec2 macro_uv = use_mesh_uv ? UV : ((an.y > 0.65) ? w_pos.xz : vec2(w_pos.x + w_pos.z, w_pos.y * 0.42));
	float macro_grime = fbm2(macro_uv * 0.28);
	float streak = vnoise(vec2((w_pos.x + w_pos.z) * 1.15, w_pos.y * 0.16));
	float damp_low = (1.0 - smoothstep(0.0, floor_damp_height, w_pos.y)) * (0.45 + 0.55 * macro_grime);
	float damp_high = smoothstep(5.2, 7.6, w_pos.y) * (0.4 + 0.6 * streak);

	vec3 col = mix(base_col, base_col * (0.76 + det_col * 0.54), 0.22) * tint_color.rgb;

	float mortar_mask = 0.0;
	if (is_brick) {
		mortar_mask = 1.0 - smoothstep(0.28, 0.62, disp_h);
		float det_w = 1.0 - smoothstep(4.5, 7.5, cam_dist);
		float micro_grain = (det_w > 0.01) ? mix(0.5, vnoise(base_uv * 32.0), det_w) : 0.5;
		float efflorescence = smoothstep(0.56, 0.86, macro_grime * 0.65 + streak * 0.35)
			* smoothstep(0.30, 0.72, disp_h) * (0.45 + 0.55 * micro_grain);
		// Natural masonry variation from scan texture + micro-grain (ZERO artificial floor() plaid grid!)
		col *= mix(0.88, 1.08, micro_grain) * mix(vec3(0.92, 0.90, 0.88), vec3(1.06, 1.02, 0.98), disp_h);
		// Calcium-salt efflorescence bloom
		col = mix(col, vec3(0.60, 0.58, 0.54), efflorescence * 0.26);
		// Deeply recessed dark damp lime mortar
		col *= mix(1.0, 0.44, mortar_mask);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		// Uniform-safe close-up fired-clay / mortar micro-normal (outside non-uniform if-branch for WebGL2!)
		vec3 det_n = texture(normal_tex, base_uv * 4.5 + vec2(0.37, 0.61)).rgb;
		vec3 nm_u = unpack_nrm(n_map);
		vec3 dn_u = unpack_nrm(det_n);
		n_map = normalize(vec3(nm_u.xy + dn_u.xy * (mix(0.24, 0.36, mortar_mask) * det_w), nm_u.z)) * 0.5 + 0.5;
#else
		// Ultra-crisp high-frequency fired-clay / coarse sand micro-normal for close-up flashlight detail
		if (det_w > 0.01) {
			vec3 det_n = texture(normal_tex, base_uv * 4.5 + vec2(0.37, 0.61)).rgb;
			vec3 nm_u = unpack_nrm(n_map);
			vec3 dn_u = unpack_nrm(det_n);
			n_map = normalize(vec3(nm_u.xy + dn_u.xy * (mix(0.24, 0.36, mortar_mask) * det_w), nm_u.z)) * 0.5 + 0.5;
		}
#endif
	}

	float moss_stain = smoothstep(0.48, 0.80, macro_grime * 0.7 + streak * 0.3);
	col *= mix(vec3(1.0), vec3(0.90, 0.92, 0.86), moss_stain * grime_strength * 0.55);

	float dirt = clamp(macro_grime * grime_strength + damp_low * 0.36 + damp_high * 0.32 + (streak - 0.5) * 0.22, 0.0, 0.74);
	col *= mix(vec3(1.0), vec3(0.36, 0.36, 0.34), dirt);

	float wet_pocket = (smoothstep(0.50, 0.82, macro_grime) * 0.48 + damp_low * 0.36) * wet_strength;
	float up_face = smoothstep(0.75, 0.95, wn.y);
	float puddle = 0.0;
	if (up_face > 0.01) {
		float puddle_n = fbm2(w_pos.xz * 0.42 + vec2(2.1, -1.7));
		puddle = up_face * smoothstep(0.56, 0.74, puddle_n) * clamp(wet_strength * 1.45, 0.0, 1.0);
		col *= mix(1.0, 0.56, puddle);
	}

	float rough = clamp(base_r * roughness_mult - wet_pocket, 0.11, 0.96);
	if (is_brick) {
		rough = mix(rough, 0.95, mortar_mask * 0.78);
		rough = mix(rough, 0.16, clamp(wet_pocket * (1.0 - mortar_mask * 0.65), 0.0, 0.75));
	}
	rough = mix(rough, 0.055, puddle);
	n_map = mix(n_map, vec3(0.5, 0.5, 1.0), puddle * 0.85);

	float cavity_ao = mix(base_ao, min(base_ao, smoothstep(0.12, 0.68, disp_h)), is_brick ? 0.72 : 0.28);

	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = clamp(0.46 + wet_pocket * 0.18 + puddle * 0.18 - mortar_mask * 0.26, 0.10, 0.64);
	AO = clamp(cavity_ao * (1.0 - damp_low * 0.34), 0.10, 1.0);
	AO_LIGHT_AFFECT = 0.85;
	NORMAL_MAP = n_map;
	NORMAL_MAP_DEPTH = normal_depth * (1.0 + mortar_mask * 0.32);
}
