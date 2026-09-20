class_name ReactorClock
extends RefCounted


static func decay_per_second(interval: float, multiplier: float) -> float:
	if interval <= 0.0:
		return 0.0
	return multiplier / interval


static func step(percent: float, delta: float, interval: float, multiplier: float) -> float:
	return maxf(0.0, percent - decay_per_second(interval, multiplier) * delta)


static func apply_delta(percent: float, amount: float, cap: float) -> float:
	return clampf(percent + amount, 0.0, cap)


static func is_critical(percent: float, threshold: float) -> bool:
	return percent < threshold


static func display_percent(percent: float) -> int:
	if percent <= 0.0:
		return 0
	return clampi(ceili(percent), 1, 100)


static func bar_ratio(percent: float, cap: float) -> float:
	if cap <= 0.0:
		return 0.0
	return clampf(percent / cap, 0.0, 1.0)
