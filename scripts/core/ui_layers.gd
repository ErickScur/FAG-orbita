class_name UiLayers
extends RefCounted

const SPACE_BACKDROP: int = -1
const WORLD: int = 0
const CUTSCENE_OVERLAY: int = 1
const MEMORY_TINT: int = 4
const VIGNETTE: int = 5
const MEMORY_OVERLAY: int = 7
const TUTORIAL_CARD: int = 9
const HUD: int = 10
const ENERGY_TERMINAL: int = 20
const DIALOGUE: int = 30
const EARTH_SIGNAL: int = 31
const CHASSIS_MENU: int = 40
const CONFIRM_DIALOG: int = 45
const PAUSE_MENU: int = 50
const SAVE_TOAST: int = 60
const CHASSIS_LOST: int = 80
const SCENE_TRANSITION: int = 100

const BELOW_HUD: Array[int] = [
	SPACE_BACKDROP, WORLD, CUTSCENE_OVERLAY, MEMORY_TINT, VIGNETTE, MEMORY_OVERLAY, TUTORIAL_CARD
]
const ABOVE_HUD: Array[int] = [
	ENERGY_TERMINAL, DIALOGUE, EARTH_SIGNAL, CHASSIS_MENU, CONFIRM_DIALOG, PAUSE_MENU,
	SAVE_TOAST, CHASSIS_LOST, SCENE_TRANSITION
]


static func all() -> Array[int]:
	var result: Array[int] = []
	result.append_array(BELOW_HUD)
	result.append(HUD)
	result.append_array(ABOVE_HUD)
	return result
