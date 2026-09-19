class_name AudioMath
extends RefCounted

const SILENT_DB: float = -80.0
const SILENCE_THRESHOLD: float = 0.001


static func linear_to_db_safe(linear: float) -> float:
	if linear <= SILENCE_THRESHOLD:
		return SILENT_DB
	return linear_to_db(clampf(linear, 0.0, 1.0))


static func db_to_linear_safe(db: float) -> float:
	if db <= SILENT_DB:
		return 0.0
	return clampf(db_to_linear(db), 0.0, 1.0)


static func is_silent(linear: float) -> bool:
	return linear <= SILENCE_THRESHOLD
