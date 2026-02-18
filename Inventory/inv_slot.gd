extends Panel

@onready var item_visual: Sprite2D = $item_display
@onready var inv: Inv = preload("res://Inventory/playersinv.tres")

var moving_object = false
var moved_into = false
var temp_position 
var SPEED = 5
var has_item = false
var state = false
var has_mouse_ = false
var selected = false

func update(item: InvItem):
	if !item:
		print(name, " item cleared")
		item_visual.visible = false
		has_item = false
	else:
		print(name, " item set")
		item_visual.visible = true
		item_visual.texture = item.texture
		has_item = true

func _on_mouse_entered() -> void:
	self.scale = (Vector2(1.2,1.2))
	has_mouse_ = true

func _on_mouse_exited() -> void:
	self.scale = (Vector2(1,1))
	has_mouse_ = false
	
func _process(delta):
	if has_item:
		if (has_mouse_ and Input.is_action_just_pressed("left_click")) or moving_object:
			moving_object = true
			#global_position = get_global_mouse_position()
			item_visual.global_position = item_visual.global_position.lerp(get_global_mouse_position(), SPEED*delta)
			if Input.is_action_just_released("left_click"):
				moving_object = false
	if not moving_object:
		item_visual.position = item_visual.position.lerp(Vector2(8,8), SPEED*delta)
		
func select():
	if not selected:
		selected = true
		item_visual.scale *= 2
		scale *= 2

func unselect():
	if selected:
		selected = false
		item_visual.scale *= .5
		scale *= .5

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			item_visual.apply_scale(Vector2(2,2))
			#print("Control node clicked!")
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			item_visual.apply_scale(Vector2(.5,.5))
			#print("Control node unclicked!")
			
			# Optional: accept the event to stop it from propagating further
