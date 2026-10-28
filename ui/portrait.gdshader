shader_type canvas_item;
// Placeholder portraits as noir photographs: greyscale, crushed blacks, warm tint.
uniform vec3 tint : source_color = vec3(1.0, 0.93, 0.82);
uniform float contrast = 1.35;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	g = clamp((g - 0.5) * contrast + 0.45, 0.0, 1.0);
	float edge = smoothstep(0.75, 0.25, distance(UV, vec2(0.5, 0.45)));
	COLOR = vec4(vec3(g) * tint * mix(0.45, 1.0, edge), c.a);
}
