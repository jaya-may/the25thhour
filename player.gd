extends CharacterBody2D

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
const DASH_SPEED = 1000

#working vars
var direction:Vector2 = Vector2.ZERO
var jump_pressed = false
var jump_held = false
var air_stall = false
var run = false

#dash
var can_dash = true
var dash_this_frame = false

#some more other shit
var prior_vel = 0
var counter = 0
var jumpBuffer = 0 


func _process(delta: float):
	# --- GET INPUT ---

	direction = Vector2(Input.get_axis("ui_left", "ui_right"), 0)
	if Input.is_action_just_pressed("ui_accept"):
		jump_pressed = true
	if Input.is_action_pressed("ui_accept"):
		jump_held=true
	else:
		jump_held = false
	if Input.is_key_pressed(KEY_SHIFT):
		$Timer.start()
		dash_this_frame = true
		#run=true	
	
		

func _physics_process(delta: float) -> void:
	#print("Velocity: ", velocity)
	#print("Prior vel: ", prior_vel)
	#print(counter)
	jumpBuffer -= delta  # Decrease jump buffer over time

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
	if dash_this_frame && can_dash:
		velocity.x += DASH_SPEED * sign(velocity.x)
		can_dash=false
	dash_this_frame = false
	
	if direction.x!=0:
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
		if counter < TIME_TO_BHOP:
			print("hi")
			velocity.x = prior_vel
		counter  = 0
			
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
		
	
	
	move_and_slide()


func _on_timer_timeout() -> void:
	can_dash=true
