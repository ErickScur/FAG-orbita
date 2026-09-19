extends Control

const FIRST_LEVEL: String = "res://scenes/levels/core_hub.tscn"
const FALLBACK_LEVEL: String = "res://tests/qa/scenes/loading_target.tscn"
const BACKGROUND_FAR: String = "res://assets/backgrounds/space_far.png"
const TIME_PREFIX: String = "TEMPO EM ÓRBITA  "

@onready var stars: TextureRect = %Stars
@onready var detail: Label = %Detail
@onready var time_line: Label = %TimeLine
@onready var load_button: Button = %LoadButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	get_tree().paused = false
	stars.texture = AssetResolver.texture(BACKGROUND_FAR)
	detail.text = RunStats.unread_logs_line(GameState)
	time_line.text = TIME_PREFIX + RunStats.format_time(GameState.play_time)
	load_button.disabled = not SaveManager.has_save()
	load_button.pressed.connect(_on_load)
	menu_button.pressed.connect(_on_menu)
	for button: Button in [load_button, menu_button]:
		button.focus_entered.connect(_play_move)
	AudioManager.stop_music()
	AudioManager.play_sfx(&"reactor_alarm")
	_focus_first()


func _focus_first() -> void:
	if load_button.disabled:
		menu_button.grab_focus()
		return
	load_button.grab_focus()


func _first_level() -> String:
	if ResourceLoader.exists(FIRST_LEVEL):
		return FIRST_LEVEL
	return FALLBACK_LEVEL


func _on_load() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	if not SaveManager.load_game():
		AudioManager.play_sfx(&"ui_error")
		load_button.disabled = true
		_focus_first()
		return
	SceneManager.goto(String(GameState.checkpoint.get("scene", _first_level())))


func _on_menu() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	SceneManager.goto(ScenePaths.MAIN_MENU)


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")
