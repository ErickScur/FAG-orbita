extends Control

const DATA_PATH: String = "res://data/ui/briefing.json"
const NEXT_SCENE: String = "res://scenes/levels/core_hub.tscn"
const BLIP_EVERY: int = 3
const FIELD_WIDTH: float = 148.0
const COLOR_FIELD: Color = Color("6f8291")
const COLOR_VALUE: Color = Color("5fd4c8")
const COLOR_LINE: Color = Color("e0ebee")

var _blocks: Array = []
var _block: int = -1
var _rows: Array[Label] = []
var _row: int = 0
var _typed: float = 0.0
var _blips: int = 0
var _leaving: bool = false

@onready var _header: Label = %Header
@onready var _title: Label = %Title
@onready var _body: VBoxContainer = %Body
@onready var _footer: Label = %Footer


func _ready() -> void:
	var data: Dictionary = load_data()
	_header.text = String(data.get("header", ""))
	_blocks = data.get("blocks", [])
	_footer.text = footer_text(false)
	if _blocks.is_empty():
		push_error("Briefing: nenhum bloco em %s" % DATA_PATH)
		return
	_open_block(0)


func _process(delta: float) -> void:
	if _leaving or _row >= _rows.size():
		return
	var label: Label = _rows[_row]
	_typed += delta * Balance.BRIEFING_CPS
	var shown: int = mini(int(_typed), label.text.length())
	if shown > label.visible_characters:
		_blips += shown - label.visible_characters
		if _blips >= BLIP_EVERY:
			_blips = 0
			AudioManager.play_sfx(&"dialogue_blip")
		label.visible_characters = shown
	if shown < label.text.length():
		return
	_row += 1
	_typed = 0.0
	if _row >= _rows.size():
		_footer.text = footer_text(true)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
		return
	if not (event.is_action_pressed(&"jump") or event.is_action_pressed(&"interact")):
		return
	get_viewport().set_input_as_handled()
	if _row < _rows.size():
		_reveal_all()
		return
	AudioManager.play_sfx(&"ui_confirm")
	if _block + 1 >= _blocks.size():
		_leave()
		return
	_open_block(_block + 1)


static func load_data(path: String = DATA_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func footer_text(block_done: bool) -> String:
	if block_done:
		return "[ESPAÇO] CONTINUAR      [ESC] PULAR"
	return "[ESPAÇO] ACELERAR      [ESC] PULAR"


func block_index() -> int:
	return _block


func is_block_complete() -> bool:
	return _row >= _rows.size()


func _open_block(index: int) -> void:
	_block = index
	var data: Dictionary = _blocks[index]
	_title.text = String(data.get("title", ""))
	_rows.clear()
	_row = 0
	_typed = 0.0
	_blips = 0
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	for value: Variant in data.get("fields", []) as Array:
		if value is Array and (value as Array).size() >= 2:
			_add_field(value as Array)
	for value: Variant in data.get("lines", []) as Array:
		_add_line(String(value))
	_footer.text = footer_text(_rows.is_empty())


func _add_field(pair: Array) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	var field := Label.new()
	field.text = String(pair[0])
	field.custom_minimum_size = Vector2(FIELD_WIDTH, 0.0)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_theme_font_size_override("font_size", 16)
	field.add_theme_color_override("font_color", COLOR_FIELD)
	row.add_child(field)
	var value := Label.new()
	value.text = String(pair[1])
	value.visible_characters = 0
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", COLOR_VALUE)
	row.add_child(value)
	_body.add_child(row)
	_rows.append(value)


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.visible_characters = 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_LINE)
	_body.add_child(label)
	_rows.append(label)


func _reveal_all() -> void:
	for label: Label in _rows:
		label.visible_characters = -1
	_row = _rows.size()
	_typed = 0.0
	_footer.text = footer_text(true)


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	set_process(false)
	AudioManager.play_sfx(&"ui_confirm")
	if not ResourceLoader.exists(NEXT_SCENE):
		push_error("Briefing: cena inexistente %s" % NEXT_SCENE)
		return
	SceneManager.goto_with_loading(NEXT_SCENE)
