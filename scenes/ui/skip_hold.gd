class_name SkipHold
extends Control

const HINT_SIZE: Vector2 = Vector2(152, 16)
const MARGIN: Vector2 = Vector2(8, 2)
const IDLE_ALPHA: float = 0.45
const HINT_COLOR: Color = Color(0.372549, 0.831373, 0.784314)

var _hold: float = 0.0
var _armed: bool = false
var _done: bool = false
var _label: Label = null
var _bar: ColorRect = null


func _init(text_value: String = "") -> void:
	name = "SkipHold"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.name = "Hint"
	_label.text = text_value
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = HINT_SIZE
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_label)
	_bar = ColorRect.new()
	_bar.name = "Bar"
	_bar.color = HINT_COLOR
	_bar.position = Vector2(0, HINT_SIZE.y)
	_bar.size = Vector2(0, 1)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	size = HINT_SIZE + Vector2(0, 1)
	_apply(0.0)


func place_top_right(screen: Vector2) -> void:
	position = Vector2(screen.x - HINT_SIZE.x - MARGIN.x, MARGIN.y)


func arm() -> void:
	_armed = false
	_done = false
	_hold = 0.0
	_apply(0.0)


func tick(delta: float) -> bool:
	if _done:
		return true
	var pressed: bool = any_action_pressed()
	if not _armed:
		_armed = not pressed
		return false
	_hold = _hold + delta if pressed else 0.0
	var ratio: float = clampf(_hold / Balance.ENDING_SKIP_HOLD_TIME, 0.0, 1.0)
	_apply(ratio)
	_done = _hold >= Balance.ENDING_SKIP_HOLD_TIME
	return _done


func progress() -> float:
	return clampf(_hold / Balance.ENDING_SKIP_HOLD_TIME, 0.0, 1.0)


func hint_text() -> String:
	return _label.text


func _apply(ratio: float) -> void:
	_label.modulate.a = 1.0 if ratio > 0.0 else IDLE_ALPHA
	_bar.visible = ratio > 0.0
	_bar.size.x = HINT_SIZE.x * ratio


static func any_action_pressed() -> bool:
	for action: StringName in InputMap.get_actions():
		if Input.is_action_pressed(action):
			return true
	return false
