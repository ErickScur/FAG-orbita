class_name EnergyNetwork
extends Node

signal overload_changed(terminal_id: StringName, active: bool)

const ENERGY_DIR: String = "res://data/energy/"
const POWERED_GROUP: StringName = &"powered"
const NETWORK_GROUP: StringName = &"energy_network"

var _grids: Dictionary = {}
var _order: Array[StringName] = []
var _pending_bark: StringName = &""
var _last_bark: StringName = &""
var _snapshots: Dictionary = {}


func _ready() -> void:
	add_to_group(NETWORK_GROUP)


func _process(delta: float) -> void:
	for terminal_id: StringName in _order:
		var target: EnergyGrid = grid(terminal_id)
		if target == null or not target.is_overloaded():
			continue
		var shed: Array[StringName] = target.tick_overload(delta)
		if target.is_overloaded():
			continue
		_finish_overload(terminal_id, target, shed)


func can_overload(terminal_id: StringName) -> bool:
	var target: EnergyGrid = grid(terminal_id)
	if target == null or target.is_overloaded():
		return false
	if not GameState.has_ability(UpgradeRules.ROOT_ABILITY):
		return false
	return GameState.charge >= Balance.ROOT_OVERLOAD_COST


func overload(terminal_id: StringName) -> bool:
	if not can_overload(terminal_id):
		AudioManager.play_sfx(&"ui_error")
		return false
	if not GameState.spend_charge(Balance.ROOT_OVERLOAD_COST):
		return false
	grid(terminal_id).start_overload(Balance.ROOT_OVERLOAD_UNITS, Balance.ROOT_OVERLOAD_TIME)
	AudioManager.play_sfx(&"power_on")
	overload_changed.emit(terminal_id, true)
	return true


func end_overload(terminal_id: StringName) -> void:
	var target: EnergyGrid = grid(terminal_id)
	if target == null or not target.is_overloaded():
		return
	_finish_overload(terminal_id, target, target.end_overload())


func is_overloaded(terminal_id: StringName) -> bool:
	var target: EnergyGrid = grid(terminal_id)
	return target != null and target.is_overloaded()


func overload_left(terminal_id: StringName) -> float:
	var target: EnergyGrid = grid(terminal_id)
	if target == null:
		return 0.0
	return target.overload_left


func load_terminals(ids: Array) -> void:
	for value: Variant in ids:
		_load_terminal(StringName(String(value)))


func terminal_ids() -> Array[StringName]:
	return _order.duplicate()


func has_terminal(terminal_id: StringName) -> bool:
	return _grids.has(terminal_id)


func grid(terminal_id: StringName) -> EnergyGrid:
	if not _grids.has(terminal_id):
		return null
	return _grids[terminal_id]


func toggle(terminal_id: StringName, system_id: StringName) -> Dictionary:
	var target: EnergyGrid = grid(terminal_id)
	var empty: Array[StringName] = []
	if target == null:
		return {"result": EnergyGrid.Result.UNKNOWN_SYSTEM, "on": empty, "off": empty}
	var outcome: Dictionary = target.toggle(system_id)
	var switched_on: Array[StringName] = outcome["on"]
	var switched_off: Array[StringName] = outcome["off"]
	if switched_on.is_empty() and switched_off.is_empty():
		AudioManager.play_sfx(&"ui_error")
		return outcome
	AudioManager.play_sfx(&"terminal_breaker")
	for changed: StringName in switched_on:
		_apply_system(terminal_id, target, changed, true, false)
	for changed: StringName in switched_off:
		_apply_system(terminal_id, target, changed, false, false)
	GameState.energy_states[terminal_id] = target.get_state()
	for changed: StringName in switched_on:
		EventBus.energy_changed.emit(terminal_id, changed, true)
	for changed: StringName in switched_off:
		EventBus.energy_changed.emit(terminal_id, changed, false)
	_pending_bark = target.bark_of(system_id, target.is_powered(system_id))
	return outcome


func begin_session(terminal_id: StringName) -> void:
	var target: EnergyGrid = grid(terminal_id)
	if target == null:
		return
	_snapshots[terminal_id] = target.get_state()
	_pending_bark = &""
	if target.intro_bark != &"":
		DialogueManager.play(target.intro_bark)


