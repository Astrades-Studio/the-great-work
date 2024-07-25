shader_type spatial;
uniform	sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float time : hint_range(0, 10);
uniform float intensity : hint_range(0, 1) = 0.5;
uniform vec4 parameter_color : source_color;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Warping effect
    uv.x += sin(uv.y * 10.0 + time * 5.0) * 0.01 * intensity;
    uv.y += cos(uv.x * 10.0 + time * 5.0) * 0.01 * intensity;

    // Blur effect
    float blur = intensity * 0.005;
    vec4 color = parameter_color;
	
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            color += texture(SCREEN_TEXTURE, uv + vec2(float(x),float(y)) * blur) / 25.0;
        }
    }

    // Color shift effect
    vec3 shift = vec3(0.05 * intensity, -0.05 * intensity, 0.0);
    vec4 final_color;
    final_color.r = texture(SCREEN_TEXTURE, uv + shift.rg).r;
    final_color.g = texture(SCREEN_TEXTURE, uv + shift.gr).g;
    final_color.b = texture(SCREEN_TEXTURE, uv + shift.bg).b;

    // Combine effects
    ALBEDO = mix(final_color.rgb, color.rgb, 0.5);
}
