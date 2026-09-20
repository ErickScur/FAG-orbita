extends CanvasLayer

const DONE_MARK: String = "[OK]"
const COLOR_KEY: Color = Color("5fd4c8")
const COLOR_TEXT: Color = Color("e0ebee")
const COLOR_HINT: Color = Color("6f8291")
const COLOR_DONE: Color = Color("7ad17a")

var _catalog: Dictionary = {}
var _current: StringName = &""
var _done: bool = false
var _done_left: float = 0.0
var _dialogue_was_active: bool = false

@onready var _card: PanelContainer = %Card
@onready var _key: Label = %Key
@onready var _action: Label = %Action
@onready var _hint: Label = %Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = TutorialData.load_all()
	_card.visible = false
	_card.modulate.a = 0.0
	set_process(true)
	EventBus.tutorial_requested.connect(request)


func _process(delta: float) -> void:
	if _current == &"":
		return
	if _done:
		_dialogue_was_active = DialogueManager.is_active()
		_done_left -= delta
		_card.modulate.a = clampf(_done_left / Balance.TUTORIAL_CARD_FADE, 0.0, 1.0)
		if _done_left <= 0.0:
			_dismiss()
		return
	_card.modulate.a = minf(_card.modulate.a + delta / Balance.TUTORIAL_CARD_FADE, 1.0)
	var advancing_dialogue: bool = _dialogue_was_active
	_dialogue_was_active = DialogueManager.is_active()
	if advancing_dialogue:
		return
	if _pressed_any(TutorialData.actions_of(_current, _catalog)):
		_complete()


func request(tutorial_id: StringName) -> void:
	if tutorial_id == &"" or tutorial_id == _current:
		return
	if not TutorialData.has(tutorial_id, _catalog):
		push_warning("TutorialCard: cartão '%s' não existe em %s" % [tutorial_id, TutorialData.PATH])
		return
	if is_learned(tutorial_id):
		return
	_current = tutorial_id
	_done = false
	_done_left = 0.0
	_dialogue_was_active = DialogueManager.is_active()
	var data: Dictionary = TutorialData.entry(tutorial_id, _catalog)
	_key.text = String(data["key"])
	_action.text = String(data["text"])
	_hint.text = String(data["hint"])
	_hint.visible = not _hint.text.is_empty()
	_key.add_theme_color_override("font_color", COLOR_KEY)
	_action.add_theme_color_override("font_color", COLOR_TEXT)
	_card.modulate.a = 0.0
	_card.visible = true


func current() -> StringName:
	return _current


func is_showing() -> bool:
	return _card != null and _card.visible


func is_learned(tutorial_id: StringName) -> bool:
	return bool(GameState.flags.get(TutorialData.flag_name(tutorial_id), false))


func _complete() -> void:
	_done = true
	_done_left = Balance.TUTORIAL_CARD_HOLD
	_key.text = DONE_MARK
	_key.add_theme_color_override("font_color", COLOR_DONE)
	_action.add_theme_color_override("font_color", COLOR_DONE)
	GameState.flags[TutorialData.flag_name(_current)] = true
	AudioManager.play_sfx(&"ui_confirm")
	EventBus.tutorial_completed.emit(_current)


func _dismiss() -> void:
	_current = &""
	_done = false
	_card.visible = false
	_card.modulate.a = 0.0


func _pressed_any(actions: Array[StringName]) -> bool:
	for action: StringName in actions:
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			return true
	return false
