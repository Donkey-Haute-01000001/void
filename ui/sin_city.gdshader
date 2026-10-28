shader_type canvas_item;
// Sin City grade: the room goes hard black and white; only strong reds keep
// their colour (the tie, the pins and string, an ember, later blood).
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float contrast = 1.55;
uniform float pivot = 0.32;

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	l = clamp((l - pivot) * contrast + pivot, 0.0, 1.0);
	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float sat = (hi - lo) / max(hi, 0.001);
	float red = smoothstep(0.6, 0.8, sat) * step(c.g * 1.7, c.r) * step(c.b * 1.7, c.r) * smoothstep(0.04, 0.1, c.r);
	vec3 keep = vec3(0.82, 0.07, 0.11) * (0.45 + l * 1.2);
	COLOR = vec4(mix(vec3(l), keep, red), 1.0);
}
