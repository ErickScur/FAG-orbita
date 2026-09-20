class_name LightMath
extends RefCounted

const TEXTURE_SIZE: float = 256.0


static func scale_for_radius(radius: float, texture_size: float) -> float:
	if texture_size <= 0.0 or radius <= 0.0:
		return 0.0
	return radius * 2.0 / texture_size


static func radius_for_scale(texture_scale: float, texture_size: float) -> float:
	return texture_scale * texture_size * 0.5


static func drain_for(delta: float, drain_per_second: float) -> float:
	if delta <= 0.0 or drain_per_second <= 0.0:
		return 0.0
	return delta * drain_per_second


static func can_enable(charge: float, drain_per_second: float) -> bool:
	if charge <= 0.0:
		return false
	return charge >= drain_per_second


static func pulse(base_energy: float, elapsed: float, frequency: float, depth: float) -> float:
	if base_energy <= 0.0 or frequency <= 0.0 or depth <= 0.0:
		return maxf(base_energy, 0.0)
	var wave: float = sin(elapsed * frequency * TAU)
	return maxf(0.0, base_energy * (1.0 + wave * clampf(depth, 0.0, 1.0)))
