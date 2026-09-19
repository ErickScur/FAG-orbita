extends Node

const TARGET: String = "res://tests/qa/scenes/loading_target.tscn"


func _ready() -> void:
	SceneManager.goto_with_loading(TARGET)
