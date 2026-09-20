class_name EnergyGrid
extends RefCounted

enum Result { OK, NO_BUDGET, MISSING_DEPENDENCY, UNKNOWN_SYSTEM, ALREADY_ON, ALREADY_OFF, LOCKED }

const ACTION_POWER: StringName = &"power"
const ACTION_INVERT: StringName = &"invert"
const TARGET_GROUP: String = "group:"
const TARGET_ID: String = "id:"
const ENTITY_PREFIX: String = "entity:"

var id: StringName = &""
var title: String = ""
var budget: int = 0
var goal_text: String = ""
var goal_done_text: String = ""
var intro_bark: StringName = &""
var systems: Array[Dictionary] = []

var _goal: Array[StringName] = []
var _order: Array[StringName] = []
var _index: Dictionary = {}
var _powered: Dictionary = {}
var _initial: Array[StringName] = []


static func from_dict(data: Dictionary) -> EnergyGrid:
	var grid := EnergyGrid.new()
	grid.id = StringName(String(data.get("id", "")))
	grid.title = String(data.get("title", ""))
	grid.budget = int(data.get("budget", 0))
	grid.goal_text = String(data.get("goal_text", ""))
	grid.goal_done_text = String(data.get("goal_done_text", ""))
	grid.intro_bark = StringName(String(data.get("intro_bark", "")))
	for value: Variant in data.get("goal_systems", []) as Array:
		var goal_id := StringName(String(value))
		if not grid._goal.has(goal_id):
			grid._goal.append(goal_id)
	for value: Variant in data.get("systems", []) as Array:
		if not (value is Dictionary):
			continue
		grid._add_system(value)
	for value: Variant in data.get("initial", []) as Array:
		var system_id := StringName(String(value))
		if not grid._initial.has(system_id):
			grid._initial.append(system_id)
	grid.reset_to_initial()
	return grid


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id == &"":
		errors.append("terminal sem 'id'")
	if title.strip_edges().is_empty():
		errors.append("terminal '%s' sem 'title'" % id)
	if budget < 1:
		errors.append("terminal '%s': orçamento %d deve ser >= 1" % [id, budget])
	errors.append_array(_validate_goal())
	if systems.is_empty():
		errors.append("terminal '%s' sem sistemas" % id)
	var seen: Dictionary = {}
	var total_cost: int = 0
	for entry: Dictionary in systems:
		var system_id: StringName = entry["id"]
		if system_id == &"":
			errors.append("terminal '%s': sistema sem 'id'" % id)
		elif seen.has(system_id):
			errors.append("terminal '%s': id repetido '%s'" % [id, system_id])
		seen[system_id] = true
		if String(entry["name"]).strip_edges().is_empty():
			errors.append("terminal '%s': sistema '%s' sem 'name'" % [id, system_id])
		if String(entry["description"]).strip_edges().is_empty():
			errors.append("terminal '%s': sistema '%s' sem 'description'" % [id, system_id])
		if String(entry["tag"]).strip_edges().is_empty():
			errors.append("terminal '%s': sistema '%s' sem 'tag'" % [id, system_id])
		if String(entry["effect_off"]).strip_edges().is_empty():
			errors.append("terminal '%s': sistema '%s' sem 'effect_off'" % [id, system_id])
		var cost: int = entry["cost"]
		if cost < 1:
			errors.append("terminal '%s': custo de '%s' deve ser >= 1" % [id, system_id])
		total_cost += maxi(cost, 0)
		errors.append_array(_validate_requires(entry))
		errors.append_array(_validate_effects(entry))
	if not systems.is_empty() and total_cost <= budget:
		errors.append(
			"terminal '%s' sem escassez: soma dos custos (%d) deve ser maior que o orçamento (%d)"
			% [id, total_cost, budget]
		)
	errors.append_array(_validate_cycles())
	errors.append_array(_validate_initial())
	return errors


func system(system_id: StringName) -> Dictionary:
	var position: int = int(_index.get(system_id, -1))
	if position < 0:
		return {}
	return systems[position]


func system_ids() -> Array[StringName]:
	return _order.duplicate()


func has_system(system_id: StringName) -> bool:
	return _index.has(system_id)


func system_name(system_id: StringName) -> String:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return String(system_id)
	return String(entry["name"])


func system_description(system_id: StringName) -> String:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return ""
	return String(entry["description"])


func tag_of(system_id: StringName) -> String:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return ""
	return String(entry["tag"])


func effect_off_of(system_id: StringName) -> String:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return ""
	return String(entry["effect_off"])


func bark_of(system_id: StringName, powered: bool) -> StringName:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return &""
	return entry["bark_on"] if powered else entry["bark_off"]


func goal_systems() -> Array[StringName]:
	return _goal.duplicate()


func goal_met() -> bool:
	if _goal.is_empty():
		return false
	for goal_id: StringName in _goal:
		if not _powered.has(goal_id):
			return false
	return true


