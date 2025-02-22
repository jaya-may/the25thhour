extends Area2D

@export var damage: float = -10.0  # Negative means it reduces HP
var timer = 1
var killmode = false

func _ready():
	connect("body_entered", _on_body_entered)  # Connect signal

func _process(delta: float) -> void:
	timer-=delta
	if(timer<=.5):
		killmode=true

func _on_body_entered(body):
	if(killmode):
		if body.is_in_group("Player"):
			if body.has_method("modifyHp"): 
				body.modifyHp(damage)  
