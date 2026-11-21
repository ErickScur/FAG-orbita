class_name ArgosLogic
extends RefCounted

enum State { IDLE, ACTIVE, DEFEATED, FAILED }

var state: State = State.IDLE
var time_left: float = Balance.ARGOS_TIME
var heat_clock: float = 0.0

var _overloaded: Array[StringName] = []


static func lift_ratio(clock: float, offset: float) -> float:
	var cycle: float = Balance.ARGOS_LIFT_CYCLE
	if cycle <= 0.0:
		return 0.0
	var hold: float = clampf(Balance.ARGOS_LIFT_HOLD, 0.0, 0.5)
	var move: float = 0.5 - hold
	var t: float = fposmod(clock / cycle + offset, 1.0)
	if t < hold:
		return 0.0
	if t < hold + move:
		return smoothstep(0.0, 1.0, (t - hold) / move)
	if t < 2.0 * hold + move:
		return 1.0
	return 1.0 - smoothstep(0.0, 1.0, (t - 2.0 * hold - move) / move)


static func segments_for(seconds_left: float) -> int:
	var count: int = maxi(1, Balance.ARGOS_SEGMENTS)
	var step: float = Balance.ARGOS_TIME / float(count)
	if seconds_left <= 0.0 or step <= 0.0:
		return 0
	return clampi(ceili(seconds_left / step - 0.0001), 0, count)


static func is_urgent(seconds_left: float) -> bool:
	return seconds_left <= Balance.ARGOS_ALARM_FAST_TIME


static func alarm_interval(seconds_left: float) -> float:
	if seconds_left <= Balance.ARGOS_ALARM_FAST_TIME:
		return Balance.ARGOS_ALARM_FAST_INTERVAL
	return Balance.ARGOS_ALARM_INTERVAL


func start() -> bool:
	if state != State.IDLE:
		return false
	state = State.ACTIVE
	time_left = Balance.ARGOS_TIME
	return true


func tick(delta: float) -> bool:
	var step: float = maxf(delta, 0.0)
	heat_clock += step * speed_scale()
	if state != State.ACTIVE:
		return false
	time_left = maxf(0.0, time_left - step)
	if time_left > 0.0:
		return false
	state = State.FAILED
	return true


func overload(coupler_id: StringName) -> bool:
	if state != State.ACTIVE or coupler_id == &"" or _overloaded.has(coupler_id):
		return false
	_overloaded.append(coupler_id)
	if _overloaded.size() >= Balance.ARGOS_COUPLERS:
		state = State.DEFEATED
	return true


func defeat() -> void:
	state = State.DEFEATED
	time_left = 0.0


func fail() -> bool:
	if state != State.ACTIVE:
		return false
	state = State.FAILED
	return true


func reset() -> void:
	if state == State.DEFEATED:
		return
	state = State.IDLE
	time_left = Balance.ARGOS_TIME
	_overloaded.clear()


func is_active() -> bool:
	return state == State.ACTIVE


func is_defeated() -> bool:
	return state == State.DEFEATED


func overloaded_count() -> int:
	return _overloaded.size()


func is_overloaded(coupler_id: StringName) -> bool:
	return _overloaded.has(coupler_id)


func phase() -> int:
	return mini(_overloaded.size() + 1, Balance.ARGOS_COUPLERS)


func speed_scale() -> float:
	var steps: int = mini(_overloaded.size(), Balance.ARGOS_COUPLERS - 1)
	return 1.0 + Balance.ARGOS_PHASE_SPEEDUP * float(steps)


func lit_segments() -> int:
	if state == State.IDLE:
		return Balance.ARGOS_SEGMENTS
	return segments_for(time_left)
