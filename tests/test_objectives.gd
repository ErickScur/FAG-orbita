extends TestCase

const DEMO_IDS: Array[StringName] = [&"obj_core_hub", &"obj_greenhouse"]
const LEVEL_OBJECTIVES: Dictionary = {
	"res://data/levels/core_hub.json": "obj_core_hub",
	"res://data/levels/greenhouse.json": "obj_greenhouse",
}
const LEVELS_DIR: String = "res://data/levels/"
const DIALOGUE_DIR: String = "res://data/dialogue/"

var _table: Dictionary = {}


func before_each() -> void:
	_table = Objectives.load_all()


func test_load_all_has_demo_ids() -> void:
	assert_eq(_table.size(), DEMO_IDS.size(), "um objetivo por fase da demo")
	for id: StringName in DEMO_IDS:
		assert_true(_table.has(id), "objetivo %s" % id)


func test_text_for_known() -> void:
	assert_eq(
		Objectives.text_for(&"obj_greenhouse", _table),
		"Religar o Nó do Setor da Estufa",
		"texto com acentos"
	)
	assert_eq(
		Objectives.text_for(&"obj_core_hub", _table),
		"Atravessar o Núcleo Central e chegar à Estufa",
		"objetivo do Núcleo"
	)


func test_text_for_unknown_is_empty() -> void:
	assert_eq(Objectives.text_for(&"obj_inexistente", _table), "", "id desconhecido")
	assert_false(Objectives.has(&"obj_inexistente", _table), "has falso")
	assert_true(Objectives.has(&"obj_core_hub", _table), "has verdadeiro")


func test_each_level_declares_its_own_objective() -> void:
	for path: String in LEVEL_OBJECTIVES:
		var meta: Dictionary = _load_json(path)
		assert_eq(
			String(meta.get("objective", "")),
			String(LEVEL_OBJECTIVES[path]),
			"objetivo de %s" % path
		)


func test_no_trigger_changes_the_objective() -> void:
	for path: String in _files_in(LEVELS_DIR, ".json"):
		var meta: Dictionary = _load_json(path)
		for value: Variant in meta.get("triggers", []) as Array:
			var trigger: Dictionary = value
			assert_false(
				trigger.has("objective"),
				"gatilho '%s' em %s troca o objetivo" % [trigger.get("id", "?"), path]
			)


func test_no_dialogue_changes_the_objective() -> void:
	for path: String in _files_in(DIALOGUE_DIR, ".json"):
		var content: Dictionary = _load_json(path)
		var sequences: Dictionary = content.get("sequences", {})
		for key: Variant in sequences:
			var sequence: Dictionary = sequences[key]
			assert_false(
				sequence.has("objective"), "fala '%s' em %s troca o objetivo" % [key, path]
			)


func test_json_is_flat_strings() -> void:
	for id: Variant in _table:
		var value: Variant = _table[id]
		assert_true(value is String, "valor de %s é texto" % id)
		assert_false(String(value).is_empty(), "valor de %s não é vazio" % id)


func test_load_all_missing_file_is_empty() -> void:
	var missing: Dictionary = Objectives.load_all("res://data/nao_existe.json")
	assert_eq(missing.size(), 0, "arquivo ausente devolve vazio")


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	return parsed


func _files_in(directory: String, suffix: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		if file_name.ends_with(suffix):
			found.append(directory + file_name)
	found.sort()
	return found
