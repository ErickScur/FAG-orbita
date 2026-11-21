class_name OverloadRule
extends RefCounted

const EPSILON: float = 0.001

var _recharged: float = 0.0
var _fired: bool = false


static func reaches_full(before: float, after: float, maximum: float) -> bool:
	if maximum <= 0.0:
		return false
	return before < maximum - EPSILON and after >= maximum - EPSILON


func begin() -> void:
	_recharged = 0.0
	_fired = false


func feed(before: float, after: float, maximum: float) -> bool:
	if after > before:
		_recharged += after - before
	if _fired or not reaches_full(before, after, maximum):
		return false
	if _recharged + EPSILON < Balance.OVERLOAD_MIN_RECHARGE:
		return false
	_fired = true
	return true


func recharged() -> float:
	return _recharged


func has_fired() -> bool:
	return _fired
