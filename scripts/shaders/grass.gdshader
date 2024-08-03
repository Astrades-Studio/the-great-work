shader_type spatial;

uniform sampler2D texture : source_color; // Cambiado de hint_albedo a source_color
uniform float tile_size = 1.0; // Tamaño del mosaico

void fragment() {
    vec2 uv = UV * tile_size;
    vec4 color = texture(texture, uv);
    ALBEDO = color.rgb;
}