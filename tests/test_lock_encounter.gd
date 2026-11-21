extends TestCase

const STEP: float = 1.0 / 60.0
const WEST: StringName = &"west"
const CENTER: StringName = &"center"
const EAST: StringName = &"east"
const PARK_X: float = 1800.0
const GATE_X: float = 1520.0
const VENT_X: float = 1600.0

var _fight: LockEncounter = null


func before_each() -> void:
	_fight = LockEncounter.new()
	_fight.setup(
		{WEST: 1400.0, CENTER: 1600.0, EAST: 1800.0},
		PARK_X,
		{LockEncounter.STAGE_GATE: GATE_X, LockEncounter.STAGE_VENT: VENT_X},
		3
	)


func test_starts_dormant_and_ignores_time() -> void:
	assert_eq(_fight.phase, LockEncounter.Phase.DORMANT, "dormente")
	var events: Array[Dictionary] = _run(5.0, 0.0, {}, 0, true)
	assert_eq(events.size(), 0, "nada acontece antes de o MU-7 descer")
	assert_almost_eq(_fight.time_left, Balance.LOCK_TIME_LIMIT, 0.001, "relógio cheio")


func test_start_seals_the_entry_and_arms_after_waking() -> void:
	var events: Array[Dictionary] = _fight.start()
	assert_true(_has(events, LockEncounter.EVENT_SEAL_ENTRY), "a escotilha sela na hora")
	assert_eq(_fight.phase, LockEncounter.Phase.WAKING, "acordando")
	assert_eq(_fight.start().size(), 0, "começar de novo não faz nada")
	events = _run(Balance.LOCK_WAKE_TIME + STEP, 0.0, {}, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_ARMED), "acopladores armados")
	assert_eq(_fight.phase, LockEncounter.Phase.ACTIVE, "ativo")


func test_holding_charges_a_coupler_in_the_charge_time() -> void:
	_arm()
	var holding: Dictionary = {WEST: true}
	_run(Balance.LOCK_CHARGE_TIME * 0.5, 1400.0, holding, 0, true)
	assert_almost_eq(_fight.progress(WEST), 0.5, 0.03, "meia carga")
	var events: Array[Dictionary] = _run(Balance.LOCK_CHARGE_TIME * 0.6, 1400.0, holding, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_POWERED), "alimentado")
	assert_true(_fight.is_powered(WEST), "acoplador oeste alimentado")
	assert_eq(_fight.powered_count(), 1, "um de três")


func test_releasing_drains_the_charge() -> void:
	_arm()
	_run(Balance.LOCK_CHARGE_TIME * 0.5, 1400.0, {WEST: true}, 0, true)
	_run(1.0, 1400.0, {}, 0, true)
	assert_almost_eq(
		_fight.progress(WEST), 0.5 - Balance.LOCK_CHARGE_DECAY, 0.03, "perde carga ao soltar"
	)


func test_the_arm_hunts_the_coupler_nearest_the_player() -> void:
	_arm()
	_run(0.5, 1590.0, {}, 0, true)
	assert_eq(_fight.arm_target, CENTER, "persegue o do centro")
	assert_true(_fight.arm_x < PARK_X, "anda para oeste")
	_run(0.5, 1820.0, {}, 0, true)
	assert_eq(_fight.arm_target, EAST, "troca de alvo quando o MU-7 troca de lado")


func test_the_arm_seals_and_steals_the_charge() -> void:
	_arm()
	var holding: Dictionary = {EAST: true}
	var events: Array[Dictionary] = _run(0.2, 1800.0, holding, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_WINDUP), "a garra desce: aviso")
	events = _run(Balance.LOCK_SEAL_WINDUP, 1800.0, holding, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_SEAL), "trava")
	assert_true(_has(events, LockEncounter.EVENT_CHARGE_LOST), "quem carregava perde")
	assert_true(_fight.is_sealed(EAST), "trancado")
	assert_almost_eq(_fight.progress(EAST), 0.0, 0.001, "carga zerada")
	_run(1.0, 1800.0, holding, 0, true)
	assert_almost_eq(_fight.progress(EAST), 0.0, 0.001, "trancado não carrega")
	events = _run(Balance.LOCK_SEAL_TIME, 1800.0, holding, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_UNSEAL), "solta a placa")
	assert_false(_fight.is_sealed(EAST), "livre de novo")
	assert_eq(_fight.arm_state, LockEncounter.Arm.REST, "descansa")


func test_the_last_coupler_always_has_a_window() -> void:
	assert_true(
		Balance.LOCK_ARM_REST + Balance.LOCK_SEAL_WINDUP > Balance.LOCK_CHARGE_TIME,
		"descanso + aviso maior que a carga: o último acoplador tem janela"
	)
	_fight = LockEncounter.new()
	_fight.setup({EAST: 1800.0}, PARK_X, {}, 0)
	_fight.start()
	_run(Balance.LOCK_WAKE_TIME + STEP, 1800.0, {}, 0, true)
	_run(Balance.LOCK_SEAL_WINDUP + 0.1, 1800.0, {}, 0, true)
	assert_true(_fight.is_sealed(EAST), "trancado com o braço em cima")
	_run(Balance.LOCK_SEAL_TIME, 1800.0, {EAST: true}, 0, true)
	var events: Array[Dictionary] = _run(
		Balance.LOCK_CHARGE_TIME + 0.1, 1800.0, {EAST: true}, 0, true
	)
	assert_true(_has(events, LockEncounter.EVENT_DEFEATED), "carregou na janela")


