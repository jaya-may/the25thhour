extends RigidBody2D

#mostly copied from fragment

var homeBase: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var hp = 75
enum ENEMY_STATE {IDLE, APPROACH, WINDUP, DODGE, ATTACK, COUNTER, WAIT}
var state = ENEMY_STATE.IDLE
var player_detected = false

@export var speed: float = 200.0  # Movement speed
@export var attack_radius: float = 120.0  # Distance to stop and attack

var player = null  
var attacking = false 

#audio
@onready var detection_area = $Detect  
@onready var hitboxL = $HitboxL  
@onready var hitboxR = $HitboxR  


@onready var audio_player = $AudioStreamPlayer2D 
@onready var swingPlayer = $Swing 

var punishment = [
	preload("res://sounds/prism/punishment.wav"),
	preload("res://sounds/prism/dust.wav")
	]
var swingSound = preload("res://sounds/prism/swing.wav")

#new
@onready var sprite = $PrismSprite  

var facing_angle = -1

var hitboxesActive = false


#consts

var WIND_UP_TIME = .6

# TIMERSSSS
var counterTimer = 0
var counterPhase = 0
var windUpTimer = 0
var whereToDash


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(homeBase == Vector2.ZERO):
		homeBase = global_position
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)



func _physics_process(delta: float) -> void:
	
	
	move_and_collide(velocity * delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#determine facing angle
	if(player):
		if ((global_position - player.global_position).x > 0):
			facing_angle=1
		else: 
			facing_angle=-1
	if(facing_angle == 1):
		sprite.scale.x = 1
	else:
		sprite.scale.x =-1
		
	
	
	#kil if die
	if(hp < 0):
		queue_free()
		
	if(hitboxesActive):
		print("FINNA KILL UR ASS")
		check_killzone(facing_angle)
		
	#do state transitions
	if(state == ENEMY_STATE.IDLE):
		#print("idle")
		var direction_to_home = (homeBase - global_position).normalized()
		velocity.x = (direction_to_home * speed/3).x  # Move towards home base
		
	elif (state == ENEMY_STATE.APPROACH):
		windUpTimer = 0
		if player!=null:
			#print("approach")
			var direction_to_player = (player.global_position - global_position).normalized()
			velocity.x = (direction_to_player * speed).x
			if(global_position.distance_to(player.global_position) < attack_radius):
				state = ENEMY_STATE.WINDUP
		else:
			state = ENEMY_STATE.IDLE
			
	elif (state == ENEMY_STATE.WINDUP):
		#print("windup")
		velocity.x = 0
		
		windUpTimer+=delta
		if(windUpTimer > WIND_UP_TIME):
			state = ENEMY_STATE.ATTACK
			swingPlayer.stream = swingSound
			swingPlayer.play()
			windUpTimer = 0
			hitboxesActive = true
		
	elif (state == ENEMY_STATE.COUNTER):
		print(counterPhase)
		counterTimer+=delta
		if(counterPhase==0):
			
			var direction_to_player = (player.global_position - global_position).normalized()
			velocity.x = (-direction_to_player*speed*3).x
			whereToDash = (direction_to_player).x
			if(counterTimer > 0.4):
				counterTimer = 0
				counterPhase = 1
		
		elif(counterPhase == 1):
			velocity.x = 0
			if(counterTimer>0.5):
				counterPhase=2
				counterTimer = 0
				hitboxesActive = true
		elif(counterPhase == 2):
			
			velocity.x = whereToDash*speed*5
			if(counterTimer > 0.5):
				hitboxesActive = false
				counterTimer=0
				counterPhase=0
				state=ENEMY_STATE.IDLE
			

		print("countering")
		
	elif (state == ENEMY_STATE.ATTACK):
		
		#hitboxesActive = true
		windUpTimer += delta
		if(windUpTimer > 0.2):
			state = ENEMY_STATE.WAIT
			windUpTimer=0
			hitboxesActive = false
		
	elif (state == ENEMY_STATE.WAIT):
		print("we waitin")
		
		hitboxesActive = false
		windUpTimer += delta
		if(windUpTimer > 1.2):
			state = ENEMY_STATE.APPROACH
			windUpTimer=0
		
	if(player_detected):
		if(state == ENEMY_STATE.IDLE):
			state = ENEMY_STATE.APPROACH	
	else:
		state = ENEMY_STATE.IDLE
	
func Slam(damage: float, playerpos: Vector2, facing_angle: int) -> void:
	hp += damage
	if(state == ENEMY_STATE.WINDUP):
		var probability : int = 4 # 1/10 chance
		if (randi() % probability) == (probability - 1):
			audio_player.stream = punishment[randi() % punishment.size()]   # Pick a random sound
			audio_player.play()
		state = ENEMY_STATE.COUNTER
		counterPhase = 0
		

func Hit(damage: float, playerpos: Vector2, facing_angle: int) -> void:
	if(state == ENEMY_STATE.WINDUP):
		var probability : int = 4 # 1/10 chance
		if (randi() % probability) == (probability - 1):
			audio_player.stream = punishment[randi() % punishment.size()]   # Pick a random sound
			audio_player.play()
		state = ENEMY_STATE.COUNTER
		counterPhase = 0
		
	hp += damage
	
	
func check_killzone(facing: int):
	#print("we got this far")
	if facing == 1:
		for body in hitboxL.get_overlapping_bodies():
			if body.is_in_group("Player") and body.has_method("modifyHp"):
				body.modifyHp(-25)  # Apply damage only at this moment
				body.velocity.x = velocity.x * 2
				hitboxesActive = false
	else:
		for body in hitboxR.get_overlapping_bodies():
			if body.is_in_group("Player") and body.has_method("modifyHp"):
				body.modifyHp(-25)  # Apply damage only at this moment
				body.velocity.x = velocity.x * 2
				hitboxesActive = false

func _on_player_entered(body):
	print("Detected:", body.name)
	if body.is_in_group("Player"):  # Ensure player is detected
		player = body
		player_detected = true

func _on_player_exited(body):
	if body == player:
		player = null
		player_detected = false

func get_distance_to_player(player):
	return "unimplemented"
	
