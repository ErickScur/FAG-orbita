class_name InteractionRules
extends RefCounted

const KEYBOARD_GLYPH: String = "[E]"
const JOYPAD_GLYPH: String = "[X]"
const KEYBOARD_ACCEPT_GLYPH: String = "[ENTER]"
const JOYPAD_ACCEPT_GLYPH: String = "[A]"
const TEXTS_PATH: String = "res://data/ui/interaction.json"
const PRIORITY_INERT: int = -100
const PRIORITY_GATE: int = 10
const PROMPT_HEAD_GAP: float = 40.0
const PROMPT_FOOT_GAP: float = 8.0
const PROMPT_MARGIN: float = 4.0
const PROMPT_TOP_LIMIT: float = 56.0

static var _texts: Dictionary = {}
static var _joypad: bool = false


static func pick_index(
	positions: PackedVector2Array,
	enabled: PackedInt32Array,
	priorities: PackedInt32Array,
	origin: Vector2
) -> int:
	var best: int = -1
	var best_priority: int = 0
	var best_distance: float = 0.0
	for index: int in range(positions.size()):
		if index >= enabled.size() or enabled[index] == 0:
			continue
		var priority: int = priorities[index] if index < priorities.size() else 0
		var distance: float = origin.distance_squared_to(positions[index])
		if best < 0:
			best = index
			best_priority = priority
			best_distance = distance
			continue
		if priority > best_priority:
			best = index
			best_priority = priority
			best_distance = distance
		elif priority == best_priority and distance < best_distance:
			best = index
			best_distance = distance
	return best


static func effective_priority(priority: int, actionable: bool) -> int:
	if actionable:
		return priority
	return PRIORITY_INERT


static func prompt(glyph: String, text: String, actionable: bool = true) -> String:
	if text.is_empty():
		return ""
	if glyph.is_empty() or not actionable:
		return text
	return "%s %s" % [glyph, text]


static func glyph(joypad: bool) -> String:
	if joypad:
		return JOYPAD_GLYPH
	return KeyBindings.relabel(KEYBOARD_GLYPH, [&"interact"])


static func accept_glyph(joypad: bool) -> String:
	return JOYPAD_ACCEPT_GLYPH if joypad else KEYBOARD_ACCEPT_GLYPH


static func is_joypad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


static func note_device(event: InputEvent) -> bool:
	var joypad: bool = is_joypad_event(event)
	if not joypad and not (event is InputEventKey):
		return false
	if joypad == _joypad:
		return false
	_joypad = joypad
	return true


static func using_joypad() -> bool:
	return _joypad


static func text(id: StringName) -> String:
	if _texts.is_empty():
		_texts = Objectives.load_all(TEXTS_PATH)
	var value: String = Objectives.text_for(id, _texts)
	if value.is_empty():
		push_warning("InteractionRules: texto '%s' ausente em %s" % [id, TEXTS_PATH])
	return value


static func prompt_position(anchor: Vector2, size: Vector2, screen: Vector2) -> Vector2:
	var x: float = anchor.x - size.x * 0.5
	x = clampf(x, PROMPT_MARGIN, maxf(PROMPT_MARGIN, screen.x - PROMPT_MARGIN - size.x))
	var y: float = anchor.y - PROMPT_HEAD_GAP - size.y
	if y < PROMPT_TOP_LIMIT:
		y = anchor.y + PROMPT_FOOT_GAP
	var bottom: float = maxf(PROMPT_TOP_LIMIT, screen.y - PROMPT_MARGIN - size.y)
	y = clampf(y, PROMPT_TOP_LIMIT, bottom)
	return Vector2(roundf(x), roundf(y))
