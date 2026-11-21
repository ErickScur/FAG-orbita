class_name EscapeCradle
extends Node2D

const SHEET: String = "res://assets/sprites/world/escape_cradle.png"
const SIZE: Vector2i = Vector2i(128, 64)


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = AssetResolver.texture(SHEET)
	sprite.offset = Vector2(0.0, -float(SIZE.y) * 0.5)
	add_child(sprite)

