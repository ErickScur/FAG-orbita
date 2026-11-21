class_name FirewallLogic
extends RefCounted

var luto_system: StringName = &""
var delay: float = 0.0

var _session_open: bool = false
var _powered_in_session: Array[StringName] = []
var _pending: StringName = &""
var _left: float = 0.0
var _acting: bool = false


static func create(luto: StringName, swap_delay: float) -> FirewallLogic:
	var logic := FirewallLogic.new()
	logic.luto_system = luto
	logic.delay = swap_delay
	return logic


static func swap_plan(grid: EnergyGrid, target: StringName, luto: StringName) -> Array[StringName]:
	var plan: Array[StringName] = []
	if grid == null or target == &"" or target == luto or not grid.is_powered(target):
		return plan
	plan.append(target)
	var saved: Array[StringName] = grid.get_state()
	grid.power_off(target)
	if luto != &"" and grid.can_power(luto) == EnergyGrid.Result.OK:
		plan.append(luto)
	grid.set_state(saved)
	return plan


func is_session_open() -> bool:
	return _session_open


func begin_session() -> void:
	_session_open = true
	_powered_in_session.clear()


func note_change(system_id: StringName, on: bool) -> void:
	if _acting or not _session_open or system_id == luto_system:
		return
	_powered_in_session.erase(system_id)
	if on:
		_powered_in_session.append(system_id)


func last_powered() -> StringName:
	if _powered_in_session.is_empty():
		return &""
	return _powered_in_session[_powered_in_session.size() - 1]


func end_session() -> StringName:
	if not _session_open:
		return &""
	_session_open = false
	var target: StringName = last_powered()
	_powered_in_session.clear()
	if target == &"":
		return &""
	_pending = target
	_left = delay
	return target


func pending() -> StringName:
	return _pending


func time_left() -> float:
	return _left


func cancel() -> void:
	_pending = &""
	_left = 0.0
	_session_open = false
	_powered_in_session.clear()


func tick(delta: float) -> StringName:
	if _pending == &"":
		return &""
	_left = maxf(0.0, _left - delta)
	if _left > 0.0:
		return &""
	var target: StringName = _pending
	_pending = &""
	return target


func begin_acting() -> void:
	_acting = true


func end_acting() -> void:
	_acting = false
