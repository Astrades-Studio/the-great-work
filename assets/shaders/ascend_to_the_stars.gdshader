shader_type canvas_item;

#define t TIME
#define iResolution 1.0/SCREEN_PIXEL_SIZE

uniform float res_x = 1152;
uniform float res_y = 648;

void fragment(){
	vec3 c;
	float l,z = t/3.0;
	for(int i = 0;i < 3; i++) {
		vec2 uv,p = UV;
		float ratio = res_x / res_y;
		uv = p;
		p -= 0.5;
		//p.x *= UV.x/UV.y;
		p = p * vec2(ratio, 1.0);
		z += .07;
		l = length(p);
		uv += p/l * (sin( z * 1.0) + 1.) * abs(sin( l * 9. - z - z));
		c[i] = .01/length(mod(uv,1.)-.5);
	}
	COLOR=vec4(c/l,t);
}