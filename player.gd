extends CharacterBody2D

enum CHAR_STATE {NORMAL,SLAM,DASH}
var cur_state = CHAR_STATE.NORMAL

var hp = 100

#melee
var melee_damage: float = -15.0  
var melee_range: float = 100.0  
var facing_angle = 1

#consts
const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const AIR_DECEL = 400
const AIR_ACEL = 500
const GROUND_DECEL = 1500
const GROUND_ACEL = 200
const AIR_SPEED_CAP = 800
const GROUND_SPEED_CAP = 120
const TIME_TO_BHOP = 0.02
const JUMP_BUFFER_TIME = 0.1  
const RUN_SPEED = 100
const JUMP_BOOST_DIV = 15
const DASH_SPEED = 100
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
		#run=true	
	if Input.is_action_just_pressed("Slam") && not is_on_floor():
		slam_this_frame = true
		
	if Input.is_action_just_pressed("Melee") and cur_state == CHAR_STATE.NORMAL:
		melee_attack()

func _physics_process(delta: float) -> void:
	#print("Velocity: ", velocity)
	#print("Prior vel: ", prior_vel)
	#print(counter)
	jumpBuffer -= delta  # Decrease jump buffer over time
	dashCounter+=delta
	justSlammedGround-=delta
	if(cur_state == CHAR_STATE.NORMAL):
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
				print("hi")
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
		# --- STATE CHANGE ---
		if(slam_this_frame):
			cur_state = CHAR_STATE.SLAM
			slam_this_frame = false
			slam_just_started=true
			
	elif (cur_state == CHAR_STATE.SLAM):
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
			justSlammedGround = .2
			cur_state = CHAR_STATE.NORMAL
		velocity.x = direction.x * SLAM_SIDEWAYS_SPEED 





	move_and_slide()

func modifyHp(hpChange: float)-> void:
	hp+=hpChange
	print("hp is now: ",hp)

func melee_attack():
	print("Player attacks!")

	# Create a hitbox Area2D for melee attack
	var attack_area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = Vector2(melee_range, 10)  # Small attack box
	attack_area.add_child(shape)

	# Enable monitoring
	attack_area.monitoring = true
	attack_area.collision_layer = 0  # Set to 0 so it doesn't interfere with physics
	attack_area.collision_mask = 1  # Adjust this to match enemy collision layer

	# Position the attack in front of the player
	attack_area.global_position = global_position + Vector2(melee_range * sign(facing_angle), 0)
	get_parent().add_child(attack_area)  # Add to the scene
	await get_tree().process_frame

	# Check for enemies and deal damage
	print("we finna detect")
	for body in attack_area.get_overlapping_bodies():
		print("Detected body:", body.name)
		if body.has_method("hit"):
			body.hit(melee_damage)
			print("Hit enemy:", body.name)

	attack_area.queue_free()  # Remove the hitbox after checking
