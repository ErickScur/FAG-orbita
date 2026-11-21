class_name EndingData
extends RefCounted

const ENDINGS_PATH: String = "res://data/endings/endings.json"
const CREW_PATH: String = "res://data/endings/crew.json"
const CREDITS_PATH: String = "res://data/endings/credits.json"
const SEEDING: StringName = &"seeding"
const TRANSMISSION: StringName = &"transmission"
const ENDING_IDS: Array[StringName] = [SEEDING, TRANSMISSION]
const TIER_FEW: StringName = &"few"
const TIER_SOME: StringName = &"some"
const TIER_MOST: StringName = &"most"
const TIERS: Array[StringName] = [TIER_FEW, TIER_SOME, TIER_MOST]
const FLAG_ENDING: String = "ending"
const FLAG_COMPLETED: String = "game_completed"
const EVENT_CUT: String = "cut"
const CUTSCENE_ACTIONS: PackedStringArray = [
	"charge", "launch", "lights_step", "fire", "ring", "cut"
]


static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}


static func load_table() -> Dictionary:
	return read_json(ENDINGS_PATH)


static func is_ending(ending_id: StringName) -> bool:
	return ENDING_IDS.has(ending_id)


static func entry(table: Dictionary, ending_id: StringName) -> Dictionary:
	var endings: Dictionary = table.get("endings", {})
	var value: Variant = endings.get(String(ending_id), {})
	if value is Dictionary:
		return value
	return {}


static func text(table: Dictionary, ending_id: StringName, key: String) -> String:
	return String(entry(table, ending_id).get(key, ""))


static func ui_text(table: Dictionary, key: String) -> String:
	var ui: Dictionary = table.get("ui", {})
	return String(ui.get(key, ""))


static func tier_for(collected: int, total: int) -> StringName:
	if total <= 0:
		return TIER_FEW
	var count: int = clampi(collected, 0, total)
	if count >= ceili(float(total) * Balance.EPILOGUE_MOST_RATIO):
		return TIER_MOST
	if count >= ceili(float(total) * Balance.EPILOGUE_SOME_RATIO):
		return TIER_SOME
	return TIER_FEW


static func epilogue(
	table: Dictionary, ending_id: StringName, tier: StringName
) -> PackedStringArray:
	var tiers: Dictionary = entry(table, ending_id).get("epilogue", {})
	var lines := PackedStringArray()
	for value: Variant in tiers.get(String(tier), []) as Array:
		lines.append(String(value))
	return lines


static func cutscene_events(table: Dictionary, ending_id: StringName) -> Array[Dictionary]:
	var cutscene: Dictionary = entry(table, ending_id).get("cutscene", {})
	var events: Array[Dictionary] = []
	for value: Variant in cutscene.get("events", []) as Array:
		if value is Dictionary:
			events.append(value)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("at", 0.0)) < float(b.get("at", 0.0))
	)
	return events


static func cutscene_length(events: Array[Dictionary]) -> float:
	for event: Dictionary in events:
		if String(event.get("do", "")) == EVENT_CUT:
			return float(event.get("at", 0.0))
	return 0.0


static func count_action(events: Array[Dictionary], action: String) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if String(event.get("do", "")) == action:
			count += 1
	return count


static func record_choice(flags: Dictionary, ending_id: StringName) -> bool:
	if not is_ending(ending_id):
		return false
	flags[FLAG_ENDING] = String(ending_id)
	flags[FLAG_COMPLETED] = true
	return true


static func chosen(flags: Dictionary) -> StringName:
	var value: StringName = StringName(String(flags.get(FLAG_ENDING, "")))
	return value if is_ending(value) else &""


static func chosen_or_default(flags: Dictionary) -> StringName:
	var value: StringName = chosen(flags)
	return value if value != &"" else SEEDING


static func is_completed(flags: Dictionary) -> bool:
	return bool(flags.get(FLAG_COMPLETED, false)) and chosen(flags) != &""


