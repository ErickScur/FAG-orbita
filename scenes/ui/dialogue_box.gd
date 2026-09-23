extends CanvasLayer

const REC_TEXT: String = "[REC] REPRODUZINDO"
const NEXT_TEXT: String = "v"
const BLINK_PERIOD: float = 1.0
const BOTTOM_MARGIN: float = 6.0
const DEGRADED_TINT: Color = Color(1.0, 0.878, 0.714, 1.0)
const DEFAULT_SPEAKER_COLOR: String = "#d7e3e8"
const PORTRAIT_FRAME: Vector2 = Vector2(64, 64)
const MOUTH_BEATS: Array[float] = [0.12, 0.08, 0.14, 0.09, 0.11, 0.10]

var _blink: float = 0.0
var _complete: bool = false
var _show_next: bool = false
var _portrait_row: int = 0
var _mouth_open: bool = false
var _mouth_timer: float = 0.0
var _mouth_beat: int = 0
var _portrait_atlas: AtlasTexture = AtlasTexture.new()

@onready var _box: PanelContainer = %Box
@onready var _header: Label = %Header
@onready var _speaker: Label = %Speaker
@onready var _rec: Label = %Rec
@onready var _next: Label = %Next
@onready var _text: RichTextLabel = %Text
@onready var _portrait: TextureRect = %Portrait


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rec.text = REC_TEXT
	_next.text = NEXT_TEXT
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_portrait.texture = _portrait_atlas
	hide_box()


func _process(delta: float) -> void:
	if not visible:
		return
	_blink = fmod(_blink + delta, BLINK_PERIOD)
	var on: bool = _blink < BLINK_PERIOD * 0.5
	_next.visible = _show_next and _complete and on
	_rec.self_modulate.a = 1.0 if on else 0.35
	if _portrait.visible:
		_animate_mouth(delta)
	_fit()


func show_line(
	speaker: Dictionary,
	text: String,
	header: String,
	blocking: bool,
	expression: StringName = DialogueData.DEFAULT_EXPRESSION
) -> void:
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
	_show_portrait(String(speaker.get("portrait", "")), expression)
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


func is_mouth_open() -> bool:
	return _mouth_open


func portrait_row() -> int:
	return _portrait_row if _portrait.visible else -1


func _fit() -> void:
	var height: float = _box.get_combined_minimum_size().y
	_box.offset_top = -(height + BOTTOM_MARGIN)
	_box.offset_bottom = -BOTTOM_MARGIN


func _show_portrait(path: String, expression: StringName) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		_portrait.visible = false
		return
	var sheet: Texture2D = load(path) as Texture2D
	if sheet == null:
		_portrait.visible = false
		return
	_portrait_atlas.atlas = sheet
	_portrait_row = maxi(0, DialogueData.EXPRESSIONS.find(expression))
	_mouth_beat = 0
	_mouth_timer = MOUTH_BEATS[0]
	_set_mouth(true)
	_portrait.visible = true


func _animate_mouth(delta: float) -> void:
	if _complete:
		if _mouth_open:
			_set_mouth(false)
		return
	_mouth_timer -= delta
	if _mouth_timer > 0.0:
		return
	_mouth_beat = (_mouth_beat + 1) % MOUTH_BEATS.size()
	_mouth_timer += MOUTH_BEATS[_mouth_beat]
	_set_mouth(not _mouth_open)


func _set_mouth(open: bool) -> void:
	_mouth_open = open
	var column: float = 1.0 if open else 0.0
	_portrait_atlas.region = Rect2(
		Vector2(column * PORTRAIT_FRAME.x, float(_portrait_row) * PORTRAIT_FRAME.y), PORTRAIT_FRAME
	)
