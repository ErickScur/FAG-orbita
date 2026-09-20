class_name Growth
extends RefCounted

const COMPLETE: float = 1.0


static func step(progress: float, powered: bool, delta: float, grow_time: float) -> float:
	var current: float = clampf(progress, 0.0, COMPLETE)
	if not powered or delta <= 0.0:
		return current
	if grow_time <= 0.0:
		return COMPLETE
	var next: float = current + delta / grow_time
	if next >= COMPLETE or is_equal_approx(next, COMPLETE):
		return COMPLETE
	return maxf(next, 0.0)


static func frame_for(progress: float, frames: int) -> int:
	if frames <= 0:
		return 0
	var index: int = int(floorf(clampf(progress, 0.0, COMPLETE) * float(frames)))
	return clampi(index, 0, frames - 1)


static func is_grown(progress: float) -> bool:
	return progress >= COMPLETE or is_equal_approx(progress, COMPLETE)
