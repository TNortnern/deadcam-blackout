shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform vec3 beam_color : source_color = vec3(0.78, 0.85, 0.96);
uniform float intensity : hint_range(0.0, 0.5) = 0.055;

void fragment() {
	// UV.y = 0 near emitter, 1 at far tip of cone
	float axial = smoothstep(0.0, 0.12, UV.y) * pow(1.0 - UV.y, 1.85);
	float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = pow(ndv, 1.75);
	float dust = 0.82 + 0.18 * sin(UV.x * 38.0 + TIME * 0.6) * cos(UV.y * 24.0 - TIME * 0.45);
	float a = axial * edge * intensity * dust;
	ALBEDO = beam_color * a;
	ALPHA = clamp(a, 0.0, 0.35);
}
