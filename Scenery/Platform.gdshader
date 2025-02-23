shader_type canvas_item;

uniform vec3 basecolor : source_color = vec3(0.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR.rgb = basecolor;
	COLOR.a = 1.0;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
