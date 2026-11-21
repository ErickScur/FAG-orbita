class_name UpgradeRules
extends RefCounted

const ROOT_ABILITY: StringName = &"root_access"
const ROOT_DOOR_FLAG_PREFIX: String = "root_door_open_"
const CELL_FULL_WIDTH: int = 16
const CELL_MIN_WIDTH: int = 9
const CELL_GAP: int = 1


static func capacitors_installed(charge_max: float) -> int:
	if Balance.CAPACITOR_BONUS <= 0.0:
		return 0
	return maxi(0, roundi((charge_max - Balance.CHARGE_MAX) / Balance.CAPACITOR_BONUS))


static func plates_installed(integrity_max: int) -> int:
	if Balance.ARMOR_PLATE_BONUS <= 0:
		return 0
	return maxi(0, (integrity_max - Balance.INTEGRITY_MAX) / Balance.ARMOR_PLATE_BONUS)


static func cell_count(integrity_max: int) -> int:
	if integrity_max <= 0 or Balance.INTEGRITY_PER_CELL <= 0:
		return 0
	return maxi(1, ceili(float(integrity_max) / float(Balance.INTEGRITY_PER_CELL)))


static func cell_layout(cells: int, slot_width: int) -> Vector2i:
	if cells <= 0:
		return Vector2i(CELL_FULL_WIDTH, CELL_GAP)
	var gap: int = CELL_GAP
	if cells * CELL_MIN_WIDTH + (cells - 1) * CELL_GAP > slot_width:
		gap = 0
	var width: int = (slot_width + gap) / cells - gap
	return Vector2i(clampi(width, CELL_MIN_WIDTH, CELL_FULL_WIDTH), gap)


static func cells_width(cells: int, slot_width: int) -> int:
	var layout: Vector2i = cell_layout(cells, slot_width)
	return cells * layout.x + maxi(0, cells - 1) * layout.y


static func charge_frame_width(charge_max: float, base_width: float, slot_width: float) -> float:
	var steps: int = Balance.CAPACITORS_TOTAL
	if steps <= 0:
		return base_width
	var installed: int = mini(capacitors_installed(charge_max), steps)
	return roundf(base_width + (slot_width - base_width) * float(installed) / float(steps))


static func door_locked(required: StringName, abilities: Array) -> bool:
	if required == &"":
		return false
	return not abilities.has(required)


static func root_door_flag(door_id: StringName) -> String:
	return ROOT_DOOR_FLAG_PREFIX + String(door_id)
