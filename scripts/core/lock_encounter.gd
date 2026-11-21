class_name LockEncounter
extends RefCounted

enum Phase { DORMANT, WAKING, ACTIVE, STAGGER, DEFEATED, CONTAINED, FROZEN }
enum Arm { IDLE, HUNT, WINDUP, HOLD, REST, RUSH, WELD, OFF }

const EVENT_SEAL_ENTRY: StringName = &"seal_entry"
const EVENT_ARMED: StringName = &"armed"
const EVENT_WINDUP: StringName = &"windup"
const EVENT_SEAL: StringName = &"seal"
const EVENT_UNSEAL: StringName = &"unseal"
const EVENT_CHARGE_LOST: StringName = &"charge_lost"
const EVENT_POWERED: StringName = &"powered"
const EVENT_STAGGER: StringName = &"stagger"
const EVENT_STAGE: StringName = &"stage"
const EVENT_SPAWN: StringName = &"spawn"
const EVENT_DEFEATED: StringName = &"defeated"
const EVENT_CONTAINED: StringName = &"contained"
const EVENT_RESET: StringName = &"reset"
const STAGE_GATE: int = 1
const STAGE_VENT: int = 2
const LAMP_OFF: int = 0
const LAMP_AMBER: int = 1
const LAMP_RED: int = 2
const MIN_SPAWN_INTERVAL: float = 1.0

var phase: Phase = Phase.DORMANT
var arm_state: Arm = Arm.IDLE
var arm_x: float = 0.0
var arm_target: StringName = &""
var time_left: float = Balance.LOCK_TIME_LIMIT
var stage: int = 0
var spawn_count: int = 0

var _order: Array[StringName] = []
var _couplers: Dictionary = {}
var _park_x: float = 0.0
var _anchors: Dictionary = {}
var _bays: int = 0
var _phase_left: float = 0.0
var _arm_left: float = 0.0
var _spawn_left: float = 0.0
var _events: Array[Dictionary] = []


func setup(coupler_x: Dictionary, park_x: float, anchors: Dictionary, bays: int) -> void:
	_order.clear()
	_couplers.clear()
	for key: Variant in coupler_x:
		var id := StringName(String(key))
		_order.append(id)
		_couplers[id] = {
			"x": float(coupler_x[key]), "progress": 0.0, "sealed": false, "powered": false
		}
	_park_x = park_x
	_anchors = anchors.duplicate()
	_bays = maxi(0, bays)
	_restore()


func reset() -> Array[Dictionary]:
	_events.clear()
	if phase == Phase.DEFEATED:
		return _take()
	_restore()
	_emit(EVENT_RESET)
	return _take()


func start() -> Array[Dictionary]:
	_events.clear()
	if phase != Phase.DORMANT:
		return _take()
	phase = Phase.WAKING
	_phase_left = Balance.LOCK_WAKE_TIME
	_emit(EVENT_SEAL_ENTRY)
	return _take()


func freeze() -> void:
	if phase == Phase.DORMANT or phase == Phase.DEFEATED:
		return
	phase = Phase.FROZEN


func defeat_instantly() -> void:
	for id: StringName in _order:
		var coupler: Dictionary = _couplers[id]
		coupler["powered"] = true
		coupler["sealed"] = false
		coupler["progress"] = 1.0
	stage = _order.size()
	phase = Phase.DEFEATED
	arm_state = Arm.OFF
	arm_target = &""


func tick(
	delta: float, player_x: float, holding: Dictionary, alive: int, clock_running: bool
) -> Array[Dictionary]:
	_events.clear()
	match phase:
		Phase.WAKING:
			_tick_waking(delta)
		Phase.ACTIVE, Phase.STAGGER:
			_tick_fight(delta, player_x, holding, alive, clock_running)
	return _take()


func is_running() -> bool:
	return phase == Phase.WAKING or phase == Phase.ACTIVE or phase == Phase.STAGGER


func is_defeated() -> bool:
	return phase == Phase.DEFEATED


func coupler_ids() -> Array[StringName]:
	return _order.duplicate()


func coupler_x(id: StringName) -> float:
	return float((_couplers.get(id, {}) as Dictionary).get("x", 0.0))


func progress(id: StringName) -> float:
	return float((_couplers.get(id, {}) as Dictionary).get("progress", 0.0))


func is_sealed(id: StringName) -> bool:
	return bool((_couplers.get(id, {}) as Dictionary).get("sealed", false))


