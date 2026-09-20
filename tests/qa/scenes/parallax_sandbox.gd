extends Node2D

const PARALLAX_SCENE: String = "res://scenes/world/space_parallax.tscn"
const START_X: float = 192.0
const STEP_X: float = 32.0
const STEP_FRAME: int = 91
const MARKER_COLOR: Color = Color(0.905882, 0.470588, 0.384314)
const MARKER_SIZE: Vector2 = Vector2(4, 216)

var _frame: int = 0

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_camera.position_smoothing_enabled = false
	_camera.global_position = Vector2(START_X, 108.0)
	_camera.make_current()
	_add_markers()
	if not ResourceLoader.exists(PARALLAX_SCENE):
		push_warning("parallax_sandbox: cena de parallax ausente (F26)")
		return
	add_child(load(PARALLAX_SCENE).instantiate())


func _process(_delta: float) -> void:
	_frame += 1
	if _frame != STEP_FRAME:
		return
	_camera.global_position.x = START_X + STEP_X
	_camera.force_update_scroll()


func _add_markers() -> void:
	for index: int in range(0, 9):
		var marker := ColorRect.new()
		marker.color = MARKER_COLOR
		marker.size = MARKER_SIZE
		marker.position = Vector2(float(index) * 96.0, 0.0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)
