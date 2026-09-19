extends Control

signal answered(confirmed: bool)

@onready var message_label: Label = %Message
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

var _answered: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	yes_button.pressed.connect(_answer.bind(true))
	no_button.pressed.connect(_answer.bind(false))
	no_button.grab_focus()
	yes_button.focus_entered.connect(_play_move)
	no_button.focus_entered.connect(_play_move)


func _unhandled_input(event: InputEvent) -> void:
	if _answered:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func open(message: String, yes_text: String = "", no_text: String = "") -> void:
	message_label.text = message
	if not yes_text.is_empty():
		yes_button.text = yes_text
	if not no_text.is_empty():
		no_button.text = no_text
	no_button.grab_focus()


func _answer(confirmed: bool) -> void:
	if _answered:
		return
	_answered = true
	AudioManager.play_sfx(&"ui_confirm" if confirmed else &"ui_back")
	answered.emit(confirmed)
	queue_free()


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")
