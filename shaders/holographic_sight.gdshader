shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled;
// Ultra-crisp realistic pinpoint EOTech holographic sight (NOT oversized cartoon crosshair!)

uniform vec4 reticle_color : source_color = vec4(1.0, 0.035, 0.008, 1.0);
uniform float brightness = 1.75;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);

	// Crisp realistic pinpoint 1-MOA center dot + delicate 65-MOA outer ring & micro ticks
	float ring = (1.0 - smoothstep(0.022, 0.077, abs(r - 0.34)));
	ring *= 0.63 + 0.37 * smoothstep(0.18, 0.36, abs(sin(atan(p.y,p.x) * 2.0)));
	float dot_c = (1.0 - smoothstep(0.040, 0.099, r));
	float tx = (1.0 - smoothstep(0.008, 0.026, abs(p.y))) * step(0.25, abs(p.x)) * step(abs(p.x), 0.43);
	float ty = (1.0 - smoothstep(0.008, 0.026, abs(p.x))) * step(0.25, abs(p.y)) * step(abs(p.y), 0.43);

	float halo = exp(-abs(r - 0.34) * 22.0) * 0.14 + exp(-r * 16.0) * 0.18;
	float mask = clamp(max(max(ring, dot_c), max(tx, ty)) + halo, 0.0, 1.0);
	float glass_tint = (1.0 - smoothstep(0.84, 0.98, max(abs(p.x), abs(p.y)))) * 0.045;

	ALBEDO = reticle_color.rgb * brightness * mask + vec3(0.10, 0.18, 0.20) * glass_tint;
	ALPHA = clamp(mask * 0.92 + glass_tint, 0.0, 1.0);
}
