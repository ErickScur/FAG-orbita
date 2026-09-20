class_name StatusEffects
extends RefCounted

const CORROSION: StringName = &"corrosion"
const OVERHEAT: StringName = &"overheat"
const FREEZE: StringName = &"freeze"
const DISCHARGE: StringName = &"discharge"
const OVERLOAD: StringName = &"overload"
const ORDER: Array[StringName] = [CORROSION, OVERHEAT, FREEZE, DISCHARGE, OVERLOAD]
const KEY_DURATION: String = "duration"
const KEY_BLOCKS_CHARGE: String = "blocks_charge_gain"
const KEY_BLOCKS_ABILITIES: String = "blocks_abilities"
const KEY_SPEED: String = "speed_mult"
const KEY_JUMP: String = "jump_mult"
const KEY_CHARGE_DRAIN: String = "charge_drain_mult"
const KEY_INTEGRITY_DPS: String = "integrity_dps"
const KEY_SLIPPERY: String = "slippery"
const WHILE_EXPOSED: float = 0.0

static var _definitions: Dictionary = _build_definitions()

var _active: Dictionary = {}


static func definitions() -> Dictionary:
	return _definitions


static func definition(status_id: StringName) -> Dictionary:
	return _definitions.get(status_id, {})


static func is_known(status_id: StringName) -> bool:
	return _definitions.has(status_id)


static func default_duration(status_id: StringName) -> float:
	var entry: Dictionary = definition(status_id)
	var value: float = float(entry.get(KEY_DURATION, WHILE_EXPOSED))
	if value > 0.0:
		return value
	return Balance.STATUS_EXPOSURE_GRACE


static func lasts_while_exposed(status_id: StringName) -> bool:
	return float(definition(status_id).get(KEY_DURATION, WHILE_EXPOSED)) <= 0.0


func apply(status_id: StringName, duration: float = -1.0) -> bool:
	if not is_known(status_id):
		return false
	var wanted: float = duration if duration >= 0.0 else default_duration(status_id)
	if wanted <= 0.0:
		return false
	var fresh: bool = not _active.has(status_id)
	_active[status_id] = maxf(remaining(status_id), wanted)
	return fresh


func clear(status_id: StringName) -> bool:
	if not _active.has(status_id):
		return false
	_active.erase(status_id)
	return true


func clear_all() -> Array[StringName]:
	var cleared: Array[StringName] = active_ids()
	_active.clear()
	return cleared


func tick(delta: float) -> Array[StringName]:
	var expired: Array[StringName] = []
	if delta <= 0.0:
		return expired
	for status_id: StringName in active_ids():
		var left: float = float(_active[status_id]) - delta
		if left > 0.0:
			_active[status_id] = left
			continue
		_active.erase(status_id)
		expired.append(status_id)
	return expired


func has(status_id: StringName) -> bool:
	return _active.has(status_id)


func remaining(status_id: StringName) -> float:
	return float(_active.get(status_id, 0.0))


func active_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for status_id: StringName in ORDER:
		if _active.has(status_id):
			ids.append(status_id)
	return ids


func is_empty() -> bool:
	return _active.is_empty()


func blocks_charge_gain() -> bool:
	return _any_flag(KEY_BLOCKS_CHARGE)


func blocks_abilities() -> bool:
	return _any_flag(KEY_BLOCKS_ABILITIES)


func is_slippery() -> bool:
	return _any_flag(KEY_SLIPPERY)


func speed_multiplier() -> float:
	return _product(KEY_SPEED)


func jump_multiplier() -> float:
	return _product(KEY_JUMP)


func charge_drain_multiplier() -> float:
	return _product(KEY_CHARGE_DRAIN)


func integrity_dps() -> float:
	var total: float = 0.0
	for status_id: StringName in active_ids():
		total += float(definition(status_id).get(KEY_INTEGRITY_DPS, 0.0))
	return total


func _any_flag(key: String) -> bool:
	for status_id: StringName in active_ids():
		if bool(definition(status_id).get(key, false)):
			return true
	return false


func _product(key: String) -> float:
	var value: float = 1.0
	for status_id: StringName in active_ids():
		value *= float(definition(status_id).get(key, 1.0))
	return value


static func _build_definitions() -> Dictionary:
	return {
		CORROSION: {
			KEY_DURATION: Balance.CORROSION_TIME,
			KEY_BLOCKS_CHARGE: true,
		},
		OVERHEAT: {
			KEY_DURATION: WHILE_EXPOSED,
			KEY_INTEGRITY_DPS: Balance.OVERHEAT_DPS,
			KEY_CHARGE_DRAIN: Balance.OVERHEAT_CHARGE_MULT,
		},
		FREEZE: {
			KEY_DURATION: WHILE_EXPOSED,
			KEY_SPEED: Balance.FREEZE_SPEED_MULT,
			KEY_JUMP: Balance.FREEZE_JUMP_MULT,
			KEY_SLIPPERY: true,
		},
		DISCHARGE: {
			KEY_DURATION: Balance.DISCHARGE_TIME,
			KEY_BLOCKS_ABILITIES: true,
		},
		OVERLOAD: {
			KEY_DURATION: Balance.OVERLOAD_TIME,
			KEY_SPEED: Balance.OVERLOAD_SPEED_MULT,
		},
	}
