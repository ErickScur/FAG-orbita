extends Control

signal closed

const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const TEST_SFX: StringName = &"ui_confirm"
const VOICE_SAMPLE: String = "res://assets/audio/sfx/ui_confirm.wav"
const TEXTS_PATH: String = "res://data/ui/options.json"
const ACTION_LABEL_WIDTH: float = 150.0
const COLOR_MESSAGE: Color = Color(0.878431, 0.705882, 0.235294, 1.0)
const COLOR_WAITING: Color = Color(0.372549, 0.831373, 0.784314, 1.0)

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var voice_slider: HSlider = %VoiceSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var voice_value: Label = %VoiceValue
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var difficulty_hint: Label = %DifficultyHint
@onready var no_timer_check: CheckBox = %NoTimerCheck
@onready var no_timer_hint: Label = %NoTimerHint
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var subtitle_option: OptionButton = %SubtitleOption
@onready var colorblind_check: CheckBox = %ColorblindCheck
@onready var colorblind_hint: Label = %ColorblindHint
@onready var bindings_box: VBoxContainer = %Bindings
@onready var restore_button: Button = %RestoreButton
@onready var message_label: Label = %Message
@onready var back_button: Button = %BackButton

var _focus_trap: FocusTrap = FocusTrap.new()
var _dragging: bool = false
var _closing: bool = false
var _texts: Dictionary = {}
var _binding_buttons: Dictionary = {}
var _capturing: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_texts = _load_texts()
	_apply_texts()
	_build_bindings()
	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	voice_slider.value = Settings.voice_volume
	difficulty_option.selected = maxi(0, DIFFICULTIES.find(Settings.difficulty))
	no_timer_check.button_pressed = Settings.no_timer
	fullscreen_check.button_pressed = Settings.fullscreen
	subtitle_option.selected = maxi(0, Accessibility.SUBTITLE_SIZES.find(Settings.subtitle_size))
	colorblind_check.button_pressed = Settings.colorblind
	_refresh_values()
	_refresh_hints()
	_refresh_bindings()
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	voice_slider.value_changed.connect(_on_voice_changed)
	for slider: HSlider in _sliders():
		slider.drag_started.connect(_on_drag_started)
	sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	voice_slider.drag_ended.connect(_on_voice_drag_ended)
	master_slider.drag_ended.connect(_on_plain_drag_ended)
	music_slider.drag_ended.connect(_on_plain_drag_ended)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	no_timer_check.toggled.connect(_on_no_timer_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	subtitle_option.item_selected.connect(_on_subtitle_selected)
	colorblind_check.toggled.connect(_on_colorblind_toggled)
	restore_button.pressed.connect(_on_restore)
	back_button.pressed.connect(close)
	Settings.bindings_changed.connect(_refresh_bindings)
	_link_focus()
	_focus_trap.capture(_focus_chain())
	master_slider.grab_focus()
	_scroll_to_top.call_deferred()
	for control: Control in _focus_chain():
		control.focus_entered.connect(_play_move)


func _input(event: InputEvent) -> void:
	if _closing:
		return
	if _capturing != &"":
		_capture_input(event)
		return
	var option: OptionButton = _focused_option()
	if option == null:
		return
	if event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		_shift_option(option, 1)
	elif event.is_action_pressed(&"ui_left"):
		get_viewport().set_input_as_handled()
		_shift_option(option, -1)


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	_focus_trap.release()
	if _closing:
		return
	_closing = true
	_capturing = &""
	if Settings.bindings_changed.is_connected(_refresh_bindings):
		Settings.bindings_changed.disconnect(_refresh_bindings)
	Settings.save_settings()
	AudioManager.play_sfx(&"ui_back")
	closed.emit()
	queue_free()


func is_capturing() -> bool:
	return _capturing != &""


func binding_text(action: String) -> String:
	var button: Button = _binding_buttons.get(StringName(action), null)
	return button.text if button != null else ""


func message() -> String:
	return message_label.text


func _scroll_to_top() -> void:
	%Scroll.scroll_vertical = 0


func _sliders() -> Array[HSlider]:
	return [master_slider, music_slider, sfx_slider, voice_slider]


func _focus_chain() -> Array[Control]:
	var chain: Array[Control] = [
		master_slider,
		music_slider,
		sfx_slider,
		voice_slider,
		difficulty_option,
		no_timer_check,
		fullscreen_check,
		subtitle_option,
		colorblind_check,
	]
	for action: StringName in KeyBindings.REMAPPABLE:
		if _binding_buttons.has(action):
			chain.append(_binding_buttons[action])
	chain.append(restore_button)
	chain.append(back_button)
	return chain


func _link_focus() -> void:
	var chain: Array[Control] = _focus_chain()
	for index: int in range(chain.size()):
		var current: Control = chain[index]
		var previous: Control = chain[(index - 1 + chain.size()) % chain.size()]
		var following: Control = chain[(index + 1) % chain.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)


func _load_texts() -> Dictionary:
	if not FileAccess.file_exists(TEXTS_PATH):
		push_warning("OptionsMenu: textos ausentes em %s" % TEXTS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	return parsed if parsed is Dictionary else {}


func _text(key: String) -> String:
	return String(_texts.get(key, ""))


func _apply_texts() -> void:
	%AudioHeader.text = _text("section_audio")
	%GameHeader.text = _text("section_game")
	%AccessHeader.text = _text("section_access")
	%ControlsHeader.text = _text("section_controls")
	%ControlsHint.text = _text("controls_hint")
	%SubtitleLabel.text = _text("subtitle_label")
	colorblind_check.text = _text("colorblind")
	colorblind_hint.text = _text("colorblind_hint")
	restore_button.text = _text("restore")
	var sizes: Dictionary = _texts.get("subtitle_sizes", {})
	subtitle_option.clear()
	for index: int in range(Accessibility.SUBTITLE_SIZES.size()):
		var size_id: StringName = Accessibility.SUBTITLE_SIZES[index]
		subtitle_option.add_item(String(sizes.get(String(size_id), String(size_id))), index)
	message_label.text = ""


func _build_bindings() -> void:
	var names: Dictionary = _texts.get("actions", {})
	for action: StringName in KeyBindings.REMAPPABLE:
		if not InputMap.has_action(action):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var label := Label.new()
		label.custom_minimum_size = Vector2(ACTION_LABEL_WIDTH, 0.0)
		label.text = String(names.get(String(action), String(action)))
		row.add_child(label)
		var button := Button.new()
		button.name = "Bind_%s" % action
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_start_capture.bind(action))
		row.add_child(button)
		bindings_box.add_child(row)
		_binding_buttons[action] = button


func _refresh_bindings() -> void:
	for action: StringName in _binding_buttons:
		var button: Button = _binding_buttons[action]
		if action == _capturing:
			button.text = _text("waiting")
		else:
			button.text = KeyBindings.action_label(action)


func _action_name(action: StringName) -> String:
	var names: Dictionary = _texts.get("actions", {})
	return String(names.get(String(action), String(action)))


func _start_capture(action: StringName) -> void:
	if _capturing != &"":
		return
	_capturing = action
	AudioManager.play_sfx(&"ui_confirm")
	_show_message(_text("waiting_message") % _action_name(action), COLOR_WAITING)
	_refresh_bindings()


func _capture_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	if not (event is InputEventKey):
		if event.is_action_pressed(&"ui_cancel"):
			_cancel_capture()
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode: int = KeyBindings.event_keycode(key_event)
	var action: StringName = _capturing
	if keycode == KEY_ESCAPE and action != &"pause":
		_cancel_capture()
		return
	_capturing = &""
	_report(action, keycode, Settings.rebind(action, keycode))
	_refresh_bindings()


func _cancel_capture() -> void:
	_capturing = &""
	_show_message(_text("cancelled"), COLOR_MESSAGE)
	AudioManager.play_sfx(&"ui_back")
	_refresh_bindings()


func _report(action: StringName, keycode: int, outcome: Dictionary) -> void:
	var label: String = KeyBindings.key_label(keycode)
	var other: StringName = outcome.get("other", &"")
	match StringName(outcome.get("result", &"")):
		KeyBindings.RESULT_SWAPPED:
			_show_message(_text("swapped") % [label, _action_name(other)], COLOR_MESSAGE)
			AudioManager.play_sfx(&"ui_confirm")
		KeyBindings.RESULT_RESERVED:
			_show_message(_text("reserved") % [label, _action_name(other)], COLOR_MESSAGE)
			AudioManager.play_sfx(&"ui_error")
		_:
			_show_message(_text("assigned") % [_action_name(action), label], COLOR_WAITING)
			AudioManager.play_sfx(&"ui_confirm")


func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override(&"font_color", color)


func _focused_option() -> OptionButton:
	if difficulty_option.has_focus():
		return difficulty_option
	if subtitle_option.has_focus():
		return subtitle_option
	return null


func _shift_option(option: OptionButton, step: int) -> void:
	var index: int = clampi(option.selected + step, 0, option.item_count - 1)
	if index == option.selected:
		return
	option.selected = index
	option.item_selected.emit(index)


func _percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _refresh_values() -> void:
	master_value.text = _percent(master_slider.value)
	music_value.text = _percent(music_slider.value)
	sfx_value.text = _percent(sfx_slider.value)
	voice_value.text = _percent(voice_slider.value)


func _refresh_hints() -> void:
	difficulty_hint.text = DifficultyText.describe(Settings.difficulty)
	no_timer_hint.text = DifficultyText.no_timer_hint()
	no_timer_hint.visible = Settings.no_timer
	colorblind_hint.visible = Settings.colorblind


func _on_master_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_MASTER, value)
	master_value.text = _percent(value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, value)
	music_value.text = _percent(value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, value)
	sfx_value.text = _percent(value)
	if not _dragging:
		_play_sfx_sample()


