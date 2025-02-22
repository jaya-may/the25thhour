extends Area2D

@export var damage: float = -10.0  # Negative means it reduces HP
var timer = 1.0
var killmode = false

func _process(delta: float) -> void:
	timer -= delta
	
	if timer <= 0.5 and not killmode:
		killmode = true
		_check_for_players()  # ONLY check for players now

	if timer <= 0:
		queue_free()

func _check_for_players():
	for body in get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("modifyHp"):
			body.modifyHp(damage)  # Apply damage only at this moment
