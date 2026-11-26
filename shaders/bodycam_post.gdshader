shader_type canvas_item;
render_mode blend_disabled;
// Authentic Bodycam 155-deg Wide-Angle Lens Optics - Zero-Copy SubViewport Pass

uniform float fisheye_strength : hint_range(0.0, 0.45) = 0.212;
uniform float ca_strength : hint_range(0.0, 0.025) = 0.0068;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.80;
uniform float corner_roundness : hint_range(0.5, 2.5) = 1.05;
uniform vec2 focus_uv = vec2(0.5);
uniform float near_focus = 0.0;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.016;
uniform float sharpen_strength : hint_range(0.0, 1.0) = 0.36;
uniform float damage_vignette : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fixed_time : hint_range(-1.0, 10000.0) = -1.0;
uniform float yaw_vel : hint_range(-10.0, 10.0) = 0.0;
uniform vec2 hit_dir_screen = vec2(0.0);
uniform float hit_ca_boost : hint_range(0.0, 0.025) = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 barrel_distort(vec2 uv, float k) {
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	float zoom = 1.0 / (1.0 + k * 1.98);
	vec2 d = p * (1.0 + k * r2) * zoom;
	return d * 0.5 + 0.5;
}

void fragment() {
	float t = (fixed_time >= 0.0) ? fixed_time : TIME;
	vec2 uv = UV;

	if (fixed_time < 0.0) {
		uv.x += clamp(yaw_vel, -4.0, 4.0) * 0.0020 * (uv.y - 0.5);
	}

	if (glitch_amount > 0.001) {
		float band = floor(uv.y * 90.0);
		float n = hash12(vec2(band, floor(t * 24.0)));
		if (n > 1.0 - glitch_amount * 0.45) {
			uv.x += (n - 0.5) * 0.12 * glitch_amount;
		}
	}

	vec2 duv = clamp(barrel_distort(uv, fisheye_strength), vec2(0.001), vec2(0.999));
	vec2 center_vec = duv - vec2(0.5);
	float r2 = dot(center_vec * vec2(1.12, 1.0), center_vec * vec2(1.12, 1.0));
	float r = sqrt(r2);

	vec2 ca_off = center_vec * ((ca_strength + hit_ca_boost) * (0.18 + r2 * 3.1));
	vec2 uv_r = clamp(duv + ca_off, vec2(0.001), vec2(0.999));
	vec2 uv_g = clamp(duv, vec2(0.001), vec2(0.999));
	vec2 uv_b = clamp(duv - ca_off, vec2(0.001), vec2(0.999));

	// Core 3-channel optical sample
	float cr = texture(TEXTURE, uv_r).r;
	float cg = texture(TEXTURE, uv_g).g;
	float cb = texture(TEXTURE, uv_b).b;
	vec3 col = vec3(cr, cg, cb);

	// Budgeted 2 extra taps: outer shutter/lens blur OR central CAS micro-sharpen (never both -> <= 5 taps total!)
	float spread = near_focus * smoothstep(0.155, 0.37, length((duv - focus_uv) * vec2(1.55, 1.0)));
	if (spread > 0.005) {
		vec2 shutter = vec2(0.017, 0.0026) * spread;
		vec3 moving = texture(TEXTURE, clamp(duv - shutter, vec2(0.001), vec2(0.999))).rgb;
		moving += texture(TEXTURE, clamp(duv + shutter * 0.59, vec2(0.001), vec2(0.999))).rgb;
		col = mix(col, moving * 0.5, 0.62 * spread);
	} else if (r > 0.48) {
		float sm = clamp((r - 0.48) * 1.5, 0.0, 0.22);
		vec2 rdir = center_vec * 0.018 * sm;
		vec3 s1 = texture(TEXTURE, clamp(duv - rdir, vec2(0.001), vec2(0.999))).rgb;
		vec3 s2 = texture(TEXTURE, clamp(duv + rdir, vec2(0.001), vec2(0.999))).rgb;
		col = mix(col, (col + s1 + s2) / 3.0, sm);
	} else {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		// Fast directional luma-edge FXAA + clamped symmetric CAS for crisp, stair-step-free WebGL2 optics
		vec2 px = TEXTURE_PIXEL_SIZE;
		vec3 nw = texture(TEXTURE, clamp(duv + vec2(-px.x, -px.y), vec2(0.001), vec2(0.999))).rgb;
		vec3 ne = texture(TEXTURE, clamp(duv + vec2( px.x, -px.y), vec2(0.001), vec2(0.999))).rgb;
		vec3 sw = texture(TEXTURE, clamp(duv + vec2(-px.x,  px.y), vec2(0.001), vec2(0.999))).rgb;
		vec3 se = texture(TEXTURE, clamp(duv + vec2( px.x,  px.y), vec2(0.001), vec2(0.999))).rgb;
		vec3 l_w = vec3(0.299, 0.587, 0.114);
		float l_m  = dot(col, l_w);
		float l_nw = dot(nw, l_w);
		float l_ne = dot(ne, l_w);
		float l_sw = dot(sw, l_w);
		float l_se = dot(se, l_w);
		float l_min = min(l_m, min(min(l_nw, l_ne), min(l_sw, l_se)));
		float l_max = max(l_m, max(max(l_nw, l_ne), max(l_sw, l_se)));
		float l_range = l_max - l_min;
		if (l_range > max(0.0312, l_max * 0.125)) {
			vec2 dir = vec2(-((l_nw + l_ne) - (l_sw + l_se)), ((l_nw + l_sw) - (l_ne + l_se)));
			float dir_reduce = max((l_nw + l_ne + l_sw + l_se) * 0.03125, 0.0078125);
			float rcp_min = 1.0 / (min(abs(dir.x), abs(dir.y)) + dir_reduce);
			dir = clamp(dir * rcp_min, vec2(-4.0), vec2(4.0)) * px;
			vec3 rgb_a = 0.5 * (
				texture(TEXTURE, clamp(duv + dir * (1.0 / 3.0 - 0.5), vec2(0.001), vec2(0.999))).rgb +
				texture(TEXTURE, clamp(duv + dir * (2.0 / 3.0 - 0.5), vec2(0.001), vec2(0.999))).rgb
			);
			vec3 rgb_b = rgb_a * 0.5 + 0.25 * (
				texture(TEXTURE, clamp(duv + dir * -0.5, vec2(0.001), vec2(0.999))).rgb +
				texture(TEXTURE, clamp(duv + dir *  0.5, vec2(0.001), vec2(0.999))).rgb
			);
			float l_b = dot(rgb_b, l_w);
			col = (l_b < l_min || l_b > l_max) ? rgb_a : rgb_b;
		} else {
			float center_sharp = sharpen_strength * 0.55 * (1.0 - clamp(r * 1.35, 0.0, 0.90));
			if (center_sharp > 0.015) {
				vec3 avg_n = (nw + ne + sw + se) * 0.25;
				vec3 mn_c = min(col, min(min(nw, ne), min(sw, se)));
				vec3 mx_c = max(col, max(max(nw, ne), max(sw, se)));
				col = clamp(col + (col - avg_n) * center_sharp, mn_c, mx_c);
			}
		}
#else
		float center_sharp = sharpen_strength * (1.0 - clamp(r * 1.35, 0.0, 0.90));
		if (center_sharp > 0.015) {
			vec2 px = TEXTURE_PIXEL_SIZE;
			vec3 blur_small = (
				texture(TEXTURE, clamp(duv + px, vec2(0.001), vec2(0.999))).rgb +
				texture(TEXTURE, clamp(duv - px, vec2(0.001), vec2(0.999))).rgb
			) * 0.5;
			col += (col - blur_small) * center_sharp;
		}
#endif
	}

	// Lightweight sensor grain (highlight/shadow scaled) + optical vignette
	// Tonemapping, AgX curve & shadow split-tone are handled natively in HDR linear space before post!
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec2 grain_coord = floor(FRAGCOORD.xy);
#else
	vec2 grain_coord = floor(uv * vec2(1600.0, 900.0));
#endif
	float g_n = hash12(grain_coord + vec2(fract(t * 17.3) * 512.0, fract(t * 29.1) * 512.0)) - 0.5;
	float shadow_boost = mix(1.55, 0.22, clamp(luma * 2.4, 0.0, 1.0));
	col += vec3(g_n) * grain_strength * shadow_boost;

	vec2 vpos = (uv * 2.0 - 1.0) * vec2(0.92, 0.86);
	float corner_dist = length(vpos + vec2(0.03, -0.02));
	float vig = 1.0 - smoothstep(0.68, 1.26, pow(corner_dist, corner_roundness * 0.95));
	col *= mix(1.0, vig, clamp(vignette_strength, 0.0, 1.0));

	if (damage_vignette > 0.001) {
		float dir_bias = clamp(dot(normalize(center_vec + vec2(0.0001)), hit_dir_screen), -0.4, 1.0);
		float dv = smoothstep(0.28, 1.15, corner_dist + dir_bias * 0.24) * damage_vignette;
		float claw_ang = atan(center_vec.y, center_vec.x);
		float claw = smoothstep(0.65, 0.98, abs(sin(claw_ang * 7.0 + hit_dir_screen.x * 3.0))) * smoothstep(0.28, 0.62, r) * damage_vignette;
		col = mix(col, vec3(0.42, 0.015, 0.012), clamp(dv * 0.72 + claw * 0.24, 0.0, 0.85));
	}

	if (glitch_amount > 0.001) {
		float static_n = hash12(FRAGCOORD.xy * 0.5 + vec2(t * 111.0, t * 73.0));
		col = mix(col, vec3(static_n * 0.35), glitch_amount * 0.55);
	}

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
