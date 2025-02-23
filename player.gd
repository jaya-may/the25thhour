extends CharacterBody2D

@onready var hitboxL = $HitboxL  # Reference to the Hitbox Area2D
@onready var hitboxR = $HitboxR  # Reference to the Hitbox Area2D
@onready var hitboxSlam = $HitboxSlam

var hitSound = preload("res://sounds/playersounds/hurtsound.mp3")
@onready var audio_player = $AudioStreamPlayer2D 

var dashSound = preload("res://sounds/playersounds/dash.mp3")
@onready var dash_player = $Dashy 


var punch = preload("res://sounds/playersounds/punch.mp3")
var finisher = preload("res://sounds/playersounds/finisher.mp3")

@onready var punch_player = $Punch 
@onready var finisher_player = $Finisherf 


enum CHAR_STATE {NORMAL,SLAM,DASH,ATTACK}
var cur_state = CHAR_STATE.NORMAL

var hp = 100

#melee
var melee_damage: float = -15.0  
var melee_range: float = 100.0  
var facing_angle = 1

var current_melee_hit = 0 #tracks what part of da combo
var endlag = 0.0#how many seconds of endlag an attack gives
var buffered_attack = false #r u a combohead?
const MAX_COMBO = 4 
var melee_attack_this_frame = false # r we tryna melee

#consts
const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const AIR_DECEL = 400
const AIR_ACEL = 440
const GROUND_DECEL = 1900
const GROUND_ACEL = 300
const AIR_SPEED_CAP = 800
const GROUND_SPEED_CAP = 120
const TIME_TO_BHOP = 0.02
const JUMP_BUFFER_TIME = 0.1  
const RUN_SPEED = 100
const JUMP_BOOST_DIV = 15
const DASH_SPEED = 150
const DASH_COOLDOWN = .7

#working vars
var direction:Vector2 = Vector2.ZERO
var jump_pressed = false
var jump_held = false
var air_stall = false
var run = false


#dash
var can_dash = true
var dash_this_frame = false
var dashCounter = 0

#slam
const SLAM_DOWNWARDS_SPEED = 500
const SLAM_SIDEWAYS_SPEED = 100
const SLAM_STARTUP = .1
const SLAMSTORE_LENIENCY = 0.3
var slam_counter = 0
var slam_this_frame = false
var slam_just_started = false
var justSlammedGround = 0


#some more other shit
var prior_vel = 0
var prior_facing_angle = 1
var counter = 0
var jumpBuffer = 0 

func _ready():
	add_to_group("Player")

func _process(delta: float):
	#print("hp: ",hp)
	if(hp<0):
		queue_free()
		
	# --- GET INPUT ---

	direction = Vector2(Input.get_axis("Left", "Right"), 0)
	
	if Input.is_action_just_pressed("Jump"):
		jump_pressed = true
	if Input.is_action_pressed("Jump"):
		jump_held=true
	else:
		jump_held = false
	if Input.is_action_pressed("Dash") && dashCounter > DASH_COOLDOWN:
		dash_this_frame = true
		dashCounter = 0
		dash_player.stream = dashSound
		dash_player.play()

		#run=true	
	if Input.is_action_just_pressed("Slam") && not is_on_floor():
		slam_this_frame = true
		
	
	if Input.is_action_just_pressed("Melee"):
		melee_attack_this_frame=true
		#print("trying to melee")
		
	#function calls if needed
	update_melee_status(delta)
	

func _physics_process(delta: float) -> void:
	
	jumpBuffer -= delta  
	dashCounter+=delta
	justSlammedGround-=delta
			
	#determine which physics model to use rn
	if(cur_state == CHAR_STATE.NORMAL):	
		defaultPhysics(delta)
		
	
	elif(cur_state== CHAR_STATE.ATTACK):
		attackPhysics(delta)
		
	elif (cur_state == CHAR_STATE.SLAM):
		slamPhysics(delta)
		var overlap
		overlap = hitboxSlam.get_overlapping_areas()

		# Loop through each body and print its name (or do something else)
		for body in overlap:
			#print("Hitbox intersects with:", body.name)
			if body.get_parent().has_method("Hit"):
				body.get_parent().Slam(melee_damage/2,self.global_position,facing_angle)
				velocity.y = -450
				cur_state = CHAR_STATE.NORMAL
	
	elif (cur_state == CHAR_STATE.DASH):
		var a
	
	#manage state changes, slam is given priority
	if(slam_this_frame):
		cur_state = CHAR_STATE.SLAM
		slam_this_frame = false
		slam_just_started=true
		melee_attack_this_frame = false
		current_melee_hit = 0
		endlag = 0
		buffered_attack = false
		melee_attack_this_frame = false
	
	move_and_slide()

