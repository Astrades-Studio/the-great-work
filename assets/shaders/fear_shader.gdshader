shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float time : hint_range(0, 100);
uniform float amplitude : hint_range(0, 10) = 0.02;
uniform float frequency : hint_range(0, 10) = 10.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Create a wobble effect using sine waves
    uv.x += sin(uv.y * frequency + time) * amplitude;
    uv.y += cos(uv.x * frequency + time) * amplitude;

    // Sample the texture with the distorted UV coordinates
    vec4 color = texture(SCREEN_TEXTURE, uv);

    COLOR = color;
}
