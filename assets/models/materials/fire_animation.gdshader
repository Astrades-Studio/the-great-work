shader_type spatial;

render_mode unshaded, blend_add;

uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset = vec3(0.0, 0.0, 0.0);
uniform float variation = 0.0;
varying float elapsed_time;
void vertex() {
	elapsed_time = TIME;
	UV = UV*uv1_scale.xy+uv1_offset.xy;
}
float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}
vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
						      dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}
vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
                              dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}
float param_rnd(float minimum, float maximum, float seed) {
	return minimum+(maximum-minimum)*rand(vec2(seed));
}
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
float value_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float p00 = rand(mod(o, size));
	float p01 = rand(mod(o + vec2(0.0, 1.0), size));
	float p10 = rand(mod(o + vec2(1.0, 0.0), size));
	float p11 = rand(mod(o + vec2(1.0, 1.0), size));
	p00 = sin(p00 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p01 = sin(p01 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p10 = sin(p10 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	p11 = sin(p11 * 6.28318530718 + offset * 6.28318530718) / 2.0 + 0.5;
	vec2 t =  f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(p00, p10, t.x), mix(p01, p11, t.x), t.y);
}
float fbm_2d_value(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = value_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float perlin_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float a00 = rand(mod(o, size)) * 6.28318530718 + offset * 6.28318530718;
	float a01 = rand(mod(o + vec2(0.0, 1.0), size)) * 6.28318530718 + offset * 6.28318530718;
	float a10 = rand(mod(o + vec2(1.0, 0.0), size)) * 6.28318530718 + offset * 6.28318530718;
	float a11 = rand(mod(o + vec2(1.0, 1.0), size)) * 6.28318530718 + offset * 6.28318530718;
	vec2 v00 = vec2(cos(a00), sin(a00));
	vec2 v01 = vec2(cos(a01), sin(a01));
	vec2 v10 = vec2(cos(a10), sin(a10));
	vec2 v11 = vec2(cos(a11), sin(a11));
	float p00 = dot(v00, f);
	float p01 = dot(v01, f - vec2(0.0, 1.0));
	float p10 = dot(v10, f - vec2(1.0, 0.0));
	float p11 = dot(v11, f - vec2(1.0, 1.0));
	vec2 t =  f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return 0.5 + mix(mix(p00, p10, t.x), mix(p01, p11, t.x), t.y);
}
float fbm_2d_perlin(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = perlin_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float perlinabs_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	return abs(2.0*perlin_noise_2d(coord, size, offset, seed)-1.0);
}
float fbm_2d_perlinabs(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = perlinabs_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float fbm_2d_mod289(float x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}
float fbm_2d_permute(float x) {
	return fbm_2d_mod289(((x * 34.0) + 1.0) * x);
}
vec2 fbm_2d_rgrad2(vec2 p, float rot, float seed) {
	float u = fbm_2d_permute(fbm_2d_permute(p.x) + p.y) * 0.0243902439 + rot; // Rotate by shift
	u = fract(u) * 6.28318530718; // 2*pi
	return vec2(cos(u), sin(u));
}
float simplex_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	coord *= 2.0; // needed for it to tile
	coord += rand2(vec2(seed, 1.0-seed)) + size;
	size *= 2.0; // needed for it to tile
	coord.y += 0.001;
	vec2 uv = vec2(coord.x + coord.y*0.5, coord.y);
	vec2 i0 = floor(uv);
	vec2 f0 = fract(uv);
	vec2 i1 = (f0.x > f0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 p0 = vec2(i0.x - i0.y * 0.5, i0.y);
	vec2 p1 = vec2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
	vec2 p2 = vec2(p0.x + 0.5, p0.y + 1.0);
	i1 = i0 + i1;
	vec2 i2 = i0 + vec2(1.0, 1.0);
	vec2 d0 = coord - p0;
	vec2 d1 = coord - p1;
	vec2 d2 = coord - p2;
	vec3 xw = mod(vec3(p0.x, p1.x, p2.x), size.x);
	vec3 yw = mod(vec3(p0.y, p1.y, p2.y), size.y);
	vec3 iuw = xw + 0.5 * yw;
	vec3 ivw = yw;
	vec2 g0 = fbm_2d_rgrad2(vec2(iuw.x, ivw.x), offset, seed);
	vec2 g1 = fbm_2d_rgrad2(vec2(iuw.y, ivw.y), offset, seed);
	vec2 g2 = fbm_2d_rgrad2(vec2(iuw.z, ivw.z), offset, seed);
	vec3 w = vec3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
	vec3 t = 0.8 - vec3(dot(d0, d0), dot(d1, d1), dot(d2, d2));
	t = max(t, vec3(0.0));
	vec3 t2 = t * t;
	vec3 t4 = t2 * t2;
	float n = dot(t4, w);
	return 0.5 + 5.5 * n;
}
float fbm_2d_simplex(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = simplex_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node =  0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718 * node);
			vec2 diff = neighbor + node - f;
			float dist = length(diff);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular2_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = length(diff);
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular2(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular2_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular3_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = abs((diff).x) + abs((diff).y);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular3(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular3_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular4_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = abs((diff).x) + abs((diff).y);
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular4(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular4_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular5_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.5 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = max(abs((diff).x), abs((diff).y));
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}
float fbm_2d_cellular5(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular5_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
float cellular6_noise_2d(vec2 coord, vec2 size, float offset, float seed) {
	vec2 o = floor(coord)+rand2(vec2(seed, 1.0-seed))+size;
	vec2 f = fract(coord);
	float min_dist1 = 2.0;
	float min_dist2 = 2.0;
	for(float x = -1.0; x <= 1.0; x++) {
		for(float y = -1.0; y <= 1.0; y++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 node = rand2(mod(o + vec2(x, y), size)) + vec2(x, y);
			node = 0.5 + 0.25 * sin(offset * 6.28318530718 + 6.28318530718*node);
			vec2 diff = neighbor + node - f;
			float dist = max(abs((diff).x), abs((diff).y));
			if (min_dist1 > dist) {
				min_dist2 = min_dist1;
				min_dist1 = dist;
			} else if (min_dist2 > dist) {
				min_dist2 = dist;
			}
		}
	}
	return min_dist2-min_dist1;
}
float fbm_2d_cellular6(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = cellular6_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
// MIT License Inigo Quilez - https://www.shadertoy.com/view/Xd23Dh
float voronoise_noise_2d( vec2 coord, vec2 size, float offset, float seed) {
	vec2 i = floor(coord) + rand2(vec2(seed, 1.0-seed)) + size;
	vec2 f = fract(coord);
	
	vec2 a = vec2(0.0);
	
	for( int y=-2; y<=2; y++ ) {
		for( int x=-2; x<=2; x++ ) {
			vec2  g = vec2( float(x), float(y) );
			vec3  o = rand3( mod(i + g, size) + vec2(seed) );
			o.xy += 0.25 * sin(offset * 6.28318530718 + 6.28318530718*o.xy);
			vec2  d = g - f + o.xy;
			float w = pow( 1.0-smoothstep(0.0, 1.414, length(d)), 1.0 );
			a += vec2(o.z*w,w);
		}
	}
	
	return a.x/a.y;
}
float fbm_2d_voronoise(vec2 coord, vec2 size, int folds, int octaves, float persistence, float offset, float seed) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	for (int i = 0; i < octaves; i++) {
		float noise = voronoise_noise_2d(coord*size, size, offset, seed);
		for (int f = 0; f < folds; ++f) {
			noise = abs(2.0*noise-1.0);
		}
		value += noise * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}
vec2 transform2_clamp(vec2 uv) {
	return clamp(uv, vec2(0.0), vec2(1.0));
}
vec2 transform2(vec2 uv, vec2 translate, float rotate, vec2 scale) {
 	vec2 rv;
	uv -= translate;
	uv -= vec2(0.5);
	rv.x = cos(rotate)*uv.x + sin(rotate)*uv.y;
	rv.y = -sin(rotate)*uv.x + cos(rotate)*uv.y;
	rv /= scale;
	rv += vec2(0.5);
	return rv;	
}
uniform sampler2D texture_1;
const float texture_1_size = 1024.0;
uniform sampler2D texture_2;
const float texture_2_size = 1024.0;
float pingpong(float a, float b)
{
  return (b != 0.0) ? abs(fract((a - b) / (b * 2.0)) * b * 2.0 - b) : 0.0;
}
vec3 blend_normal(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1 + (1.0-opacity)*c2;
}
vec3 blend_dissolve(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	if (rand(uv) < opacity) {
		return c1;
	} else {
		return c2;
	}
}
vec3 blend_multiply(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*c1*c2 + (1.0-opacity)*c2;
}
vec3 blend_screen(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*(1.0-(1.0-c1)*(1.0-c2)) + (1.0-opacity)*c2;
}
float blend_overlay_f(float c1, float c2) {
	return (c1 < 0.5) ? (2.0*c1*c2) : (1.0-2.0*(1.0-c1)*(1.0-c2));
}
vec3 blend_overlay(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_overlay_f(c1.x, c2.x), blend_overlay_f(c1.y, c2.y), blend_overlay_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
vec3 blend_hard_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*0.5*(c1*c2+blend_overlay(uv, c1, c2, 1.0)) + (1.0-opacity)*c2;
}
float blend_soft_light_f(float c1, float c2) {
	return (c2 < 0.5) ? (2.0*c1*c2+c1*c1*(1.0-2.0*c2)) : 2.0*c1*(1.0-c2)+sqrt(c1)*(2.0*c2-1.0);
}
vec3 blend_soft_light(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_soft_light_f(c1.x, c2.x), blend_soft_light_f(c1.y, c2.y), blend_soft_light_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_burn_f(float c1, float c2) {
	return (c1==0.0)?c1:max((1.0-((1.0-c2)/c1)),0.0);
}
vec3 blend_burn(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_burn_f(c1.x, c2.x), blend_burn_f(c1.y, c2.y), blend_burn_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
float blend_dodge_f(float c1, float c2) {
	return (c1==1.0)?c1:min(c2/(1.0-c1),1.0);
}
vec3 blend_dodge(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*vec3(blend_dodge_f(c1.x, c2.x), blend_dodge_f(c1.y, c2.y), blend_dodge_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}
vec3 blend_lighten(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*max(c1, c2) + (1.0-opacity)*c2;
}
vec3 blend_darken(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*min(c1, c2) + (1.0-opacity)*c2;
}
vec3 blend_difference(vec2 uv, vec3 c1, vec3 c2, float opacity) {
	return opacity*clamp(c2-c1, vec3(0.0), vec3(1.0)) + (1.0-opacity)*c2;
}
vec3 blend_additive(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + c1 * oppacity;
}
vec3 blend_addsub(vec2 uv, vec3 c1, vec3 c2, float oppacity) {
	return c2 + (c1 - .5) * 2.0 * oppacity;
}
const float p_o7210_gradient_0_pos = 0.000000000;
const vec4 p_o7210_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o7210_gradient_1_pos = 0.150122000;
const vec4 p_o7210_gradient_1_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o7210_gradient_2_pos = 0.431940000;
const vec4 p_o7210_gradient_2_col = vec4(0.796875000, 0.255784005, 0.018677000, 1.000000000);
const float p_o7210_gradient_3_pos = 0.677395000;
const vec4 p_o7210_gradient_3_col = vec4(1.000000000, 0.708922982, 0.019531000, 1.000000000);
const float p_o7210_gradient_4_pos = 0.895577000;
const vec4 p_o7210_gradient_4_col = vec4(1.000000000, 0.955565989, 0.781250000, 1.000000000);
const float p_o7210_gradient_5_pos = 1.000000000;
const vec4 p_o7210_gradient_5_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o7210_gradient_gradient_fct(float x) {
  if (x < p_o7210_gradient_0_pos) {
    return p_o7210_gradient_0_col;
  } else if (x < p_o7210_gradient_1_pos) {
    return mix(mix(p_o7210_gradient_1_col, p_o7210_gradient_2_col, (x-p_o7210_gradient_1_pos)/(p_o7210_gradient_2_pos-p_o7210_gradient_1_pos)), mix(p_o7210_gradient_0_col, p_o7210_gradient_1_col, (x-p_o7210_gradient_0_pos)/(p_o7210_gradient_1_pos-p_o7210_gradient_0_pos)), 1.0-0.5*(x-p_o7210_gradient_0_pos)/(p_o7210_gradient_1_pos-p_o7210_gradient_0_pos));
  } else if (x < p_o7210_gradient_2_pos) {
    return 0.5*(mix(p_o7210_gradient_1_col, p_o7210_gradient_2_col, (x-p_o7210_gradient_1_pos)/(p_o7210_gradient_2_pos-p_o7210_gradient_1_pos)) + mix(mix(p_o7210_gradient_0_col, p_o7210_gradient_1_col, (x-p_o7210_gradient_0_pos)/(p_o7210_gradient_1_pos-p_o7210_gradient_0_pos)), mix(p_o7210_gradient_2_col, p_o7210_gradient_3_col, (x-p_o7210_gradient_2_pos)/(p_o7210_gradient_3_pos-p_o7210_gradient_2_pos)), 0.5-0.5*cos(3.14159265359*(x-p_o7210_gradient_1_pos)/(p_o7210_gradient_2_pos-p_o7210_gradient_1_pos))));
  } else if (x < p_o7210_gradient_3_pos) {
    return 0.5*(mix(p_o7210_gradient_2_col, p_o7210_gradient_3_col, (x-p_o7210_gradient_2_pos)/(p_o7210_gradient_3_pos-p_o7210_gradient_2_pos)) + mix(mix(p_o7210_gradient_1_col, p_o7210_gradient_2_col, (x-p_o7210_gradient_1_pos)/(p_o7210_gradient_2_pos-p_o7210_gradient_1_pos)), mix(p_o7210_gradient_3_col, p_o7210_gradient_4_col, (x-p_o7210_gradient_3_pos)/(p_o7210_gradient_4_pos-p_o7210_gradient_3_pos)), 0.5-0.5*cos(3.14159265359*(x-p_o7210_gradient_2_pos)/(p_o7210_gradient_3_pos-p_o7210_gradient_2_pos))));
  } else if (x < p_o7210_gradient_4_pos) {
    return 0.5*(mix(p_o7210_gradient_3_col, p_o7210_gradient_4_col, (x-p_o7210_gradient_3_pos)/(p_o7210_gradient_4_pos-p_o7210_gradient_3_pos)) + mix(mix(p_o7210_gradient_2_col, p_o7210_gradient_3_col, (x-p_o7210_gradient_2_pos)/(p_o7210_gradient_3_pos-p_o7210_gradient_2_pos)), mix(p_o7210_gradient_4_col, p_o7210_gradient_5_col, (x-p_o7210_gradient_4_pos)/(p_o7210_gradient_5_pos-p_o7210_gradient_4_pos)), 0.5-0.5*cos(3.14159265359*(x-p_o7210_gradient_3_pos)/(p_o7210_gradient_4_pos-p_o7210_gradient_3_pos))));
  } else if (x < p_o7210_gradient_5_pos) {
    return mix(mix(p_o7210_gradient_3_col, p_o7210_gradient_4_col, (x-p_o7210_gradient_3_pos)/(p_o7210_gradient_4_pos-p_o7210_gradient_3_pos)), mix(p_o7210_gradient_4_col, p_o7210_gradient_5_col, (x-p_o7210_gradient_4_pos)/(p_o7210_gradient_5_pos-p_o7210_gradient_4_pos)), 0.5+0.5*(x-p_o7210_gradient_4_pos)/(p_o7210_gradient_5_pos-p_o7210_gradient_4_pos));
  }
  return p_o7210_gradient_5_col;
}
const float p_o7263_amount = 0.390000000;
const float p_o7196_repeat = 1.000000000;
const float p_o7196_rotate = 90.000000000;
const float p_o7196_gradient_0_pos = 0.000000000;
const vec4 p_o7196_gradient_0_col = vec4(0.000000000, 0.000000000, 0.000000000, 1.000000000);
const float p_o7196_gradient_1_pos = 0.548455000;
const vec4 p_o7196_gradient_1_col = vec4(0.417968988, 0.417968988, 0.417968988, 1.000000000);
const float p_o7196_gradient_2_pos = 1.000000000;
const vec4 p_o7196_gradient_2_col = vec4(1.000000000, 1.000000000, 1.000000000, 1.000000000);
vec4 o7196_gradient_gradient_fct(float x) {
  if (x < p_o7196_gradient_0_pos) {
    return p_o7196_gradient_0_col;
  } else if (x < p_o7196_gradient_1_pos) {
    return mix(mix(p_o7196_gradient_1_col, p_o7196_gradient_2_col, (x-p_o7196_gradient_1_pos)/(p_o7196_gradient_2_pos-p_o7196_gradient_1_pos)), mix(p_o7196_gradient_0_col, p_o7196_gradient_1_col, (x-p_o7196_gradient_0_pos)/(p_o7196_gradient_1_pos-p_o7196_gradient_0_pos)), 1.0-0.5*(x-p_o7196_gradient_0_pos)/(p_o7196_gradient_1_pos-p_o7196_gradient_0_pos));
  } else if (x < p_o7196_gradient_2_pos) {
    return mix(mix(p_o7196_gradient_0_col, p_o7196_gradient_1_col, (x-p_o7196_gradient_0_pos)/(p_o7196_gradient_1_pos-p_o7196_gradient_0_pos)), mix(p_o7196_gradient_1_col, p_o7196_gradient_2_col, (x-p_o7196_gradient_1_pos)/(p_o7196_gradient_2_pos-p_o7196_gradient_1_pos)), 0.5+0.5*(x-p_o7196_gradient_1_pos)/(p_o7196_gradient_2_pos-p_o7196_gradient_1_pos));
  }
  return p_o7196_gradient_2_col;
}
const float p_o7236_in_min = 0.000000000;
const float p_o7236_in_max = 0.680000000;
const float p_o7236_out_min = 0.000000000;
const float p_o7236_out_max = 1.000000000;
const float p_o7260_amount = 1.000000000;
const float p_o7235_amount = 1.000000000;
const float p_o7243_amount = 0.000000000;
const float p_o7243_eps = 0.110000000;
const float p_o7258_translate_x = 0.000000000;
const float p_o7258_translate_y = 0.500000000;
const float p_o7247_translate_x = 0.000000000;
const float p_o7247_translate_y = -0.200000000;
const float p_o7247_rotate = 0.000000000;
const float p_o7247_scale_x = 1.000000000;
const float p_o7247_scale_y = 1.000000000;
const float seed_o7242 = 0.000000000;
const float p_o7242_scale_x = 4.000000000;
const float p_o7242_scale_y = 4.000000000;
const float p_o7242_folds = 0.000000000;
const float p_o7242_iterations = 5.000000000;
const float p_o7242_persistence = 0.360000000;
const float p_o7242_offset = 0.000000000;
float o7243_input_d(vec2 uv, float _seed_variation_) {
float o7228_0_1_f = (elapsed_time);
float o7228_0_3_f = (elapsed_time);
float o7242_0_1_f = fbm_2d_value((fract(transform2(((uv)-vec2(p_o7258_translate_x, p_o7258_translate_y)), vec2(p_o7247_translate_x*(2.0*1.0-1.0), p_o7247_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7247_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7247_scale_x*(2.0*1.0-1.0), p_o7247_scale_y*(2.0*1.0-1.0))))), vec2(p_o7242_scale_x, p_o7242_scale_y), int(p_o7242_folds), int(p_o7242_iterations), p_o7242_persistence, o7228_0_3_f, (seed_o7242+fract(_seed_variation_)));
vec4 o7247_0_1_rgba = vec4(vec3(o7242_0_1_f), 1.0);
vec4 o7258_0_1_rgba = o7247_0_1_rgba;
return (dot((o7258_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7243_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7243_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7243_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7243_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7243_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7231_amount = 0.310000000;
const float p_o7231_eps = 0.050000000;
const float p_o7185_translate_x = -0.010000000;
const float p_o7185_translate_y = -0.220000000;
const float p_o7185_rotate = 0.000000000;
const float p_o7185_scale_x = 1.000000000;
const float p_o7185_scale_y = 1.000000000;
float o7231_input_d(vec2 uv, float _seed_variation_) {
float o7228_0_1_f = (elapsed_time);
vec4 o7237_0 = textureLod(texture_1, fract(transform2((uv), vec2(p_o7185_translate_x*(2.0*o7228_0_1_f-1.0), p_o7185_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7185_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7185_scale_x*(2.0*1.0-1.0), p_o7185_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o7185_0_1_rgba = o7237_0;
return (dot((o7185_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7231_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7231_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7231_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7231_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7231_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7230_translate_x = 0.000000000;
const float p_o7230_translate_y = -0.120000000;
const float p_o7230_rotate = 0.000000000;
const float p_o7230_scale_x = 1.000000000;
const float p_o7230_scale_y = 1.000000000;
const float p_o7195_amount = 1.000000000;
const float p_o7248_amount = 0.135000000;
const float p_o7248_eps = 0.055000000;
const float p_o7259_translate_x = 0.570000000;
const float p_o7259_translate_y = 0.250000000;
const float p_o7257_translate_x = 0.010000000;
const float p_o7257_translate_y = -0.300000000;
const float p_o7257_rotate = 0.000000000;
const float p_o7257_scale_x = 1.000000000;
const float p_o7257_scale_y = 1.000000000;
float o7248_input_d(vec2 uv, float _seed_variation_) {
float o7228_0_1_f = (elapsed_time);
float o7228_0_3_f = (elapsed_time);
float o7242_0_1_f = fbm_2d_value((fract(transform2(((uv)-vec2(p_o7259_translate_x, p_o7259_translate_y)), vec2(p_o7257_translate_x*(2.0*o7228_0_1_f-1.0), p_o7257_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7257_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7257_scale_x*(2.0*1.0-1.0), p_o7257_scale_y*(2.0*1.0-1.0))))), vec2(p_o7242_scale_x, p_o7242_scale_y), int(p_o7242_folds), int(p_o7242_iterations), p_o7242_persistence, o7228_0_3_f, (seed_o7242+fract(_seed_variation_)));
vec4 o7257_0_1_rgba = vec4(vec3(o7242_0_1_f), 1.0);
vec4 o7259_0_1_rgba = o7257_0_1_rgba;
return (dot((o7259_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7248_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7248_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7248_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7248_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7248_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7186_amount = 0.175000000;
const float p_o7186_eps = 0.200000000;
float o7186_input_d(vec2 uv, float _seed_variation_) {
vec2 o7231_0_slope = o7231_slope((uv), p_o7231_eps, _seed_variation_);
vec2 o7231_0_warp = o7231_0_slope*(1.0-o7231_input_d((uv), _seed_variation_));float o7228_0_1_f = (elapsed_time);
vec4 o7239_0 = textureLod(texture_2, fract(transform2(((uv)+p_o7231_amount*o7231_0_warp), vec2(p_o7230_translate_x*(2.0*1.0-1.0), p_o7230_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7230_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7230_scale_x*(2.0*1.0-1.0), p_o7230_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o7230_0_1_rgba = o7239_0;
vec4 o7231_0_1_rgba = o7230_0_1_rgba;
return (dot((o7231_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7186_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7186_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7186_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7186_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7186_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7253_amount = 0.150000000;
const float p_o7253_eps = 0.065000000;
const float p_o7252_translate_x = -0.010000000;
const float p_o7252_translate_y = -0.240000000;
const float p_o7252_rotate = 0.000000000;
const float p_o7252_scale_x = 1.000000000;
const float p_o7252_scale_y = 1.000000000;
float o7253_input_d(vec2 uv, float _seed_variation_) {
float o7228_0_1_f = (elapsed_time);
float o7228_0_3_f = (elapsed_time);
float o7242_0_1_f = fbm_2d_value((fract(transform2((uv), vec2(p_o7252_translate_x*(2.0*o7228_0_1_f-1.0), p_o7252_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7252_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7252_scale_x*(2.0*1.0-1.0), p_o7252_scale_y*(2.0*1.0-1.0))))), vec2(p_o7242_scale_x, p_o7242_scale_y), int(p_o7242_folds), int(p_o7242_iterations), p_o7242_persistence, o7228_0_3_f, (seed_o7242+fract(_seed_variation_)));
vec4 o7252_0_1_rgba = vec4(vec3(o7242_0_1_f), 1.0);
return (dot((o7252_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7253_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7253_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7253_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7253_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7253_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7191_amount = 0.095000000;
const float p_o7191_eps = 0.110000000;
float o7191_input_d(vec2 uv, float _seed_variation_) {
float o7228_0_1_f = (elapsed_time);
vec4 o7237_0 = textureLod(texture_1, fract(transform2((uv), vec2(p_o7185_translate_x*(2.0*o7228_0_1_f-1.0), p_o7185_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7185_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7185_scale_x*(2.0*1.0-1.0), p_o7185_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o7185_0_1_rgba = o7237_0;
return (dot((o7185_0_1_rgba).rgb, vec3(1.0))/3.0);
}
vec2 o7191_slope(vec2 uv, float epsilon, float _seed_variation_) {
	return vec2(o7191_input_d(fract(uv+vec2(epsilon, 0.0)), _seed_variation_)-o7191_input_d(fract(uv-vec2(epsilon, 0.0)), _seed_variation_), o7191_input_d(fract(uv+vec2(0.0, epsilon)), _seed_variation_)-o7191_input_d(fract(uv-vec2(0.0, epsilon)), _seed_variation_));
}const float p_o7190_translate_x = 0.010000000;
const float p_o7190_translate_y = -0.160000000;
const float p_o7190_rotate = 0.000000000;
const float p_o7190_scale_x = 1.000000000;
const float p_o7190_scale_y = 1.000000000;
const float seed_o7184 = 0.000000000;
const float p_o7184_scale_x = 8.000000000;
const float p_o7184_scale_y = 8.000000000;
const float p_o7184_folds = 0.000000000;
const float p_o7184_iterations = 4.000000000;
const float p_o7184_persistence = 0.640000000;
const float p_o7184_offset = 0.000000000;
const float p_o7229_default_in1 = 0.000000000;
const float p_o7229_default_in2 = 1.000000000;
void fragment() {
	float _seed_variation_ = variation;
	vec2 uv = fract(UV);
float o7196_0_r = 0.5+(cos(p_o7196_rotate*0.01745329251)*((uv).x-0.5)+sin(p_o7196_rotate*0.01745329251)*((uv).y-0.5))/(cos(abs(mod(p_o7196_rotate, 90.0)-45.0)*0.01745329251)*1.41421356237);vec4 o7196_0_1_rgba = o7196_gradient_gradient_fct(fract(o7196_0_r*p_o7196_repeat));
vec2 o7243_0_slope = o7243_slope((uv), p_o7243_eps, _seed_variation_);
vec2 o7243_0_warp = o7243_0_slope*(1.0-o7243_input_d((uv), _seed_variation_));vec2 o7231_0_slope = o7231_slope(((uv)+p_o7243_amount*o7243_0_warp), p_o7231_eps, _seed_variation_);
vec2 o7231_0_warp = o7231_0_slope*(1.0-o7231_input_d(((uv)+p_o7243_amount*o7243_0_warp), _seed_variation_));float o7228_0_1_f = (elapsed_time);
vec4 o7239_0 = textureLod(texture_2, fract(transform2((((uv)+p_o7243_amount*o7243_0_warp)+p_o7231_amount*o7231_0_warp), vec2(p_o7230_translate_x*(2.0*1.0-1.0), p_o7230_translate_y*(2.0*o7228_0_1_f-1.0)), p_o7230_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7230_scale_x*(2.0*1.0-1.0), p_o7230_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o7230_0_1_rgba = o7239_0;
vec4 o7231_0_1_rgba = o7230_0_1_rgba;
vec4 o7243_0_1_rgba = o7231_0_1_rgba;
vec2 o7248_0_slope = o7248_slope((uv), p_o7248_eps, _seed_variation_);
vec2 o7248_0_warp = o7248_0_slope*(1.0-o7248_input_d((uv), _seed_variation_));vec2 o7186_0_slope = o7186_slope(((uv)+p_o7248_amount*o7248_0_warp), p_o7186_eps, _seed_variation_);
vec2 o7186_0_warp = o7186_0_slope*(1.0-o7186_input_d(((uv)+p_o7248_amount*o7248_0_warp), _seed_variation_));float o7228_0_3_f = (elapsed_time);
vec4 o7237_0 = textureLod(texture_1, fract(transform2((((uv)+p_o7248_amount*o7248_0_warp)+p_o7186_amount*o7186_0_warp), vec2(p_o7185_translate_x*(2.0*o7228_0_3_f-1.0), p_o7185_translate_y*(2.0*o7228_0_3_f-1.0)), p_o7185_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7185_scale_x*(2.0*1.0-1.0), p_o7185_scale_y*(2.0*1.0-1.0)))), 0.0);
vec4 o7185_0_1_rgba = o7237_0;
vec4 o7186_0_1_rgba = o7185_0_1_rgba;
vec4 o7248_0_1_rgba = o7186_0_1_rgba;
vec2 o7253_0_slope = o7253_slope((uv), p_o7253_eps, _seed_variation_);
vec2 o7253_0_warp = o7253_0_slope*(1.0-o7253_input_d((uv), _seed_variation_));vec2 o7191_0_slope = o7191_slope(((uv)+p_o7253_amount*o7253_0_warp), p_o7191_eps, _seed_variation_);
vec2 o7191_0_warp = o7191_0_slope;float o7228_0_5_f = (elapsed_time);
float o7228_0_7_f = (elapsed_time);
float o7229_0_clamp_false = o7228_0_7_f*p_o7229_default_in2;
float o7229_0_clamp_true = clamp(o7229_0_clamp_false, 0.0, 1.0);
float o7229_0_2_f = o7229_0_clamp_false;
float o7184_0_1_f = fbm_2d_value((fract(transform2((((uv)+p_o7253_amount*o7253_0_warp)+p_o7191_amount*o7191_0_warp), vec2(p_o7190_translate_x*(2.0*o7228_0_5_f-1.0), p_o7190_translate_y*(2.0*o7228_0_5_f-1.0)), p_o7190_rotate*0.01745329251*(2.0*1.0-1.0), vec2(p_o7190_scale_x*(2.0*1.0-1.0), p_o7190_scale_y*(2.0*1.0-1.0))))), vec2(p_o7184_scale_x, p_o7184_scale_y), int(p_o7184_folds), int(p_o7184_iterations), p_o7184_persistence, o7229_0_2_f, (seed_o7184+fract(_seed_variation_)));
vec4 o7190_0_1_rgba = vec4(vec3(o7184_0_1_f), 1.0);
vec4 o7191_0_1_rgba = o7190_0_1_rgba;
vec4 o7253_0_1_rgba = o7191_0_1_rgba;
vec4 o7195_0_s1 = o7248_0_1_rgba;
vec4 o7195_0_s2 = o7253_0_1_rgba;
float o7195_0_a = p_o7195_amount*1.0;
vec4 o7195_0_2_rgba = vec4(blend_overlay((uv), o7195_0_s1.rgb, o7195_0_s2.rgb, o7195_0_a*o7195_0_s1.a), min(1.0, o7195_0_s2.a+o7195_0_a*o7195_0_s1.a));
vec4 o7235_0_s1 = o7243_0_1_rgba;
vec4 o7235_0_s2 = o7195_0_2_rgba;
float o7235_0_a = p_o7235_amount*1.0;
vec4 o7235_0_2_rgba = vec4(blend_overlay((uv), o7235_0_s1.rgb, o7235_0_s2.rgb, o7235_0_a*o7235_0_s1.a), min(1.0, o7235_0_s2.a+o7235_0_a*o7235_0_s1.a));
vec4 o7260_0_s1 = o7196_0_1_rgba;
vec4 o7260_0_s2 = o7235_0_2_rgba;
float o7260_0_a = p_o7260_amount*1.0;
vec4 o7260_0_2_rgba = vec4(blend_multiply((uv), o7260_0_s1.rgb, o7260_0_s2.rgb, o7260_0_a*o7260_0_s1.a), min(1.0, o7260_0_s2.a+o7260_0_a*o7260_0_s1.a));
vec4 o7236_0_1_rgba = vec4(vec3(p_o7236_out_min)+(o7260_0_2_rgba.rgb-vec3(p_o7236_in_min))*vec3((p_o7236_out_max-(p_o7236_out_min))/(p_o7236_in_max-(p_o7236_in_min))), o7260_0_2_rgba.a);
vec4 o7263_0_s1 = o7196_0_1_rgba;
vec4 o7263_0_s2 = o7236_0_1_rgba;
float o7263_0_a = p_o7263_amount*1.0;
vec4 o7263_0_2_rgba = vec4(blend_lighten((uv), o7263_0_s1.rgb, o7263_0_s2.rgb, o7263_0_a*o7263_0_s1.a), min(1.0, o7263_0_s2.a+o7263_0_a*o7263_0_s1.a));
vec4 o7210_0_1_rgba = o7210_gradient_gradient_fct((dot((o7263_0_2_rgba).rgb, vec3(1.0))/3.0));

	vec4 color_tex = o7210_0_1_rgba;
	color_tex = mix(pow((color_tex + vec4(0.055)) * (1.0 / (1.0 + 0.055)),vec4(2.4)),color_tex * (1.0 / 12.92),lessThan(color_tex,vec4(0.04045)));
	ALBEDO = color_tex.rgb;
	ALPHA = color_tex.a;

}