func goal_line() -> String:
	return goal_done_text if goal_met() else goal_text


func cost_of(system_id: StringName) -> int:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return 0
	return int(entry["cost"])


func requires_of(system_id: StringName) -> Array[StringName]:
	var entry: Dictionary = system(system_id)
	var result: Array[StringName] = []
	if entry.is_empty():
		return result
	result.assign(entry["requires"])
	return result


func effects_of(system_id: StringName) -> Array:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return []
	return entry["effects"]


func is_locked(system_id: StringName) -> bool:
	var entry: Dictionary = system(system_id)
	if entry.is_empty():
		return false
	return bool(entry["locked"])


func is_powered(system_id: StringName) -> bool:
	return _powered.has(system_id)


func powered() -> Array[StringName]:
	var result: Array[StringName] = []
	for system_id: StringName in _order:
		if _powered.has(system_id):
			result.append(system_id)
	return result


func used() -> int:
	var total: int = 0
	for system_id: StringName in _order:
		if _powered.has(system_id):
			total += cost_of(system_id)
	return total


func free_units() -> int:
	return budget - used()


func missing_requirement(system_id: StringName) -> StringName:
	for required: StringName in requires_of(system_id):
		if not _powered.has(required):
			return required
	return &""


func can_power(system_id: StringName) -> Result:
	if not _index.has(system_id):
		return Result.UNKNOWN_SYSTEM
	if _powered.has(system_id):
		return Result.ALREADY_ON
	if is_locked(system_id):
		return Result.LOCKED
	if missing_requirement(system_id) != &"":
		return Result.MISSING_DEPENDENCY
	if cost_of(system_id) > free_units():
		return Result.NO_BUDGET
	return Result.OK


func can_unpower(system_id: StringName) -> Result:
	if not _index.has(system_id):
		return Result.UNKNOWN_SYSTEM
	if not _powered.has(system_id):
		return Result.ALREADY_OFF
	if is_locked(system_id):
		return Result.LOCKED
	return Result.OK


func power_on(system_id: StringName) -> Array[StringName]:
	var changed: Array[StringName] = []
	if can_power(system_id) != Result.OK:
		return changed
	_powered[system_id] = true
	changed.append(system_id)
	return changed


func power_off(system_id: StringName) -> Array[StringName]:
	var changed: Array[StringName] = []
	if can_unpower(system_id) != Result.OK:
		return changed
	_powered.erase(system_id)
	changed.append(system_id)
	var scanning: bool = true
	while scanning:
		scanning = false
		for candidate: StringName in _order:
			if not _powered.has(candidate):
				continue
			if missing_requirement(candidate) == &"":
				continue
			_powered.erase(candidate)
			changed.append(candidate)
			scanning = true
	return changed


func toggle(system_id: StringName) -> Dictionary:
	var on: Array[StringName] = []
	var off: Array[StringName] = []
	if not _index.has(system_id):
		return {"result": Result.UNKNOWN_SYSTEM, "on": on, "off": off}
	if is_locked(system_id):
		return {"result": Result.LOCKED, "on": on, "off": off}
	if _powered.has(system_id):
		off = power_off(system_id)
		return {"result": Result.OK, "on": on, "off": off}
	var reason: Result = can_power(system_id)
	if reason != Result.OK:
		return {"result": reason, "on": on, "off": off}
	on = power_on(system_id)
	return {"result": Result.OK, "on": on, "off": off}