func _on_voice_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_VOICE, value)
	voice_value.text = _percent(value)
	if not _dragging:
		_play_voice_sample()


func _on_drag_started() -> void:
	_dragging = true


func _on_plain_drag_ended(_value_changed: bool) -> void:
	_dragging = false


func _on_sfx_drag_ended(value_changed: bool) -> void:
	_dragging = false
	if value_changed:
		_play_sfx_sample()


func _on_voice_drag_ended(value_changed: bool) -> void:
	_dragging = false
	if value_changed:
		_play_voice_sample()


func _play_sfx_sample() -> void:
	AudioManager.play_sfx(TEST_SFX)


func _play_voice_sample() -> void:
	AudioManager.play_voice(AssetResolver.audio(VOICE_SAMPLE))


func _on_difficulty_selected(index: int) -> void:
	Settings.difficulty = DIFFICULTIES[clampi(index, 0, DIFFICULTIES.size() - 1)]
	_refresh_hints()
	AudioManager.play_sfx(&"ui_move")


func _on_subtitle_selected(index: int) -> void:
	var sizes: Array[StringName] = Accessibility.SUBTITLE_SIZES
	Settings.set_subtitle_size(sizes[clampi(index, 0, sizes.size() - 1)])
	AudioManager.play_sfx(&"ui_move")


func _on_no_timer_toggled(pressed: bool) -> void:
	Settings.no_timer = pressed
	_refresh_hints()
	AudioManager.play_sfx(&"ui_confirm")


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.fullscreen = pressed
	Settings.apply_display()
	AudioManager.play_sfx(&"ui_confirm")


func _on_colorblind_toggled(pressed: bool) -> void:
	Settings.set_colorblind(pressed)
	_refresh_hints()
	AudioManager.play_sfx(&"ui_confirm")


func _on_restore() -> void:
	_capturing = &""
	Settings.restore_default_bindings()
	_show_message(_text("restored"), COLOR_WAITING)
	AudioManager.play_sfx(&"ui_confirm")


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")
