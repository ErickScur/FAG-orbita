class_name Accessibility
extends RefCounted

const SUBTITLE_NORMAL: StringName = &"normal"
const SUBTITLE_LARGE: StringName = &"large"
const SUBTITLE_SIZES: Array[StringName] = [SUBTITLE_NORMAL, SUBTITLE_LARGE]
const SUBTITLE_FONT_SIZES: Dictionary = {
	SUBTITLE_NORMAL: 16,
	SUBTITLE_LARGE: 32,
}
const FONT_GRID: int = 16
const VISION_DEUTAN: StringName = &"deutan"
const VISION_PROTAN: StringName = &"protan"
const VISIONS: Array[StringName] = [VISION_DEUTAN, VISION_PROTAN]
const ROLE_SECTOR_RESTORED: StringName = &"sector_restored"
const ROLE_SECTOR_PENDING: StringName = &"sector_pending"
const ROLE_TERMINAL_ON: StringName = &"terminal_on"
const ROLE_TERMINAL_ALERT: StringName = &"terminal_alert"
const ROLE_TERMINAL_GOAL: StringName = &"terminal_goal"
const ROLE_INTEGRITY_LOST: StringName = &"integrity_lost"
const ROLE_REACTOR_CRITICAL: StringName = &"reactor_critical"
const ROLE_REACTOR_CRITICAL_DIM: StringName = &"reactor_critical_dim"
const PALETTE: Dictionary = {
	ROLE_SECTOR_RESTORED: [Color("6fe08a"), Color("56b4e9")],
	ROLE_SECTOR_PENDING: [Color("c0463c"), Color("e69f00")],
	ROLE_TERMINAL_ON: [Color("5fd4c8"), Color("56b4e9")],
	ROLE_TERMINAL_ALERT: [Color("d9534f"), Color("d55e00")],
	ROLE_TERMINAL_GOAL: [Color("e0b43c"), Color("f0e442")],
	ROLE_INTEGRITY_LOST: [Color("ff8c73"), Color("e69f00")],
	ROLE_REACTOR_CRITICAL: [Color("ff5c5c"), Color("ffb000")],
	ROLE_REACTOR_CRITICAL_DIM: [Color("b82929"), Color("8a5a00")],
}
const CONTRAST_PAIRS: Array = [
	[ROLE_SECTOR_RESTORED, ROLE_SECTOR_PENDING],
	[ROLE_TERMINAL_ON, ROLE_TERMINAL_ALERT],
	[ROLE_TERMINAL_GOAL, ROLE_TERMINAL_ALERT],
	[ROLE_TERMINAL_ON, ROLE_TERMINAL_GOAL],
]


static func subtitle_font_size(size_id: StringName) -> int:
	return int(SUBTITLE_FONT_SIZES.get(size_id, SUBTITLE_FONT_SIZES[SUBTITLE_NORMAL]))


static func valid_subtitle(size_id: StringName) -> StringName:
	return size_id if SUBTITLE_SIZES.has(size_id) else SUBTITLE_NORMAL


static func color(role: StringName, colorblind: bool) -> Color:
	var pair: Array = PALETTE.get(role, [Color.WHITE, Color.WHITE])
	return pair[1] if colorblind else pair[0]


static func simulate(source: Color, vision: StringName) -> Color:
	var red: float = source.srgb_to_linear().r
	var green: float = source.srgb_to_linear().g
	var blue: float = source.srgb_to_linear().b
	var mixed: float
	var shifted: float
	if vision == VISION_PROTAN:
		mixed = 0.11238 * red + 0.88762 * green
		shifted = 0.00401 * red - 0.00401 * green + blue
	else:
		mixed = 0.29275 * red + 0.70725 * green
		shifted = -0.02234 * red + 0.02234 * green + blue
	var seen := Color(
		clampf(mixed, 0.0, 1.0), clampf(mixed, 0.0, 1.0), clampf(shifted, 0.0, 1.0), source.a
	)
	return seen.linear_to_srgb()


static func perceived_distance(first: Color, second: Color, vision: StringName) -> float:
	var a: Color = simulate(first, vision)
	var b: Color = simulate(second, vision)
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


static func weakest_contrast(colorblind: bool) -> float:
	var weakest: float = INF
	for pair: Array in CONTRAST_PAIRS:
		for vision: StringName in VISIONS:
			var distance: float = perceived_distance(
				color(pair[0], colorblind), color(pair[1], colorblind), vision
			)
			weakest = minf(weakest, distance)
	return weakest
