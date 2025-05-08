shader_type canvas_item;

uniform float glitch_amount = 0.0;

void fragment() {
    if (glitch_amount <= 0.0) {
        COLOR = texture(TEXTURE, UV);
    } else {
        vec2 uv = UV;
        float glitch = clamp(glitch_amount, 0.0, 1.0);

        // 🔺 Глітч-смещения (тремтіння)
        uv.x += sin(UV.y * 1000.0 + TIME * 80.0) * glitch * 0.015;
        uv.y += cos(UV.x * 200.0 + TIME * 60.0) * glitch * 0.007;

        // 🔺 Сильніше викривлення (лінза)
        uv = uv * 2.0 - 1.0;  // від [0,1] до [-1,1]
        float actual_curvature = pow(glitch, 1.2) * 0.3;  // прогресивна кривизна
        uv *= 1.0 + actual_curvature * (uv.x * uv.x + uv.y * uv.y);
        uv = uv * 0.5 + 0.5;  // назад у [0,1]

        // 🔺 Хроматична аберація
        float aberration = 0.0001 + glitch * 0.003;
        vec4 color;
        color.r = texture(TEXTURE, uv + vec2(aberration, 0.0)).r;
        color.g = texture(TEXTURE, uv).g;
        color.b = texture(TEXTURE, uv - vec2(aberration, 0.0)).b;
        color.a = 1.0;

        // 🔺 Сканлайни
        float scanline_intensity = 0.003;
        float scanline = sin(UV.y * 600.0 + TIME * 10.0) * (scanline_intensity + glitch * 0.02);
        color.rgb -= scanline;

        // 🔺 Віньєтка
        vec2 vin_uv = UV * 2.0 - 1.0;
        float vignette = smoothstep(1.0, 0.8, length(vin_uv));
        float vignette_mix = mix(1.0, vignette, 0.03 + glitch * 0.25);
        color.rgb *= vignette_mix;

        COLOR = color;
    }
}
