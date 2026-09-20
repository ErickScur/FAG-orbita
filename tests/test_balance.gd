extends TestCase

const EXPECTED: Dictionary = {
	"TILE_SIZE": 16,
	"INTEGRITY_MAX": 100,
	"INTEGRITY_CELLS": 4,
	"CHARGE_MAX": 100.0,
	"CHARGE_DOCK_REGEN": 5.0,
	"WALK_SPEED": 110.0,
	"DASH_SPEED": 320.0,
	"DASH_TIME": 0.25,
	"DASH_COST": 20.0,
	"DASH_COOLDOWN": 1.0,
	"JUMP_HEIGHT": 40.0,
	"GRAVITY": 980.0,
	"DOUBLE_JUMP_COST": 15.0,
	"BEAM_COST": 25.0,
	"BEAM_SHUTDOWN_TIME": 4.0,
	"FLASHLIGHT_DRAIN": 1.0,
	"VISION_RADIUS_OFF": 48.0,
	"VISION_RADIUS_ON": 128.0,
	"REACTOR_START": 100.0,
	"REACTOR_DECAY_INTERVAL": 90.0,
	"REACTOR_SECTOR_BONUS": 15.0,
	"REACTOR_LOG_BONUS": 0.5,
	"REACTOR_DEATH_PENALTY": 3.0,
	"REACTOR_CRITICAL": 25.0,
	"RESPAWN_INTEGRITY_RATIO": 0.5,
	"SR3_CONTACT_DAMAGE": 10,
	"SPORE_DPS": 5.0,
	"CORROSION_TIME": 6.0,
	"STEAM_DAMAGE": 20,
	"STEAM_ON_TIME": 3.0,
	"STEAM_OFF_TIME": 2.0,
	"ELECTRIC_FLOOR_DPS": 8.0,
	"ENERGY_CELL_CHARGE": 40.0,
	"REPAIR_KIT_INTEGRITY": 25,
	"CAPACITOR_BONUS": 25.0,
	"LOGS_TOTAL": 24,
	"RESEARCH_TOTAL": 12,
	"RESPAWN_CHARGE_RATIO": 1.0,
	"DOCK_REPAIR_RATE": 10.0,
	"INTERACT_RANGE": 20.0,
	"DEATH_DELAY": 1.2,
	"SCENE_FADE_TIME": 0.4,
	"LOADING_MIN_TIME": 1.6,
	"SPLASH_TIME": 2.5,
	"MUSIC_FADE_TIME": 1.5,
	"CAMERA_SMOOTHING": 5.0,
	"CAMERA_LOOK_AHEAD": 24.0,
	"CAMERA_LOOK_AHEAD_SPEED": 4.0,
	"CAMERA_OFFSET_Y": -16.0,
	"COYOTE_TIME": 0.12,
	"JUMP_BUFFER": 0.12,
	"JUMP_CUT_MULTIPLIER": 0.5,
	"MAX_FALL_SPEED": 400.0,
	"WALK_ACCEL": 900.0,
	"WALK_DECEL": 1200.0,
	"AIR_ACCEL_RATIO": 0.7,
	"DROP_THROUGH_TIME": 0.2,
	"INVULNERABLE_TIME": 0.8,
	"KNOCKBACK_SPEED": 140.0,
	"CLAW_CLIMB_SPEED": 70.0,
	"CLAW_JUMP_PUSH": 90.0,
	"SPORE_RADIUS": 24.0,
	"SPORE_RADIUS_HEATED": 48.0,
	"SPORE_EXPAND_TIME": 2.0,
	"STATUS_EXPOSURE_GRACE": 0.3,
	"PLATFORM_SPEED": 40.0,
	"PLANT_GROW_TIME": 2.0,
	"SR3_SPEED": 40.0,
	"SR3_KNOCKBACK_X": 120.0,
	"SR3_KNOCKBACK_Y": 120.0,
	"SR3_KNOCKBACK_LOCK": 0.15,
	"BEAM_RANGE": 32.0,
	"LAMP_RADIUS": 96.0,
	"LAMP_ENERGY": 0.9,
	"LIGHT_FADE_TIME": 0.15,
	"PLATFORM_WAIT": 0.6,
	"SECRET_WALL_FADE_TIME": 0.3,
	"SECRET_WALL_ALPHA": 0.25,
	"SECRETS_TOTAL": 4,
	"STEAM_WARN_TIME": 0.5,
	"DRONE_SPEED": 45.0,
	"DRONE_WANDER_RADIUS": 64.0,
	"DRONE_RETARGET_TIME": 1.5,
	"DRONE_FOLLOW_RADIUS": 120.0,
	"OVERHEAT_DPS": 3.0,
	"OVERHEAT_CHARGE_MULT": 2.0,
	"FREEZE_SPEED_MULT": 0.5,
	"FREEZE_JUMP_MULT": 0.7,
	"DISCHARGE_TIME": 3.0,
	"OVERLOAD_TIME": 10.0,
	"OVERLOAD_SPEED_MULT": 1.3,
	"DIALOGUE_CPS": 40.0,
	"DIALOGUE_READ_CPS": 15.0,
	"DIALOGUE_AMBIENT_MIN_TIME": 2.0,
}


func test_constants_match_gdd() -> void:
	var constants: Dictionary = Balance.new().get_script().get_script_constant_map()
	for key: String in EXPECTED:
		assert_true(constants.has(key), "constante ausente: %s" % key)
		if constants.has(key):
			assert_almost_eq(float(constants[key]), float(EXPECTED[key]), 0.0001, key)


func test_ambient_dark_color() -> void:
	assert_eq(Balance.AMBIENT_DARK, Color("191d26"), "AMBIENT_DARK")


func test_light_colors() -> void:
	assert_eq(Balance.LAMP_COLOR, Color("bfe6ff"), "LAMP_COLOR")
	assert_eq(Balance.FLASHLIGHT_COLOR, Color("cfeaf2"), "FLASHLIGHT_COLOR")


func test_difficulty_dictionaries() -> void:
	assert_eq(Balance.DIFFICULTY_DAMAGE_MULT.size(), 3, "DIFFICULTY_DAMAGE_MULT")
	assert_eq(Balance.DIFFICULTY_REACTOR_MULT.size(), 3, "DIFFICULTY_REACTOR_MULT")


func test_difficulty_damage_multiplier() -> void:
	assert_almost_eq(Balance.difficulty_damage_multiplier(&"easy"), 0.5, 0.0001, "easy")
	assert_almost_eq(Balance.difficulty_damage_multiplier(&"normal"), 1.0, 0.0001, "normal")
	assert_almost_eq(Balance.difficulty_damage_multiplier(&"hard"), 1.5, 0.0001, "hard")
	assert_almost_eq(Balance.difficulty_damage_multiplier(&"nada"), 1.0, 0.0001, "padrão")


func test_difficulty_reactor_multiplier() -> void:
	assert_almost_eq(Balance.difficulty_reactor_multiplier(&"easy"), 0.5, 0.0001, "easy")
	assert_almost_eq(Balance.difficulty_reactor_multiplier(&"normal"), 1.0, 0.0001, "normal")
	assert_almost_eq(Balance.difficulty_reactor_multiplier(&"hard"), 1.5, 0.0001, "hard")
