shader_type canvas_item;

uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
uniform vec3 color_outer : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 color_inner : source_color = vec3(1.0);

uniform float ramp_cut = 0.2;
uniform float ramp_blend = 0.01;
uniform float speed = 0.4;

uniform float band_cut = 0.2;
uniform float band_blend = 0.01;



void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float n = texture(noise, vec2(UV.x + TIME * speed, 0.0)).r;
	float n2 = texture(noise, vec2(UV.x - TIME * speed, 0.0)).r;
	n = smoothstep(ramp_cut, ramp_cut + ramp_blend, n);
	n2 = smoothstep(ramp_cut, ramp_cut + ramp_blend, n2);
	n *= n2;
	
	float gradient = UV.x;
	gradient *= 1.0-UV.x;
	gradient *= 2.0;
	
	gradient = smoothstep(band_cut,band_cut + band_blend,gradient);
	
	
	COLOR.rgb= mix(n*color_outer, color_inner, gradient);
	COLOR.a=clamp(n+gradient, 0.0,1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
