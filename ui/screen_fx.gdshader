shader_type canvas_item;
// Film look over the room: dark vignette and moving grain.
uniform float vignette = 0.82;
uniform float grain = 0.07;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float d = distance(UV, vec2(0.5, 0.48));
	float v = smoothstep(0.32, 0.82, d) * vignette;
	float n = rand(floor(UV * vec2(960.0, 540.0)) + floor(TIME * 24.0) * 1.7);
	float g = (n - 0.5) * grain;
	// Black vignette, with grain laid over what the vignette leaves showing.
	float ga = abs(g) * (1.0 - v);
	float a = v + ga;
	vec3 grain_rgb = vec3(g > 0.0 ? 1.0 : 0.0);
	COLOR = vec4(grain_rgb * ga / max(a, 0.0001), a);
}
