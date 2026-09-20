class_name PickupRules
extends RefCounted

const KIND_CELL: StringName = &"cell"
const KIND_REPAIR_KIT: StringName = &"repair_kit"
const KIND_LOG: StringName = &"log"
const KIND_RESEARCH: StringName = &"research"
const KIND_CAPACITOR: StringName = &"capacitor"
const KINDS: Array[StringName] = [
	KIND_CELL, KIND_REPAIR_KIT, KIND_LOG, KIND_RESEARCH, KIND_CAPACITOR
]
const SHEET_ROWS: Dictionary = {
	KIND_CELL: 0,
	KIND_REPAIR_KIT: 1,
	KIND_LOG: 2,
	KIND_RESEARCH: 3,
	KIND_CAPACITOR: 4,
}
const SFX_DEFAULT: StringName = &"pickup"
const SFX_BY_KIND: Dictionary = {KIND_LOG: &"log_pickup"}
const COUNTED_KINDS: Array[StringName] = [KIND_LOG, KIND_RESEARCH]


static func is_known(kind: StringName) -> bool:
	return KINDS.has(kind)


static func can_collect(
	kind: StringName, charge: float, charge_max: float, integrity: int, integrity_max: int
) -> bool:
	if not is_known(kind):
		return false
	if kind == KIND_CELL:
		return charge < charge_max
	if kind == KIND_REPAIR_KIT:
		return integrity < integrity_max
	return true


static func sheet_row(kind: StringName) -> int:
	return int(SHEET_ROWS.get(kind, 0))


static func sfx_for(kind: StringName) -> StringName:
	return StringName(SFX_BY_KIND.get(kind, SFX_DEFAULT))


static func amount_for(kind: StringName) -> int:
	match kind:
		KIND_CELL:
			return int(Balance.ENERGY_CELL_CHARGE)
		KIND_REPAIR_KIT:
			return Balance.REPAIR_KIT_INTEGRITY
		KIND_CAPACITOR:
			return int(Balance.CAPACITOR_BONUS)
	return 0


static func counts_toward_score(kind: StringName) -> bool:
	return COUNTED_KINDS.has(kind)


static func default_item_id(level_id: String, kind: StringName, cell: Vector2i) -> StringName:
	return StringName("%s_%s_%d_%d" % [level_id, String(kind), cell.x, cell.y])
