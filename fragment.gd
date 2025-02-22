extends RigidBody2D


enum ENEMY_STATE {IDLE,APPROACH,WINDUP,ATTACK}
var state  = ENEMY_STATE.IDLE
var player_detected = false

@export var speed: float = 100.0  # Movement speed
@export var attack_radius: float = 200.0  # Distance to stop and attack

var played_sound = 0

var player = null  
var attacking = false 

@onready var detection_area = $Area2D  
@onready var animator = $FragmentSprite/AnimationPlayer
var windup_timer = 2


# SOUNDS

@onready var audio_player = $AudioStreamPlayer2D 
var sounds = [
	preload("res://sounds/ashlatin.mp3"),
	preload("res://sounds/goodbye idiot.mp3"),
	preload("res://sounds/impure.mp3"),
	preload("res://sounds/pridefulsinner.mp3"),
	preload("res://sounds/purelatin.mp3")
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(state)
	if(state==ENEMY_STATE.IDLE):
		if(player_detected):
			if(played_sound % 5 == 0):
				audio_player.stream = sounds[randi() % sounds.size()]  # Pick a random sound
				audio_player.play()
				print("playingh sounds,.")
			
			played_sound+=1
			state=ENEMY_STATE.APPROACH
	#APPROACH IS HANDLED BY PHYSICS
		#print("coolin")
	if(state == ENEMY_STATE.WINDUP):
		#print("windin'")
		windup_timer-=delta
		if windup_timer < 0:
			if(global_position.distance_to(player.global_position) > attack_radius):
				windup_timer=120
				state = ENEMY_STATE.APPROACH
			#else:
			windup_timer = 2
			print("kills you.")
			state = ENEMY_STATE.ATTACK
	if(state==ENEMY_STATE.ATTACK):
		var laser = preload("res://laser.tscn").instantiate()
		get_parent().add_child(laser)  # Make sure the laser is added to the scene tree
		laser.global_position = player.global_position  # Spawn at enemy position
		print("laser spawned")
		state = ENEMY_STATE.IDLE
		
func _physics_process(delta: float) -> void:
	if(state==ENEMY_STATE.APPROACH):
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		var move_velocity = direction * speed
		move_and_collide(move_velocity * delta)
		if(distance < attack_radius):
			state = ENEMY_STATE.WINDUP
			windup_timer = 2

func _on_player_entered(body):
	print("Detected:", body.name)
	if body.is_in_group("Player"):  # Ensure player is detected
		player = body
		print("I CAN SEE YOU.")
		player_detected = true

func _on_player_exited(body):
	if body == player:
		player = null
		state = ENEMY_STATE.IDLE
		player_detected=false
