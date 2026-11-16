shader_type canvas_item;
// SpeedVignette: a soft tinted glow at the screen edges only; the centre stays clear.

uniform vec4 tint : source_color = vec4(0.3, 1.0, 0.45, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.15;
uniform float inner = 0.96;  // where the glow starts, 0 = centre, 1 = edge

void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;  // 0 at the centre, 1 at an edge
	float edge = max(d.x, d.y);
	float glow = smoothstep(inner, 1.0, edge);
	COLOR = vec4(tint.rgb, glow * strength);
}
