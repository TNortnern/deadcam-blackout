shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

// Photorealistic 4x4 photographic flipbook + turbulent heat-warp fire shader (Forward+ & WebGL2 Compatibility safe)
uniform sampler2D fire_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float has_fire_tex : hint_range(0.0, 1.0) = 0.0;
uniform float atlas_fps : hint_range(4.0, 32.0) = 18.0;
uniform float flip_x : hint_range(-1.0, 1.0) = 1.0;
uniform float age_norm : hint_range(0.0, 1.0) = 0.0;
uniform float blue_core : hint_range(0.0, 1.0) = 0.0;

uniform float flame_speed : hint_range(0.5, 8.0) = 2.6;
uniform float phase_seed = 0.0;
uniform float intensity : hint_range(0.0, 4.0) = 1.45;
uniform float smoke_mix : hint_range(0.0, 1.0) = 0.42;
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float billboard_y : hint_range(0.0, 1.0) = 1.0;
uniform float jet_mode : hint_range(0.0, 1.0) = 0.0; // 0 = rising fire plume, 1 = spherical/expanding flamethrower napalm fireball

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.52;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = rot * p * 2.07 + vec2(13.4, 7.1);
		a *= 0.50;
	}
	return v;
}

vec3 sample_atlas_cell(vec2 cell_uv, float frame_idx) {
	float idx = mod(floor(frame_idx), 16.0);
	float col = mod(idx, 4.0);
	float row = floor(idx * 0.25);
	vec2 clamped = clamp(cell_uv, vec2(0.015), vec2(0.985));
	vec2 atlas_uv = (vec2(col, row) + clamped) * 0.25;
	return texture(fire_tex, atlas_uv).rgb;
}

void vertex() {
	if (billboard_y > 0.5) {
		if (jet_mode > 0.5) {
			// Full camera-facing billboard for rolling napalm fireballs & explosive bursts
			MODELVIEW_MATRIX = VIEW_MATRIX * MODEL_MATRIX;
			MODELVIEW_MATRIX[0] = vec4(length(MODELVIEW_MATRIX[0].xyz), 0.0, 0.0, 0.0);
			MODELVIEW_MATRIX[1] = vec4(0.0, length(MODELVIEW_MATRIX[1].xyz), 0.0, 0.0);
			MODELVIEW_MATRIX[2] = vec4(0.0, 0.0, length(MODELVIEW_MATRIX[2].xyz), 0.0);
		} else {
			// Cylindrical Y-axis billboard so rising ground flames stay upright & grounded from every angle
			vec3 world_pos = MODEL_MATRIX[3].xyz;
			vec3 to_cam = INV_VIEW_MATRIX[3].xyz - world_pos;
			to_cam.y = 0.0;
			float raw_len = length(to_cam);
			vec3 fwd = raw_len > 0.001 ? (to_cam / raw_len) : vec3(0.0, 0.0, 1.0);
			vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
			float sx = length(MODEL_MATRIX[0].xyz);
			float sy = length(MODEL_MATRIX[1].xyz);
			float sz = length(MODEL_MATRIX[2].xyz);
			mat4 bb = mat4(
				vec4(right * sx, 0.0),
				vec4(0.0, sy, 0.0, 0.0),
				vec4(fwd * sz, 0.0),
				vec4(world_pos, 1.0)
			);
			MODELVIEW_MATRIX = VIEW_MATRIX * bb;
		}
	}
}

