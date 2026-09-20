extends Control

const FIRST_LEVEL: String = "res://scenes/levels/core_hub.tscn"
const BRIEFING_SCENE: String = "res://scenes/boot/briefing.tscn"
const FALLBACK_LEVEL: String = "res://tests/qa/scenes/loading_target.tscn"
const OPTIONS_SCENE: String = "res://scenes/ui/options_menu.tscn"
const CONFIRM_SCENE: String = "res://scenes/ui/confirm_dialog.tscn"
const LOGO_PATH: String = "res://assets/ui/logo.png"
const BACKDROP_PATH: String = "res://assets/backgrounds/menu_backdrop.png"

@export var new_game_question: String = ""
@export var corrupted_message: String = ""

@onready var backdrop: TextureRect = %Backdrop
@onready var logo_image: TextureRect = %Logo
@onready var logo_text: Label = %LogoText
@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var toast: Label = %Toast
@onready var toast_timer: Timer = %ToastTimer
@onready var overlay: Control = %Overlay


func _ready() -> void:
	_apply_backdrop()
	_apply_logo()
	AudioManager.play_music(&"menu")
	continue_button.disabled = not SaveManager.has_save()
	options_button.disabled = not ResourceLoader.exists(OPTIONS_SCENE)
	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	toast.visible = false
	toast_timer.timeout.connect(_hide_toast)
	_focus_first()
	for button: Button in _buttons():
		button.focus_entered.connect(_play_move)
	if SaveManager.is_corrupted():
		_show_toast(corrupted_message)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if _overlay_open():
		return
	get_viewport().set_input_as_handled()


func _buttons() -> Array[Button]:
	return [continue_button, new_game_button, options_button, quit_button]


func _focus_first() -> void:
	for button: Button in _buttons():
		if not button.disabled:
			button.grab_focus()
			return


func _overlay_open() -> bool:
	return overlay.get_child_count() > 0


func _first_level() -> String:
	if ResourceLoader.exists(FIRST_LEVEL):
		return FIRST_LEVEL
	return FALLBACK_LEVEL


func _on_continue() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	if not SaveManager.load_game():
		continue_button.disabled = true
		_show_toast(corrupted_message)
		_focus_first()
		return
	SceneManager.goto(String(GameState.checkpoint.get("scene", _first_level())))


func _on_new_game() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	if not SaveManager.has_save():
		_start_new_game()
		return
	var dialog: Control = _open_dialog()
	if dialog == null:
		_start_new_game()
		return
	dialog.answered.connect(_on_new_game_answered)
	dialog.call("open", new_game_question)


func _on_new_game_answered(confirmed: bool) -> void:
	if confirmed:
		_start_new_game()
		return
	new_game_button.grab_focus.call_deferred()


func _start_new_game() -> void:
	SaveManager.delete_save()
	GameState.new_game()
	SceneManager.goto(_new_game_destination())


func _new_game_destination() -> String:
	if ResourceLoader.exists(BRIEFING_SCENE):
		return BRIEFING_SCENE
	return _first_level()


func _on_options() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	if _overlay_open() or not ResourceLoader.exists(OPTIONS_SCENE):
		return
	var packed: PackedScene = load(OPTIONS_SCENE)
	if packed == null:
		return
	var menu: Control = packed.instantiate()
	overlay.add_child(menu)
	menu.connect(&"closed", _on_options_closed)


func _on_options_closed() -> void:
	options_button.grab_focus.call_deferred()


func _on_quit() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	get_tree().quit()


func _open_dialog() -> Control:
	if _overlay_open() or not ResourceLoader.exists(CONFIRM_SCENE):
		return null
	var packed: PackedScene = load(CONFIRM_SCENE)
	if packed == null:
		return null
	var dialog: Control = packed.instantiate()
	overlay.add_child(dialog)
	return dialog


func _show_toast(message: String) -> void:
	AudioManager.play_sfx(&"ui_error")
	toast.text = message
	toast.visible = true
	toast_timer.start()


func _hide_toast() -> void:
	toast.visible = false


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")


func _apply_backdrop() -> void:
	var texture: Texture2D = AssetResolver.texture(BACKDROP_PATH)
	if texture == null:
		return
	backdrop.texture = texture
	backdrop.visible = true
	var parallax: Node = get_node_or_null("SpaceParallax")
	if parallax != null:
		parallax.queue_free()


func _apply_logo() -> void:
	var texture: Texture2D = AssetResolver.texture(LOGO_PATH)
	if texture == null:
		return
	logo_image.texture = texture
	logo_image.visible = true
	logo_text.visible = false

