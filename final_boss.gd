extends Node2D

@export var max_prisms: int = 2
@export var bullets_per_shot: int = 3
@export var time_between_shots: float = 2.0
@export var prisms_needed_to_phase: int = 2

@onready var spawn_point_1 = $Spawn1
@onready var spawn_point_2 = $Spawn2

var prisms_killed = 0
var current_phase = 1
var active_prisms = []

var counter = 0

var prism_scene = preload("res://prism.tscn")  # Ensure correct path to prism scene
var virtue_scene = preload("res://fragment.tscn")  # Ensure correct path to prism scene

@onready var shoot_timer = $ShootTimer

func _ready():
	print("Boss global position:", global_position)
	# Initialize prism scene here to avoid reloading it each time

func _process(delta: float) -> void:
	if(current_phase==1):
		var v1 = virtue_scene.instantiate()
		var v2 = virtue_scene.instantiate()
		add_child(v1)  
		add_child(v2)   
		v1.global_position = spawn_point_1.global_position  
		v2.global_position = spawn_point_2.global_position  
		current_phase = 2
	elif(current_phase==2):
		if(count_prisms_in_scene()==0):
			#current_phase=3
			counter+=delta
			if(counter > 2):
				current_phase = 3
				counter = 0
	elif(current_phase==3):
		var prism1 = prism_scene.instantiate()
		var prism2 = prism_scene.instantiate()
		add_child(prism1)  
		add_child(prism2)   
		prism1.global_position = spawn_point_1.global_position  
		prism2.global_position = spawn_point_2.global_position 
		current_phase=4
	elif(current_phase == 4):
		if(count_prisms_in_scene()==0):
			#current_phase=3
			counter+=delta
			if(counter > 2):
				current_phase = 5
				counter = 0
	elif(current_phase==5):
		var v1 = virtue_scene.instantiate()
		var prism1 = prism_scene.instantiate()
		var prism2 = prism_scene.instantiate()
		add_child(prism1)  
		add_child(prism2)   
		add_child(v1)   

		prism1.global_position = spawn_point_1.global_position  
		prism2.global_position = spawn_point_2.global_position 
		v1.global_position = global_position 

		current_phase=6
	elif(current_phase == 6):
		if(count_prisms_in_scene()==0):
			#current_phase=3
			counter+=delta
			if(counter > 2):
				current_phase = 7
				counter = 0

func count_prisms_in_scene() -> int:
	var prisms_in_scene = get_tree().get_nodes_in_group("Enemy")
	var prism_count = 0

	for node in prisms_in_scene:
		prism_count+=1

	return prism_count
