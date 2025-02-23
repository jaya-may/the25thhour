extends RigidBody2D



var homeBase: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var hp = 100
enum ENEMY_STATE {IDLE, APPROACH, WINDUP, ATTACK}
var state = ENEMY_STATE.IDLE
var player_detected = false

signal health_depleted

@export var speed: float = 100.0  # Movement speed
@export var attack_radius: float = 200.0  # Distance to stop and attack

var played_sound = 0
var rot_speed = 0

var player = null  
var attacking = false 

@onready var detection_area = $Area2D  
@onready var animator = $FragmentSprite/AnimationPlayer
var windup_timer = 2

# SOUNDS
@onready var audio_player = $AudioStreamPlayer2D 

var hitSounds = [
	preload("res://sounds/vhitsounds/vhit1.ogg"),
	preload("res://sounds/vhitsounds/vhit2.wav")
] 

var deathSound = preload("res://sounds/vhitsounds/vdeath.mp3")
var sounds = [
	preload("res://sounds/ashlatin.mp3"),
	preload("res://sounds/goodbye idiot.mp3"),
	preload("res://sounds/impure.mp3"),
	preload("res://sounds/pridefulsinner.mp3"),
	preload("res://sounds/purelatin.mp3")
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(homeBase == Vector2.ZERO):
		homeBase = global_position
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	rotation += rot_speed * delta
	rot_speed = move_toward(rot_speed, 0, delta * 20)

	if hp < 0:
		var new_audio_player = AudioStreamPlayer2D.new()
		new_audio_player.stream = deathSound
		new_audio_player.global_position = global_position
		get_parent().add_child(new_audio_player)
		new_audio_player.play()
		new_audio_player.finished.connect(func(): new_audio_player.queue_free())  # Cleanup after play
		health_depleted.emit()
		queue_free()

	if state == ENEMY_STATE.IDLE:
		if player_detected:
			if played_sound % 5 == 0:
				audio_player.stream = sounds[randi() % sounds.size()]  # Pick a random sound
				audio_player.play()
			played_sound += 1
			state = ENEMY_STATE.APPROACH
		else:
			# Return to home base when idle
			var direction_to_home = (homeBase - global_position).normalized()
			velocity = direction_to_home * speed/3  # Move towards home base
			

	if state == ENEMY_STATE.WINDUP:
		windup_timer -= delta
		if windup_timer < 0:
			if global_position.distance_to(player.global_position) > attack_radius:
				state = ENEMY_STATE.APPROACH
				windup_timer = 2
			else:
				state = ENEMY_STATE.ATTACK

	if state == ENEMY_STATE.ATTACK:
		var laser = preload("res://laser.tscn").instantiate()
		get_parent().add_child(laser)  # Make sure the laser is added to the scene tree
		laser.global_position = player.global_position  # Spawn at enemy position
		state = ENEMY_STATE.IDLE

func _physics_process(delta: float) -> void:
	if state == ENEMY_STATE.APPROACH:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)
		velocity = direction * speed
		if distance < attack_radius:
			velocity = Vector2.ZERO
			state = ENEMY_STATE.WINDUP
			windup_timer = 2
			
	#print(velocity)
	velocity.x = move_toward(velocity.x,0,delta*300)
	velocity.y = move_toward(velocity.y,0,delta*300)
	
	move_and_collide(velocity * delta)

func _on_player_entered(body):
	print("Detected:", body.name)
	if body.is_in_group("Player"):  # Ensure player is detected
		player = body
		player_detected = true

func _on_player_exited(body):
	if body == player:
		player = null
		state = ENEMY_STATE.IDLE
		player_detected = false


func Slam(damage: float, playerpos: Vector2, facing_angle: int) -> void:
	rot_speed += damage * facing_angle * -1
	
	if not audio_player.playing:  # Only play if nothing is currently playing
		audio_player.stream = hitSounds[randi() % hitSounds.size()]  # Pick a random sound
		audio_player.play()
	else:
		var new_audio_player = AudioStreamPlayer2D.new()
		new_audio_player.stream = hitSounds[randi() % hitSounds.size()]
		new_audio_player.global_position = global_position
		get_parent().add_child(new_audio_player)
		new_audio_player.play()
		new_audio_player.finished.connect(func(): new_audio_player.queue_free())  # Cleanup after play
	
	var direction_to_player = (global_position - playerpos).normalized()  # Get direction away from the player
	var pushback_distance = 200  # How far to move away from the player
	velocity.x += direction_to_player.x * pushback_distance/10  # Apply pushback velocity
	velocity.y = 50
	print("pushback now makes me:", velocity)
	hp += damage

func Hit(damage: float, playerpos: Vector2, facing_angle: int) -> void:
	rot_speed += damage / 2 * facing_angle * -1
	
	if not audio_player.playing:  # Only play if nothing is currently playing
		audio_player.stream = hitSounds[randi() % hitSounds.size()]  # Pick a random sound
		audio_player.play()
	else:
		var new_audio_player = AudioStreamPlayer2D.new()
		new_audio_player.stream = hitSounds[randi() % hitSounds.size()]
		new_audio_player.global_position = global_position
		get_parent().add_child(new_audio_player)
		new_audio_player.play()
		new_audio_player.finished.connect(func(): new_audio_player.queue_free())  # Cleanup after play
	
	var direction_to_player = (global_position - playerpos).normalized()  # Get direction away from the player
	var pushback_distance = 200  # How far to move away from the player
	velocity.x += direction_to_player.x * pushback_distance  # Apply pushback velocity
	print("pushback now makes me:", velocity)
	hp += damage
