extends Camera2D
class_name CustomCamera2D

@export var TargetNode: Node2D = null

func _process(_delta: float) -> void:
	if TargetNode:
		var pos: Vector2 = Vector2(TargetNode.position.x, global_position.y)
		position = pos  # Correct way to set position in Godot 4
	
