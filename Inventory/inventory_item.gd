extends Resource

class_name InvItem

@export var name: String
@export var texture: Texture2D
@export var description: String
@export var attack: bool
@export var style: String

func use_item():
	print("Using item ", self.name)
	return style
	
