extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"

var _state: Node = null
var _previous_difficulty: StringName = &"normal"


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_state.new_game()
	_previous_difficulty = Settings.difficulty


func after_each() -> void:
	Settings.difficulty = _previous_difficulty
	if _state != null:
		_state.free()
		_state = null


func test_new_game_defaults() -> void:
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "reactor_percent")
	assert_eq(_state.integrity, Balance.INTEGRITY_MAX, "integrity")
	assert_eq(_state.integrity_max, Balance.INTEGRITY_MAX, "integrity_max")
	assert_almost_eq(_state.charge, Balance.CHARGE_MAX, 0.0001, "charge")
	assert_almost_eq(_state.charge_max, Balance.CHARGE_MAX, 0.0001, "charge_max")
	assert_eq(_state.logs_collected.size(), 0, "logs_collected")
	assert_eq(_state.research_collected.size(), 0, "research_collected")
	assert_eq(_state.collected_ids.size(), 0, "collected_ids")
	assert_eq(_state.abilities.size(), 0, "abilities")
	assert_eq(_state.sectors_restored.size(), 0, "sectors_restored")
	assert_eq(_state.deaths, 0, "deaths")
	assert_almost_eq(_state.play_time, 0.0, 0.0001, "play_time")
	assert_eq(_state.checkpoint.size(), 0, "checkpoint")


func test_apply_damage_hard() -> void:
	Settings.difficulty = &"hard"
	_state.apply_damage(10)
	assert_eq(_state.integrity, Balance.INTEGRITY_MAX - 15, "dano em difícil")


func test_apply_damage_easy() -> void:
	Settings.difficulty = &"easy"
	_state.apply_damage(10)
	assert_eq(_state.integrity, Balance.INTEGRITY_MAX - 5, "dano em fácil")


func test_apply_damage_kills_once() -> void:
	Settings.difficulty = &"normal"
	_state.apply_damage(Balance.INTEGRITY_MAX)
	assert_eq(_state.integrity, 0, "integridade zerada")
	assert_true(_state.is_dead(), "is_dead")
	_state.apply_damage(10)
	assert_eq(_state.integrity, 0, "dano após morte")


func test_repair_restores_integrity() -> void:
	Settings.difficulty = &"normal"
	_state.apply_damage(50)
	_state.repair(Balance.REPAIR_KIT_INTEGRITY)
	assert_eq(_state.integrity, Balance.INTEGRITY_MAX - 50 + Balance.REPAIR_KIT_INTEGRITY, "repair")


func test_spend_charge_rejects_when_short() -> void:
	_state.charge = 10.0
	assert_false(_state.spend_charge(20.0), "spend_charge insuficiente")
	assert_almost_eq(_state.charge, 10.0, 0.0001, "carga intacta")
	assert_true(_state.spend_charge(10.0), "spend_charge suficiente")
	assert_almost_eq(_state.charge, 0.0, 0.0001, "carga gasta")


func test_add_charge_saturates() -> void:
	_state.add_charge(500.0)
	assert_almost_eq(_state.charge, _state.charge_max, 0.0001, "add_charge satura")


func test_change_reactor_clamps() -> void:
	_state.change_reactor(-500.0)
	assert_almost_eq(_state.reactor_percent, 0.0, 0.0001, "piso")
	_state.change_reactor(500.0)
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "teto")


func test_register_pickup_is_unique() -> void:
	assert_true(_state.register_pickup(&"log", &"log_01"), "primeira coleta")
	assert_false(_state.register_pickup(&"log", &"log_01"), "coleta repetida")
	assert_eq(_state.logs_collected.size(), 1, "logs_collected")
	assert_true(_state.register_pickup(&"research", &"res_01"), "pesquisa")
	assert_eq(_state.research_collected.size(), 1, "research_collected")
	assert_eq(_state.collected_ids.size(), 2, "collected_ids")


