shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);
	float luma = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(mix(source.rgb, vec3(luma), amount), 1.0);
}
