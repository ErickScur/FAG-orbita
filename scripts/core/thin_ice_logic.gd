class_name ThinIceLogic
extends RefCounted

enum State { INTACT, CRACKED, BROKEN }

const FRAME_INTACT: int = 0
const FRAME_CRACKED: int = 1
const FRAME_BREAKING: int = 2
const FRAME_EMPTY: int = 3

var break_time: float = Balance.THIN_ICE_BREAK_TIME
var reform_time: float = Balance.THIN_ICE_REFORM_TIME

var _state: State = State.INTACT
var _timer: float = 0.0


func update(delta: float, stepped: bool, occupied: bool) -> StringName:
	var step: float = maxf(0.0, delta)
	match _state:
		State.INTACT:
			if stepped:
				_state = State.CRACKED
				_timer = break_time
				return &"cracked"
		State.CRACKED:
			_timer = maxf(0.0, _timer - step)
			if _timer <= 0.0:
				_state = State.BROKEN
				_timer = reform_time
				return &"broke"
		State.BROKEN:
			_timer = maxf(0.0, _timer - step)
			if _timer <= 0.0 and not occupied:
				_state = State.INTACT
				return &"reformed"
	return &""


func state() -> State:
	return _state


func is_solid() -> bool:
	return _state != State.BROKEN


func frame() -> int:
	match _state:
		State.CRACKED:
			return FRAME_CRACKED if _timer > break_time * 0.5 else FRAME_BREAKING
		State.BROKEN:
			return FRAME_EMPTY
	return FRAME_INTACT


func time_left() -> float:
	return _timer
