extends Area2D

# Bullet properties
var sprite 
var damage_group
var knockback
var speed = 600
var damage = 0
var direction = Vector2.ZERO
var raycast_mask = 1  # Collision mask for the raycast
var reflections = 0  # Current number of reflections
var delay_count = 0
var init_direction = Vector2.ZERO

# Modular properties
var waveform  # Oscillator type
var reverb = [0, 1.0]
var delay = [0, 1.0]
var slider1 = 0.0

# Timer for delay effect
@onready var delay_timer = $DelayTimer

func scale_bullet_size():
	var base_size = 2.0  # Default size when damage is 100
	var scale_factor = damage / 50.0  # Adjust proportionally
	var volume_factor = pow(damage / 100.0, 2)  # Squared for dramatic effect
	scale = Vector2(base_size * scale_factor, base_size * scale_factor)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	SoundManager.play_sound("laser", position, reflections, 1+slider1)
	if delay[0] >= 1:
		delay_timer.start()

func _process(delta):
	
	# Calculate the next position of the bullet
	var next_position = global_position + direction * speed * delta
		
	# Update rotation to align with travel direction
	rotation = direction.angle()

	# Create raycast parameters
	var ray_params = PhysicsRayQueryParameters2D.new()
	ray_params.from = global_position
	ray_params.to = next_position
	ray_params.collision_mask = raycast_mask
	ray_params.exclude = [self]  # Exclude the bullet itself

	# Perform the raycast
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(ray_params)
	
	if result:
		# Handle reflection or destruction
		if reflections < reverb[0]:
			if reverb[0] >= 0:
				reflect_bullet(result)
		else:
			print("bullet destroyed")
			queue_free()
	else:
		# Move the bullet forward
		position = next_position
		
func _on_DelayTimer_timeout():
	# Spawn the delayed bullet
	var player = get_parent().get_node("Frog")
	var new_bullet = preload("res://bullet.tscn").instantiate()
	new_bullet.global_position = player.global_position
	new_bullet.set_direction(init_direction)
	new_bullet.configure_bullet({
		"damage_group": damage_group,
		"knockback" : knockback,
		"waveform": waveform,
		"speed": speed,
		"damage": damage*delay[1],
		"reverb": [reverb[0]-1,reverb[1]],  # Reduce ricochets and damage for delayed bullets
		"delay": [delay[0]-1,reverb[1]],
		"init_direction": init_direction,
		"slider1": slider1,
	})
	get_parent().add_child(new_bullet)

func reflect_bullet(result):
	# Get the collision normal from the raycast result
	var normal = result.normal
	SoundManager.play_sound("laser", position, reflections, reverb[1])
	# Reflect the bullet's direction based on the normal
	direction = direction.bounce(normal).normalized()
	reflections += 1
	damage *= reverb[1]
	scale_bullet_size()
	
	# Move the bullet slightly away from the collision point to avoid re-collision
	global_position = result.position + direction * 1

func set_direction(dir):
	# Initialize the bullet's direction
	direction = dir.normalized()
	# Align rotation with the initial direction
	rotation = direction.angle()
	
func _on_body_entered(body: Node):
	if body.is_in_group(damage_group) and body.has_method("apply_damage"):
		print("Enemy Damaged" + str(damage))
		body.apply_damage(damage, direction, knockback)  # 200 = knockback force

func configure_bullet(config):
	# Accept modular configurations
	#sprite = config.sprite
	damage_group = config.damage_group
	knockback = config.knockback
	speed = config.speed
	damage = config.damage
	waveform = config.waveform
	reverb = config.reverb
	delay = config.delay
	slider1 = config.slider1
	init_direction = config.init_direction
	
	# Scale bullet size based on damage
	scale_bullet_size()
