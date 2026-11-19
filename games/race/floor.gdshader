// Podłogi: 0 parkiet, 1 kafelki, 2 wykładzina, 3 panele, 4 dywan (UV), 5 asfalt, 6 płyty betonowe 2×2 m,
// 7 żwir, 8 trawa, 9 blacha ryflowana, 10 lastryko, 11 kostka brukowa 0,2×0,1 m.
shader_type spatial;

uniform int mode = 0;
uniform vec3 col_a : source_color = vec3(0.55, 0.33, 0.16);
uniform vec3 col_b : source_color = vec3(0.42, 0.24, 0.11);
uniform sampler2D bump_tex : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

vec3 planks(vec2 p, vec2 size, out float edge) {
	vec2 q = p / size;
	q.x += hash(vec2(floor(q.y), 3.1)) * 3.0;
	vec2 id = floor(q);
	vec2 f = fract(q);
	float h = hash(id);
	edge = min(min(f.x, 1.0 - f.x) * size.x, min(f.y, 1.0 - f.y) * size.y);
	float grain = noise(vec2(p.x * 2.0 + h * 17.0, p.y * 60.0)) * 0.6 + noise(vec2(p.x * 9.0, p.y * 140.0 + h * 5.0)) * 0.4;
	return mix(col_a, col_b, h * 0.7 + grain * 0.3);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	vec3 c;
	float rough = 0.6;
	float edge = 1.0;
	float metal = 0.0;
	if (mode == 0) {
		c = planks(p, vec2(0.6, 0.1), edge);
		c *= mix(0.5, 1.0, smoothstep(0.0, 0.004, edge));
		rough = 0.35;
	} else if (mode == 1) {
		vec2 q = p / 0.3;
		vec2 f = fract(q);
		float chk = mod(floor(q.x) + floor(q.y), 2.0);
		edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 0.3;
		c = mix(col_a, col_b, chk) * (0.95 + 0.05 * noise(p * 30.0));
		c = mix(vec3(0.55), c, smoothstep(0.003, 0.006, edge));
		rough = 0.12;
	} else if (mode == 2) {
		c = mix(col_a, col_b, noise(p * 6.0)) * (0.85 + 0.3 * hash(floor(p * 400.0)));
		rough = 1.0;
	} else if (mode == 3) {
		c = planks(p, vec2(1.3, 0.2), edge);
		c *= mix(0.6, 1.0, smoothstep(0.0, 0.003, edge));
		rough = 0.45;
	} else if (mode == 5) {
		// asfalt: ciemny, ziarnisty, z delikatnymi plamami
		float speck = hash(floor(p * 90.0));
		c = mix(col_a, col_b, noise(p * 1.5) * 0.5 + speck * 0.35) * (0.9 + 0.2 * noise(p * 12.0));
		rough = 0.85;
	} else if (mode == 6) {
		// płyty betonowe 2×2 m: fuga, odcień płyty, plamy
		vec2 q = p / 2.0;
		vec2 f = fract(q);
		edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 2.0;
		float tint = hash(floor(q));
		float stain = smoothstep(0.55, 0.8, noise(p * 0.9 + tint * 9.0));
		c = mix(col_a, col_b, tint * 0.5 + noise(p * 6.0) * 0.25) * (0.92 + 0.12 * hash(floor(p * 120.0)));
		c *= 1.0 - stain * 0.3;
		c = mix(c * 0.45, c, smoothstep(0.012, 0.025, edge));
		rough = 0.9;
	} else if (mode == 7) {
		// żwir: drobne ziarna w dwóch odcieniach z cieniem między nimi
		vec2 q = p * 35.0;
		vec2 f = fract(q) - 0.5;
		float h1 = hash(floor(q));
		float stone = 1.0 - smoothstep(0.25, 0.5, length(f + (vec2(hash(floor(q) + 3.1), h1) - 0.5) * 0.3));
		c = mix(col_a, col_b, h1) * mix(0.55, 1.05, stone) * (0.9 + 0.2 * noise(p * 3.0));
		rough = 1.0;
	} else if (mode == 8) {
		// trawa: szum dwóch zieleni + źdźbła
		float n = noise(p * 0.8) * 0.5 + noise(p * 4.0) * 0.3 + noise(p * 22.0) * 0.2;
		c = mix(col_a, col_b, n) * (0.8 + 0.35 * hash(floor(p * 160.0)));
		rough = 0.95;
	} else if (mode == 9) {
		// blacha ryflowana: rzędy krótkich wypustek naprzemiennie pod ±45°, metal
		vec2 q = p / 0.035;
		vec2 id = floor(q);
		vec2 f = fract(q) - 0.5;
		float s = mod(id.x + id.y, 2.0) * 2.0 - 1.0;
		vec2 r = vec2(f.x + s * f.y, f.y - s * f.x) * 0.7071;
		float bump = 1.0 - smoothstep(0.08, 0.13, length(vec2(r.x * 0.35, r.y)));
		c = mix(col_a, col_b, noise(p * 2.0) * 0.4) * (0.75 + 0.4 * bump);
		rough = 0.45 - bump * 0.15;
		metal = 0.85;
	} else if (mode == 10) {
		// lastryko: kolorowe odpryski na jasnym tle, polerowane
		c = col_a * (0.95 + 0.05 * noise(p * 8.0));
		for (int k = 0; k < 2; k++) {
			float sc = k == 0 ? 9.0 : 20.0;
			vec2 q = p * sc + float(k) * 17.3;
			vec2 id = floor(q);
			float h1 = hash(id);
			vec2 off = vec2(hash(id + 5.7), hash(id + 9.1)) - 0.5;
			float chip = 1.0 - smoothstep(0.14, 0.2 + h1 * 0.1, length(fract(q) - 0.5 - off * 0.4));
			vec3 cc = h1 < 0.4 ? col_b : (h1 < 0.7 ? col_b * 0.45 : vec3(0.92));
			c = mix(c, cc, chip * step(0.35, hash(id + 1.3)));
		}
		rough = 0.22;
	} else if (mode == 11) {
		// kostka brukowa 0,2×0,1 m w cegiełkę
		vec2 q = p / vec2(0.2, 0.1);
		q.x += 0.5 * mod(floor(q.y), 2.0);
		vec2 f = fract(q);
		edge = min(min(f.x, 1.0 - f.x) * 0.2, min(f.y, 1.0 - f.y) * 0.1);
		c = mix(col_a, col_b, hash(floor(q)) * 0.8) * (0.88 + 0.2 * noise(p * 25.0));
		c = mix(c * 0.4, c, smoothstep(0.004, 0.009, edge));
		rough = 0.85;
	} else {
		vec2 u = UV;
		float d = min(min(u.x, 1.0 - u.x), min(u.y, 1.0 - u.y));
		float band = step(0.06, d) - step(0.1, d) + step(0.14, d) - step(0.16, d);
		float ring = step(0.5, fract(length(u - 0.5) * 9.0));
		c = mix(col_a, col_b, clamp(band + ring * step(0.2, d) * 0.6, 0.0, 1.0));
		c = mix(c, c * 0.6, step(d, 0.02));
		c *= 0.85 + 0.3 * hash(floor(p * 300.0));
		rough = 1.0;
	}
	// nierówności z normal mapy w skali świata + matowe szczeliny między deskami/kaflami
	NORMAL_MAP = texture(bump_tex, p * ((mode == 2 || mode == 4) ? 2.0 : 0.35)).xyz;
	NORMAL_MAP_DEPTH = mode == 1 ? 0.25 : ((mode == 2 || mode == 4) ? 1.2 : 0.5);
	float smudge = noise(p * 0.7);
	ALBEDO = c;
	ROUGHNESS = clamp(rough + (smudge - 0.5) * 0.25 + (1.0 - smoothstep(0.0, 0.004, edge)) * 0.4, 0.04, 1.0);
	SPECULAR = (mode == 1 || mode == 10) ? 0.7 : 0.5;
	METALLIC = metal;
}
