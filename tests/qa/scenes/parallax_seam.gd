extends Node2D

const PARALLAX_SCENE: String = "res://scenes/world/space_parallax.tscn"
const STATION_FRAMES: int = 60
const STATION_COUNT: int = 3
const CAMERA_Y: float = 108.0

var _stations: PackedFloat32Array = PackedFloat32Array()
var _frame: int = 0
var _index: int = 0

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_camera.position_smoothing_enabled = false
	_camera.global_position = Vector2(0.0, CAMERA_Y)
	_camera.make_current()
	if not ResourceLoader.exists(PARALLAX_SCENE):
		push_warning("parallax_seam: cena de parallax ausente (F26)")
		return
	var parallax: Node = load(PARALLAX_SCENE).instantiate()
	add_child(parallax)
	_freeze(parallax)
	_build_stations()
	_park(0)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame % STATION_FRAMES != 0:
		return
	_index += 1
	if _index >= _stations.size():
		return
	_park(_index)


func station_positions() -> PackedFloat32Array:
	return _stations


func _freeze(parallax: Node) -> void:
	for child: Node in parallax.get_children():
		if child is Parallax2D:
			(child as Parallax2D).autoscroll = Vector2.ZERO


func _build_stations() -> void:
	var width: float = float(
		ProjectSettings.get_setting("display/window/size/viewport_width", 384)
	)
	var step: float = width / maxf(Balance.PARALLAX_NEAR_SCALE.x, 0.01)
	_stations = PackedFloat32Array()
	for index: int in range(STATION_COUNT):
		_stations.append(float(index) * step)


func _park(index: int) -> void:
	if index < 0 or index >= _stations.size():
		return
	_camera.global_position = Vector2(_stations[index], CAMERA_Y)
	_camera.force_update_scroll()
