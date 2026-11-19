// Ściana malowana wałkiem. Maska (tekstura float) trzyma grubość farby w „warstwach”:
// cienka warstwa prześwituje podkładem, gruba spływa zaciekami. Faktura wałka i tynku to mapa normalnych
// liczona z wysokości. Schnięcie idzie plamami: cienkie miejsca i krawędzie pierwsze, zacieki ostatnie.
shader_type spatial;

uniform sampler2D mask : filter_linear, repeat_disable;
uniform vec3 primer : source_color = vec3(0.62, 0.61, 0.58);
uniform vec3 paint : source_color = vec3(0.78, 0.05, 0.09);
uniform float wetness = 1.0;                 // 1 = świeżo pomalowana, 0 = sucha
uniform float sheen = 0.85;                  // szorstkość suchej powłoki (zależy od rodzaju farby)
uniform vec2 touch_pos = vec2(-1.0);         // odcisk dłoni w UV; < 0 = brak
uniform vec2 wall_size = vec2(5.2, 2.6);     // metry — szum liczony w metrach, nie w UV
uniform float seed = 0.0;                    // inny układ plam na każdej ścianie

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return s / 0.94;
}

// Zaciek: farba z przemalowanego miejsca powyżej spływa wąskimi strużkami (do ~30 cm w dół).
float drip(vec2 uv, vec2 m) {
	float column = smoothstep(0.5, 0.8, noise(vec2(m.x * 40.0 + seed, 2.0)));
	float d = 0.0;
	for (int i = 0; i < 5; i++) {
		float up = float(i) * 0.06 / wall_size.y;
		d = max(d, smoothstep(2.3, 3.2, texture(mask, uv - vec2(0.0, up)).r) * (1.0 - float(i) * 0.18));
	}
	return d * column;
}

// Wysokość powierzchni (jednostki umowne): tynk + powłoka z „barankiem” po wałku, zakładkami pasów i zaciekami.
float surf(vec2 uv) {
	vec2 m = uv * wall_size;
	float t = texture(mask, uv).r;
	float cover = 1.0 - exp(-2.6 * t);
	float plaster = fbm(m * 7.0 + seed) + 0.3 * noise(m * 60.0);
	float stipple = noise(m * vec2(95.0, 80.0) + seed);
	float laps = noise(vec2(m.x * 6.0 + seed, 0.5));
	return plaster * mix(1.0, 0.35, cover)      // farba wypełnia pory tynku
		+ cover * (0.9 * stipple + 0.5 * laps)
		+ min(t, 3.0) * 0.6
		+ drip(uv, m) * 2.5;
}

void fragment() {
	vec2 uv = UV;
	vec2 m = uv * wall_size;
	float t = texture(mask, uv).r;
	float ragged = (noise(m * 70.0 + seed) - 0.5) * 0.12;
	float cover = (1.0 - exp(-2.6 * t)) * smoothstep(0.03, 0.14, t + ragged);
	float dr = drip(uv, m);

	// Kolejność schnięcia f: 0 = schnie pierwsze, 1 = ostatnie.
	float f = 0.55 * fbm(m * 1.8 + seed) + 0.3 * smoothstep(0.4, 2.0, t) + 0.15 * noise(m * 25.0);
	vec2 from_edge = min(uv, 1.0 - uv) * wall_size;
	f *= 0.6 + 0.4 * smoothstep(0.0, 0.35, min(from_edge.x, from_edge.y));
	f = clamp(max(f, dr), 0.0, 1.0);
	float th = mix(0.12, 0.88, f);
	float wet = smoothstep(th - 0.1, th + 0.1, wetness);    // lokalna wilgotność

	float streak = noise(vec2(m.x * 80.0 + seed, m.y * 5.0));
	vec3 base = primer * (0.9 + 0.1 * fbm(m * 7.0 + seed));
	vec3 coat = paint * (0.93 + 0.1 * streak) * mix(1.0, 0.8, wet) * (1.0 - 0.12 * dr);
	vec3 col = mix(base, coat, cover);
	float rough = mix(0.95, mix(sheen, 0.07, wet), cover);

	if (touch_pos.x >= 0.0) {
		vec2 dv = (uv - touch_pos) * wall_size;
		float d = length(dv * vec2(1.25, 1.0));
		float fp = (1.0 - smoothstep(0.075, 0.09, d)) * (0.5 + 0.5 * sin(d * 420.0 + atan(dv.y, dv.x) * 2.0));
		col = mix(col, base, fp * 0.75 * cover);
		rough = mix(rough, 0.9, fp);
	}

	float e = 0.004;    // krok różnic skończonych [m]
	float h0 = surf(uv);
	float hx = surf(uv + vec2(e / wall_size.x, 0.0));
	float hy = surf(uv + vec2(0.0, e / wall_size.y));
	float k = mix(0.25, 0.5, cover);
	NORMAL_MAP = normalize(vec3((h0 - hx) * k, (h0 - hy) * k, 1.0)) * 0.5 + 0.5;

	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = mix(0.3, 0.5 + 0.3 * wet, cover);
	CLEARCOAT = cover * wet * 0.8;
	CLEARCOAT_ROUGHNESS = 0.06;
}
