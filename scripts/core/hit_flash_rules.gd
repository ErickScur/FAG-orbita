class_name HitFlashRules
extends RefCounted

const FULL: float = 1.0
const OVER_TIME: float = 0.35
const OVER_TIME_INTERVAL: float = 0.6


static func flash_for(over_time: bool, since_last_pulse: float) -> float:
	if not over_time:
		return FULL
	if since_last_pulse < OVER_TIME_INTERVAL:
		return 0.0
	return OVER_TIME


static func shakes(over_time: bool) -> bool:
	return not over_time
