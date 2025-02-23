extends Control
@onready var healthbar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	healthbar.value = 100;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_health_value(hp):
	healthbar.value = hp
	pass # Replace with function body.
