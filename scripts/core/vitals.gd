class_name Vitals
extends RefCounted

const FULL_CELL: int = 2
const PARTIAL_CELL: int = 1
const EMPTY_CELL: int = 0


static func scale_damage(amount: int, multiplier: float) -> int:
	if amount <= 0 or multiplier <= 0.0:
		return 0
	return maxi(1, ceili(float(amount) * multiplier))


static func cell_states(integrity: int, maximum: int, cells: int) -> Array[int]:
	var states: Array[int] = []
	if cells <= 0 or maximum <= 0:
		return states
	var per_cell: float = float(maximum) / float(cells)
	var left: float = clampf(float(integrity), 0.0, float(maximum))
	for index: int in range(cells):
		if left >= per_cell:
			states.append(FULL_CELL)
			left -= per_cell
		elif left > 0.0:
			states.append(PARTIAL_CELL)
			left = 0.0
		else:
			states.append(EMPTY_CELL)
	return states


static func respawn_integrity(maximum: int, ratio: float) -> int:
	if maximum <= 0 or ratio <= 0.0:
		return 0
	return mini(maximum, maxi(1, ceili(float(maximum) * ratio)))


static func respawn_charge(maximum: float, ratio: float) -> float:
	return clampf(maximum * ratio, 0.0, maximum)


static func accumulate(accumulator: float, per_second: float, delta: float) -> Vector2:
	var total: float = accumulator + per_second * delta
	if total <= 0.0:
		return Vector2(0.0, 0.0)
	var whole: float = floorf(total)
	return Vector2(whole, total - whole)


static func clamp_add(current: float, amount: float, maximum: float) -> float:
	return clampf(current + amount, 0.0, maximum)
