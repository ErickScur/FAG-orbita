extends CanvasLayer

const FADE_IN: float = 0.2
const HOLD: float = 1.1
const FADE_OUT: float = 0.2

@onready var label: Label = %Label

var _tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	label.modulate.a = 0.0


func show_toast(message: String = "") -> void:
	if not message.is_empty():
		label.text = message
	AudioManager.play_sfx(&"power_on")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	label.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(label, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(HOLD)
	_tween.tween_property(label, "modulate:a", 0.0, FADE_OUT)
