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
	"LOGS_TOTAL": 4,
	"RESEARCH_TOTAL": 4,
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
	"DIALOGUE_CPS": 55.0,
	"DIALOGUE_READ_CPS": 45.0,
	"DIALOGUE_AMBIENT_MIN_TIME": 1.6,
	"CUTSCENE_CAMERA_SPEED": 220.0,
	"CUTSCENE_TRAVEL_MIN_TIME": 3.0,
	"CUTSCENE_TRAVEL_MAX_TIME": 7.0,
	"CUTSCENE_HOLD_START_TIME": 0.8,
	"CUTSCENE_HOLD_END_TIME": 1.0,
	"CUTSCENE_RETURN_TIME": 1.2,
	"CUTSCENE_WAYPOINT_SPACING": 96.0,
	"CUTSCENE_WAYPOINT_LIMIT": 8,
	"CUTSCENE_SKIP_ARM_TIME": 0.4,
	"CUTSCENE_REVEAL_HALF_SIZE": Vector2(144, 88),
	"FREIGHT_LIFT_SPEED": 90.0,
	"MAGNETIC_GLOW_RADIUS": 18.0,
	"MAGNETIC_GLOW_ENERGY": 0.55,
	"MAGNETIC_SELF_LIGHT": 1.6,
	"MAGNETIC_GLOW_COLOR": Color("e8b93a"),
	"MUSIC_ONE_SHOT_FADE_TIME": 0.35,
	"MUSIC_LAYER_FADE_TIME": 2.5,
	"MUSIC_LAYER_GAIN_DB": -6.0,
	"FLASHLIGHT_ENERGY": 1.5,
	"SENSOR_ENERGY": 0.7,
	"BRIEFING_CPS": 60.0,
	"TUTORIAL_CARD_HOLD": 0.6,
	"TUTORIAL_CARD_FADE": 0.2,
	"HUD_TOAST_TIME": 2.0,
	"HUD_PULSE_HZ": 2.0,
	"LOW_INTEGRITY_BEEP_INTERVAL": 1.5,
	"PICKUP_BOB_AMPLITUDE": 2.0,
	"PICKUP_BOB_SPEED": 2.0,
	"SHAKE_TIME": 0.25,
	"SHAKE_FREQUENCY": 24.0,
	"SHAKE_DAMAGE": 4.0,
	"SHAKE_LAND": 2.0,
	"SHAKE_SECTOR": 3.0,
	"LAND_SHAKE_SPEED": 260.0,
	"HIT_FLASH_TIME": 0.12,
	"LAMP_PULSE_HZ": 0.45,
	"LAMP_PULSE_DEPTH": 0.12,
	"VIGNETTE_STRENGTH": 0.55,
	"VIGNETTE_INNER": 0.45,
	"VIGNETTE_OUTER": 1.0,
	"AMBIENT_MOTE_AMOUNT": 28,
	"AMBIENT_MOTE_LIFETIME": 7.0,
	"AMBIENT_MOTE_SPEED": 5.0,
	"AMBIENT_MOTE_RISE": -3.0,
	"PARALLAX_FAR_DIM": 0.75,
	"PARALLAX_MID_DIM": 0.9,
	"SECTOR_FLASH_TIME": 0.12,
	"SECTOR_SETTLE_TIME": 1.2,
	"HUD_BAR_SLIDE_TIME": 0.25,
	"HUD_CELL_LOST_TIME": 0.35,
	"HUD_CELL_LOST_SCALE": 1.5,
	"HUD_TOAST_SLIDE": 8.0,
	"HUD_TOAST_SLIDE_TIME": 0.18,
	"MU7_FPS_IDLE": 3.0,
	"MU7_FPS_WALK": 8.0,
	"MU7_FPS_JUMP": 9.0,
	"MU7_FPS_FALL": 6.0,
	"MU7_FPS_LAND": 10.0,
	"MU7_FPS_HURT": 8.0,
	"MU7_FPS_INTERACT": 6.0,
	"MU7_FPS_CLIMB": 5.0,
	"MU7_FPS_DEATH": 4.0,
	"MU7_FPS_DASH": 12.0,
}


func test_constants_match_gdd() -> void:
	var constants: Dictionary = Balance.new().get_script().get_script_constant_map()
	for key: String in EXPECTED:
		assert_true(constants.has(key), "constante ausente: %s" % key)
		if constants.has(key):
			assert_almost_eq(float(constants[key]), float(EXPECTED[key]), 0.0001, key)


func test_ambient_dark_color() -> void:
	assert_eq(Balance.AMBIENT_DARK, Color("0d1219"), "AMBIENT_DARK")


func test_polish_colors() -> void:
	assert_eq(Balance.HIT_FLASH_COLOR, Color("fff4e0"), "HIT_FLASH_COLOR")
	assert_eq(Balance.VIGNETTE_COLOR, Color("06090f"), "VIGNETTE_COLOR")
	assert_eq(Balance.BACKGROUND_TINT, Color("6b7a8c"), "BACKGROUND_TINT")
	assert_eq(Balance.SECTOR_FLASH_COLOR, Color("e8f4ff"), "SECTOR_FLASH_COLOR")


func test_parallax_layers_get_further_apart() -> void:
	assert_true(
		Balance.PARALLAX_FAR_SCALE.x < Balance.PARALLAX_MID_SCALE.x,
		"o fundo distante anda menos que o do meio"
	)
	assert_true(
		Balance.PARALLAX_MID_SCALE.x < Balance.PARALLAX_NEAR_SCALE.x,
		"o do meio anda menos que o próximo"
	)
	assert_true(
		Balance.PARALLAX_FAR_SCALE.y < Balance.PARALLAX_FAR_SCALE.x,
		"a subida arrasta menos o fundo que o lado"
	)
	assert_true(
		Balance.PARALLAX_FAR_DIM < Balance.PARALLAX_MID_DIM,
		"o fundo distante é o mais escuro"
	)


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
