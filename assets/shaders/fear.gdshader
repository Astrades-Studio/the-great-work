shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time : hint_range(0, 10) = 0.0;
uniform float amplitude : hint_range(0, 1) = 0.05; // Zoom amplitude
uniform float frequency : hint_range(0, 10) = 3.0; // Breathing frequency
uniform float vignette_radius : hint_range(0, 1) = 1; // Increased radius to cover more area
uniform float vignette_intensity : hint_range(0, 1) = 1; // Increased intensity for stronger effect
uniform float blur_amount : hint_range(0, 1) = 1; // Blur amount for vignette



void fragment() {
    vec2 uv = SCREEN_UV;
    // Calculate zoom factor to simulate breathing effect
    float zoom = 1.0 + sin(time * frequency) * amplitude;
    zoom = max(zoom, 0.1);
    uv = (uv - 0.5) / zoom + 0.5;

    vec4 color = texture(SCREEN_TEXTURE, uv);

    // Compute vignette effect
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);

    // Darken the edges by inverting the vignette calculation
    float vignette = smoothstep(1.0 - vignette_radius, 1.0 - vignette_radius + vignette_intensity, dist);
    vec4 vignette_color = vec4(mix(color.rgb, vec3(0.0), vignette), color.a);

    // Simple blur effect (for demonstration, can be optimized)
    vec4 blurColor = vec4(0.0);
    float blurSize = 0.01;
    for (float x = -blurSize; x <= blurSize; x += blurSize) {
        for (float y = -blurSize; y <= blurSize; y += blurSize) {
            blurColor += texture(SCREEN_TEXTURE, uv + vec2(x, y));
        }
    }
    blurColor /= 9.0;

    // Combine blur and vignette effects
    color = mix(vignette_color, blurColor, vignette * blur_amount);

    COLOR = color;
}
