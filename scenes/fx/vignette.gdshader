shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.55;
uniform float inner : hint_range(0.0, 1.5) = 0.45;
uniform float outer : hint_range(0.0, 2.0) = 1.0;
uniform float aspect = 1.7777778;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * vec2(aspect, 1.0);
	float corner = length(vec2(aspect, 1.0) * 0.5);
	float distance_from_center = length(centered) / corner;
	float mask = smoothstep(inner, outer, distance_from_center);
	COLOR = vec4(edge_color.rgb, mask * strength);
}
