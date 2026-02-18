extends Control

@onready var inv: Inv = preload("res://Inventory/playersinv.tres")
@onready var slots: Array = $MainPanel/VBoxContainer/Items/GridContainer.get_children()
var temp_slot 
var item_name
var selected_slot
var selected_item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_slots()
	selected_slot = slots[0]
	selected_item = inv.items[0]

func _process(delta):
	for i in range(slots.size()):
			if slots[i].moving_object and inv.items[i]:
				item_name = inv.items[i].name
				for y in range(slots.size()):
					if slots[y].has_mouse_:
						if Input.is_action_just_released("left_click"):
							print(item_name," placed in slot ", y)
							temp_slot = inv.items[y]
							inv.items[y] = inv.items[i]
							inv.items[i] = temp_slot
							update_slots()
	if Input.is_action_just_pressed('inv1'):
		select_slot(0)
	if Input.is_action_just_pressed('inv2'):
		select_slot(1)
	if Input.is_action_just_pressed('inv3'):
		select_slot(2)
	if Input.is_action_just_pressed('inv4'):
		select_slot(3)
	if Input.is_action_just_pressed('inv5'):
		select_slot(4)
	if Input.is_action_just_pressed('inv6'):
		select_slot(5)
							
func update_slots():
	for i in range(min(inv.items.size(),slots.size())):
		slots[i].update(inv.items[i])
		
func select_slot(selected_slot):
	for i in range(slots.size()):
		if selected_slot == i:
			slots[i].select()
			selected_item = inv.items[i]
		else:
			slots[i].unselect()
			
func use_item():
	if selected_item:
		return selected_item.use_item()
