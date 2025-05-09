shader_type canvas_item;

uniform float speed = 0.01;
uniform vec2 scale = vec2(1.0, 1.0);
uniform float hit_flash = 0.0; // 0.0 = обычный цвет, 1.0 = цвет при уроне

void fragment() {
    vec2 uv = UV * scale;

    // Движение
    uv.x -= TIME * speed * 0.001;
    uv.y += TIME * speed * 0.003;

    // Глитч-дрожание
    uv.x += sin(TIME * 5.0 + uv.y * 50.0) * 0.002;

    float pulse = 0.9 + 0.1 * sin(TIME * 2.0);

    vec4 tex = texture(TEXTURE, uv);

    // Основной цвет
    vec3 normal_tint = vec3(0.49, 0.466, 0.655);
	//vec3 normal_tint = vec3(0.2, 1.0, 0.2);

    vec3 hit_tint = vec3(1.5, 0.05, 0.05);  // красный при уроне

    // Плавное смешение
    vec3 final_tint = mix(normal_tint, hit_tint, hit_flash);

    COLOR = vec4(min(tex.rgb * final_tint * 1.1, vec3(1.0)), tex.a) * pulse;
}
