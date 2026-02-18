extends CharacterBody2D

@onready var _animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HUD/MainPanel/VBoxContainer/Health/ProgressBar
@onready var hud = $HUD
@export var inv: Inv

# Movement variables
var acceleration = 1500  # Acceleration rate for horizontal movement
var speed = 500
var jump_force = -1000
var gravity = 2000
var dash_speed = 750  # Initial dash speed
var dash_duration = .3  # Duration of the dash in seconds
var dash_cooldown = 0.5  # Cooldown time between dashes
var double_tap_time = 0.2  # Maximum time between taps to trigger a dash
var right = false
var left = false

# Friction variables
var ground_friction = 5000  # Strong friction to stop quickly on the ground
var air_friction = 200  # Weak friction to allow slow deceleration in the air

# Dash upgrade variables
var max_dashes_per_jump = 1  # Maximum dashes allowed per jump
var dashes_remaining = 1  # Current available dashes during a jump

# Dash tracking variables
var is_dashing = false
var dash_timer = 0.0
var dash_jump_force = -400
var dash_cooldown_timer = 0.0
var current_dash_speed = 0  # Speed during the dash, dynamically adjusted
var dash_direction = 0  # Direction of the dash (-1 for left, 1 for right)

# Double-tap tracking variables
var last_tap_time_left = 0.0  # Time of the last tap on `ui_left`
var last_tap_time_right = 0.0  # Time of the last tap on `ui_right`

# Add new wall jump variables
var max_wall_jumps = 1  # Maximum wall jumps allowed
var wall_jumps_remaining = 1  # Current available wall jumps
var wall_jump_force = -700  # Vertical force for wall jumps
var wall_jump_push = 500  # Horizontal force to push the player away from the wall

# Ammo variables
var max_ammo = 10  # Maximum ammo
var current_ammo = 10  # Current ammo
var ammo_recharge_time = 5  # Time in seconds to fully recharge ammo
var ammo_recharge_timer = 0.0  # Timer for recharging ammo

# Gun variables
var bullet_scene = preload("res://bullet.tscn")  # Path to the bullet scene
var croak_scene = preload("res://croak.tscn")  # Path to the bullet scene

var shoot_cooldown = 0.5  # Time between shots
var shoot_timer = 0.2  # Cooldown timer
var current_waveform = "sine"  # Default waveform
var bullet_speed = 500
var bullet_damage = 20
var reverb = [1,1] #number of reflections, #damage decay
var delay = [0,1]
var slider1 = 1
var pitch = 1

# Player variables
var can_shoot = true  # Initially false until the gun is picked up
var max_health = 1000
var current_health = 1000
var knockback_velocity := Vector2.ZERO
var knockback_decay := 0.9

func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	_animated_sprite.play("idle")

func apply_damage(amount: int, bullet_direction: Vector2, knockback_force: float):
	print("Taking Damage")
	current_health = clamp(current_health - amount, 0, max_health)
	print(current_health)
	health_bar.value = current_health
	var knockback = bullet_direction.normalized() * knockback_force
	knockback_velocity -= knockback
	if current_health <= 0:
		queue_free()
		
func _physics_process(delta):
	if velocity.x > 0.1:
		if is_on_floor():
			_animated_sprite.play("run_right")
		else:
			_animated_sprite.play("jump_right")
		right = true
		left = false
	elif velocity.x < -0.1:
		if is_on_floor():
			_animated_sprite.play("run_left")
		else:
			_animated_sprite.play("jump_left")
		right = false
		left = true
	else:
		_animated_sprite.play("idle")
		right = false
		left = false
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Reset dashes and wall jumps when the player lands
	if is_on_floor():
		reset_dashes()
		reset_wall_jumps()

	# Dash cooldown timer
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Handle movement, dashing, and wall jumping
	handle_movement(delta)

	# Update dash timer and decelerate if dashing
	if is_dashing:
		dash_timer -= delta
		decay_dash_momentum(delta)  # Gradually reduce momentum
		if dash_timer <= 0:
			cancel_dash()

	# Apply movement and check for collisions
	move_and_slide()

	# Apply friction if not dashing
	if not is_dashing:
		apply_friction(delta)

	# Check for horizontal collisions during dashing
	if is_dashing:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision and abs(collision.get_normal().x) > 0.7:  # Significant horizontal collision
				cancel_dash()
				break  # No need to check further collisions
	# Recharge ammo over time
	if current_ammo < max_ammo:
		ammo_recharge_timer += delta
		if ammo_recharge_timer >= ammo_recharge_time:
			current_ammo = max_ammo
			ammo_recharge_timer = 0.0
	# Handle shooting
	if Input.is_action_just_pressed("ui_shoot") and shoot_timer <= 0 and current_ammo > 0 and can_shoot:
		#shoot_bullet()
		shoot_timer = shoot_cooldown		
		if hud.use_item() == "shoot":
			shoot_bullet()
		else:
			var croak = croak_scene.instantiate()
			croak.position = global_position
			var mouse_position = get_global_mouse_position()
			if (mouse_position - global_position).x > 0:
				croak.scale = Vector2(.5,.5)
			else:
				croak.scale = Vector2(-.5,.5)
			get_parent().add_child(croak)
		#current_ammo -= 1

	# Decrease shoot cooldown
	if shoot_timer > 0:
		shoot_timer -= delta
	# Apply knockback
	velocity += knockback_velocity
	knockback_velocity *= knockback_decay

