extends Area2D

signal square_wave_picked_up

var player_nearby = null

func _process(delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept"):  # Default for "E"
		player_nearby.unlock_square()
		emit_signal("square_wave_picked_up")
		queue_free()  # Remove the gun from the scene

func _on_square_body_entered(body):
	if body.name == "Frog":
		print("Player entered square area")
		player_nearby = body  # Track the player

func _on_square_body_exited(body):
	if body == player_nearby:
		print("Player exited square area")
		player_nearby = null
