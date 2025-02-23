extends Node2D

var counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	counter+=delta
	if(counter > 3):
		get_tree().change_scene_to_file("res://mainscene.tscn")
