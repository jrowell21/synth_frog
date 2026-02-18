extends Area2D

@onready var croak = $AudioStreamPlayer2D
@onready var path = $Path2D/PathFollow2D
@onready var sprite = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	path.progress_ratio = 0
	print("SHOT FIRED")
	croak.pitch_scale = randf_range(0.3, 1.2)  # slight variation
	croak.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if path.progress_ratio == 1:
		queue_free()
	else:
		path.progress_ratio += delta * 1.3
		sprite.position = path.position