func announce_change(terminal_id: StringName) -> void:
	var bark: StringName = _pending_bark
	_pending_bark = &""
	var target: EnergyGrid = grid(terminal_id)
	if target == null or bark == &"" or bark == _last_bark:
		return
	var before: Array[StringName] = []
	before.assign(_snapshots.get(terminal_id, []))
	if before == target.get_state():
		return
	_last_bark = bark
	DialogueManager.play(bark)


func pending_bark() -> StringName:
	return _pending_bark


func apply_all(terminal_id: StringName, silent: bool) -> void:
	var target: EnergyGrid = grid(terminal_id)
	if target == null:
		return
	for system_id: StringName in target.system_ids():
		_apply_system(terminal_id, target, system_id, target.is_powered(system_id), silent)


func _finish_overload(
	terminal_id: StringName, target: EnergyGrid, shed: Array[StringName]
) -> void:
	for changed: StringName in shed:
		_apply_system(terminal_id, target, changed, false, false)
	GameState.energy_states[terminal_id] = target.get_state()
	for changed: StringName in shed:
		EventBus.energy_changed.emit(terminal_id, changed, false)
	if not shed.is_empty():
		AudioManager.play_sfx(&"power_off")
	overload_changed.emit(terminal_id, false)


func _load_terminal(terminal_id: StringName) -> void:
	if terminal_id == &"" or _grids.has(terminal_id):
		return
	var path: String = ENERGY_DIR + String(terminal_id) + ".json"
	if not FileAccess.file_exists(path):
		push_error("EnergyNetwork: terminal ausente em %s" % path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("EnergyNetwork: JSON inválido em %s" % path)
		return
	var built: EnergyGrid = EnergyGrid.from_dict(parsed)
	var errors: PackedStringArray = built.validate()
	if not errors.is_empty():
		for message: String in errors:
			push_error("EnergyNetwork (%s): %s" % [terminal_id, message])
		return
	if GameState.energy_states.has(terminal_id):
		built.set_state(GameState.energy_states[terminal_id])
	_grids[terminal_id] = built
	_order.append(terminal_id)
	GameState.energy_states[terminal_id] = built.get_state()
	apply_all(terminal_id, true)


func _apply_system(
	terminal_id: StringName,
	target: EnergyGrid,
	system_id: StringName,
	on: bool,
	silent: bool
) -> void:
	var touched: Array[Node] = []
	for node: Node in _bound_nodes(terminal_id, system_id):
		_drive(node, on, silent, touched)
	for value: Variant in target.effects_of(system_id):
		var effect: Dictionary = value
		var powered: bool = on
		if StringName(effect["action"]) == EnergyGrid.ACTION_INVERT:
			powered = not on
		for node: Node in _effect_nodes(String(effect["target"])):
			_drive(node, powered, silent, touched)


func _bound_nodes(terminal_id: StringName, system_id: StringName) -> Array[Node]:
	var result: Array[Node] = []
	var tree: SceneTree = get_tree()
	if tree == null:
		return result
	for node: Node in tree.get_nodes_in_group(POWERED_GROUP):
		if _name_of(node, &"terminal_id") != terminal_id:
			continue
		if _name_of(node, &"system_id") != system_id:
			continue
		result.append(node)
	return result


func _name_of(node: Node, property: StringName) -> StringName:
	var value: Variant = node.get(property)
	if value == null:
		return &""
	return StringName(String(value))


func _effect_nodes(target: String) -> Array[Node]:
	var result: Array[Node] = []
	var tree: SceneTree = get_tree()
	if tree == null:
		return result
	var separator: int = target.find(":")
	if separator < 0:
		return result
	var prefix: String = target.substr(0, separator + 1)
	var name: String = target.substr(separator + 1).strip_edges()
	if name.is_empty():
		return result
	if prefix == EnergyGrid.TARGET_ID:
		name = EnergyGrid.ENTITY_PREFIX + name
	elif prefix != EnergyGrid.TARGET_GROUP:
		return result
	for node: Node in tree.get_nodes_in_group(StringName(name)):
		result.append(node)
	return result


func _drive(node: Node, on: bool, silent: bool, touched: Array[Node]) -> void:
	if node == null or touched.has(node):
		return
	touched.append(node)
	if silent and node.has_method(&"set_powered_silent"):
		node.call(&"set_powered_silent", on)
		return
	if node.has_method(&"set_powered"):
		node.call(&"set_powered", on)
		return
	push_warning("EnergyNetwork: '%s' não implementa set_powered" % node.name)