func test_dict_round_trip_through_json() -> void:
	_state.apply_damage(10)
	_state.register_pickup(&"log", &"log_01")
	_state.register_pickup(&"research", &"res_01")
	_state.abilities.append(&"magnetic_claws")
	_state.sectors_restored.append(&"greenhouse")
	_state.energy_states[&"gh_terminal"] = [&"heater", &"lights"]
	_state.checkpoint = {"scene": "res://scenes/levels/greenhouse.tscn", "dock_id": "gh_dock_01"}
	_state.flags["alarm"] = true
	_state.deaths = 2
	_state.play_time = 123.5
	_state.change_reactor(-7.5)
	var encoded: String = JSON.stringify(_state.to_dict())
	var decoded: Variant = JSON.parse_string(encoded)
	assert_true(decoded is Dictionary, "json decodificado")
	var restored: Node = load(GAME_STATE_SCRIPT).new()
	restored.from_dict(decoded)
	assert_eq(restored.integrity, _state.integrity, "integrity")
	assert_eq(restored.deaths, _state.deaths, "deaths")
	assert_almost_eq(restored.play_time, _state.play_time, 0.0001, "play_time")
	assert_almost_eq(restored.reactor_percent, _state.reactor_percent, 0.0001, "reactor_percent")
	assert_eq(restored.logs_collected, _state.logs_collected, "logs_collected")
	assert_eq(restored.research_collected, _state.research_collected, "research_collected")
	assert_eq(restored.collected_ids, _state.collected_ids, "collected_ids")
	assert_eq(restored.abilities, _state.abilities, "abilities")
	assert_eq(restored.sectors_restored, _state.sectors_restored, "sectors_restored")
	assert_eq(restored.energy_states, _state.energy_states, "energy_states")
	assert_eq(restored.checkpoint, _state.checkpoint, "checkpoint")
	assert_eq(restored.flags, _state.flags, "flags")
	restored.free()


func test_timer_freezes_without_timer_setting() -> void:
	var previous: bool = Settings.no_timer
	Settings.no_timer = true
	assert_true(_state.is_timer_frozen(), "no_timer congela")
	Settings.no_timer = false
	assert_false(_state.is_timer_frozen(), "sem congelamento")
	Settings.no_timer = previous


func test_expand_charge_max_is_permanent() -> void:
	_state.charge = 10.0
	_state.expand_charge_max(Balance.CAPACITOR_BONUS)
	assert_almost_eq(
		_state.charge_max, Balance.CHARGE_MAX + Balance.CAPACITOR_BONUS, 0.0001, "charge_max"
	)
	assert_almost_eq(_state.charge, 10.0 + Balance.CAPACITOR_BONUS, 0.0001, "charge")
	_state.add_charge(1000.0)
	assert_almost_eq(_state.charge, _state.charge_max, 0.0001, "satura no novo máximo")


func test_capacitor_bonus_survives_the_save() -> void:
	_state.expand_charge_max(Balance.CAPACITOR_BONUS)
	_state.register_pickup(&"capacitor", &"cap_01")
	var decoded: Variant = JSON.parse_string(JSON.stringify(_state.to_dict()))
	var restored: Node = load(GAME_STATE_SCRIPT).new()
	restored.from_dict(decoded)
	assert_almost_eq(
		restored.charge_max, Balance.CHARGE_MAX + Balance.CAPACITOR_BONUS, 0.0001, "charge_max"
	)
	assert_true(restored.collected_ids.has(&"cap_01"), "capacitor não reaparece")
	restored.free()


func test_get_stats_reports_the_run() -> void:
	_state.play_time = 754.2
	_state.deaths = 2
	_state.register_pickup(&"log", &"log_core_01")
	_state.register_pickup(&"research", &"res_01")
	_state.register_pickup(&"research", &"res_02")
	_state.sectors_restored.append(&"greenhouse")
	_state.flags["secret_greenhouse_01"] = true
	var stats: Dictionary = _state.get_stats()
	assert_almost_eq(float(stats["time"]), 754.2, 0.0001, "time")
	assert_eq(String(stats["time_text"]), "12:34", "time_text")
	assert_eq(int(stats["logs"]), 1, "logs")
	assert_eq(int(stats["logs_total"]), Balance.LOGS_TOTAL, "logs_total")
	assert_eq(int(stats["research"]), 2, "research")
	assert_eq(int(stats["research_total"]), Balance.RESEARCH_TOTAL, "research_total")
	assert_eq(int(stats["deaths"]), 2, "deaths")
	assert_eq(int(stats["secrets"]), 1, "secrets")
	assert_eq(int(stats["secrets_total"]), Balance.SECRETS_TOTAL, "secrets_total")
	assert_eq(int(stats["sectors"]), 1, "sectors")


func test_get_stats_rows_match_run_stats() -> void:
	_state.play_time = 61.0
	var stats: Dictionary = _state.get_stats()
	var rows: Array = stats["rows"]
	assert_eq(rows.size(), 5, "cinco linhas")
	var first: PackedStringArray = rows[0]
	assert_eq(first[0], "TEMPO", "rótulo")
	assert_eq(first[1], "01:01", "valor")
	assert_eq((stats["lines"] as PackedStringArray).size(), 5, "linhas formatadas")