func defaultPhysics(delta: float) -> void:
	# --- GRAVITY AND SHIT ---
	if not is_on_floor():
		velocity.y += ProjectSettings.get("physics/2d/default_gravity") * delta
		prior_vel = velocity.x
	else:
		counter += delta
		if counter > TIME_TO_BHOP:
			prior_vel = 0
		#velocity.x = move_toward(velocity.x, 0, GROUND_DECEL * delta)


	# --- MOVEMENT ---
	#if direction.x != 0:
	if dash_this_frame && direction.x!=0:
		velocity.x += DASH_SPEED * sign(direction.x)
		if(justSlammedGround > 0):
			velocity.x += DASH_SPEED * 2 * sign(direction.x)
			justSlammedGround = 0
		dash_this_frame=false

	if direction.x!=0:
		if(direction.x<1): facing_angle=-1
		else: facing_angle=1
		if is_on_floor():
			var add = 0
			if run == true:
				add = RUN_SPEED
			velocity.x = direction.x * (GROUND_ACEL + add)
		else:
			if abs(velocity.x) > AIR_SPEED_CAP:
				#so we're over cap. will our next move put us under?
				if abs(velocity.x + direction.x) < AIR_SPEED_CAP:
					velocity.x += direction.x * AIR_ACEL * delta
				#if not, add nothing this frame. thus softcapping speed
			else:	
				#we are not over cap
				velocity.x += direction.x * AIR_ACEL * delta

	# --- DECEL ---
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, GROUND_DECEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, AIR_DECEL * delta)

	# --- JUMP LOGIC ---

	if jump_pressed:
		jumpBuffer = JUMP_BUFFER_TIME
		jump_pressed = false
		
	if jumpBuffer > 0 and is_on_floor():
		if counter < TIME_TO_BHOP && abs(velocity.x)>150 && facing_angle == prior_facing_angle:
			#print("hi")
			velocity.x = prior_vel
		counter  = 0
		prior_facing_angle = facing_angle
			
		velocity.y = JUMP_VELOCITY - abs(velocity.x)/15
		if direction.x != 0:
			velocity.x += velocity.x / JUMP_BOOST_DIV
		jumpBuffer = 0  # Reset jump buffer after jumping

	if jump_held && is_on_floor():
		air_stall = true
	if not jump_held:
		air_stall = false
	if air_stall && velocity.y < -1 && not is_on_floor():
		velocity.y -= 7
	

func attackPhysics(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get("physics/2d/default_gravity") * delta
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, GROUND_DECEL * delta)
	else:
		if(direction.x!=0):
			velocity.x = direction.x * SLAM_SIDEWAYS_SPEED /2
		velocity.x = move_toward(velocity.x, 0, AIR_DECEL * delta)

func slamPhysics(delta: float) -> void:
	if(slam_this_frame): slam_this_frame = false
	if(slam_just_started):
		velocity.y = (SLAM_DOWNWARDS_SPEED/5) * -1
		slam_counter+=delta
		if slam_counter > SLAM_STARTUP:
			slam_just_started=false
			slam_counter=0
	else:
		velocity.y = SLAM_DOWNWARDS_SPEED
	if is_on_floor():
		justSlammedGround = SLAMSTORE_LENIENCY
		cur_state = CHAR_STATE.NORMAL
	velocity.x = direction.x * SLAM_SIDEWAYS_SPEED 

func modifyHp(hpChange: float)-> void:
	hp+=hpChange
	print("hp is now: ",hp)
	audio_player.stream = hitSound
	audio_player.play()


func update_melee_status(delta: float)-> void:
	if melee_attack_this_frame:
		
		#print(endlag)
		if current_melee_hit == 0:
			melee_attack()
		elif(endlag > 0):
			if(current_melee_hit < MAX_COMBO):
				buffered_attack = true
				#print("buffered next hit")
		
			
		
			
			
	melee_attack_this_frame=false
	
	endlag-=delta
	if(endlag < 0):
		if(buffered_attack && current_melee_hit < MAX_COMBO):
			melee_attack()
			#print("used it")
			buffered_attack=false
	if(endlag<0 && cur_state == CHAR_STATE.ATTACK):
		endlag=0
		cur_state = CHAR_STATE.NORMAL
		current_melee_hit = 0
	
	
	

func melee_attack():
	var finisher = false
	
	cur_state = CHAR_STATE.ATTACK
	current_melee_hit+=1

	print(current_melee_hit)
	
	if(current_melee_hit<MAX_COMBO):
		punch_player.stream = punch
		punch_player.play()
		endlag = 0.23
		finisher = 1
	
	if(current_melee_hit == MAX_COMBO):
		finisher_player.stream = finisher
		finisher_player.play()
		endlag = 0.8
		finisher = 1.5
		

	var overlap
	if(facing_angle==1): overlap = hitboxR.get_overlapping_areas()
	else: overlap = hitboxL.get_overlapping_areas()

	# Loop through each body and print its name (or do something else)
	for body in overlap:
		print("Hitbox intersects with:", body.name)
		if body.get_parent().has_method("Hit"):
			body.get_parent().Hit(melee_damage * finisher,self.global_position,facing_angle)
			endlag+=0.1
			velocity.y = -200
		
		#print("This is an enemy!")
		#print("attacked")
	
