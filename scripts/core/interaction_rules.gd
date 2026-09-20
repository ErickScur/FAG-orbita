class_name InteractionRules
extends RefCounted

const KEYBOARD_GLYPH: String = "[E]"
const JOYPAD_GLYPH: String = "[X]"


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


static func prompt(glyph: String, text: String) -> String:
	if text.is_empty():
		return ""
	if glyph.is_empty():
		return text
	return "%s %s" % [glyph, text]


static func glyph(joypad: bool) -> String:
	return JOYPAD_GLYPH if joypad else KEYBOARD_GLYPH
