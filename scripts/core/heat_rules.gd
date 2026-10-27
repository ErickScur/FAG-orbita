class_name HeatRules
extends RefCounted

const ABILITY_ID: StringName = &"heat_sink"
const KIND_WARM: StringName = &"warm"
const KIND_FURNACE: StringName = &"furnace"


static func normalize_kind(kind: StringName) -> StringName:
	return KIND_FURNACE if kind == KIND_FURNACE else KIND_WARM


static func overheats(in_heat: bool, cooled: bool) -> bool:
	return in_heat and not cooled


static func furnace_dps(kind: StringName, in_heat: bool, cooled: bool) -> float:
	if not overheats(in_heat, cooled) or normalize_kind(kind) != KIND_FURNACE:
		return 0.0
	return Balance.FURNACE_DPS


static func total_dps(status_dps: float, furnace: float, has_heat_sink: bool) -> float:
	var total: float = maxf(0.0, status_dps) + maxf(0.0, furnace)
	if has_heat_sink:
		total *= Balance.HEAT_SINK_DAMAGE_MULT
	return total


static func exposure_dps(
	in_heat: bool, kind: StringName, cooled: bool, has_heat_sink: bool
) -> float:
	var status: float = Balance.OVERHEAT_DPS if overheats(in_heat, cooled) else 0.0
	return total_dps(status, furnace_dps(kind, in_heat, cooled), has_heat_sink)


static func has_heat_sink(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)
