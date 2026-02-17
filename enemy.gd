extends CharacterBody2D

var movement_speed: float = 200.0
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player = %Frog  # Adjust path as needed
# Optional timer to reduce frequency of path recalculations
var path_update_interval := 0.2
var time_since_last_path_update := 0.0
var origin = Vector2(0,0)

var health := 100
var knockback_velocity := Vector2.ZERO
var knockback_decay := 0.9

# Gun variables
var bullet_scene = preload("res://bullet.tscn")  # Path to the bullet scene
var shoot_cooldown = 3  # Time between shots
var shoot_timer = 0.2  # Cooldown timer
var current_waveform = "sine"  # Default waveform
var bullet_speed = 500
var bullet_damage = 20
var reverb = [5,.8] #number of reflections, #damage decay
var delay = [0,.5]
var slider1 = 0.0
var pitch = 0.0

func apply_damage(amount: int, source_position: Vector2, knockback_force: float):
	health -= amount
	var knockback = (global_position - source_position).normalized() * knockback_force
	knockback_velocity += knockback
	if health <= 0:
		queue_free()
		
func _ready():
	actor_setup.call_deferred()

func actor_setup():
	await get_tree().physics_frame
	navigation_agent.path_desired_distance = 1
	navigation_agent.target_desired_distance = 0.1
	update_path_to_player()

func update_path_to_player():
	if not player or not is_player_on_navmesh():
		navigation_agent.target_position = origin
		return

	# Only update target if it changed meaningfully
	var current_target = navigation_agent.target_position
	var player_pos = player.global_position

	if current_target.distance_to(player_pos) > 8.0:
		navigation_agent.target_position = player_pos

func is_player_on_navmesh() -> bool:
	if not player:
		return false
	var nav_map = navigation_agent.get_navigation_map()
	var player_pos = player.global_position
	var closest_nav_point = NavigationServer2D.map_get_closest_point(nav_map, player_pos)
	var distance = player_pos.distance_to(closest_nav_point)

	# Consider points "on navmesh" if within ~8 pixels
	return distance <= 8.0


func _physics_process(delta):
	time_since_last_path_update += delta

	if player and time_since_last_path_update >= path_update_interval:
		update_path_to_player()
		time_since_last_path_update = 0.0

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_position = navigation_agent.get_next_path_position()
		velocity = global_position.direction_to(next_position) * movement_speed
		
	# Apply knockback
	velocity += knockback_velocity
	knockback_velocity *= knockback_decay
	move_and_slide()
	# Cooldown timer for shooting
	shoot_timer -= delta
	if has_line_of_sight_to_player() and shoot_timer <= 0:
		#shoot_bullet()
		shoot_timer = shoot_cooldown

	
func has_line_of_sight_to_player() -> bool:
	if not player:
		return false

	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.new()
	ray_params.from = global_position
	ray_params.to = player.global_position
	ray_params.collision_mask = 1  # Make sure this matches your "obstacles" layer
	ray_params.exclude = [self]

	var result = space_state.intersect_ray(ray_params)
	if result and result.has("collider"):
		queue_redraw()
		return result.collider == player

	return false

func _draw():
	if player:
		draw_line(global_position, player.global_position, Color.YELLOW)
	
func shoot_bullet():
	# Spawn and configure the bullet
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	var direction = (player.global_position - global_position).normalized()
	bullet.set_direction(direction)  # FIXED

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
		"damage_group":"player",
		"knockback":10,
		"speed": bullet_speed,
		"damage": bullet_damage,
		"init_direction": direction,
		"waveform": current_waveform,
		"delay": delay,
		"reverb": reverb,
		"slider1": slider1,
	})

	get_parent().add_child(bullet)
