class_name EndingEpilogue
extends Control

enum Stage { EPILOGUE, NAMES, CREW_FOOTER, STATS, QUESTION }

const STARS_PATH: String = "res://assets/backgrounds/space_far.png"
const SCREEN_SIZE: Vector2 = Vector2(384, 216)
const MARGIN: float = 24.0
const ROW_HEIGHT: float = 16.0
const NAMES_TOP: float = 40.0
const NAMES_HEIGHT: float = 144.0
const STAGE_NAMES: Dictionary = {
	Stage.EPILOGUE: &"epilogue",
	Stage.NAMES: &"names",
	Stage.CREW_FOOTER: &"crew_footer",
	Stage.STATS: &"stats",
	Stage.QUESTION: &"question",
}
const TITLE_COLOR: Color = Color(0.372549, 0.831373, 0.784314)
const TEXT_COLOR: Color = Color(0.847059, 0.890196, 0.909804)
const DIM_COLOR: Color = Color(0.541176, 0.607843, 0.658824)

var _table: Dictionary = {}
var _ending: StringName = EndingData.SEEDING
var _tier: StringName = EndingData.TIER_FEW
var _paragraphs: PackedStringArray = []
var _paragraph: int = 0
var _typed: float = 0.0
var _typing: bool = false
var _hold_left: float = 0.0
var _stage: Stage = Stage.EPILOGUE
var _header: Label = null
var _body: Label = null
var _hint: Label = null
var _names_clip: Control = null
var _names_box: VBoxContainer = null
var _names_title: Label = null
var _footer: Label = null
var _stats: VBoxContainer = null
var _question: Label = null
var _buttons: HBoxContainer = null
var _yes: Button = null
var _no: Button = null
var _focus_trap: FocusTrap = FocusTrap.new()
var _skip: SkipHold = null
var _joypad: bool = false


func _ready() -> void:
	get_tree().paused = false
	_table = EndingData.load_table()
	_ending = EndingData.chosen_or_default(GameState.flags)
	_tier = EndingData.tier_for(GameState.research_collected.size(), Balance.RESEARCH_TOTAL)
	_paragraphs = EndingData.epilogue(_table, _ending, _tier)
	_build()
	_show_paragraph(0)


func _process(delta: float) -> void:
	match _stage:
		Stage.EPILOGUE:
			_tick_epilogue(delta)
		Stage.NAMES:
			_tick_names(delta)
		Stage.CREW_FOOTER, Stage.STATS:
			_hold_left -= delta
			if _hold_left <= 0.0:
				_advance()


func _input(event: InputEvent) -> void:
	var joypad: bool = EndingData.joypad_from_event(event, _joypad)
	if joypad == _joypad:
		return
	_joypad = joypad
	_hint.text = EndingData.continue_hint(_table, _joypad)


func _unhandled_input(event: InputEvent) -> void:
	if _stage == Stage.QUESTION or _stage == Stage.NAMES:
		return
	if not event.is_action_pressed(&"ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if _stage == Stage.EPILOGUE and _typing:
		_finish_typing()
		return
	_advance()


func stage_name() -> StringName:
	return STAGE_NAMES.get(_stage, &"")


func tier() -> StringName:
	return _tier


func paragraph_index() -> int:
	return _paragraph


func current_text() -> String:
	return _body.text if _body != null else ""


func continue_hint() -> String:
	return _hint.text if _hint != null else ""


func skip_hint_visible() -> bool:
	return _skip != null and _skip.is_visible_in_tree()


func skip_progress() -> float:
	return _skip.progress() if _skip != null else 0.0


func _advance() -> void:
	match _stage:
		Stage.EPILOGUE:
			if _paragraph + 1 < _paragraphs.size():
				_show_paragraph(_paragraph + 1)
			else:
				_start_names()
		Stage.NAMES:
			_show_crew_footer()
		Stage.CREW_FOOTER:
			_show_stats()
		Stage.STATS:
			_show_question()


func _tick_epilogue(delta: float) -> void:
	if _typing:
		_typed += Balance.ENDING_TEXT_CPS * delta
		_body.visible_characters = int(_typed)
		if _typed >= float(_body.text.length()):
			_finish_typing()
		return
	_hold_left -= delta
	if _hold_left <= 0.0:
		_advance()


func _tick_names(delta: float) -> void:
	if _skip.tick(delta):
		_show_crew_footer()
		return
	_names_box.position.y -= Balance.ENDING_NAMES_SPEED * delta
	if _names_box.position.y + _names_box.size.y <= 0.0:
		_show_crew_footer()


func _show_paragraph(index: int) -> void:
	_stage = Stage.EPILOGUE
	_paragraph = index
	_body.text = _paragraphs[index] if index < _paragraphs.size() else ""
	_body.visible_characters = 0
	_typed = 0.0
	_typing = true
	_hint.visible = false


func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	_hold_left = maxf(
		Balance.ENDING_PARAGRAPH_MIN_HOLD, float(_body.text.length()) / Balance.ENDING_READ_CPS
	)
	_hint.visible = true


func _start_names() -> void:
	_stage = Stage.NAMES
	_header.visible = false
	_body.visible = false
	_hint.visible = false
	_names_title.visible = true
	_names_clip.visible = true
	_names_box.position = Vector2(0, NAMES_HEIGHT)
	_skip.arm()
	_skip.visible = true


func _show_crew_footer() -> void:
	_stage = Stage.CREW_FOOTER
	_names_clip.visible = false
	_skip.visible = false
	_footer.visible = true
	_hold_left = Balance.ENDING_PARAGRAPH_MIN_HOLD


func _show_stats() -> void:
	_stage = Stage.STATS
	_names_title.visible = false
	_footer.visible = false
	_header.text = EndingData.text(_table, _ending, "title")
	_header.visible = true
	_stats.visible = true
	_hold_left = Balance.ENDING_PARAGRAPH_MIN_HOLD


func _show_question() -> void:
	_stage = Stage.QUESTION
	_question.visible = true
	_buttons.visible = true
	_focus_trap.capture([_yes, _no] as Array[Control])
	_yes.grab_focus()


func _on_answer() -> void:
	if not _buttons.visible:
		return
	_buttons.visible = false
	_focus_trap.release()
	AudioManager.play_sfx(&"ui_confirm")
	SceneManager.goto(ScenePaths.CREDITS)


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = SCREEN_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var stars := TextureRect.new()
	stars.texture = AssetResolver.texture(STARS_PATH)
	stars.size = SCREEN_SIZE
	stars.stretch_mode = TextureRect.STRETCH_KEEP
	stars.modulate = Color(1, 1, 1, 0.25)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars)
	_header = _label(EndingData.text(_table, _ending, "title"), DIM_COLOR, 16)
	_place(_header, Vector2(MARGIN, 16), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 16))
	_body = _label("", TEXT_COLOR, 16)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_body, Vector2(MARGIN, 48), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 112))
	_hint = _label(EndingData.continue_hint(_table, _joypad), DIM_COLOR, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_hint, Vector2(MARGIN, SCREEN_SIZE.y - 28), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 16))
	_build_names()
	_build_stats()
	_skip = SkipHold.new(EndingData.ui_text(_table, "skip_hint"))
	_skip.place_top_right(SCREEN_SIZE)
	_skip.visible = false
	add_child(_skip)


