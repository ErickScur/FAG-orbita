class_name SectorRevisit
extends RefCounted

const KEY_BLOCK: String = "revisit"
const KEY_AFTER: String = "after_sector"
const KEY_SPAWN_DOCK: String = "spawn_dock"


static func is_restored(sector_id: StringName, restored: Array) -> bool:
	if sector_id == &"":
		return false
	for value: Variant in restored:
		if StringName(String(value)) == sector_id:
			return true
	return false


static func blocks(meta: Dictionary) -> Array[Dictionary]:
	var raw: Variant = meta.get(KEY_BLOCK, {})
	var found: Array[Dictionary] = []
	if raw is Dictionary:
		found.append(raw as Dictionary)
	elif raw is Array:
		for entry: Variant in raw as Array:
			if entry is Dictionary:
				found.append(entry as Dictionary)
	return found


static func active_block(meta: Dictionary, restored: Array) -> Dictionary:
	var active: Dictionary = {}
	for block: Dictionary in blocks(meta):
		var after: StringName = StringName(String(block.get(KEY_AFTER, "")))
		if is_restored(after, restored):
			active = block
	return active


static func apply(meta: Dictionary, restored: Array) -> Dictionary:
	var result: Dictionary = meta.duplicate(true)
	result.erase(KEY_BLOCK)
	result.erase(KEY_SPAWN_DOCK)
	var block: Dictionary = active_block(meta, restored)
	for key: Variant in block:
		var name: String = String(key)
		if name == KEY_AFTER:
			continue
		result[name] = block[key]
	return result


static func spawn_dock(meta: Dictionary, restored: Array) -> String:
	return String(active_block(meta, restored).get(KEY_SPAWN_DOCK, ""))


static func door_sealed(sealed_until_sector: StringName, restored: Array) -> bool:
	return sealed_until_sector != &"" and not is_restored(sealed_until_sector, restored)


static func door_unsealed(sealed_until_sector: StringName, restored: Array) -> bool:
	return sealed_until_sector != &"" and is_restored(sealed_until_sector, restored)


static func exit_closed(closes_after_sector: StringName, restored: Array) -> bool:
	return is_restored(closes_after_sector, restored)
