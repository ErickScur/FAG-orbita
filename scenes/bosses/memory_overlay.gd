class_name MemoryOverlay
extends CanvasLayer

const CREW_SHEET: String = "res://assets/sprites/props/memory_crew_sheet.png"
const CREW_FRAME: Vector2i = Vector2i(32, 32)
const CREW_COLUMNS: int = 4
const CREW_ROWS: int = 2
const SCREEN_SIZE: Vector2 = Vector2(384, 216)
const LAYER: int = 7
const PANEL_RECT: Rect2 = Rect2(16, 140, 352, 64)
const HEADER_RECT: Rect2 = Rect2(24, 142, 336, 16)
const TEXT_RECT: Rect2 = Rect2(24, 158, 336, 44)
const PANEL_COLOR: Color = Color(0.03, 0.04, 0.06, 0.78)
const HEADER_COLOR: Color = Color("7fe3f0")
const TEXT_COLOR: Color = Color("e8eef2")
const FLASH_COLOR: Color = Color("ffe6f0")
const FLASH_ALPHA: float = 0.55
const CREW_SCALE: float = 4.0
const FONT_SIZE: int = 16

var _panel: ColorRect = null
var _header: Label = null
var _text: Label = null
var _flash: ColorRect = null
var _crew: TextureRect = null
var _full: String = ""
var _typed: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = LAYER
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.size = SCREEN_SIZE
	_flash.color = FLASH_COLOR
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	add_child(_flash)
	_crew = TextureRect.new()
	_crew.name = "Crew"
	_crew.size = Vector2(CREW_FRAME) * CREW_SCALE
	_crew.position = (SCREEN_SIZE - _crew.size) * 0.5 - Vector2(0, 24)
	_crew.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crew.stretch_mode = TextureRect.STRETCH_SCALE
	_crew.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_crew.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crew.modulate.a = 0.0
	add_child(_crew)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.color = PANEL_COLOR
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_header = _label(HEADER_RECT, HEADER_COLOR)
	_header.name = "Header"
	_text = _label(TEXT_RECT, TEXT_COLOR)
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _process(delta: float) -> void:
	if _full.is_empty() or is_typing_done():
		return
	_typed = minf(float(_full.length()), _typed + Balance.RECALL_TEXT_CPS * delta)
	_text.visible_characters = int(_typed)


func open(header: String) -> void:
	_header.text = header
	_header.visible = true
	_panel.visible = true
	_text.visible = true
	_text.text = ""
	_full = ""
	_typed = 0.0


func close() -> void:
	_panel.visible = false
	_header.visible = false
	_text.visible = false
	_full = ""


func show_line(text: String) -> void:
	_full = text
	_typed = 0.0
	_text.text = text
	_text.visible_characters = 0


func current_line() -> String:
	return _full


func is_typing_done() -> bool:
	return _full.is_empty() or int(_typed) >= _full.length()


func is_open() -> bool:
	return _panel.visible


func set_flash(ratio: float) -> void:
	var strength: float = clampf(ratio, 0.0, 1.0)
	_flash.modulate.a = strength * FLASH_ALPHA
	_crew.modulate.a = strength


func pick_memory() -> void:
	var texture: Texture2D = AssetResolver.atlas(
		CREW_SHEET,
		CREW_FRAME,
		_rng.randi_range(0, CREW_COLUMNS - 1),
		_rng.randi_range(0, CREW_ROWS - 1)
	)
	_crew.texture = texture


func _label(rect: Rect2, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.visible = false
	add_child(label)
	return label
