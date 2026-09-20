extends CanvasLayer

const REC_TEXT: String = "▮ REPRODUZINDO"
const NEXT_TEXT: String = "▼"
const BLINK_PERIOD: float = 1.0
const BOTTOM_MARGIN: float = 6.0
const DEGRADED_TINT: Color = Color(1.0, 0.878, 0.714, 1.0)
const DEFAULT_SPEAKER_COLOR: String = "#d7e3e8"

var _blink: float = 0.0
var _complete: bool = false
var _show_next: bool = false

@onready var _box: PanelContainer = %Box
@onready var _header: Label = %Header
@onready var _speaker: Label = %Speaker
@onready var _rec: Label = %Rec
@onready var _next: Label = %Next
@onready var _text: RichTextLabel = %Text


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rec.text = REC_TEXT
	_next.text = NEXT_TEXT
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	hide_box()


func _process(delta: float) -> void:
	if not visible:
		return
	_blink = fmod(_blink + delta, BLINK_PERIOD)
	var on: bool = _blink < BLINK_PERIOD * 0.5
	_next.visible = _show_next and _complete and on
	_rec.self_modulate.a = 1.0 if on else 0.35
	_fit()


func show_line(speaker: Dictionary, text: String, header: String, blocking: bool) -> void:
	_speaker.text = String(speaker.get("name", ""))
	_speaker.add_theme_color_override(
		&"font_color", Color(String(speaker.get("color", DEFAULT_SPEAKER_COLOR)))
	)
	var degraded: bool = bool(speaker.get("degraded", false))
	_rec.visible = degraded
	_text.modulate = DEGRADED_TINT if degraded else Color.WHITE
	_header.text = header
	_header.visible = not header.is_empty()
	_text.text = text
	_text.visible_characters = 0
	_show_next = blocking
	_complete = false
	_next.visible = false
	_blink = 0.0
	visible = true
	_fit()


func set_progress(characters: int, complete: bool) -> void:
	_text.visible_characters = characters
	_complete = complete


func hide_box() -> void:
	visible = false
	_complete = false
	_show_next = false


func is_complete() -> bool:
	return _complete


func _fit() -> void:
	var height: float = _box.get_combined_minimum_size().y
	_box.offset_top = -(height + BOTTOM_MARGIN)
	_box.offset_bottom = -BOTTOM_MARGIN
