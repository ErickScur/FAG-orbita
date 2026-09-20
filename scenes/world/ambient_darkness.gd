class_name AmbientDarkness
extends CanvasModulate

@export var ambient_color: Color = Balance.AMBIENT_DARK


func _ready() -> void:
	color = ambient_color


func configure(value: Color) -> void:
	ambient_color = value
	color = value
