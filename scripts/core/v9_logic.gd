class_name V9Logic
extends RefCounted

enum State { PATROL, ALERT, CHASE, LATCHED, COOLDOWN, SHUTDOWN, OFF }

const EVENT_NONE: StringName = &""
const EVENT_ALERTED: StringName = &"alerted"
const EVENT_CHASING: StringName = &"chasing"
const EVENT_LATCHED: StringName = &"latched"
const EVENT_RELEASED: StringName = &"released"
const EVENT_LOST: StringName = &"lost"
const EVENT_GAVE_UP: StringName = &"gave_up"
const EVENT_WOKE: StringName = &"woke"
const EVENT_RESTED: StringName = &"rested"

var powered: bool = true

var _state: State = State.PATROL
var _timer: float = 0.0
var _chase_elapsed: float = 0.0
var _unseen: float = 0.0


static func vision_range(lit: bool) -> float:
	return Balance.V9_VISION_RANGE if lit else Balance.V9_DARK_VISION


static func sees(distance: float, lit: bool, line_clear: bool) -> bool:
	return line_clear and distance <= vision_range(lit)


static func hears(distance: float, dashing: bool) -> bool:
	return dashing and distance <= Balance.V9_HEAR_RADIUS


static func latch_drain(delta: float, charge: float) -> float:
	return clampf(Balance.V9_LATCH_DRAIN * maxf(0.0, delta), 0.0, maxf(0.0, charge))


func update(delta: float, sees_target: bool, heard: bool, touching: bool) -> StringName:
	if not powered:
		_state = State.OFF
		return EVENT_NONE
	var step: float = maxf(0.0, delta)
	match _state:
		State.OFF:
			_state = State.PATROL
			return EVENT_WOKE
		State.SHUTDOWN:
			_timer = maxf(0.0, _timer - step)
			if _timer > 0.0:
				return EVENT_NONE
			_state = State.PATROL
			return EVENT_WOKE
		State.PATROL:
			if sees_target or heard:
				_enter(State.ALERT, Balance.V9_ALERT_TIME)
				return EVENT_ALERTED
		State.ALERT:
			_timer = maxf(0.0, _timer - step)
			if _timer > 0.0:
				return EVENT_NONE
			_chase_elapsed = 0.0
			_unseen = 0.0
			_enter(State.CHASE, 0.0)
			return EVENT_CHASING
		State.CHASE:
			return _update_chase(step, sees_target or heard, touching)
		State.LATCHED:
			_timer = maxf(0.0, _timer - step)
			if _timer > 0.0:
				return EVENT_NONE
			_enter(State.COOLDOWN, Balance.V9_COOLDOWN)
			return EVENT_RELEASED
		State.COOLDOWN:
			_timer = maxf(0.0, _timer - step)
			if _timer > 0.0:
				return EVENT_NONE
			_state = State.PATROL
			return EVENT_RESTED
	return EVENT_NONE


func set_powered(on: bool) -> void:
	powered = on
	if not on:
		_enter(State.OFF, 0.0)
	elif _state == State.OFF:
		_enter(State.PATROL, 0.0)


func shutdown(duration: float) -> bool:
	if duration <= 0.0 or not powered:
		return false
	var was_awake: bool = _state != State.SHUTDOWN
	_state = State.SHUTDOWN
	_timer = maxf(_timer if not was_awake else 0.0, duration)
	return was_awake


func release() -> bool:
	if _state != State.LATCHED:
		return false
	_enter(State.COOLDOWN, Balance.V9_COOLDOWN)
	return true


func state() -> State:
	return State.OFF if not powered else _state


func time_left() -> float:
	return _timer


func chase_elapsed() -> float:
	return _chase_elapsed


func is_latched() -> bool:
	return state() == State.LATCHED


func is_chasing() -> bool:
	return state() == State.CHASE


func is_grounded() -> bool:
	var current: State = state()
	return current == State.OFF or current == State.SHUTDOWN


func follows_track() -> bool:
	var current: State = state()
	return current == State.PATROL or current == State.COOLDOWN


func _update_chase(step: float, perceived: bool, touching: bool) -> StringName:
	_chase_elapsed += step
	if touching:
		_enter(State.LATCHED, Balance.V9_LATCH_TIME)
		return EVENT_LATCHED
	_unseen = 0.0 if perceived else _unseen + step
	if _unseen >= Balance.V9_LOSE_TIME:
		_state = State.PATROL
		return EVENT_LOST
	if _chase_elapsed >= Balance.V9_CHASE_TIME:
		_enter(State.COOLDOWN, Balance.V9_COOLDOWN)
		return EVENT_GAVE_UP
	return EVENT_NONE


func _enter(next: State, timer: float) -> void:
	_state = next
	_timer = timer