func _build_names() -> void:
	_names_title = _label(EndingData.ui_text(_table, "crew_title"), TITLE_COLOR, 16)
	_place(_names_title, Vector2(MARGIN, 16), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 16))
	_names_title.visible = false
	_names_clip = Control.new()
	_names_clip.clip_contents = true
	_names_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_names_clip, Vector2(MARGIN * 2.0, NAMES_TOP), Vector2(
		SCREEN_SIZE.x - MARGIN * 4.0, NAMES_HEIGHT
	))
	_names_clip.visible = false
	_names_box = VBoxContainer.new()
	_names_box.add_theme_constant_override("separation", 0)
	_names_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_names_box.size = Vector2(_names_clip.size.x, 0)
	_names_clip.add_child(_names_box)
	for member: Dictionary in EndingData.crew():
		_names_box.add_child(_crew_row(member))
	var footer_text: String = EndingData.ui_text(_table, "crew_footer") % Balance.CREW_TOTAL
	_footer = _label(footer_text, TEXT_COLOR, 16)
	_footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_footer, Vector2(MARGIN, 0), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, SCREEN_SIZE.y))
	_footer.visible = false


func _crew_row(member: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := _label(String(member.get("name", "")), TEXT_COLOR, 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var role_label := _label(String(member.get("role", "")), DIM_COLOR, 16)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(role_label)
	return row


func _build_stats() -> void:
	_stats = VBoxContainer.new()
	_stats.add_theme_constant_override("separation", 0)
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_stats, Vector2(MARGIN * 4.0, 40), Vector2(SCREEN_SIZE.x - MARGIN * 8.0, 80))
	for row: PackedStringArray in EndingData.stats_rows(GameState, _table, _ending):
		var line := HBoxContainer.new()
		line.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var name_label := _label(row[0], DIM_COLOR, 16)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var value_label := _label(row[1], TITLE_COLOR, 16)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(value_label)
		_stats.add_child(line)
	_stats.visible = false
	_question = _label(EndingData.ui_text(_table, "question"), TEXT_COLOR, 32)
	_place(_question, Vector2(MARGIN, 128), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 32))
	_question.visible = false
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	_place(_buttons, Vector2(MARGIN, 166), Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 20))
	_yes = _button(EndingData.ui_text(_table, "answer_yes"))
	_no = _button(EndingData.ui_text(_table, "answer_no"))
	_buttons.add_child(_yes)
	_buttons.add_child(_no)
	_buttons.visible = false


func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(64, 0)
	button.pressed.connect(_on_answer)
	button.focus_entered.connect(_play_move)
	return button


func _play_move() -> void:
	if _buttons.visible:
		AudioManager.play_sfx(&"ui_move")


func _place(control: Control, at: Vector2, area: Vector2) -> void:
	control.position = at
	control.size = area
	add_child(control)


func _label(text_value: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
