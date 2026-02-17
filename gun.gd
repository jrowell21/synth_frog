extends Area2D

var player_nearby = null

func _process(delta):
	if player_nearby and Input.is_action_just_pressed("ui_accept"):  # Default for "E"
		player_nearby.unlock_gun()
		#emit_signal("gun_picked_up")
		queue_free()  # Remove the gun from the scene

func _on_gun_body_entered(body):
	if body.name == "Frog":
		print("Player entered gun area")
		player_nearby = body  # Track the player

func _on_gun_body_exited(body):
	if body == player_nearby:
		print("Player exited gun area")
		player_nearby = null
