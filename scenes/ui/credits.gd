class_name Credits
extends Control

const LOGO_PATH: String = "res://assets/ui/logo.png"
const STARS_PATH: String = "res://assets/backgrounds/space_far.png"
const SCREEN_SIZE: Vector2 = Vector2(384, 216)
const SECTION_GAP: float = 16.0
const TOP_BAND: float = 20.0
const LINE_HEIGHT: float = 16.0
const TITLE_COLOR: Color = Color(0.372549, 0.831373, 0.784314)
const TEXT_COLOR: Color = Color(0.847059, 0.890196, 0.909804)

var _box: VBoxContainer = null
var _finished: bool = false
var _resting: bool = false
var _rest_left: float = 0.0
var _skip: SkipHold = null


func _ready() -> void:
	get_tree().paused = false
	_build(EndingData.credits())
	_box.position = Vector2(0, SCREEN_SIZE.y)
	var band := ColorRect.new()
	band.color = Color.BLACK
	band.size = Vector2(SCREEN_SIZE.x, TOP_BAND)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	_skip = SkipHold.new(EndingData.ui_text(EndingData.load_table(), "skip_hint"))
	_skip.place_top_right(SCREEN_SIZE)
	add_child(_skip)


func _process(delta: float) -> void:
	if _finished:
		return
	if _skip.tick(delta):
		_leave()
		return
	if _resting:
		_rest_left -= delta
		if _rest_left <= 0.0:
			_leave()
		return
	_box.position.y -= Balance.CREDITS_SCROLL_SPEED * delta
	if _box.position.y + _box.size.y <= (SCREEN_SIZE.y + LINE_HEIGHT) * 0.5:
		_resting = true
		_rest_left = Balance.ENDING_PARAGRAPH_MIN_HOLD * 2.0


func scroll_offset() -> float:
	return _box.position.y if _box != null else 0.0


func is_resting() -> bool:
	return _resting


func skip_progress() -> float:
	return _skip.progress() if _skip != null else 0.0


func _leave() -> void:
	if _finished:
		return
	_finished = true
	SceneManager.goto(ScenePaths.MAIN_MENU)


func _build(data: Dictionary) -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = SCREEN_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var stars := TextureRect.new()
	stars.texture = AssetResolver.texture(STARS_PATH)
	stars.size = SCREEN_SIZE
	stars.stretch_mode = TextureRect.STRETCH_KEEP
	stars.modulate = Color(1, 1, 1, 0.35)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.size = Vector2(SCREEN_SIZE.x, 0)
	add_child(_box)
	_add_logo(String(data.get("title", "")))
	for value: Variant in data.get("sections", []) as Array:
		if value is Dictionary:
			_add_section(value)


func _add_logo(fallback: String) -> void:
	var texture: Texture2D = AssetResolver.texture(LOGO_PATH)
	if texture == null:
		_box.add_child(_label(fallback, TITLE_COLOR, 32))
		return
	var logo := TextureRect.new()
	logo.texture = texture
	logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	logo.custom_minimum_size = Vector2(SCREEN_SIZE.x, float(texture.get_height()))
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(logo)


func _add_section(section: Dictionary) -> void:
	_box.add_child(_spacer())
	var heading: String = String(section.get("heading", ""))
	if not heading.is_empty():
		_box.add_child(_label(heading, TITLE_COLOR, 16))
	for line: Variant in section.get("lines", []) as Array:
		_box.add_child(_label(String(line), TEXT_COLOR, 16))


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, SECTION_GAP)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _label(text_value: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(SCREEN_SIZE.x, LINE_HEIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
