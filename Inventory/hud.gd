extends Control

@onready var inv: Inv = preload("res://Inventory/playersinv.tres")
@onready var slots: Array = $MainPanel/VBoxContainer/Items/GridContainer.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_slots()

func update_slots():
	for i in range(min(inv.items.size(),slots.size())):
		slots[i].update(inv.items[i])
