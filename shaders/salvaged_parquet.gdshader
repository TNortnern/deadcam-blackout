shader_type spatial;

uniform sampler2D oak : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grain : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D silt : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec2 floor_pos;

void vertex() {
	floor_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 dust = texture(silt, floor_pos * 0.45).rgb;
	float patches = texture(silt, floor_pos * 0.11 + vec2(0.36, 0.79)).g;
	float edges = smoothstep(6.3, 8.1, max(abs(floor_pos.y), abs(floor_pos.x) * 0.8));
	float deposit = smoothstep(0.14, 0.39, sqrt(patches) + dust.r * 0.38 + edges * 0.28);
	float sheen = smoothstep(0.20, 0.65, 1.0 - deposit);
	vec3 wood = texture(oak, UV).rgb * COLOR.rgb * mix(0.92, 1.04, sheen);
	ALBEDO = mix(wood, dust * vec3(0.45, 0.39, 0.32), deposit * 0.77);
	NORMAL_MAP = texture(grain, UV).rgb;
	NORMAL_MAP_DEPTH = 1.08;
	ROUGHNESS = mix(0.30, 0.94, deposit);
	SPECULAR = mix(0.64, 0.24, deposit);
}
