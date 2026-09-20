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
		&"reactor_falling",
		&"reactor_frozen",
		&"reactor_no_timer",
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
	assert_eq(template % 74, "ESTABILIDADE DO REATOR: 74%", "título formatado")
