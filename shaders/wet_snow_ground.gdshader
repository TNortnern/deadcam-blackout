shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Hyperreal winter courtyard ground: real scanned snow/boot-tracks + height-blended frozen gravel mud,
// synchronized wall/fence snowbanks, analytical recessed bootprints, shadowed HDR crystal glints & snow SSS.
// NOTE: snow_height_fast() MUST stay 1:1 synchronized with WorldBuilder._snow_height_at()!

uniform sampler2D snow_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_rough : filter_linear_mipmap, repeat_enable;

#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
uniform sampler2D snow_disp : filter_linear_mipmap, repeat_enable;
uniform sampler2D tracks_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tracks_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D tracks_height : filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_disp : filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_ao : filter_linear_mipmap, repeat_enable;
uniform sampler2D churned_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D churned_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D churned_height : filter_linear_mipmap, repeat_enable;
#endif

uniform float tile_scale = 0.30;
uniform float normal_strength = 1.48;
uniform float pom_quality = 1.0;

varying vec3 w_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.53);
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

float fbm3(vec2 p) {
	float v = 0.0;
	v += 0.56 * vnoise(p);
	v += 0.29 * vnoise(p * 2.17 + vec2(3.7, 8.1));
	v += 0.15 * vnoise(p * 4.61 + vec2(9.2, 1.4));
	return v;
}

vec3 unpack_nrm(vec3 c) {
	vec2 xy = c.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.01)));
}

// Fast pure-ALU snowdrift + wall snowbank height (1:1 synchronized with WorldBuilder._snow_height_at)
float snow_height_fast(vec2 ground) {
	float edge = smoothstep(1.5, 5.2, abs(ground.x + 1.4 * sin(ground.y * 0.14)));
	float drift = vnoise(ground * 0.36) * (0.18 + 0.50 * edge);
	float track_x = ground.x + sin(ground.y * 0.29) * 0.67;
	float rut_d = abs(track_x) - 0.72;
	float rut = exp(-6.5 * rut_d * rut_d);
	float in_yard = smoothstep(-27.8, -28.8, ground.y);
	float wall_bank = in_yard * smoothstep(2.1, 3.8, abs(ground.x)) * exp(-abs(-28.4 - ground.y) * 0.75) * 0.34;
	float fb_u = (abs(ground.x) - 8.4) / 1.45;
	float fence_bank = in_yard * exp(-fb_u * fb_u) * 0.22;
	float cabin_bank = smoothstep(-51.5, -53.4, ground.y) * smoothstep(1.6, 3.4, abs(ground.x)) * 0.28;
	return drift - 0.11 * rut + 0.06 * sin(ground.x * 1.4 + ground.y * 0.9) + wall_bank + fence_bank + cabin_bank;
}

// Sparse organic compressed bootprints along central trodden path (only abs(x) < 2.2)
vec2 eval_bootprint(vec2 xz) {
	float path_c = xz.x + sin(xz.y * 0.14) * 1.4;
	if (abs(path_c) >= 2.2 || xz.y > -28.0 || xz.y < -52.5) {
		return vec2(0.0);
	}
	float row = floor(xz.y / 0.78);
	float stride = mod(row, 2.0) - 0.5;
	int lane = clamp(int(round(path_c / 1.18)), -1, 1);
	if (hash21(vec2(row, float(lane) * 7.1 + 3.0)) < 0.45) {
		return vec2(0.0);
	}
	float phase = float(lane) * 4.31;
	float jx = (hash21(vec2(row, float(lane))) - 0.5) * 0.22;
	float drift = sin(xz.y * 0.15 + phase) * 0.38;
	vec2 foot = vec2(path_c - float(lane) * 1.18 - drift - stride * 0.25 - jx,
		mod(xz.y, 0.78) - 0.38);
	foot.x += foot.y * (0.22 * stride + 0.16 * sin(row + phase));
	float heel = length((foot - vec2(0.0, -0.088)) / vec2(0.078, 0.088));
	float toe = length((foot - vec2(0.0, 0.064)) / vec2(0.095, 0.140));
	float tread = sin(foot.y * 92.0) * 0.05;
	float d_raw = min(heel, toe) + tread;
	float depth_print = 1.0 - smoothstep(0.68, 1.02, d_raw);
	float rim_u = (d_raw - 1.06) / 0.18;
	float rim_ring = exp(-rim_u * rim_u) * 0.42;
	return vec2(depth_print, rim_ring);
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 ground = w_pos.xz;
	float h0 = snow_height_fast(ground);
	VERTEX.y += h0;
	float hx = snow_height_fast(ground + vec2(0.25, 0.0)) - h0;
	float hz = snow_height_fast(ground + vec2(0.0, 0.25)) - h0;
	NORMAL = normalize(vec3(-hx, 0.25, -hz));
}

