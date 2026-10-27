extends TestCase

const HEAT_SCENE: String = "res://scenes/world/heat_zone.tscn"

var _previous_difficulty: StringName = &"normal"


func before_each() -> void:
	_previous_difficulty = Settings.difficulty


func after_each() -> void:
	Settings.difficulty = _previous_difficulty


func test_warm_zone_overheats_and_hurts_by_the_status() -> void:
	assert_true(HeatRules.overheats(true, false), "zona quente superaquece")
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_WARM, false, false),
		Balance.OVERHEAT_DPS, 0.0001, "3/s do SUPERAQUECIMENTO"
	)


func test_furnace_adds_its_own_dps() -> void:
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_FURNACE, false, false),
		Balance.OVERHEAT_DPS + Balance.FURNACE_DPS, 0.0001, "fornalha soma 12/s"
	)
	assert_almost_eq(
		HeatRules.furnace_dps(HeatRules.KIND_WARM, true, false), 0.0, 0.0001, "zona comum"
	)


func test_active_cold_island_cancels_everything() -> void:
	assert_false(HeatRules.overheats(true, true), "ilha fria anula o status")
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_FURNACE, true, false), 0.0, 0.0001,
		"ilha fria anula até a fornalha"
	)


func test_outside_heat_nothing_happens() -> void:
	assert_false(HeatRules.overheats(false, false), "fora do calor")
	assert_almost_eq(
		HeatRules.exposure_dps(false, HeatRules.KIND_FURNACE, false, false), 0.0, 0.0001, "sem dano"
	)


func test_heat_sink_cuts_heat_damage_to_thirty_percent() -> void:
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_WARM, false, true),
		Balance.OVERHEAT_DPS * Balance.HEAT_SINK_DAMAGE_MULT, 0.0001, "calor com Dissipador"
	)
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_FURNACE, false, true),
		(Balance.OVERHEAT_DPS + Balance.FURNACE_DPS) * Balance.HEAT_SINK_DAMAGE_MULT, 0.0001,
		"fornalha com Dissipador"
	)
	assert_true(HeatRules.overheats(true, false), "o status continua aparecendo")
	assert_true(HeatRules.has_heat_sink([HeatRules.ABILITY_ID]), "habilidade reconhecida")
	assert_false(HeatRules.has_heat_sink([ClimbLogic.ABILITY_ID]), "garras não são Dissipador")


func test_status_is_the_only_source_of_overheat_damage() -> void:
	var statuses := StatusEffects.new()
	statuses.apply(StatusEffects.OVERHEAT)
	var zone_extra: float = HeatRules.furnace_dps(HeatRules.KIND_WARM, true, false)
	assert_almost_eq(
		HeatRules.total_dps(statuses.integrity_dps(), zone_extra, false),
		Balance.OVERHEAT_DPS, 0.0001, "zona quente não soma o DPS duas vezes"
	)
	assert_almost_eq(
		statuses.charge_drain_multiplier(), Balance.OVERHEAT_CHARGE_MULT, 0.0001,
		"lanterna drena 2x"
	)


func test_heat_zone_is_not_a_damage_area() -> void:
	var node: Node = load(HEAT_SCENE).instantiate()
	assert_false(node is DamageArea, "calor não passa pelo DPS do DamageArea")
	assert_true(node is HeatZone, "script da zona")
	node.free()


func test_difficulty_stays_in_game_state() -> void:
	Settings.difficulty = &"hard"
	assert_almost_eq(
		HeatRules.exposure_dps(true, HeatRules.KIND_WARM, false, false),
		Balance.OVERHEAT_DPS, 0.0001, "dificuldade só no GameState"
	)


func test_unknown_kind_is_warm() -> void:
	assert_eq(HeatRules.normalize_kind(&"lava"), HeatRules.KIND_WARM, "tipo inválido vira warm")


func test_discharge_blocks_abilities() -> void:
	var statuses := StatusEffects.new()
	assert_false(statuses.blocks_abilities(), "sem status")
	statuses.apply(StatusEffects.DISCHARGE, Balance.DISCHARGE_TIME)
	assert_true(statuses.blocks_abilities(), "DESCARGA bloqueia as garras")
	statuses.tick(Balance.DISCHARGE_TIME + 0.01)
	assert_false(statuses.blocks_abilities(), "passa depois de 3 s")
