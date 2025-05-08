shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int columns = 8;
uniform int rows = 8;
uniform float speed = 2.0; // ускоряет разницу между плитками

void fragment() {
    vec2 uv = UV;

    int x = int(floor(uv.x * float(columns)));
    int y = int(floor(uv.y * float(rows)));

    float cell_time = float(y) / float(rows);
    float offset = float((x + y) % 2) * 0.15;

    // Усиленная задержка по каждой плитке
    float threshold = cell_time + offset;

    float alpha = 1.0;
    if (progress * speed > threshold) {
        alpha = 0.0;
    }

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
