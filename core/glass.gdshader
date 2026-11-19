// Matowe szkło: rozmyte tło spod panelu + przyciemnienie + jasna krawędź.
// Panel musi mieć StyleBoxFlat z białym tłem i czerwoną ramką (maska) — patrz Collection.glass().
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float lod = 3.2;
uniform vec4 tint : source_color = vec4(0.04, 0.04, 0.06, 0.55);
uniform vec4 edge : source_color = vec4(1.0, 1.0, 1.0, 0.22);

void fragment() {
	vec4 mask = COLOR;
	vec2 o = SCREEN_PIXEL_SIZE * 6.0;
	vec3 bg = textureLod(screen_tex, SCREEN_UV, lod).rgb * 0.4
		+ (textureLod(screen_tex, SCREEN_UV + vec2(o.x, o.y), lod).rgb
		+ textureLod(screen_tex, SCREEN_UV + vec2(-o.x, o.y), lod).rgb
		+ textureLod(screen_tex, SCREEN_UV + vec2(o.x, -o.y), lod).rgb
		+ textureLod(screen_tex, SCREEN_UV + vec2(-o.x, -o.y), lod).rgb) * 0.15;
	vec3 glass = mix(bg * 1.1, tint.rgb, tint.a);
	float is_edge = 1.0 - step(0.5, mask.g);
	COLOR = vec4(mix(glass, edge.rgb, edge.a * is_edge), mask.a);
}
