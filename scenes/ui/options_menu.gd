extends Control

signal closed

const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const TEST_SFX: StringName = &"ui_confirm"
const VOICE_SAMPLE: String = "res://assets/audio/sfx/ui_confirm.wav"

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
@onready var back_button: Button = %BackButton

var _focus_trap: FocusTrap = FocusTrap.new()
var _dragging: bool = false
var _closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	voice_slider.value = Settings.voice_volume
	difficulty_option.selected = maxi(0, DIFFICULTIES.find(Settings.difficulty))
	no_timer_check.button_pressed = Settings.no_timer
	fullscreen_check.button_pressed = Settings.fullscreen
	_refresh_values()
	_refresh_hints()
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
	back_button.pressed.connect(close)
	_link_focus()
	_focus_trap.capture(_focus_chain())
	master_slider.grab_focus()
	for control: Control in _focus_chain():
		control.focus_entered.connect(_play_move)


func _input(event: InputEvent) -> void:
	if _closing or not difficulty_option.has_focus():
		return
	if event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		_shift_difficulty(1)
	elif event.is_action_pressed(&"ui_left"):
		get_viewport().set_input_as_handled()
		_shift_difficulty(-1)


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
	Settings.save_settings()
	AudioManager.play_sfx(&"ui_back")
	closed.emit()
	queue_free()


func _sliders() -> Array[HSlider]:
	return [master_slider, music_slider, sfx_slider, voice_slider]


func _focus_chain() -> Array[Control]:
	return [
		master_slider,
		music_slider,
		sfx_slider,
		voice_slider,
		difficulty_option,
		no_timer_check,
		fullscreen_check,
		back_button,
	]


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


func _shift_difficulty(step: int) -> void:
	var index: int = clampi(difficulty_option.selected + step, 0, DIFFICULTIES.size() - 1)
	if index == difficulty_option.selected:
		return
	difficulty_option.selected = index
	_on_difficulty_selected(index)


func _on_difficulty_selected(index: int) -> void:
	Settings.difficulty = DIFFICULTIES[clampi(index, 0, DIFFICULTIES.size() - 1)]
	_refresh_hints()
	AudioManager.play_sfx(&"ui_move")


func _on_no_timer_toggled(pressed: bool) -> void:
	Settings.no_timer = pressed
	_refresh_hints()
	AudioManager.play_sfx(&"ui_confirm")


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.fullscreen = pressed
	Settings.apply_display()
	AudioManager.play_sfx(&"ui_confirm")


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")
