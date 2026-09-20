class_name PlatformerMath
extends RefCounted


static func jump_velocity(height: float, gravity: float, step: float = 0.0) -> float:
	if height <= 0.0 or gravity <= 0.0:
		return 0.0
	return -maxf(0.0, sqrt(2.0 * gravity * height) - gravity * maxf(0.0, step) * 0.5)


static func approach(current: float, target: float, amount: float) -> float:
	if amount <= 0.0:
		return current
	return current + clampf(target - current, -amount, amount)


static func apply_jump_cut(velocity_y: float, multiplier: float) -> float:
	if velocity_y >= 0.0:
		return velocity_y
	return velocity_y * clampf(multiplier, 0.0, 1.0)


static func clamp_fall(velocity_y: float, max_fall: float) -> float:
	if max_fall <= 0.0:
		return velocity_y
	return minf(velocity_y, max_fall)


static func simulate_jump_peak(
	initial_velocity_y: float, gravity: float, step: float, max_fall: float
) -> float:
	if step <= 0.0:
		return 0.0
	var offset: float = 0.0
	var peak: float = 0.0
	var velocity_y: float = initial_velocity_y
	var elapsed: float = 0.0
	while elapsed < 10.0:
		offset += velocity_y * step
		peak = minf(peak, offset)
		if offset >= 0.0:
			break
		velocity_y = clamp_fall(velocity_y + gravity * step, max_fall)
		elapsed += step
	return -peak