static func from_save(path: String) -> StringName:
	var state: Variant = read_json(path).get("state", {})
	if not (state is Dictionary):
		return &""
	var flags: Variant = (state as Dictionary).get("flags", {})
	if not (flags is Dictionary) or not is_completed(flags):
		return &""
	return chosen(flags)


static func stats_rows(
	state: Node, table: Dictionary, ending_id: StringName
) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var time_text: String = RunStats.format_time(_float(state, &"play_time"))
	rows.append(PackedStringArray([ui_text(table, "stat_time"), time_text]))
	rows.append(PackedStringArray([
		ui_text(table, "stat_logs"),
		"%d/%d" % [_count(state, &"logs_collected"), Balance.LOGS_TOTAL],
	]))
	rows.append(PackedStringArray([
		ui_text(table, "stat_research"),
		"%d/%d" % [_count(state, &"research_collected"), Balance.RESEARCH_TOTAL],
	]))
	var deaths: int = int(_float(state, &"deaths"))
	rows.append(PackedStringArray([ui_text(table, "stat_deaths"), "%d" % deaths]))
	rows.append(PackedStringArray([ui_text(table, "stat_ending"), text(table, ending_id, "title")]))
	return rows


static func crew(path: String = CREW_PATH) -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	for value: Variant in read_json(path).get("crew", []) as Array:
		if value is Dictionary:
			members.append(value)
	return members


static func credits(path: String = CREDITS_PATH) -> Dictionary:
	return read_json(path)


static func credit_lines(data: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	for value: Variant in data.get("sections", []) as Array:
		if not (value is Dictionary):
			continue
		var section: Dictionary = value
		var heading: String = String(section.get("heading", ""))
		if not heading.is_empty():
			lines.append(heading)
		for line: Variant in section.get("lines", []) as Array:
			lines.append(String(line))
	return lines


static func errors(table: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for ending_id: StringName in ENDING_IDS:
		var item: Dictionary = entry(table, ending_id)
		if item.is_empty():
			problems.append("final '%s' ausente" % ending_id)
			continue
		for key: String in ["title", "prompt", "confirm", "confirm_yes", "confirm_no"]:
			if String(item.get(key, "")).is_empty():
				problems.append("%s: campo '%s' vazio" % [ending_id, key])
		for tier: StringName in TIERS:
			if epilogue(table, ending_id, tier).is_empty():
				problems.append("%s: epílogo '%s' vazio" % [ending_id, tier])
		problems.append_array(_cutscene_errors(ending_id, cutscene_events(table, ending_id)))
	return problems


static func _cutscene_errors(ending_id: StringName, events: Array[Dictionary]) -> PackedStringArray:
	var problems := PackedStringArray()
	if count_action(events, EVENT_CUT) != 1:
		problems.append("%s: a cutscene precisa de exatamente um 'cut'" % ending_id)
		return problems
	if String(events[events.size() - 1].get("do", "")) != EVENT_CUT:
		problems.append("%s: o 'cut' tem de ser o último evento" % ending_id)
	var length: float = cutscene_length(events)
	if length < Balance.ENDING_CUTSCENE_MIN_TIME or length > Balance.ENDING_CUTSCENE_MAX_TIME:
		problems.append("%s: cutscene de %.1f s fora da faixa" % [ending_id, length])
	for event: Dictionary in events:
		if not CUTSCENE_ACTIONS.has(String(event.get("do", ""))):
			problems.append("%s: ação '%s' desconhecida" % [ending_id, event.get("do", "")])
	return problems


static func _count(state: Node, property: StringName) -> int:
	if state == null:
		return 0
	var value: Variant = state.get(property)
	return (value as Array).size() if value is Array else 0


static func _float(state: Node, property: StringName) -> float:
	if state == null:
		return 0.0
	var value: Variant = state.get(property)
	return float(value) if value != null else 0.0
