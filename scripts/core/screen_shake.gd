class_name ScreenShake
extends RefCounted

const VERTICAL_RATIO: float = 0.5
const VERTICAL_PHASE: float = 1.37


static func amplitude_for(current: float, requested: float) -> float:
	return maxf(current, maxf(requested, 0.0))


static func remaining_after(remaining: float, delta: float) -> float:
	return maxf(0.0, remaining - maxf(delta, 0.0))


static func falloff(remaining: float, duration: float) -> float:
	if remaining <= 0.0 or duration <= 0.0:
		return 0.0
	var ratio: float = clampf(remaining / duration, 0.0, 1.0)
	return ratio * ratio


static func offset(
	amplitude: float, remaining: float, duration: float, elapsed: float, frequency: float
) -> Vector2:
	var strength: float = amplitude * falloff(remaining, duration)
	if strength <= 0.0:
		return Vector2.ZERO
	var phase: float = elapsed * frequency * TAU
	return Vector2(
		roundf(sin(phase) * strength),
		roundf(cos(phase * VERTICAL_PHASE) * strength * VERTICAL_RATIO)
	)


static func land_amplitude(fall_speed: float, threshold: float, amplitude: float) -> float:
	if fall_speed < threshold or threshold <= 0.0:
		return 0.0
	return amplitude
