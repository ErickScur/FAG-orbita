class_name Balance
extends RefCounted

const TILE_SIZE: int = 16
const INTEGRITY_MAX: int = 100
const INTEGRITY_CELLS: int = 4
const CHARGE_MAX: float = 100.0
const CHARGE_DOCK_REGEN: float = 5.0
const WALK_SPEED: float = 110.0
const DASH_SPEED: float = 320.0
const DASH_TIME: float = 0.25
const DASH_COST: float = 20.0
const DASH_COOLDOWN: float = 1.0
const JUMP_HEIGHT: float = 40.0
const GRAVITY: float = 980.0
const DOUBLE_JUMP_COST: float = 15.0
const BEAM_COST: float = 25.0
const BEAM_SHUTDOWN_TIME: float = 4.0
const FLASHLIGHT_DRAIN: float = 1.0
const VISION_RADIUS_OFF: float = 48.0
const VISION_RADIUS_ON: float = 128.0
const REACTOR_START: float = 100.0
const REACTOR_DECAY_INTERVAL: float = 90.0
const REACTOR_SECTOR_BONUS: float = 15.0
const REACTOR_LOG_BONUS: float = 0.5
const REACTOR_DEATH_PENALTY: float = 3.0
const REACTOR_CRITICAL: float = 25.0
const RESPAWN_INTEGRITY_RATIO: float = 0.5
const SR3_CONTACT_DAMAGE: int = 10
const SPORE_DPS: float = 5.0
const CORROSION_TIME: float = 6.0
const STEAM_DAMAGE: int = 20
const STEAM_ON_TIME: float = 3.0
const STEAM_OFF_TIME: float = 2.0
const ELECTRIC_FLOOR_DPS: float = 8.0
const ENERGY_CELL_CHARGE: float = 40.0
const REPAIR_KIT_INTEGRITY: int = 25
const CAPACITOR_BONUS: float = 25.0
const LOGS_TOTAL: int = 24
const RESEARCH_TOTAL: int = 12
const DIFFICULTY_DAMAGE_MULT: Dictionary = {&"easy": 0.5, &"normal": 1.0, &"hard": 1.5}
const DIFFICULTY_REACTOR_MULT: Dictionary = {&"easy": 0.5, &"normal": 1.0, &"hard": 1.5}
const RESPAWN_CHARGE_RATIO: float = 1.0
const DOCK_REPAIR_RATE: float = 10.0
const INTERACT_RANGE: float = 20.0
const DEATH_DELAY: float = 1.2
const SCENE_FADE_TIME: float = 0.4
const LOADING_MIN_TIME: float = 1.6
const SPLASH_TIME: float = 2.5
const MUSIC_FADE_TIME: float = 1.5
const CAMERA_SMOOTHING: float = 5.0
const CAMERA_LOOK_AHEAD: float = 24.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.12
const INVULNERABLE_TIME: float = 0.8
const KNOCKBACK_SPEED: float = 140.0
const CLAW_CLIMB_SPEED: float = 70.0
const CLAW_JUMP_PUSH: float = 90.0
const SPORE_RADIUS: float = 24.0
const SPORE_RADIUS_HEATED: float = 48.0
const SPORE_EXPAND_TIME: float = 2.0
const STATUS_EXPOSURE_GRACE: float = 0.3
const PLATFORM_SPEED: float = 40.0
const PLANT_GROW_TIME: float = 2.0
const SR3_SPEED: float = 40.0
const SR3_KNOCKBACK_X: float = 120.0
const SR3_KNOCKBACK_Y: float = 120.0
const SR3_KNOCKBACK_LOCK: float = 0.15
const BEAM_RANGE: float = 32.0
const LAMP_RADIUS: float = 96.0
const LAMP_ENERGY: float = 0.9
const AMBIENT_DARK: Color = Color("191d26")
const PLATFORM_WAIT: float = 0.6
const SECRET_WALL_FADE_TIME: float = 0.3
const SECRET_WALL_ALPHA: float = 0.25
const SECRETS_TOTAL: int = 4
const STEAM_WARN_TIME: float = 0.5
const DRONE_SPEED: float = 45.0
const DRONE_WANDER_RADIUS: float = 64.0
const DRONE_RETARGET_TIME: float = 1.5
const DRONE_FOLLOW_RADIUS: float = 120.0
const OVERHEAT_DPS: float = 3.0
const OVERHEAT_CHARGE_MULT: float = 2.0
const FREEZE_SPEED_MULT: float = 0.5
const FREEZE_JUMP_MULT: float = 0.7
const DISCHARGE_TIME: float = 3.0
const OVERLOAD_TIME: float = 10.0
const OVERLOAD_SPEED_MULT: float = 1.3


static func difficulty_damage_multiplier(difficulty: StringName) -> float:
	return float(DIFFICULTY_DAMAGE_MULT.get(difficulty, 1.0))


static func difficulty_reactor_multiplier(difficulty: StringName) -> float:
	return float(DIFFICULTY_REACTOR_MULT.get(difficulty, 1.0))
