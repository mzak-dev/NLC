// Post-FX prędkości (na warstwie pod HUD-em): lekkie rozmycie radialne i aberracja chromatyczna
// tylko na krawędziach, smugi prędkości, winieta, ziarno, czerwony błysk przy uderzeniu.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float speed = 0.0;
uniform float hit = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = vec2(0.5, 0.55);
	vec2 d = uv - c;
	float r = length(d * vec2(1.6, 1.0));
	float edge = smoothstep(0.25, 0.85, r);

	// rozmycie radialne: kilka próbek w stronę środka, tylko na krawędziach
	float blur = speed * speed * edge * 0.035;
	vec3 col = vec3(0.0);
	for (int i = 0; i < 6; i++) {
		float k = float(i) / 5.0;
		col += textureLod(screen_tex, uv - d * blur * k, 0.0).rgb;
	}
	col /= 6.0;
	// aberracja chromatyczna na krawędziach (+ przy uderzeniu)
	float ca = (speed * 0.004 + hit * 0.01) * edge;
	col.r = mix(col.r, textureLod(screen_tex, uv + d * ca, 0.0).r, 0.8);
	col.b = mix(col.b, textureLod(screen_tex, uv - d * ca, 0.0).b, 0.8);

	// smugi prędkości: cienkie promienie od środka, przesuwające się na zewnątrz
	float ang = atan(d.y, d.x);
	float ray = floor(ang * 60.0);
	float h = hash(vec2(ray, 1.0));
	float lane = fract(r * 2.0 - TIME * (2.0 + h * 3.0) + h);
	float streak = step(0.93, h) * smoothstep(0.0, 0.15, lane) * smoothstep(0.6, 0.2, lane);
	streak *= smoothstep(0.35, 0.9, r) * smoothstep(0.45, 1.0, speed);
	col += vec3(1.0) * streak * 0.18;

	// winieta (mocniejsza przy prędkości), ziarno, błysk uderzenia
	col *= 1.0 - smoothstep(0.45, 1.25, r) * (0.35 + speed * 0.25);
	col += (hash(uv * 900.0 + TIME) - 0.5) * 0.025;
	col = mix(col, vec3(0.6, 0.05, 0.05), hit * hit * 0.25 * edge);
	COLOR = vec4(col, 1.0);
}
