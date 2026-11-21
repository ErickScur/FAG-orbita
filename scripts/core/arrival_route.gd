class_name ArrivalRoute
extends RefCounted

const KEY_ENTITIES: String = "entities"
const KEY_RESERVED: String = "reserved_exits"
const KEY_TARGET: String = "target"
const KEY_ID: String = "id"


static func exit_toward(meta: Dictionary, origin_scene: String) -> String:
	if origin_scene.is_empty():
		return ""
	var entities: Variant = meta.get(KEY_ENTITIES, {})
	if not (entities is Dictionary):
		return ""
	for key: Variant in entities as Dictionary:
		var params: Variant = (entities as Dictionary)[key]
		if not (params is Dictionary):
			continue
		if String((params as Dictionary).get(KEY_TARGET, "")) == origin_scene:
			return String((params as Dictionary).get(KEY_ID, ""))
	return ""


static func exits(meta: Dictionary) -> Dictionary:
	var found: Dictionary = {}
	var entities: Variant = meta.get(KEY_ENTITIES, {})
	if not (entities is Dictionary):
		return found
	for key: Variant in entities as Dictionary:
		var params: Variant = (entities as Dictionary)[key]
		if params is Dictionary and (params as Dictionary).has(KEY_TARGET):
			found[String(key)] = params
	return found


static func reserved_exits(meta: Dictionary) -> Dictionary:
	var raw: Variant = meta.get(KEY_RESERVED, {})
	return raw if raw is Dictionary else {}


static func next_origin(previous_level: String, entering_level: String) -> String:
	if previous_level == entering_level:
		return ""
	return previous_level
