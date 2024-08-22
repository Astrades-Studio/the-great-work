shader_type spatial;

uniform sampler2D albedo : source_color;
uniform vec2 tiling = vec2(1.0);
uniform vec2 offset = vec2(0.0);

group_uniforms sprite_mapping;
uniform sampler2D uv_map;
uniform sampler2D sprite : source_color, repeat_disable;
uniform vec2 uv_tiling = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform float depth = 0.0;

void fragment() {
	// Construct sprite transformation matrix
	mat3 tangent_view_matrix = mat3(TANGENT, -BINORMAL, NORMAL);
	mat3 sprite_matrix = mat3(vec3(1, 0, 0) * tangent_view_matrix, vec3(0), -VIEW * tangent_view_matrix);
	sprite_matrix[1] = normalize(cross(sprite_matrix[0], sprite_matrix[2]));
	sprite_matrix[0] = cross(sprite_matrix[2], sprite_matrix[1]);
	
	// Apply UV map and parallax
	vec4 sprite_uv_map = texture(uv_map, UV * uv_tiling + uv_offset);
	vec2 sprite_uv = sprite_uv_map.xy;
	sprite_uv -= sprite_matrix[2].xy / sprite_matrix[2].z * depth;
	
	// Rotate UV coordinates in tangent space
	sprite_uv -= 0.5;
	vec2 transformed_uv = vec2(dot(sprite_matrix[0].xy, sprite_uv), dot(sprite_matrix[1].xy, sprite_uv));
	transformed_uv += 0.5;
	
	vec4 surface_embedded_sprite = texture(sprite, transformed_uv);
	float sprite_mask = sprite_uv_map.a * surface_embedded_sprite.a;
	ALBEDO = texture(albedo, UV * tiling + offset).rgb;
	ALBEDO = mix(ALBEDO, surface_embedded_sprite.rgb, sprite_mask);
}