func shutdown_candidates(system_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if can_power(system_id) != Result.NO_BUDGET:
		return result
	var chain: Dictionary = _required_closure(system_id)
	var saved: Array[StringName] = get_state()
	for candidate: StringName in _order:
		if candidate == system_id or not _powered.has(candidate):
			continue
		if chain.has(candidate) or is_locked(candidate):
			continue
		power_off(candidate)
		if can_power(system_id) == Result.OK:
			result.append(candidate)
		set_state(saved)
	return result


func dependents_of(system_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for candidate: StringName in _order:
		if requires_of(candidate).has(system_id):
			result.append(candidate)
	return result


func set_state(ids: Array) -> void:
	var wanted: Dictionary = {}
	for value: Variant in ids:
		var system_id := StringName(String(value))
		if _index.has(system_id):
			wanted[system_id] = true
	_powered.clear()
	var scanning: bool = true
	while scanning:
		scanning = false
		for system_id: StringName in _order:
			if not wanted.has(system_id) or _powered.has(system_id):
				continue
			if can_power(system_id) != Result.OK:
				continue
			_powered[system_id] = true
			scanning = true


func get_state() -> Array[StringName]:
	return powered()


func initial_state() -> Array[StringName]:
	return _initial.duplicate()


func reset_to_initial() -> void:
	set_state(_initial)


func _add_system(raw: Dictionary) -> void:
	var system_id := StringName(String(raw.get("id", "")))
	var requires: Array[StringName] = []
	for value: Variant in raw.get("requires", []) as Array:
		requires.append(StringName(String(value)))
	var effects: Array = []
	for value: Variant in raw.get("effects", []) as Array:
		if value is Dictionary:
			effects.append(
				{
					"target": String((value as Dictionary).get("target", "")),
					"action": StringName(String((value as Dictionary).get("action", "power"))),
				}
			)
	var entry: Dictionary = {
		"id": system_id,
		"name": String(raw.get("name", "")),
		"description": String(raw.get("description", "")),
		"tag": String(raw.get("tag", "")),
		"effect_off": String(raw.get("effect_off", "")),
		"bark_on": StringName(String(raw.get("bark_on", ""))),
		"bark_off": StringName(String(raw.get("bark_off", ""))),
		"cost": int(raw.get("cost", 1)),
		"requires": requires,
		"locked": bool(raw.get("locked", false)),
		"effects": effects,
	}
	if _index.has(system_id):
		systems.append(entry)
		return
	_index[system_id] = systems.size()
	_order.append(system_id)
	systems.append(entry)


func _required_closure(system_id: StringName) -> Dictionary:
	var found: Dictionary = {}
	var pending: Array[StringName] = [system_id]
	while not pending.is_empty():
		var current: StringName = pending.pop_back()
		for required: StringName in requires_of(current):
			if found.has(required):
				continue
			found[required] = true
			pending.append(required)
	return found


func _validate_goal() -> PackedStringArray:
	var errors: PackedStringArray = []
	if goal_text.strip_edges().is_empty():
		errors.append("terminal '%s' sem 'goal_text'" % id)
	if goal_done_text.strip_edges().is_empty():
		errors.append("terminal '%s' sem 'goal_done_text'" % id)
	if _goal.is_empty():
		errors.append("terminal '%s' sem 'goal_systems'" % id)
	for goal_id: StringName in _goal:
		if not _index.has(goal_id):
			errors.append("terminal '%s': meta '%s' inexistente" % [id, goal_id])
	return errors


func _validate_requires(entry: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var system_id: StringName = entry["id"]
	var requires: Array[StringName] = []
	requires.assign(entry["requires"])
	for required: StringName in requires:
		if required == system_id:
			errors.append("terminal '%s': sistema '%s' depende de si mesmo" % [id, system_id])
		elif not _index.has(required):
			errors.append(
				"terminal '%s': sistema '%s' depende de '%s' inexistente"
				% [id, system_id, required]
			)
	return errors


func _validate_effects(entry: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var system_id: StringName = entry["id"]
	for value: Variant in entry["effects"] as Array:
		var effect: Dictionary = value
		var target: String = String(effect["target"])
		if not target.begins_with(TARGET_GROUP) and not target.begins_with(TARGET_ID):
			errors.append(
				"terminal '%s': alvo '%s' de '%s' precisa começar com 'group:' ou 'id:'"
				% [id, target, system_id]
			)
		elif target.substr(target.find(":") + 1).strip_edges().is_empty():
			errors.append("terminal '%s': alvo vazio em '%s'" % [id, system_id])
		var action: StringName = effect["action"]
		if action != ACTION_POWER and action != ACTION_INVERT:
			errors.append(
				"terminal '%s': ação '%s' de '%s' precisa ser 'power' ou 'invert'"
				% [id, action, system_id]
			)
	return errors


func _validate_cycles() -> PackedStringArray:
	var errors: PackedStringArray = []
	var state: Dictionary = {}
	for system_id: StringName in _order:
		if int(state.get(system_id, 0)) != 0:
			continue
		if _visit(system_id, state):
			errors.append("terminal '%s': ciclo de dependência em '%s'" % [id, system_id])
	return errors


func _visit(system_id: StringName, state: Dictionary) -> bool:
	state[system_id] = 1
	for required: StringName in requires_of(system_id):
		if not _index.has(required):
			continue
		var mark: int = int(state.get(required, 0))
		if mark == 1:
			return true
		if mark == 0 and _visit(required, state):
			return true
	state[system_id] = 2
	return false


func _validate_initial() -> PackedStringArray:
	var errors: PackedStringArray = []
	var cost: int = 0
	var applied: Dictionary = {}
	for system_id: StringName in _initial:
		if not _index.has(system_id):
			errors.append("terminal '%s': estado inicial '%s' inexistente" % [id, system_id])
			continue
		if applied.has(system_id):
			errors.append("terminal '%s': estado inicial repete '%s'" % [id, system_id])
			continue
		applied[system_id] = true
		cost += cost_of(system_id)
	if cost > budget:
		errors.append(
			"terminal '%s': estado inicial usa %d de %d unidades" % [id, cost, budget]
		)
	for system_id: StringName in _initial:
		if not _index.has(system_id):
			continue
		for required: StringName in requires_of(system_id):
			if not applied.has(required):
				errors.append(
					"terminal '%s': estado inicial liga '%s' sem '%s'"
					% [id, system_id, required]
				)
	return errors