void fragment() {
	vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
	float cam_dist = length(cam_pos - w_pos);

	float far_w = smoothstep(14.0, 22.0, cam_dist);
	vec2 warp = (far_w < 0.999) ? (vec2(vnoise(w_pos.xz * 0.22 + vec2(1.9, 4.4)), vnoise(w_pos.xz * 0.22 + vec2(7.3, 2.1))) - 0.5) * (1.0 - far_w) : vec2(0.0);
	vec2 ground_warped = w_pos.xz + warp * 0.38;
	vec2 snow_uv = ground_warped * tile_scale;
	vec2 trk_uv = (w_pos.xz + warp * 0.16) * 0.36;
	vec2 mud_uv = ground_warped * 0.48;
	vec2 churn_uv = ground_warped * 0.52 + vec2(0.21, 0.67);

#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
	vec3 w_view = normalize(cam_pos - w_pos);
	// Distance-faded POM (< 9.0m) using real photogrammetry displacement for tactile pebble/slush relief
	float eff_pom = 0.026 * pom_quality * (1.0 - smoothstep(5.5, 9.0, cam_dist));
	if (eff_pom > 0.001) {
		float ndotv = max(abs(w_view.y), 0.30);
		vec2 ray_xz = (-w_view.xz / ndotv) * (eff_pom / 5.0);
		vec2 dudx = dFdx(mud_uv);
		vec2 dudy = dFdy(mud_uv);
		float cur_d = 0.0;
		vec2 off_uv = vec2(0.0);
		float h_p = textureGrad(mud_disp, mud_uv, dudx, dudy).r;
		for (int i = 0; i < 5; i++) {
			if (cur_d >= (1.0 - h_p)) {
				break;
			}
			off_uv += ray_xz;
			cur_d += 0.20;
			h_p = textureGrad(mud_disp, mud_uv + off_uv * 0.48, dudx, dudy).r;
		}
		snow_uv += off_uv * tile_scale * 0.65;
		trk_uv += off_uv * 0.36;
		mud_uv += off_uv * 0.48;
		churn_uv += off_uv * 0.52;
	}
#endif

	vec3 s_col = texture(snow_albedo, snow_uv).rgb;
	vec3 s_nrm = texture(snow_normal, snow_uv).rgb;
	vec3 m_col = texture(mud_albedo, mud_uv).rgb;
	vec3 m_nrm = texture(mud_normal, mud_uv).rgb;
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
	float s_disp = texture(snow_disp, snow_uv).r;
	float m_disp = texture(mud_disp, mud_uv).r;
#else
	float s_disp = 0.5;
	float m_disp = 0.5;
#endif

	vec3 t_col = s_col;
	vec3 t_nrm = s_nrm;
	float t_h = s_disp;
	float m_ao = 0.85;
	float m_rough = 0.78;
	vec3 c_col = s_col;
	vec3 c_nrm = s_nrm;
	float c_disp = 0.5;
	if (far_w < 0.999) {
		m_rough = mix(texture(mud_rough, mud_uv).r, 0.78, far_w);
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
		t_col = mix(texture(tracks_albedo, trk_uv).rgb, s_col, far_w);
		t_nrm = mix(texture(tracks_normal, trk_uv).rgb, s_nrm, far_w);
		t_h = mix(texture(tracks_height, trk_uv).r, s_disp, far_w);
		m_ao = mix(texture(mud_ao, mud_uv).r, 0.85, far_w);
		c_col = mix(texture(churned_albedo, churn_uv).rgb, s_col, far_w);
		c_nrm = mix(texture(churned_normal, churn_uv).rgb, s_nrm, far_w);
		c_disp = mix(texture(churned_height, churn_uv).r, 0.5, far_w);
#endif
	}

	float path_center = w_pos.x + sin(w_pos.z * 0.14) * 1.4;
	float tw_u = path_center / 4.8;
	float trail_w = exp(-tw_u * tw_u);
	float track_x = w_pos.x + sin(w_pos.z * 0.29) * 0.67;
	float rut_d = abs(track_x) - 0.72;
	float rut = exp(-6.5 * rut_d * rut_d);
	float macro_drift = (far_w < 0.999) ? mix(fbm3(w_pos.xz * 0.23 + warp * 0.55), 0.52, far_w) : 0.52;

	// Blend real scanned tracked snow onto center path zone (fades smoothly to clean untouched drift flanks)
	float scan_trk_w = smoothstep(0.18, 0.78, trail_w) * (0.45 + 0.55 * macro_drift);
	s_col = mix(s_col, t_col, scan_trk_w * 0.72);
	s_disp = mix(s_disp, t_h, scan_trk_w * 0.65);

	vec2 boot_c = eval_bootprint(w_pos.xz);
	float walked = boot_c.x * (0.68 + 0.32 * macro_drift);
	float boot_rim = boot_c.y;
	vec2 boot_grad = vec2(0.0);
	if (cam_dist < 18.0 && (boot_c.x > 0.01 || boot_c.y > 0.05)) {
		float h0_b = -boot_c.x * 1.15 + boot_c.y * 0.65;
		vec2 bx = eval_bootprint(w_pos.xz + vec2(0.018, 0.0));
		vec2 bz = eval_bootprint(w_pos.xz + vec2(0.0, 0.018));
		float hx_b = -bx.x * 1.15 + bx.y * 0.65;
		float hz_b = -bz.x * 1.15 + bz.y * 0.65;
		// PlaneMesh BINORMAL = -Z, so ny_ts = +dh/dz = (hz_b - h0_b) -> sinks INWARD!
		boot_grad = vec2(h0_b - hx_b, hz_b - h0_b) * 7.8;
	}

	float snow_budget = clamp(
		0.50 + macro_drift * 0.44 + 0.30 * (1.0 - trail_w) - rut * 0.64 - walked * 0.22 + boot_rim * 0.20,
		0.0, 1.0
	);

	float snow_h = snow_budget + s_disp * 0.24;
	float mud_h = (1.0 - snow_budget) + m_disp * 0.36;
	float snow_mask = smoothstep(-0.07, 0.08, snow_h - mud_h);
	float slush_band = (1.0 - smoothstep(0.05, 0.28, abs(snow_h - mud_h))) * clamp(trail_w * 0.9 + rut * 0.75, 0.0, 1.0);

	vec3 pure_snow_col = s_col * vec3(0.95, 0.98, 1.04);
	pure_snow_col = mix(pure_snow_col, pure_snow_col * vec3(0.68, 0.76, 0.88), walked * 0.62);
	vec3 frozen_mud_col = pow(max(m_col, vec3(0.004)), vec3(0.76)) * vec3(0.84, 0.80, 0.74);
	vec3 dirty_slush_col = mix(c_col * vec3(0.80, 0.82, 0.86), frozen_mud_col * 0.78, 0.48);

	vec3 col = mix(frozen_mud_col, pure_snow_col, snow_mask);
	col = mix(col, dirty_slush_col, slush_band * 0.86);

	float rut_puddle = smoothstep(0.46, 0.84, rut * (0.58 + 0.42 * (1.0 - m_disp))) * (1.0 - snow_mask * 0.82);
	col *= mix(1.0, 0.54, rut_puddle * 0.78);
	// Never allow emissive-like blown-out snow above 0.88 albedo
	col = clamp(col, vec3(0.01), vec3(0.88));

	float rough = mix(clamp(m_rough * 0.92, 0.42, 0.92), 0.84, snow_mask);
	rough = mix(rough, 0.30, slush_band * 0.65);
	rough = mix(rough, 0.22, walked * 0.74);
	rough = mix(rough, 0.065, rut_puddle);

	vec3 s_u = unpack_nrm(s_nrm);
	vec3 t_u = unpack_nrm(t_nrm);
	s_u = normalize(mix(s_u, t_u, scan_trk_w * 0.80));
	vec3 c_u = unpack_nrm(c_nrm);
	vec3 n_snow_ts = normalize(vec3(s_u.xy + c_u.xy * (0.24 + 0.45 * slush_band), s_u.z));
	vec3 n_mud_ts = unpack_nrm(m_nrm);
	vec3 n_ts = normalize(mix(n_mud_ts, n_snow_ts, snow_mask));
	n_ts.xy = clamp(n_ts.xy + boot_grad, -0.92, 0.92);

	// Real shadowed HDR ice-crystal micro-sparkles gated strictly onto high snow without starfield spots
	float glint_mask = 0.0;
	if (snow_mask > 0.55 && cam_dist < 10.5) {
		float g_fade = (1.0 - smoothstep(4.5, 10.5, cam_dist)) * smoothstep(0.55, 0.85, snow_mask) * (1.0 - rut_puddle);
		vec2 cell = floor(w_pos.xz * 360.0);
		float h1 = hash21(cell);
		if (h1 > 0.91) {
			float h2 = hash21(cell + vec2(37.1, 83.7));
			vec3 f_dir = normalize(vec3((h1 - 0.955) * 8.0, 0.94, (h2 - 0.5) * 0.75));
			glint_mask = g_fade * smoothstep(0.91, 0.99, h1);
			n_ts = normalize(mix(n_ts, vec3(f_dir.x, -f_dir.z, f_dir.y), glint_mask));
		}
	}

	n_ts = normalize(mix(n_ts, vec3(0.0, 0.0, 1.0), rut_puddle * 0.82));
	rough = mix(rough, 0.085, glint_mask);

	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = clamp(mix(0.28 + slush_band * 0.22 + walked * 0.22 + rut_puddle * 0.44, 0.82, glint_mask), 0.18, 0.85);
	AO = clamp(mix(m_ao, 0.92, snow_mask) * (1.0 - walked * 0.34) * mix(0.68, 1.0, c_disp * 0.5 + 0.5), 0.14, 1.0);
	AO_LIGHT_AFFECT = 0.84;
	NORMAL_MAP = n_ts * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength * (1.0 - rut_puddle * 0.68);
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float is_snow = smoothstep(0.30, 0.62, dot(ALBEDO, vec3(0.30, 0.50, 0.20)));

	// Soft wrapped winter powder subsurface scattering + subtle cold glacial-blue terminator tint
	float wrap_nl = clamp((ndotl + mix(0.0, 0.36, is_snow)) / mix(1.0, 1.36, is_snow), 0.0, 1.0);
	float term = smoothstep(-0.18, 0.20, ndotl) * (1.0 - smoothstep(0.15, 0.58, ndotl)) * is_snow;
	vec3 ice_sss = vec3(0.08, 0.13, 0.22) * term;
	DIFFUSE_LIGHT += (wrap_nl + ice_sss) * (1.0 / 3.14159265) * ATTENUATION * LIGHT_COLOR;

	if (ndotl > 0.0 && SPECULAR_AMOUNT > 0.001) {
		vec3 H = normalize(VIEW + LIGHT);
		float ndoth = max(dot(NORMAL, H), 0.0);
		float ndotv = max(dot(NORMAL, VIEW), 0.04);
		float alpha = max(ROUGHNESS * ROUGHNESS, 0.008);
		float a2 = alpha * alpha;
		float d_den = ndoth * ndoth * (a2 - 1.0) + 1.0;
		float d = a2 / max(3.14159265 * d_den * d_den, 1e-4);
		float is_glint = 1.0 - smoothstep(0.08, 0.14, ROUGHNESS);
		float is_wet = 1.0 - smoothstep(0.065, 0.24, ROUGHNESS);
		float f0 = mix(0.032, 0.075, max(is_glint, is_wet * 0.60));
		float f1 = clamp(1.0 - max(dot(H, VIEW), 0.0), 0.0, 1.0);
		float f2 = f1 * f1;
		float fres = f0 + (1.0 - f0) * (f2 * f2 * f1);
		float spec = min(d * fres / max(4.0 * ndotv * ndotl, 0.16), 4.2);
		SPECULAR_LIGHT += spec * ndotl * ATTENUATION * LIGHT_COLOR * SPECULAR_AMOUNT;
	}
}
