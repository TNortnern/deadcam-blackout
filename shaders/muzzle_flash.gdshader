shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform sampler2D shape_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float flash_seed = 0.0;
uniform float intensity = 2.85;
uniform float is_side = 0.0;
uniform float cool_t : hint_range(0.0, 1.0) = 0.0;

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

void fragment() {
	vec2 uv = UV;
	float s1 = flash_seed * 13.7;
	float s2 = flash_seed * 29.3;

	float border_fade = 1.0;
	float core_mask = 0.0;
	float streaks = 0.0;
	float shock_diamond = 0.0;

	if (is_side > 0.5) {
		// Nozzle sits at UV.x == 0.0, UV.y == 0.5 shooting forward (+UV.x)
		vec2 p = vec2(uv.x, (uv.y - 0.5) * 2.0);
		float n_warp = (vnoise(uv * vec2(12.0, 18.0) + vec2(s1, s2)) - 0.5) * 0.09;
		vec2 sample_uv = clamp(vec2(uv.x, uv.y + n_warp * smoothstep(0.0, 0.55, uv.x)), vec2(0.002), vec2(0.998));
		float sprite_v = texture(shape_tex, sample_uv).r;

		float jet_y = p.y / (0.11 + uv.x * 0.44);
		float jet = exp(-(jet_y * jet_y)) * (1.0 - smoothstep(0.18, 0.94, uv.x));
		// Supersonic Mach shock diamond nodes along forward jet
		float mach = pow(max(0.0, cos(uv.x * 24.0 + flash_seed * 1.4)), 4.0) * exp(-abs(p.y) * 9.0) * (1.0 - smoothstep(0.08, 0.65, uv.x));
		float core_x = uv.x * 4.4;
		float core_y = p.y * 5.8;
		core_mask = exp(-(core_x * core_x) - (core_y * core_y));
		float ray_n = vnoise(vec2(uv.x * 9.0 + s1, atan(p.y, uv.x + 0.05) * 16.0 + s2));
		streaks = jet * (0.45 + 0.55 * ray_n) * (0.55 + 0.65 * sprite_v);
		shock_diamond = mach * 0.72;
		border_fade = smoothstep(0.0, 0.04, uv.x) * (1.0 - smoothstep(0.84, 0.99, uv.x)) * (1.0 - smoothstep(0.68, 0.98, abs(p.y)));
	} else {
		// Front M16A2 5-slot birdcage compensator pattern: open upper/lateral ports, solid bottom baffle!
		vec2 p = uv * 2.0 - 1.0;
		float rad = length(p);
		float ang = atan(p.y, p.x);
		float warp = (vnoise(vec2(cos(ang) * 4.5 + s1, sin(ang) * 4.5 + s2) + rad * 5.5) - 0.5) * 0.07;
		vec2 sample_uv = clamp(uv + normalize(p + vec2(0.0001)) * warp, vec2(0.002), vec2(0.998));
		float sprite_v = texture(shape_tex, sample_uv).r;

		// Solid bottom compensator port (screen +Y is down, so suppress downward lobe cleanly)
		float a2_baffle = mix(0.07, 1.0, smoothstep(0.32, -0.18, p.y));
		float port_ang = ang + (flash_seed - 0.5) * 0.28;
		float slot5 = pow(max(0.0, cos(port_ang * 2.5)), 2.2) * (0.72 + 0.28 * cos(port_ang * 7.0 + s1));
		float fine_ray = vnoise(vec2(ang * 11.0 + s2, rad * 7.0 + s1));
		core_mask = exp(-rad * rad * 22.0);
		streaks = (0.35 + 0.65 * sprite_v) * (0.48 + 0.52 * fine_ray) * mix(0.18, 1.35, slot5) * a2_baffle * exp(-rad * 1.55);
		border_fade = 1.0 - smoothstep(0.66, 0.96, rad);
	}

	float hot_sparks = pow(max(vnoise(uv * 42.0 + vec2(s2, s1)), 0.0), 7.0) * smoothstep(0.04, 0.35, streaks);
	float density = clamp((core_mask * 0.92 + streaks * 0.95 + shock_diamond + hot_sparks) * border_fade, 0.0, 1.35);

	// 2-frame blackbody cooling: Frame 1 = white-gold HDR (triggers Glow), Frame 2 = deep orange-red ember cooling
	vec3 hot_col = mix(vec3(1.15, 0.28, 0.03), vec3(1.85, 0.92, 0.24), smoothstep(0.12, 0.55, density));
	hot_col = mix(hot_col, vec3(3.40, 2.75, 1.85), smoothstep(0.75, 1.18, density));

	vec3 cool_col = mix(vec3(0.70, 0.09, 0.01), vec3(1.20, 0.34, 0.05), smoothstep(0.15, 0.85, density));
	vec3 col = mix(hot_col, cool_col, cool_t);

	float a = smoothstep(0.035, 0.16, density) * border_fade;
	ALBEDO = col * density * intensity * mix(1.0, 0.52, cool_t);
	ALPHA = clamp(a, 0.0, 1.0);
}