func test_the_arm_is_far_when_the_player_starts_at_the_west() -> void:
	_arm()
	var events: Array[Dictionary] = _run(
		Balance.LOCK_CHARGE_TIME + 0.1, 1400.0, {WEST: true}, 0, true
	)
	assert_true(_has(events, LockEncounter.EVENT_POWERED), "o primeiro sai antes do braço")
	assert_false(_has(events, LockEncounter.EVENT_SEAL), "sem trava")


func test_each_coupler_changes_the_arena() -> void:
	_arm()
	_run(Balance.LOCK_CHARGE_TIME + 0.1, 1400.0, {WEST: true}, 0, true)
	assert_eq(_fight.phase, LockEncounter.Phase.STAGGER, "o braço estremece")
	var events: Array[Dictionary] = _run(Balance.LOCK_STAGGER_TIME + 3.0, 1400.0, {}, 0, true)
	var stage_event: Dictionary = _first(events, LockEncounter.EVENT_STAGE)
	assert_eq(int(stage_event.get("stage", 0)), LockEncounter.STAGE_GATE, "1º: comporta do piso")
	assert_almost_eq(float(stage_event.get("x", 0.0)), GATE_X, 0.001, "solda na comporta")
	_run(Balance.LOCK_WELD_TIME + 0.1, 1800.0, {}, 0, true)
	_hold_until_powered(CENTER, 1600.0)
	assert_eq(_fight.powered_count(), 2, "dois")
	events = _run(Balance.LOCK_STAGGER_TIME + 3.0, 1600.0, {}, 0, true)
	stage_event = _first(events, LockEncounter.EVENT_STAGE)
	assert_eq(int(stage_event.get("stage", 0)), LockEncounter.STAGE_VENT, "2º: purga em vácuo")


func test_three_couplers_shut_it_down() -> void:
	_arm()
	var events: Array[Dictionary] = []
	events.append_array(_charge(WEST, 1400.0))
	events.append_array(_charge(CENTER, 1600.0))
	events.append_array(_charge(EAST, 1800.0))
	assert_true(_has(events, LockEncounter.EVENT_DEFEATED), "desligado")
	assert_eq(_fight.phase, LockEncounter.Phase.DEFEATED, "fase final")
	assert_eq(_fight.arm_state, LockEncounter.Arm.OFF, "braço apagado")
	assert_eq(_run(10.0, 1400.0, {}, 0, true).size(), 0, "desligado não faz mais nada")
	assert_eq(_fight.reset().size(), 0, "vitória não reinicia")


func test_time_out_contains_the_arena() -> void:
	_arm()
	var events: Array[Dictionary] = _run(Balance.LOCK_TIME_LIMIT + 0.1, 1400.0, {}, 0, true)
	assert_true(_has(events, LockEncounter.EVENT_CONTAINED), "contenção completa")
	assert_eq(_fight.phase, LockEncounter.Phase.CONTAINED, "contida")
	for id: StringName in [WEST, CENTER, EAST]:
		assert_true(_fight.is_sealed(id), "%s trancado" % id)
	var lamps: PackedInt32Array = _fight.lamp_states(Balance.LOCK_LAMPS)
	assert_false(lamps.has(LockEncounter.LAMP_AMBER), "todas as luzes vermelhas")


func test_the_clock_stops_when_it_is_frozen() -> void:
	_arm()
	_run(30.0, 1400.0, {}, 0, false)
	assert_almost_eq(_fight.time_left, Balance.LOCK_TIME_LIMIT, 0.001, "relógio parado")
	assert_true(_fight.spawn_count > 0, "as SR-3 continuam caindo")


func test_spawns_follow_the_rhythm_and_the_cap() -> void:
	_arm()
	var events: Array[Dictionary] = _run(Balance.LOCK_FIRST_SPAWN - 0.1, 1400.0, {}, 0, true)
	assert_false(_has(events, LockEncounter.EVENT_SPAWN), "ainda não")
	events = _run(0.2, 1400.0, {}, 0, true)
	assert_eq(int(_first(events, LockEncounter.EVENT_SPAWN).get("bay", -1)), 0, "primeira baia")
	events = _run(Balance.LOCK_SPAWN_INTERVAL, 1400.0, {}, 1, true)
	assert_eq(int(_first(events, LockEncounter.EVENT_SPAWN).get("bay", -1)), 1, "segunda baia")
	events = _run(Balance.LOCK_SPAWN_INTERVAL * 3.0, 1400.0, {}, Balance.LOCK_SR3_MAX, true)
	assert_false(_has(events, LockEncounter.EVENT_SPAWN), "teto de SR-3 vivas")


