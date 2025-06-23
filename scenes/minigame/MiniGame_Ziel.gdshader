shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 light_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float time_speed = 1.0;
uniform float wobble_strength = 0.03;
uniform float radius = 0.5;
uniform float softness = 0.3;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);

    dist += sin(uv.y * 10.0 + TIME * time_speed) * wobble_strength;
    dist += cos(uv.x * 12.0 + TIME * time_speed * 1.2) * wobble_strength;

    float intensity = smoothstep(radius, radius - softness, dist);

    COLOR = light_color * intensity;
}
