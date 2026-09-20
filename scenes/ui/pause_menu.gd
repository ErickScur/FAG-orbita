extends CanvasLayer

const FIRST_LEVEL: String = "res://scenes/levels/core_hub.tscn"
const FALLBACK_LEVEL: String = "res://tests/qa/scenes/loading_target.tscn"
const OPTIONS_SCENE: String = "res://scenes/ui/options_menu.tscn"
const CONFIRM_SCENE: String = "res://scenes/ui/confirm_dialog.tscn"
const GAMEPLAY_GROUP: StringName = &"gameplay"
const CONTROL_ROWS: Array[Dictionary] = [
	{"label": "MOVER", "actions": [&"move_left", &"move_right"]},
	{"label": "PULAR", "actions": [&"jump"]},
	{"label": "DESCER", "actions": [&"move_down"]},
	{"label": "INTERAGIR", "actions": [&"interact"]},
	{"label": "LANTERNA", "actions": [&"flashlight"]},
	{"label": "GARRAS", "actions": [&"move_up"]},
	{"label": "CHASSI", "actions": [&"map"]},
	{"label": "PAUSA", "actions": [&"pause"]},
]
const KEY_NAMES: Dictionary = {
	"Space": "ESPAÇO",
	"Escape": "ESC",
	"Shift": "SHIFT",
	"Enter": "ENTER",
	"Tab": "TAB",
}
const HEADLESS_SERVER: String = "headless"
const CONTROL_NAME_WIDTH: float = 62.0
const CONTROL_ROW_HEIGHT: float = 16.0
const CONTROL_FONT_SIZE: int = 16
const CONTROL_NAME_COLOR: Color = Color(0.541176, 0.607843, 0.658824)
const CONTROL_KEY_COLOR: Color = Color(0.843137, 0.890196, 0.909804)

@export var restart_question: String = ""
@export var quit_question: String = ""

var is_open: bool = false

@onready var main_panel: PanelContainer = %Main
@onready var controls_panel: PanelContainer = %Controls
@onready var controls_rows: VBoxContainer = %Rows
@onready var restart_panel: PanelContainer = %RestartPanel
@onready var overlay: Control = %Overlay
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var from_backup_button: Button = %FromBackupButton
@onready var from_start_button: Button = %FromStartButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	restart_panel.visible = false
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options)
	restart_button.pressed.connect(_show_restart)
	quit_button.pressed.connect(_on_quit_to_menu)
	from_backup_button.pressed.connect(_on_from_backup)
	from_start_button.pressed.connect(_on_from_start)
	cancel_button.pressed.connect(_show_main)
	for button: Button in _buttons():
		button.focus_entered.connect(_play_move)
	_build_controls()


func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT:
		return
	if is_open or not is_inside_tree():
		return
	var qa: Node = get_tree().root.get_node_or_null("QACapture")
	if qa != null and bool(qa.get("is_active")):
		return
	if can_pause():
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if is_open:
			if not _overlay_open():
				close()
		elif can_pause():
			open()
		return
	if not is_open or _overlay_open():
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if restart_panel.visible:
			_show_main()
		else:
			close()


func can_pause() -> bool:
	if not is_inside_tree():
		return false
	if get_tree().paused:
		return false
	if SceneManager.is_transitioning():
		return false
	if DialogueManager.is_active() and DialogueManager.freezes_timer():
		return false
	var scene: Node = get_tree().current_scene
	if scene == null:
		return false
	if ScenePaths.is_level(scene.scene_file_path):
		return true
	return scene.is_in_group(GAMEPLAY_GROUP)


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_show_main()
	get_tree().paused = true
	EventBus.game_paused.emit(true)
	AudioManager.play_sfx(&"ui_confirm")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_clear_overlay()
	restart_panel.visible = false
	main_panel.visible = true
	controls_panel.visible = true
	visible = false
	get_tree().paused = false
	EventBus.game_paused.emit(false)
	AudioManager.play_sfx(&"ui_back")


