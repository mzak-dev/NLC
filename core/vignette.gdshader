// Winieta + delikatne ziarno: przyciemnione rogi kierują wzrok na środek sceny.
shader_type canvas_item;

uniform float strength = 0.55;

void fragment() {
	vec2 v = UV - 0.5;
	float d = dot(v, v) * 2.2;
	float grain = fract(sin(dot(UV * 1000.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	COLOR = vec4(vec3(grain * 0.04), smoothstep(0.15, 1.1, d) * strength);
}
