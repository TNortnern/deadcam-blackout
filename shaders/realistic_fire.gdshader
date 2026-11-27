shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled, fog_disabled;

// Photorealistic domain-warped turbulent volumetric fire shader (Forward+ & WebGL2 Compatibility safe)
uniform float flame_speed : hint_range(0.5, 8.0) = 2.6;
uniform float phase_seed = 0.0;
uniform float intensity : hint_range(0.0, 4.0) = 1.85;
uniform float smoke_mix : hint_range(0.0, 1.0) = 0.42;
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float billboard_y : hint_range(0.0, 1.0) = 1.0;
uniform float jet_mode : hint_range(0.0, 1.0) = 0.0; // 0 = rising fire plume, 1 = spherical/expanding flamethrower fireball

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

void vertex() {
	if (billboard_y > 0.5) {
		if (jet_mode > 0.5) {
			// Full camera-facing billboard for rolling napalm fireballs & explosive bursts
			MODELVIEW_MATRIX = VIEW_MATRIX * MODEL_MATRIX;
			MODELVIEW_MATRIX[0] = vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0);
			MODELVIEW_MATRIX[1] = vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0);
			MODELVIEW_MATRIX[2] = vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0);
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
	float cx = (uv.x - 0.5) * 2.0; // -1..+1 horizontal

	float heat = 0.0;
	float smoke_mask = 0.0;

	if (jet_mode > 0.5) {
		// Rolling turbulent napalm puff (flamethrower stream & blast fireballs) with per-puff tumble
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
		// Rising turbulent gasoline/oil flame tongues with wispy flickering tips & soot
		float sway = (fbm(vec2(h * 1.8 - t * 0.85, phase_seed * 3.1)) - 0.5) * (0.32 + 0.55 * h);
		float xw = cx + sway;
		// Flame tapers naturally toward tips while staying broad & grounded at the base
		float width_profile = mix(0.88, 0.24, pow(h, 0.72));
		float radial = abs(xw) / max(width_profile, 0.08);

		// Multi-octave curled turbulence advecting rapidly upward
		vec2 flow_uv = vec2(xw * 1.65, h * 2.4 - t * 1.35);
		vec2 warp = vec2(
			fbm(flow_uv + vec2(phase_seed, 2.7)) - 0.5,
			fbm(flow_uv * 1.4 - vec2(0.0, t * 0.6) + 8.3) - 0.5
		);
		float n_main = fbm(vec2(xw * 2.3, h * 3.1 - t * 1.95) + warp * 1.35);
		float n_fine = fbm(vec2(xw * 5.2, h * 6.0 - t * 3.1) - warp * 0.75);
		float turb = n_main * 0.68 + n_fine * 0.32;

		// Soft bottom ground contact + jagged flickering flame licks at top
		float base_fade = smoothstep(0.0, 0.14, h);
		float top_fade = 1.0 - smoothstep(0.28, 0.98, h + (0.48 - turb) * 0.82);
		float radial_fade = 1.0 - smoothstep(0.18, 1.05, radial + (0.46 - turb) * 0.75);
		float flame_field = base_fade * top_fade * radial_fade;

		heat = clamp(flame_field * (0.78 + turb * 0.95) * (1.18 - 0.55 * h), 0.0, 1.0);
		// Dark oily soot wisps curling off the upper tips
		float smoke_h = smoothstep(0.32, 0.88, h) * (1.0 - smoothstep(0.75, 1.0, h));
		float smoke_r = 1.0 - smoothstep(0.25, 1.15, abs(xw) / mix(0.65, 0.95, h));
		smoke_mask = smoke_h * smoke_r * smoothstep(0.34, 0.72, n_main) * smoke_mix * (1.0 - smoothstep(0.18, 0.45, heat));
	}

	// Realistic filmic blackbody temperature ramp (calibrated for ACES/AgX: deep crimson -> rich gasoline orange -> bright amber-gold -> luminous core, ZERO flat white clipping!)
	vec3 col_deep = vec3(0.38, 0.022, 0.002);
	vec3 col_orange = vec3(1.06, 0.17, 0.010);
	vec3 col_gold = vec3(1.68, 0.58, 0.042);
	vec3 col_core = vec3(2.08, 1.22, 0.34);

	vec3 fire_col = mix(col_deep, col_orange, smoothstep(0.06, 0.38, heat));
	fire_col = mix(fire_col, col_gold, smoothstep(0.38, 0.72, heat));
	fire_col = mix(fire_col, col_core, smoothstep(0.72, 0.96, heat));
	fire_col *= intensity;

	float fire_alpha = smoothstep(0.08, 0.36, heat);
	// Blend dark charcoal soot seamlessly around the upper cooling edges of the fire
	vec3 soot_col = vec3(0.032, 0.028, 0.026);
	float total_alpha = clamp(max(fire_alpha, smoke_mask * 0.76), 0.0, 1.0) * fade_alpha;
	if (total_alpha < 0.02) {
		discard;
	}
	float fire_w = fire_alpha / max(total_alpha / max(fade_alpha, 0.001), 0.001);
	ALBEDO = mix(soot_col, fire_col, clamp(fire_w, 0.0, 1.0));
	ALPHA = total_alpha;
}
