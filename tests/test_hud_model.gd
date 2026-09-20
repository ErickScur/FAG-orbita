extends TestCase

var _texts: Dictionary = {}


func before_each() -> void:
	_texts = HudModel.load_texts()


func test_cell_states() -> void:
	assert_eq(
		HudModel.cell_states(100, 100, 4), [2, 2, 2, 2] as Array[int], "integridade cheia"
	)
	assert_eq(HudModel.cell_states(60, 100, 4), [2, 2, 1, 0] as Array[int], "60 de 100")
	assert_eq(HudModel.cell_states(0, 100, 4), [0, 0, 0, 0] as Array[int], "morto")
	assert_eq(HudModel.cell_states(25, 100, 4), [2, 0, 0, 0] as Array[int], "uma célula")


func test_cell_states_guards() -> void:
	assert_eq(HudModel.cell_states(50, 100, 0).size(), 0, "sem células")
	assert_eq(HudModel.cell_states(500, 100, 4), [2, 2, 2, 2] as Array[int], "satura no máximo")


func test_is_low_integrity() -> void:
	assert_true(HudModel.is_low_integrity(HudModel.cell_states(20, 100, 4)), "uma célula parcial")
	assert_true(HudModel.is_low_integrity(HudModel.cell_states(0, 100, 4)), "zerado")
	assert_false(HudModel.is_low_integrity(HudModel.cell_states(60, 100, 4)), "três células")


func test_atlas_cell() -> void:
	assert_eq(HudModel.atlas_cell(0, 8), Vector2i(0, 0), "primeiro")
	assert_eq(HudModel.atlas_cell(7, 8), Vector2i(7, 0), "fim da linha")
	assert_eq(HudModel.atlas_cell(10, 8), Vector2i(2, 1), "segunda linha")
	assert_eq(HudModel.atlas_cell(3, 0), Vector2i.ZERO, "colunas inválidas")


func test_status_icon_index() -> void:
	assert_eq(HudModel.status_icon_index(&"corrosion"), 5, "corrosão")
	assert_eq(HudModel.status_icon_index(&"overload"), 9, "sobrecarga")
	assert_eq(
		HudModel.status_icon_index(&"desconhecido"), HudModel.ICON_STATUS_FIRST, "desconhecido"
	)


func test_status_seconds() -> void:
	assert_eq(HudModel.status_seconds(6.0), 6, "inteiro")
	assert_eq(HudModel.status_seconds(5.2), 6, "arredonda para cima")
	assert_eq(HudModel.status_seconds(-1.0), 0, "nunca negativo")


func test_format_helpers() -> void:
	assert_eq(HudModel.format_pair("LOGS %02d/%02d", 1, 24), "LOGS 01/24", "contador de logs")
	assert_eq(HudModel.format_pair("", 1, 24), "1/24", "sem template")
	assert_eq(HudModel.format_single("+%d CARGA", 40), "+40 CARGA", "toast de carga")
	assert_eq(HudModel.format_single("", 7), "7", "sem template")


func test_charge_ratio() -> void:
	assert_almost_eq(HudModel.charge_ratio(35.0, 100.0), 0.35, 0.0001, "um terço")
	assert_almost_eq(HudModel.charge_ratio(35.0, 0.0), 0.0, 0.0001, "máximo zero")


func test_texts_table_has_hud_keys() -> void:
	var required: Array[StringName] = [
		&"reactor_title",
		&"reactor_critical",
		&"reactor_frozen",
		&"reactor_no_timer",
		&"integrity_label",
		&"charge_label",
		&"counter_logs",
		&"counter_research",
		&"toast_log",
		&"toast_research",
		&"toast_objective",
	]
	for id: StringName in required:
		assert_true(_texts.has(id), "texto %s" % id)
		assert_false(HudModel.text_for(id, _texts).is_empty(), "texto %s não vazio" % id)


func test_reactor_title_template_formats() -> void:
	var template: String = HudModel.text_for(&"reactor_title", _texts)
	assert_eq(template % 74, "REATOR 74%", "título formatado")


func test_reactor_state_is_hidden_when_nothing_to_say() -> void:
	assert_eq(
		HudModel.reactor_state_id(false, false, false),
		HudModel.REACTOR_STATE_NONE,
		"estado normal não mostra linha"
	)


func test_reactor_state_shows_frozen_timer() -> void:
	assert_eq(
		HudModel.reactor_state_id(false, true, false),
		HudModel.REACTOR_STATE_FROZEN,
		"leitura de log congela o timer"
	)
	assert_eq(
		HudModel.text_for(HudModel.REACTOR_STATE_FROZEN, _texts),
		"TIMER PARADO",
		"texto do timer congelado"
	)


func test_reactor_state_shows_no_timer_mode() -> void:
	assert_eq(
		HudModel.reactor_state_id(false, true, true),
		HudModel.REACTOR_STATE_NO_TIMER,
		"modo sem timer tem texto próprio"
	)
	assert_eq(
		HudModel.text_for(HudModel.REACTOR_STATE_NO_TIMER, _texts),
		"SEM TIMER",
		"texto do modo sem timer"
	)


func test_reactor_state_critical_wins_over_frozen() -> void:
	assert_eq(
		HudModel.reactor_state_id(true, false, false),
		HudModel.REACTOR_STATE_CRITICAL,
		"crítico sozinho"
	)
	assert_eq(
		HudModel.reactor_state_id(true, true, true),
		HudModel.REACTOR_STATE_CRITICAL,
		"crítico tem prioridade"
	)
	assert_eq(
		HudModel.text_for(HudModel.REACTOR_STATE_CRITICAL, _texts), "CRÍTICO", "texto crítico"
	)


func test_counters_fit_the_demo_totals() -> void:
	var logs: String = HudModel.format_pair(
		HudModel.text_for(&"counter_logs", _texts), 1, Balance.LOGS_TOTAL
	)
	var research: String = HudModel.format_pair(
		HudModel.text_for(&"counter_research", _texts), 0, Balance.RESEARCH_TOTAL
	)
	assert_eq(logs, "LOGS 1/%d" % Balance.LOGS_TOTAL, "contador de logs lê do Balance")
	assert_eq(research, "DADOS 0/%d" % Balance.RESEARCH_TOTAL, "contador de dados lê do Balance")


func test_first_pickup_card_texts_exist() -> void:
	for kind: StringName in PickupRules.KINDS:
		var title: StringName = PickupRules.first_text_id(kind)
		var hint: StringName = PickupRules.first_hint_id(kind)
		assert_false(HudModel.text_for(title, _texts).is_empty(), "nome de %s" % kind)
		assert_false(HudModel.text_for(hint, _texts).is_empty(), "explicação de %s" % kind)


func test_first_pickup_ids_follow_the_kind() -> void:
	assert_eq(PickupRules.first_text_id(&"cell"), &"first_cell", "id do nome")
	assert_eq(PickupRules.first_hint_id(&"cell"), &"first_cell_hint", "id da explicação")
	assert_eq(PickupRules.seen_flag(&"research"), "seen_kind_research", "flag de primeira coleta")


func test_seen_flag_is_unique_per_kind() -> void:
	var flags: Array[String] = []
	for kind: StringName in PickupRules.KINDS:
		var flag: String = PickupRules.seen_flag(kind)
		assert_false(flags.has(flag), "flag repetida em %s" % kind)
		flags.append(flag)