func _buttons() -> Array[Button]:
	return [
		resume_button,
		options_button,
		restart_button,
		quit_button,
		from_backup_button,
		from_start_button,
		cancel_button,
	]


func _overlay_open() -> bool:
	return overlay.get_child_count() > 0


func _clear_overlay() -> void:
	for child: Node in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()


func _first_level() -> String:
	if ResourceLoader.exists(FIRST_LEVEL):
		return FIRST_LEVEL
	return FALLBACK_LEVEL


func _show_main() -> void:
	restart_panel.visible = false
	main_panel.visible = true
	controls_panel.visible = true
	from_backup_button.disabled = not SaveManager.has_save()
	if is_open:
		resume_button.grab_focus()
	else:
		resume_button.grab_focus.call_deferred()


func _show_restart() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	main_panel.visible = false
	controls_panel.visible = false
	restart_panel.visible = true
	from_backup_button.disabled = not SaveManager.has_save()
	if from_backup_button.disabled:
		from_start_button.grab_focus()
	else:
		from_backup_button.grab_focus()


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


func _on_from_backup() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	if not SaveManager.load_game():
		AudioManager.play_sfx(&"ui_error")
		return
	var target: String = String(GameState.checkpoint.get("scene", _first_level()))
	close()
	SceneManager.goto(target)


func _on_from_start() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	var dialog: Control = _open_dialog()
	if dialog == null:
		return
	dialog.answered.connect(_on_from_start_answered)
	dialog.call("open", restart_question)


func _on_from_start_answered(confirmed: bool) -> void:
	if not confirmed:
		from_start_button.grab_focus.call_deferred()
		return
	close()
	SaveManager.delete_save()
	GameState.new_game()
	SceneManager.goto(_first_level())


func _on_quit_to_menu() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	var dialog: Control = _open_dialog()
	if dialog == null:
		return
	dialog.answered.connect(_on_quit_answered)
	dialog.call("open", quit_question)


func _on_quit_answered(confirmed: bool) -> void:
	if not confirmed:
		quit_button.grab_focus.call_deferred()
		return
	close()
	SceneManager.goto(ScenePaths.MAIN_MENU)


func _open_dialog() -> Control:
	if _overlay_open() or not ResourceLoader.exists(CONFIRM_SCENE):
		return null
	var packed: PackedScene = load(CONFIRM_SCENE)
	if packed == null:
		return null
	var dialog: Control = packed.instantiate()
	overlay.add_child(dialog)
	return dialog


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")


func _build_controls() -> void:
	for child: Node in controls_rows.get_children():
		child.queue_free()
	for entry: Dictionary in CONTROL_ROWS:
		var keys: String = _keys_for(entry["actions"])
		if keys.is_empty():
			continue
		controls_rows.add_child(_control_row(String(entry["label"]), keys))


func _control_row(name_text: String, keys_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, CONTROL_ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 2)
	row.add_child(_control_label(name_text, CONTROL_NAME_COLOR, CONTROL_NAME_WIDTH))
	row.add_child(_control_label(keys_text, CONTROL_KEY_COLOR, 0.0))
	return row


func _control_label(text: String, color: Color, width: float) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.custom_minimum_size = Vector2(width, CONTROL_ROW_HEIGHT)
	label.add_theme_font_size_override("font_size", CONTROL_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	return label


func _keys_for(actions: Array) -> String:
	var names: PackedStringArray = []
	for action: Variant in actions:
		var key: String = _first_key(StringName(action))
		if key.is_empty() or names.has(key):
			continue
		names.append(key)
	return " ".join(names)


func _first_key(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		var code: int = key.physical_keycode
		if code != 0 and DisplayServer.get_name() != HEADLESS_SERVER:
			code = DisplayServer.keyboard_get_keycode_from_physical(code)
		elif code == 0:
			code = key.keycode
		if code == 0:
			continue
		var text: String = OS.get_keycode_string(code)
		return String(KEY_NAMES.get(text, text.to_upper()))
	return ""
