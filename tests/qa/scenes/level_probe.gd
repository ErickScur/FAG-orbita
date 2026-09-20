extends Node2D

const LEVEL_SCENE: String = "res://scenes/levels/test_room.tscn"

var _level: Node2D = null


func _ready() -> void:
	if not ResourceLoader.exists(LEVEL_SCENE):
		push_warning("level_probe: fase ausente em %s" % LEVEL_SCENE)
		return
	var instance: Node = load(LEVEL_SCENE).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	var ambient: CanvasModulate = _level.get_node_or_null("CanvasModulate")
	if ambient != null:
		ambient.color = Color.WHITE
