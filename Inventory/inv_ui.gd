extends Control

@onready var inv: Inv = preload("res://Inventory/playersinv.tres")
@onready var slots: Array = $Panel/GridContainer.get_children()
var is_open = false
var temp_slot 
var item_name

func _ready():
	update_slots()
	close()

func _process(delta):
	pass
	if is_open:
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
		
	if Input.is_action_just_pressed("ui_inventory"):
		if is_open:
			close()
		else:
			open()
	
func update_slots():
	for i in range(min(inv.items.size(),slots.size())):
		slots[i].update(inv.items[i])
		
func close():
	self.visible = false
	is_open = false
	
func open():
	self.visible = true
	is_open = true
