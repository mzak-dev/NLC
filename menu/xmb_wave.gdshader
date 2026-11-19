// Tło w stylu XMB: ciemny gradient, przenikające się wstęgi fal z poświatą i dryfujące iskry.
shader_type canvas_item;

uniform float brightness = 1.0;
uniform vec3 top_color : source_color = vec3(0.015, 0.015, 0.02);
uniform vec3 bottom_color : source_color = vec3(0.17, 0.0, 0.025);
uniform vec3 wave_color : source_color = vec3(1.0, 0.12, 0.18);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// Jedna wstęga: jasna krawędź + półprzezroczysty „płat” pod nią.
float ribbon(vec2 uv, float t, float freq, float amp, float speed, float base, float sharp) {
	float y = base
		+ amp * sin(uv.x * freq + t * speed)
		+ amp * 0.45 * sin(uv.x * freq * 2.13 - t * speed * 1.37 + base * 17.0)
		+ amp * 0.25 * sin(uv.x * freq * 0.51 + t * speed * 0.61);
	float d = uv.y - y;
	float edge = exp(-abs(d) * sharp);
	float sheet = smoothstep(0.0, 0.01, d) * exp(-d * 7.0) * 0.18;
	return edge + sheet;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	vec3 col = mix(top_color, bottom_color, smoothstep(-0.1, 1.1, uv.y + 0.12 * sin(uv.x * 2.0 + t * 0.05)));

	float w = 0.0;
	w += ribbon(uv, t, 3.1, 0.055, 0.22, 0.56, 70.0) * 0.55;
	w += ribbon(uv, t, 2.3, 0.075, -0.16, 0.60, 45.0) * 0.38;
	w += ribbon(uv, t, 4.2, 0.040, 0.31, 0.53, 110.0) * 0.45;
	w += ribbon(uv, t, 1.7, 0.090, 0.11, 0.62, 30.0) * 0.22;
	float glow = ribbon(uv, t, 2.6, 0.07, 0.18, 0.58, 5.0) * 0.10;
	col += wave_color * (w + glow);
	col += vec3(1.0) * pow(clamp(w, 0.0, 1.0), 3.0) * 0.35;

	// iskry dryfujące w prawo, gęściej przy falach
	vec2 sp = uv * vec2(64.0, 36.0);
	sp.x -= t * 0.35;
	vec2 cell = floor(sp);
	vec2 f = fract(sp) - 0.5;
	float h = hash(cell);
	vec2 o = vec2(hash(cell + 1.3), hash(cell + 7.1)) - 0.5;
	float star = smoothstep(0.09, 0.0, length(f - o * 0.6)) * step(0.92, h);
	star *= 0.5 + 0.5 * sin(t * 2.3 + h * 40.0);
	col += vec3(1.0, 0.85, 0.85) * star * (0.15 + w * 2.5);

	vec2 v = uv - 0.5;
	col *= 1.0 - dot(v, v) * 0.9;
	COLOR = vec4(col * brightness, 1.0);
}
