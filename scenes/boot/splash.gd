extends Control

@onready var center: VBoxContainer = %Center
@onready var timer: Timer = %Timer

var _elapsed: float = 0.0
var _advancing: bool = false


func _ready() -> void:
	center.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(center, "modulate:a", 1.0, Balance.SCENE_FADE_TIME)
	timer.wait_time = Balance.SPLASH_TIME
	timer.timeout.connect(_advance)
	timer.start()


func _process(delta: float) -> void:
	_elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if _elapsed < Balance.SCENE_FADE_TIME:
		return
	if not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		_advance()


func _advance() -> void:
	if _advancing:
		return
	if not ResourceLoader.exists(ScenePaths.MAIN_MENU):
		return
	_advancing = true
	SceneManager.goto(ScenePaths.MAIN_MENU)
