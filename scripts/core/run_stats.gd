class_name RunStats
extends RefCounted

const SECRET_PREFIX: String = "secret_"
const LABEL_WIDTH: int = 11


static func format_time(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	var remainder: int = total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, remainder]
	return "%02d:%02d" % [minutes, remainder]


static func secrets_found(state: Node) -> int:
	var flags: Dictionary = _flags(state)
	var found: int = 0
	for key: Variant in flags:
		if not String(key).begins_with(SECRET_PREFIX):
			continue
		if bool(flags[key]):
			found += 1
	return found


static func unread_logs(state: Node) -> int:
	return maxi(0, Balance.LOGS_TOTAL - _count(state, &"logs_collected"))


static func unread_logs_line(state: Node) -> String:
	var missing: int = unread_logs(state)
	if missing == 0:
		return "VOCÊ LEU TODOS OS %d LOGS." % Balance.LOGS_TOTAL
	if missing == 1:
		return "VOCÊ NUNCA VAI LER 1 LOG."
	return "VOCÊ NUNCA VAI LER %d LOGS." % missing


static func summary_rows(state: Node) -> Array:
	return [
		PackedStringArray(["TEMPO", format_time(_play_time(state))]),
		PackedStringArray(
			["LOGS", "%d/%d" % [_count(state, &"logs_collected"), Balance.LOGS_TOTAL]]
		),
		PackedStringArray(
			["DADOS", "%d/%d" % [_count(state, &"research_collected"), Balance.RESEARCH_TOTAL]]
		),
		PackedStringArray(["MORTES", "%d" % _deaths(state)]),
		PackedStringArray(["SEGREDOS", "%d/%d" % [secrets_found(state), Balance.SECRETS_TOTAL]]),
	]


static func summary_lines(state: Node) -> PackedStringArray:
	var lines: PackedStringArray = []
	for row: PackedStringArray in summary_rows(state):
		lines.append(row[0].rpad(LABEL_WIDTH) + row[1])
	return lines


static func _flags(state: Node) -> Dictionary:
	if state == null:
		return {}
	var value: Variant = state.get(&"flags")
	if value is Dictionary:
		return value
	return {}


static func _count(state: Node, property: StringName) -> int:
	if state == null:
		return 0
	var value: Variant = state.get(property)
	if value is Array:
		var list: Array = value
		return list.size()
	return 0


static func _deaths(state: Node) -> int:
	if state == null:
		return 0
	return int(state.get(&"deaths"))


static func _play_time(state: Node) -> float:
	if state == null:
		return 0.0
	return float(state.get(&"play_time"))
