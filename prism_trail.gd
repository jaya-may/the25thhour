extends Node2D 

@export var fade_time: float = 0.5 
var elapsed_time: float = 0.0  

func _process(delta):
	print("hi")
	elapsed_time += delta
	var alpha = 1.0 - (elapsed_time / fade_time)
	
	if alpha <= 0:
		queue_free()
		
	
	modulate.a = alpha 
