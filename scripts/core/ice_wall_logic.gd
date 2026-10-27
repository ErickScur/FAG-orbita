class_name IceWallLogic
extends RefCounted

const FRAME_SOLID: int = 0
const FRAME_MELTING_A: int = 1
const FRAME_MELTING_B: int = 2
const FRAME_EMPTY: int = 3

var heated: bool = false
var melt_time: float = Balance.ICE_MELT_TIME

var _melted_forever: bool = false
var _progress: float = 0.0


static func melts_on_touch(abilities: Array) -> bool:
	return FreezeRules.has_heated_core(abilities)


func update(delta: float, occupied: bool) -> void:
	var step: float = maxf(0.0, delta)
	var rate: float = step / melt_time if melt_time > 0.0 else 1.0
	if heated or _melted_forever:
		_progress = minf(1.0, _progress + rate)
		return
	if occupied and _progress >= 1.0:
		return
	_progress = maxf(0.0, _progress - rate)


func melt_forever() -> bool:
	if _melted_forever:
		return false
	_melted_forever = true
	return true


func is_melted_forever() -> bool:
	return _melted_forever


func progress() -> float:
	return _progress


func is_solid() -> bool:
	return _progress < 1.0


func frame() -> int:
	if _progress >= 1.0:
		return FRAME_EMPTY
	if _progress <= 0.0:
		return FRAME_SOLID
	return FRAME_MELTING_A if _progress < 0.5 else FRAME_MELTING_B


func settle() -> void:
	_progress = 1.0 if heated or _melted_forever else 0.0
