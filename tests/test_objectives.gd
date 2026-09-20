extends TestCase

const DEMO_IDS: Array[StringName] = [
	&"obj_calibrate",
	&"obj_read_log",
	&"obj_open_habitat",
	&"obj_reach_greenhouse",
	&"obj_find_terminal_gh",
	&"obj_gh_choose_route",
	&"obj_gh_ride_lift",
	&"obj_gh_climb_plant",
	&"obj_gh_reach_corridor",
	&"obj_gh_find_claws",
	&"obj_gh_climb_wall",
	&"obj_gh_open_node_door",
	&"obj_restore_gh",
]

var _table: Dictionary = {}


func before_each() -> void:
	_table = Objectives.load_all()


func test_load_all_has_demo_ids() -> void:
	assert_eq(_table.size(), DEMO_IDS.size(), "quantidade de objetivos da demo")
	for id: StringName in DEMO_IDS:
		assert_true(_table.has(id), "objetivo %s" % id)


func test_text_for_known() -> void:
	assert_eq(
		Objectives.text_for(&"obj_restore_gh", _table),
		"Religar o Nó do Setor da Estufa",
		"texto com acentos"
	)


func test_text_for_unknown_is_empty() -> void:
	assert_eq(Objectives.text_for(&"obj_inexistente", _table), "", "id desconhecido")
	assert_false(Objectives.has(&"obj_inexistente", _table), "has falso")
	assert_true(Objectives.has(&"obj_calibrate", _table), "has verdadeiro")


func test_json_is_flat_strings() -> void:
	for id: Variant in _table:
		var value: Variant = _table[id]
		assert_true(value is String, "valor de %s é texto" % id)
		assert_false(String(value).is_empty(), "valor de %s não é vazio" % id)


func test_load_all_missing_file_is_empty() -> void:
	var missing: Dictionary = Objectives.load_all("res://data/nao_existe.json")
	assert_eq(missing.size(), 0, "arquivo ausente devolve vazio")
