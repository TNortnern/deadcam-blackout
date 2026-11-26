shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
#endif
uniform vec4 tint_color : source_color = vec4(0.85, 0.88, 0.90, 0.35);
uniform float soft_fade_dist : hint_range(0.02, 2.0) = 0.35;
uniform float near_fade_start : hint_range(0.01, 1.0) = 0.08;
uniform float near_fade_end : hint_range(0.05, 2.0) = 0.36;
uniform float wrap_lighting : hint_range(0.0, 1.0) = 0.65;
uniform float max_lit : hint_range(0.25, 8.0) = 1.65;
uniform float self_ambient : hint_range(0.0, 0.5) = 0.05;

varying vec4 v_color;
varying float v_view_depth;

void vertex() {
	v_color = COLOR;
	mat4 mat_world = mat4(
		normalize(INV_VIEW_MATRIX[0]),
		normalize(INV_VIEW_MATRIX[1]),
		normalize(INV_VIEW_MATRIX[2]),
		MODEL_MATRIX[3]
	);
	// Preserve particle rotation & scale from MODEL_MATRIX around view Z axis
	vec2 x_axis = MODEL_MATRIX[0].xy;
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	mat_world = mat_world * mat4(
		vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x),  cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
	mat_world[0] *= scale_x;
	mat_world[1] *= scale_y;
	mat_world[2] *= scale_z;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	v_view_depth = -vp.z;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	float a = tex.a * tint_color.a * v_color.a;
	if (a < 0.004) {
		discard;
	}

#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
	// Depth fade against opaque world geometry so quads never hard-clip walls or floors
	float raw_depth = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= max(view_pos.w, 1e-5);
	float scene_depth = -view_pos.z;
	float depth_diff = max(scene_depth - v_view_depth, 0.0);
	float soft = smoothstep(0.0, soft_fade_dist, depth_diff);
#else
	float soft = 1.0;
#endif
	float near_fade = smoothstep(near_fade_start, near_fade_end, v_view_depth);

	vec3 col = tex.rgb * tint_color.rgb * v_color.rgb;
	ALBEDO = col;
	ALPHA = clamp(a * soft * near_fade, 0.0, 1.0);
	EMISSION = col * self_ambient;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float wrap_ndl = clamp((ndl + wrap_lighting) / (1.0 + wrap_lighting), 0.0, 1.0);
	vec3 contrib = ALBEDO * LIGHT_COLOR * ATTENUATION * wrap_ndl * 0.318309886;
	// Luminance-preserving soft-knee saturation keeps arterial blood mist saturated crimson even in intense flashlight!
	float peak = max(contrib.r, max(contrib.g, contrib.b));
	DIFFUSE_LIGHT += contrib / (1.0 + peak / max(max_lit, 0.05));
}