func is_powered(id: StringName) -> bool:
	return bool((_couplers.get(id, {}) as Dictionary).get("powered", false))


func powered_count() -> int:
	var count: int = 0
	for id: StringName in _order:
		if is_powered(id):
			count += 1
	return count


func spawn_interval() -> float:
	var interval: float = Balance.LOCK_SPAWN_INTERVAL - Balance.LOCK_SPAWN_STEP * powered_count()
	return maxf(MIN_SPAWN_INTERVAL, interval)


func contention_ratio() -> float:
	if Balance.LOCK_TIME_LIMIT <= 0.0:
		return 1.0
	return clampf(1.0 - time_left / Balance.LOCK_TIME_LIMIT, 0.0, 1.0)


func lamp_states(count: int) -> PackedInt32Array:
	var states := PackedInt32Array()
	states.resize(maxi(0, count))
	if phase == Phase.DORMANT or phase == Phase.DEFEATED:
		states.fill(LAMP_OFF)
		return states
	if phase == Phase.CONTAINED:
		states.fill(LAMP_RED)
		return states
	states.fill(LAMP_AMBER)
	var red: int = int(floor(contention_ratio() * count))
	for rank: int in range(mini(red, count)):
		states[lamp_by_rank(rank, count)] = LAMP_RED
	return states


static func lamp_by_rank(rank: int, count: int) -> int:
	var side: int = rank / 2
	if rank % 2 == 0:
		return side
	return count - 1 - side


func _restore() -> void:
	phase = Phase.DORMANT
	arm_state = Arm.IDLE
	arm_x = _park_x
	arm_target = &""
	time_left = Balance.LOCK_TIME_LIMIT
	stage = 0
	spawn_count = 0
	_phase_left = 0.0
	_arm_left = 0.0
	_spawn_left = 0.0
	for id: StringName in _order:
		var coupler: Dictionary = _couplers[id]
		coupler["progress"] = 0.0
		coupler["sealed"] = false
		coupler["powered"] = false


func _tick_waking(delta: float) -> void:
	_phase_left -= delta
	if _phase_left > 0.0:
		return
	phase = Phase.ACTIVE
	_spawn_left = Balance.LOCK_FIRST_SPAWN
	_emit(EVENT_ARMED)


func _tick_fight(
	delta: float, player_x: float, holding: Dictionary, alive: int, clock_running: bool
) -> void:
	if clock_running:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			_contain()
			return
	_tick_couplers(delta, holding)
	if phase == Phase.DEFEATED:
		return
	if phase == Phase.STAGGER:
		_phase_left -= delta
		if _phase_left <= 0.0:
			phase = Phase.ACTIVE
			_begin_rush()
	else:
		_tick_arm(delta, player_x)
	_tick_spawn(delta, alive)


func _tick_couplers(delta: float, holding: Dictionary) -> void:
	for id: StringName in _order:
		var coupler: Dictionary = _couplers[id]
		if bool(coupler["powered"]):
			continue
		var held: bool = bool(holding.get(id, holding.get(String(id), false)))
		if held and not bool(coupler["sealed"]):
			var gained: float = float(coupler["progress"]) + delta / Balance.LOCK_CHARGE_TIME
			coupler["progress"] = minf(1.0, gained)
			if float(coupler["progress"]) >= 1.0:
				_power(id)
				if phase == Phase.DEFEATED:
					return
			continue
		var lost: float = float(coupler["progress"]) - Balance.LOCK_CHARGE_DECAY * delta
		coupler["progress"] = maxf(0.0, lost)


func _power(id: StringName) -> void:
	var coupler: Dictionary = _couplers[id]
	coupler["powered"] = true
	coupler["progress"] = 1.0
	coupler["sealed"] = false
	_emit(EVENT_POWERED, {"id": id})
	_release_arm()
	if powered_count() >= _order.size():
		_defeat()
		return
	stage = powered_count()
	phase = Phase.STAGGER
	_phase_left = Balance.LOCK_STAGGER_TIME
	arm_state = Arm.IDLE
	_emit(EVENT_STAGGER, {"stage": stage})


func _release_arm() -> void:
	if arm_state == Arm.HOLD and arm_target != &"" and is_sealed(arm_target):
		(_couplers[arm_target] as Dictionary)["sealed"] = false
		_emit(EVENT_UNSEAL, {"id": arm_target})
	arm_target = &""
	arm_state = Arm.IDLE
	_arm_left = 0.0