void fragment() {
	float t = TIME * flame_speed + phase_seed * 17.3;
	vec2 uv = UV;
	float h = 1.0 - uv.y; // 0 at bottom base, 1 at top tip

	if (has_fire_tex > 0.5) {
		vec2 cell_uv = uv;
		if (flip_x < 0.0) {
			cell_uv.x = 1.0 - cell_uv.x;
		}

		float frame_f = 0.0;
		float smoke_mask = 0.0;

		if (jet_mode > 0.5) {
			// Rolling turbulent napalm fireball: rotate per-puff & advect smoothly through 16 real napalm shots
			vec2 centered = cell_uv - 0.5;
			float spin_dir = (fract(phase_seed * 0.37) > 0.5) ? 1.0 : -1.0;
			float ang = phase_seed * 1.9 + TIME * 0.72 * spin_dir;
			float ca = cos(ang);
			float sa = sin(ang);
			vec2 rot_uv = mat2(vec2(ca, sa), vec2(-sa, ca)) * centered + 0.5;

			// Subtle fluid heat-shimmer UV warp so frames flow organically instead of visibly stepping
			vec2 shimmer = vec2(
				vnoise(rot_uv * 5.0 + vec2(t * 0.65, -t * 0.9)) - 0.5,
				vnoise(rot_uv * 5.0 + vec2(-t * 0.72, t * 0.8) + 4.7) - 0.5
			) * 0.028;
			cell_uv = rot_uv + shimmer;
			frame_f = phase_seed * 7.13 + TIME * atlas_fps + age_norm * 7.5;

			// Cooling billowing black petroleum smoke halo expanding as the napalm ages
			float rad = length(centered) * 2.0;
			float sn = vnoise(rot_uv * 4.5 + vec2(t * 0.45, -t * 0.65));
			float sn2 = vnoise(rot_uv * 9.0 - vec2(t * 0.5, t * 0.85));
			float sturb = sn * 0.65 + sn2 * 0.35;
			float s_env = clamp(1.0 - rad * (0.94 - age_norm * 0.14), 0.0, 1.0);
			smoke_mask = smoothstep(0.14, 0.58, s_env * (0.45 + sturb * 0.95)) * smoke_mix;
		} else {
			// Rising gasoline/oil fire plume: slight convective sway near upper tips + continuous vertical lick
			float sway = (vnoise(vec2(h * 2.2 - t * 1.05, phase_seed * 2.7)) - 0.5) * (0.04 + 0.095 * h);
			vec2 shimmer = vec2(
				sway,
				(vnoise(vec2(cell_uv.x * 4.5 + phase_seed, h * 3.8 - t * 1.65)) - 0.5) * 0.024
			);
			cell_uv = cell_uv + shimmer;
			// Cycle frames 4..15 (full roaring plumes) smoothly for rich continuous combustion
			frame_f = phase_seed * 5.71 + TIME * atlas_fps;

			// Dark oily soot curling off the upper tips of the flame
			float cx = abs((uv.x - 0.5) * 2.0);
			float sn = vnoise(vec2(uv.x * 3.8 + phase_seed, h * 3.4 - t * 1.25));
			float smoke_h = smoothstep(0.36, 0.86, h) * (1.0 - smoothstep(0.76, 1.0, h));
			float smoke_r = 1.0 - smoothstep(0.18, 0.92, cx + (0.45 - sn) * 0.45);
			smoke_mask = smoke_h * smoke_r * smoothstep(0.28, 0.72, sn) * smoke_mix;
		}

		float idx0 = floor(frame_f);
		float blend_f = smoothstep(0.0, 1.0, fract(frame_f));
		// For rising plumes, bias toward the richer mid-to-full frames (2..15) so flames never shrink to tiny sparks
		float f0 = (jet_mode > 0.5) ? mod(idx0, 16.0) : (2.0 + mod(idx0, 14.0));
		float f1 = (jet_mode > 0.5) ? mod(idx0 + 1.0, 16.0) : (2.0 + mod(idx0 + 1.0, 14.0));

		vec3 raw0 = sample_atlas_cell(cell_uv, f0);
		vec3 raw1 = sample_atlas_cell(cell_uv, f1);
		vec3 tex_col = mix(raw0, raw1, blend_f);

		// Soft edge vignette inside cell so rotated/swayed UVs never show hard quad borders
		vec2 edge_d = min(cell_uv, 1.0 - cell_uv);
		float border_fade = smoothstep(0.0, 0.075, min(edge_d.x, edge_d.y));
		tex_col *= border_fade;

		// Photographic luminance -> physical flame alpha + filmic blackbody saturation boost
		float peak = max(tex_col.r, max(tex_col.g, tex_col.b));
		float lum = dot(tex_col, vec3(0.299, 0.587, 0.114));
		float fire_alpha = smoothstep(0.032, 0.28, peak);

		// Deepen rich crimson-orange edges while keeping incandescent yellow-white core crisp (no flat pastel washout)
		vec3 graded = pow(max(tex_col, vec3(0.0001)), vec3(1.12, 1.18, 1.30));
		graded = mix(graded * vec3(1.25, 0.58, 0.14), graded * vec3(1.18, 1.02, 0.78), smoothstep(0.28, 0.85, lum));
		vec3 fire_col = graded * intensity * (1.28 + 0.55 * smoothstep(0.45, 0.95, peak));

		// Optional propane/napalm blue-cyan ignition core (M2 Flamethrower pilot flame & nozzle ignition)
		if (blue_core > 0.01) {
			// Real burners are blue only in the bottom few cm (plume) / the hot core (napalm puff)
			float zone_geo = (jet_mode > 0.5) ? (1.0 - smoothstep(0.0, 0.42, length(cell_uv - 0.5) * 2.0)) : (1.0 - smoothstep(0.02, 0.26, h));
			float base_zone = zone_geo * smoothstep(0.10, 0.65, peak);
			vec3 blue_tint = vec3(0.12, 0.42, 1.85) * intensity;
			fire_col = mix(fire_col, blue_tint, base_zone * blue_core * 0.82);
		}

		// Cooling napalm shifts progressively warmer crimson-ember as smoke takes over
		if (jet_mode > 0.5 && age_norm > 0.35) {
			float cool_w = smoothstep(0.35, 0.95, age_norm);
			fire_col *= mix(vec3(1.0), vec3(0.95, 0.34, 0.08), cool_w * 0.72);
			fire_alpha *= (1.0 - cool_w * 0.62);
		}

		vec3 soot_col = vec3(0.028, 0.025, 0.023);
		float s_alpha = smoke_mask * (1.0 - smoothstep(0.22, 0.68, fire_alpha)) * 0.82;
		float total_alpha = clamp(max(fire_alpha, s_alpha), 0.0, 1.0) * fade_alpha;
		if (total_alpha < 0.02) {
			discard;
		}
		float fire_w = fire_alpha / max(total_alpha / max(fade_alpha, 0.001), 0.001);
		ALBEDO = mix(soot_col, fire_col, clamp(fire_w, 0.0, 1.0));
		ALPHA = total_alpha;
	} else {
	// Procedural fallback (only used if fire_tex is not assigned)
	float cx = (uv.x - 0.5) * 2.0;
	float heat = 0.0;
	float smoke_mask = 0.0;
	if (jet_mode > 0.5) {
		vec2 p_raw = (uv - 0.5) * 2.0;
		float ang = phase_seed * 2.4 + t * 0.42;
		float ca = cos(ang);
		float sa = sin(ang);
		vec2 p = mat2(vec2(ca, sa), vec2(-sa, ca)) * p_raw;
		float rad = length(p_raw);
		vec2 warp = vec2(
			fbm(p * 2.7 + vec2(t * 0.50, -t * 0.80)) - 0.5,
			fbm(p * 2.7 + vec2(-t * 0.58, t * 0.68) + 5.2) - 0.5
		);
		float n1 = fbm(p * 3.4 + warp * 1.55 - vec2(0.0, t * 0.95));
		float n2 = fbm(p * 6.8 - warp * 0.95 + vec2(t * 0.65, -t * 1.45));
		float shape = clamp(1.0 - rad * 1.06, 0.0, 1.0);
		float turb = n1 * 0.66 + n2 * 0.34;
		heat = clamp(pow(max(shape * 1.44 - (1.0 - turb) * 0.82, 0.0), 1.08), 0.0, 1.0);
		smoke_mask = smoothstep(0.08, 0.52, shape * turb) * smoke_mix * (1.0 - smoothstep(0.24, 0.62, heat));
	} else {
		float sway = (fbm(vec2(h * 1.8 - t * 0.85, phase_seed * 3.1)) - 0.5) * (0.32 + 0.55 * h);
		float xw = cx + sway;
		float width_profile = mix(0.88, 0.24, pow(h, 0.72));
		float radial = abs(xw) / max(width_profile, 0.08);
		vec2 flow_uv = vec2(xw * 1.65, h * 2.4 - t * 1.35);
		vec2 warp = vec2(
			fbm(flow_uv + vec2(phase_seed, 2.7)) - 0.5,
			fbm(flow_uv * 1.4 - vec2(0.0, t * 0.6) + 8.3) - 0.5
		);
		float n_main = fbm(vec2(xw * 2.3, h * 3.1 - t * 1.95) + warp * 1.35);
		float n_fine = fbm(vec2(xw * 5.2, h * 6.0 - t * 3.1) - warp * 0.75);
		float turb = n_main * 0.68 + n_fine * 0.32;
		float base_fade = smoothstep(0.0, 0.14, h);
		float top_fade = 1.0 - smoothstep(0.28, 0.98, h + (0.48 - turb) * 0.82);
		float radial_fade = 1.0 - smoothstep(0.18, 1.05, radial + (0.46 - turb) * 0.75);
		float flame_field = base_fade * top_fade * radial_fade;
		heat = clamp(flame_field * (0.78 + turb * 0.95) * (1.18 - 0.55 * h), 0.0, 1.0);
		float smoke_h = smoothstep(0.32, 0.88, h) * (1.0 - smoothstep(0.75, 1.0, h));
		float smoke_r = 1.0 - smoothstep(0.25, 1.15, abs(xw) / mix(0.65, 0.95, h));
		smoke_mask = smoke_h * smoke_r * smoothstep(0.34, 0.72, n_main) * smoke_mix * (1.0 - smoothstep(0.18, 0.45, heat));
	}

	vec3 col_deep = vec3(0.38, 0.022, 0.002);
	vec3 col_orange = vec3(1.06, 0.17, 0.010);
	vec3 col_gold = vec3(1.68, 0.58, 0.042);
	vec3 col_core = vec3(2.08, 1.22, 0.34);

	vec3 fire_col = mix(col_deep, col_orange, smoothstep(0.06, 0.38, heat));
	fire_col = mix(fire_col, col_gold, smoothstep(0.38, 0.72, heat));
	fire_col = mix(fire_col, col_core, smoothstep(0.72, 0.96, heat));
	fire_col *= intensity;

	float fire_alpha = smoothstep(0.08, 0.36, heat);
	vec3 soot_col = vec3(0.032, 0.028, 0.026);
	float total_alpha = clamp(max(fire_alpha, smoke_mask * 0.76), 0.0, 1.0) * fade_alpha;
	if (total_alpha < 0.02) {
		discard;
	}
	float fire_w = fire_alpha / max(total_alpha / max(fade_alpha, 0.001), 0.001);
	ALBEDO = mix(soot_col, fire_col, clamp(fire_w, 0.0, 1.0));
	ALPHA = total_alpha;
	}
}
