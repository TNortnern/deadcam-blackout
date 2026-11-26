shader_type spatial;

uniform sampler2D stone : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D relief : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D aggregate : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 local_point;
varying vec3 local_normal;

void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec3 pigment = texture(stone, UV).rgb;
	vec3 weight = abs(normalize(local_normal));
	weight /= max(0.001, dot(weight, vec3(1.0)));
	vec3 grit = texture(aggregate, local_point.xz * 1.3).rgb * weight.y
		+ texture(aggregate, local_point.xy * 1.3).rgb * weight.z
		+ texture(aggregate, local_point.zy * 1.3).rgb * weight.x;
	float damp = 1.0 - smoothstep(0.15, 0.81, local_point.y + grit.g * 0.3);
	ALBEDO = clamp(pigment * mix(0.82, 1.16, dot(grit, vec3(0.333))) * mix(1.0, 0.58, damp), vec3(0.01), vec3(0.46));
	NORMAL_MAP = texture(relief, UV).rgb;
	NORMAL_MAP_DEPTH = 1.2;
	SPECULAR = 0.13;
	ROUGHNESS = mix(0.87, 0.54, damp);
}