func test_spawns_speed_up_with_each_coupler() -> void:
	_arm()
	var before: float = _fight.spawn_interval()
	_run(Balance.LOCK_CHARGE_TIME + 0.1, 1400.0, {WEST: true}, 0, true)
	assert_almost_eq(
		before - _fight.spawn_interval(), Balance.LOCK_SPAWN_STEP, 0.001, "mais rápido"
	)


func test_death_freezes_and_respawn_resets_everything() -> void:
	_arm()
	_run(Balance.LOCK_CHARGE_TIME + 0.1, 1400.0, {WEST: true}, 0, true)
	_run(5.0, 1600.0, {CENTER: true}, 0, true)
	_fight.freeze()
	assert_eq(_fight.phase, LockEncounter.Phase.FROZEN, "congela com o MU-7 caído")
	var time_before: float = _fight.time_left
	assert_eq(_run(5.0, 1600.0, {CENTER: true}, 0, true).size(), 0, "congelado não anda")
	assert_almost_eq(_fight.time_left, time_before, 0.001, "relógio parado")
	var events: Array[Dictionary] = _fight.reset()
	assert_true(_has(events, LockEncounter.EVENT_RESET), "reinício")
	assert_eq(_fight.phase, LockEncounter.Phase.DORMANT, "dormente de novo")
	assert_eq(_fight.powered_count(), 0, "acopladores apagados")
	assert_almost_eq(_fight.arm_x, PARK_X, 0.001, "braço estacionado")
	assert_almost_eq(_fight.time_left, Balance.LOCK_TIME_LIMIT, 0.001, "relógio cheio")
	assert_eq(_fight.stage, 0, "sem estágio")
	assert_eq(_fight.spawn_count, 0, "contagem de SR-3 zerada")
	for id: StringName in [WEST, CENTER, EAST]:
		assert_false(_fight.is_sealed(id), "%s livre" % id)
		assert_almost_eq(_fight.progress(id), 0.0, 0.001, "%s sem carga" % id)
	assert_true(_has(_fight.start(), LockEncounter.EVENT_SEAL_ENTRY), "recomeça limpo")


func test_contained_also_resets_on_respawn() -> void:
	_arm()
	_run(Balance.LOCK_TIME_LIMIT + 0.1, 1400.0, {}, 0, true)
	_fight.freeze()
	_fight.reset()
	assert_eq(_fight.phase, LockEncounter.Phase.DORMANT, "contida também reinicia")


func test_lamps_close_in_from_the_ends() -> void:
	assert_eq(LockEncounter.lamp_by_rank(0, 12), 0, "primeira ponta")
	assert_eq(LockEncounter.lamp_by_rank(1, 12), 11, "outra ponta")
	assert_eq(LockEncounter.lamp_by_rank(2, 12), 1, "fecha para o centro")
	assert_eq(_fight.lamp_states(12).count(LockEncounter.LAMP_OFF), 12, "apagadas antes")
	_arm()
	assert_eq(_fight.lamp_states(12).count(LockEncounter.LAMP_AMBER), 12, "âmbar ao acordar")
	_run(Balance.LOCK_TIME_LIMIT * 0.51, 1400.0, {}, 0, true)
	var lamps: PackedInt32Array = _fight.lamp_states(12)
	assert_eq(lamps.count(LockEncounter.LAMP_RED), 6, "metade vermelha na metade do tempo")
	assert_eq(lamps[0], LockEncounter.LAMP_RED, "ponta oeste")
	assert_eq(lamps[11], LockEncounter.LAMP_RED, "ponta leste")
	assert_eq(lamps[5], LockEncounter.LAMP_AMBER, "centro ainda âmbar")


func test_defeat_instantly_restores_a_won_fight() -> void:
	_fight.defeat_instantly()
	assert_true(_fight.is_defeated(), "vitória salva")
	assert_eq(_fight.powered_count(), 3, "acopladores acesos")
	assert_eq(_fight.start().size(), 0, "não acorda de novo")


func _arm() -> void:
	_fight.start()
	_run(Balance.LOCK_WAKE_TIME + STEP, 0.0, {}, 0, true)


func _charge(id: StringName, x: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = _hold_until_powered(id, x)
	events.append_array(_run(Balance.LOCK_STAGGER_TIME + 4.0, x, {}, 0, true))
	return events


func _hold_until_powered(id: StringName, x: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for _frame: int in range(int(30.0 / STEP)):
		events.append_array(_fight.tick(STEP, x, {id: true}, 0, true))
		if _fight.is_powered(id):
			break
	return events


func _run(
	seconds: float, player_x: float, holding: Dictionary, alive: int, clock: bool
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var frames: int = int(ceil(seconds / STEP))
	for _frame: int in range(frames):
		events.append_array(_fight.tick(STEP, player_x, holding, alive, clock))
	return events


func _has(events: Array[Dictionary], type: StringName) -> bool:
	return not _first(events, type).is_empty()


func _first(events: Array[Dictionary], type: StringName) -> Dictionary:
	for event: Dictionary in events:
		if StringName(event.get("type", &"")) == type:
			return event
	return {}
