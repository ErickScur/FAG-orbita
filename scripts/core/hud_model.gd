class_name HudModel
extends RefCounted

const PATH: String = "res://data/hud_texts.json"
const CELL_FULL: int = 0
const CELL_EMPTY: int = 1
const CELL_BLINK: int = 2
const ICON_STATUS_FIRST: int = 5
const ICON_LOG: int = 10
const ICON_RESEARCH: int = 11
const ICON_KEY: int = 12
const STATUS_ICONS: Dictionary = {
	&"corrosion": 5,
	&"overheat": 6,
	&"freeze": 7,
	&"discharge": 8,
	&"overload": 9,
}
const MAX_STATUS_ICONS: int = 4
const STATE_FULL: int = Vitals.FULL_CELL
const STATE_PARTIAL: int = Vitals.PARTIAL_CELL
const STATE_EMPTY: int = Vitals.EMPTY_CELL


static func load_texts(path: String = PATH) -> Dictionary:
	return Objectives.load_all(path)


static func text_for(id: StringName, table: Dictionary) -> String:
	return Objectives.text_for(id, table)


static func cell_states(integrity: int, maximum: int, cells: int) -> Array[int]:
	return Vitals.cell_states(integrity, maximum, cells)


static func is_low_integrity(states: Array[int]) -> bool:
	var alive: int = 0
	for state: int in states:
		if state > STATE_EMPTY:
			alive += 1
	return alive <= 1


static func atlas_cell(index: int, columns: int) -> Vector2i:
	if columns <= 0:
		return Vector2i.ZERO
	return Vector2i(index % columns, index / columns)


static func status_icon_index(status_id: StringName) -> int:
	return int(STATUS_ICONS.get(status_id, ICON_STATUS_FIRST))


static func status_seconds(remaining: float) -> int:
	return maxi(0, ceili(remaining))


static func format_pair(template: String, current: int, total: int) -> String:
	if template.is_empty():
		return "%d/%d" % [current, total]
	return template % [current, total]


static func format_single(template: String, value: int) -> String:
	if template.is_empty():
		return str(value)
	return template % value


static func charge_ratio(current: float, maximum: float) -> float:
	if maximum <= 0.0:
		return 0.0
	return clampf(current / maximum, 0.0, 1.0)