func _defeat() -> void:
	phase = Phase.DEFEATED
	arm_state = Arm.OFF
	arm_target = &""
	for id: StringName in _order:
		(_couplers[id] as Dictionary)["sealed"] = false
	_emit(EVENT_DEFEATED)


func _contain() -> void:
	phase = Phase.CONTAINED
	arm_state = Arm.HOLD
	for id: StringName in _order:
		var coupler: Dictionary = _couplers[id]
		if bool(coupler["powered"]):
			continue
		coupler["sealed"] = true
		coupler["progress"] = 0.0
	_emit(EVENT_CONTAINED)


func _begin_rush() -> void:
	if not _anchors.has(stage):
		arm_state = Arm.IDLE
		return
	arm_state = Arm.RUSH
	arm_target = &""


func _tick_arm(delta: float, player_x: float) -> void:
	match arm_state:
		Arm.IDLE, Arm.HUNT:
			_hunt(delta, player_x)
		Arm.WINDUP:
			_arm_left -= delta
			if _arm_left <= 0.0:
				_seal_target()
		Arm.HOLD:
			_arm_left -= delta
			if _arm_left <= 0.0:
				_unseal_target()
		Arm.REST, Arm.WELD:
			_arm_left -= delta
			if _arm_left <= 0.0:
				arm_state = Arm.IDLE
		Arm.RUSH:
			_rush(delta)


func _hunt(delta: float, player_x: float) -> void:
	var target: StringName = _nearest_open(player_x)
	if target == &"":
		arm_state = Arm.IDLE
		arm_target = &""
		return
	arm_target = target
	arm_state = Arm.HUNT
	var goal: float = coupler_x(target)
	arm_x = move_toward(arm_x, goal, Balance.LOCK_ARM_SPEED * delta)
	if absf(arm_x - goal) > Balance.LOCK_ARM_ALIGN:
		return
	arm_x = goal
	arm_state = Arm.WINDUP
	_arm_left = Balance.LOCK_SEAL_WINDUP
	_emit(EVENT_WINDUP, {"id": target})


func _seal_target() -> void:
	var coupler: Dictionary = _couplers.get(arm_target, {})
	if coupler.is_empty() or bool(coupler["powered"]):
		arm_state = Arm.IDLE
		return
	if float(coupler["progress"]) > 0.0:
		_emit(EVENT_CHARGE_LOST, {"id": arm_target})
	coupler["progress"] = 0.0
	coupler["sealed"] = true
	arm_state = Arm.HOLD
	_arm_left = Balance.LOCK_SEAL_TIME
	_emit(EVENT_SEAL, {"id": arm_target})


func _unseal_target() -> void:
	var coupler: Dictionary = _couplers.get(arm_target, {})
	if not coupler.is_empty():
		coupler["sealed"] = false
		_emit(EVENT_UNSEAL, {"id": arm_target})
	arm_target = &""
	arm_state = Arm.REST
	_arm_left = Balance.LOCK_ARM_REST


func _rush(delta: float) -> void:
	var goal: float = float(_anchors.get(stage, arm_x))
	arm_x = move_toward(arm_x, goal, Balance.LOCK_ARM_RUSH_SPEED * delta)
	if absf(arm_x - goal) > Balance.LOCK_ARM_ALIGN:
		return
	arm_x = goal
	arm_state = Arm.WELD
	_arm_left = Balance.LOCK_WELD_TIME
	_emit(EVENT_STAGE, {"stage": stage, "x": arm_x})


func _nearest_open(player_x: float) -> StringName:
	var best: StringName = &""
	var best_distance: float = INF
	for id: StringName in _order:
		if is_powered(id) or is_sealed(id):
			continue
		var distance: float = absf(coupler_x(id) - player_x)
		if distance < best_distance:
			best = id
			best_distance = distance
	return best


func _tick_spawn(delta: float, alive: int) -> void:
	if _bays <= 0:
		return
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return
	if alive >= Balance.LOCK_SR3_MAX:
		_spawn_left = 0.0
		return
	_emit(EVENT_SPAWN, {"bay": spawn_count % _bays})
	spawn_count += 1
	_spawn_left = spawn_interval()


func _emit(type: StringName, payload: Dictionary = {}) -> void:
	var event: Dictionary = payload.duplicate()
	event["type"] = type
	_events.append(event)


func _take() -> Array[Dictionary]:
	var taken: Array[Dictionary] = _events.duplicate()
	_events.clear()
	return taken