func handle_movement(delta):
	var input_direction = 0  # -1 for left, 1 for right, 0 for idle
	if Input.is_action_pressed("ui_left"):
		input_direction = -1
	elif Input.is_action_pressed("ui_right"):
		input_direction = 1

	if is_dashing:
		# Maintain dash momentum (adjusted by decay)
		velocity.x = dash_direction * current_dash_speed

		# Cancel momentum if the player taps the opposite direction
		if input_direction != 0 and input_direction != dash_direction:
			cancel_dash()
	else:
		# Apply acceleration to horizontal movement
		if input_direction != 0:
			var target_speed = input_direction * float(speed)
			velocity.x = lerp(float(velocity.x), target_speed, float(acceleration * delta) / float(speed))

		# Handle double-tap to trigger dash, only if dashes are available
		if dashes_remaining > 0:
			if Input.is_action_just_pressed("ui_left"):
				check_double_tap("ui_left")
			elif Input.is_action_just_pressed("ui_right"):
				check_double_tap("ui_right")

	# Jumping
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = jump_force
		elif is_on_wall() and wall_jumps_remaining > 0:
			perform_wall_jump()

func perform_wall_jump():
	# Wall jump logic
	var wall_direction = -1 if is_on_wall() and velocity.x > 0 else 1  # Determine the wall side
	velocity.y = wall_jump_force
	velocity.x = wall_direction * wall_jump_push
	wall_jumps_remaining -= 1
	reset_dashes()

func reset_wall_jumps():
	# Reset wall jumps when the player lands
	wall_jumps_remaining = max_wall_jumps

func decay_dash_momentum(delta):
	# Apply ground or air friction to gradually reduce dash momentum
	if is_on_floor():
		# Decelerate quickly on the ground
		if velocity.x > 0:
			velocity.x = max(velocity.x - ground_friction * delta, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + ground_friction * delta, 0)
	else:
		# Decelerate slowly in the air
		if velocity.x > 0:
			velocity.x = max(velocity.x - air_friction * delta, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + air_friction * delta, 0)

func apply_friction(delta):
	# Apply ground friction if on the floor and not moving horizontally
	if is_on_floor() and not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		if velocity.x > 0:
			velocity.x = max(velocity.x - ground_friction * delta, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + ground_friction * delta, 0)
	# Apply air friction when in the air
	elif not is_on_floor():
		if velocity.x > 0:
			velocity.x = max(velocity.x - air_friction * delta, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + air_friction * delta, 0)

func cancel_dash():
	# Immediately end the dash state
	is_dashing = false
	current_dash_speed = 0  # Reset dash speed

func check_double_tap(action):
	var current_time = Time.get_ticks_msec() / 1000.0  # Current time in seconds
	if action == "ui_left":
		if current_time - last_tap_time_left <= double_tap_time and dash_cooldown_timer <= 0:
			perform_dash(-1)  # Dash left
		last_tap_time_left = current_time
	elif action == "ui_right":
		if current_time - last_tap_time_right <= double_tap_time and dash_cooldown_timer <= 0:
			perform_dash(1)  # Dash right
		last_tap_time_right = current_time

func perform_dash(direction):
	is_dashing = true
	dash_timer = dash_duration  # Initialize the dash timer
	dash_cooldown_timer = dash_cooldown
	current_dash_speed = dash_speed
	dash_direction = direction  # Set the dash direction
	velocity.x = dash_direction * current_dash_speed
	if not is_on_floor():
		velocity.y = dash_jump_force

	# Reduce the remaining dashes
	dashes_remaining -= 1

func reset_dashes():
	# Reset the number of dashes when landing
	dashes_remaining = max_dashes_per_jump

func shoot_bullet():
	# Spawn and configure the bullet
	print("SHOT FIRED")
	var bullet = bullet_scene.instantiate()
	var stick_direction = Vector2(
		Input.get_action_strength("ui_right_stick_right") - Input.get_action_strength("ui_right_stick_left"),
		Input.get_action_strength("ui_right_stick_down") - Input.get_action_strength("ui_right_stick_up")
	)
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position-position).normalized()
	bullet.global_position = global_position + 20*direction
	bullet.set_direction(direction)

	# Pass modular configuration to the bullet
	#if reverb[0] > 0 and delay[0] > 0:
	#	audio_bus = "ReverbDelay"
	#elif reverb[0] > 0:
	#	audio_bus = "Reverb"
	#elif delay[0] > 0:
	#	audio_bus = "Delay"
	#else:
	#	audio_bus = "Master"
	bullet.configure_bullet({
		"damage_group":"enemy",
		"knockback":1000,
		"speed": bullet_speed,
		"damage": bullet_damage,
		"init_direction": direction,
		"waveform": current_waveform,
		"delay": delay,
		"reverb": reverb,
		"slider1": slider1,
		"pitch": pitch
	})

	get_parent().add_child(bullet)
