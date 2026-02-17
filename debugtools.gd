extends Node

signal slider_value_changed(value)

func _ready():
	$CanvasLayer/HSlider.connect("value_changed", Callable(self, "_on_slider_value_changed"))

func _on_slider_value_changed(value):
	emit_signal("slider_value_changed", value)
