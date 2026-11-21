class_name QAMarks
extends RefCounted

const NUMBER_TOLERANCE: float = 0.0001


static func same_value(actual: Variant, expected: Variant) -> bool:
	if _is_number(actual) and _is_number(expected):
		return absf(float(actual) - float(expected)) <= NUMBER_TOLERANCE
	if _is_text(actual) and _is_text(expected):
		return String(actual) == String(expected)
	return typeof(actual) == typeof(expected) and actual == expected


static func ordered_events(raw: Array) -> Array[Dictionary]:
	var indexed: Array[Dictionary] = []
	for entry: Variant in raw:
		if entry is Dictionary:
			indexed.append({"order": indexed.size(), "event": entry})
	indexed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var frame_a: int = int((a["event"] as Dictionary).get("frame", 0))
		var frame_b: int = int((b["event"] as Dictionary).get("frame", 0))
		if frame_a != frame_b:
			return frame_a < frame_b
		return int(a["order"]) < int(b["order"]))
	var result: Array[Dictionary] = []
	for item: Dictionary in indexed:
		result.append(item["event"])
	return result


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _is_text(value: Variant) -> bool:
	return value is String or value is StringName
