extends TestCase

const DIALOGUE_DIR: String = "res://data/dialogue/"
const LOGS_DIR: String = "res://data/logs/"
const OBJECTIVES_PATH: String = "res://data/objectives.json"
const DEMO_LOGS: int = 6
const MIN_LOG_LINES: int = 3

var _content: Dictionary = {}


func before_each() -> void:
	_content = DialogueData.merge(
		[DialogueData.load_dir(DIALOGUE_DIR), DialogueData.load_dir(LOGS_DIR)]
	)


func test_all_dialogue_files_load() -> void:
	var errors: PackedStringArray = _content["errors"]
	assert_true(errors.is_empty(), "erros de carga: %s" % ", ".join(errors))
	assert_false((_content["sequences"] as Dictionary).is_empty(), "sequências carregadas")
	assert_false((_content["speakers"] as Dictionary).is_empty(), "falantes carregados")


func test_speakers_exist() -> void:
	var errors: PackedStringArray = DialogueData.validate(
		_content["sequences"], _content["logs"], _content["speakers"]
	)
	assert_true(errors.is_empty(), "validação: %s" % ", ".join(errors))


func test_modes_valid() -> void:
	for key: Variant in _content["sequences"] as Dictionary:
		var mode: StringName = DialogueData.sequence_mode(_content["sequences"], key)
		assert_true(DialogueData.VALID_MODES.has(mode), "modo de '%s'" % key)


func test_unique_ids() -> void:
	var separate: Array = [
		DialogueData.load_dir(DIALOGUE_DIR), DialogueData.load_dir(LOGS_DIR)
	]
	var merged: Dictionary = DialogueData.merge(separate)
	for message: String in merged["errors"] as PackedStringArray:
		assert_false(message.begins_with("id duplicado"), message)


func test_objectives_exist() -> void:
	if not FileAccess.file_exists(OBJECTIVES_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
	var known: Dictionary = parsed if parsed is Dictionary else {}
	var table: Dictionary = known.get("objectives", known)
	for key: Variant in _content["sequences"] as Dictionary:
		var objective: String = String(
			((_content["sequences"] as Dictionary)[key] as Dictionary).get("objective", "")
		)
		if objective.is_empty():
			continue
		assert_true(table.has(objective), "objetivo desconhecido '%s' em '%s'" % [objective, key])


func test_demo_has_six_logs() -> void:
	var logs: Dictionary = _content["logs"]
	assert_eq(logs.size(), DEMO_LOGS, "total de logs da demo")
	for key: Variant in logs:
		var lines: Array = (logs[key] as Dictionary).get("lines", [])
		assert_true(lines.size() >= MIN_LOG_LINES, "log '%s' com %d linhas" % [key, lines.size()])


func test_line_length() -> void:
	var sequence_errors: PackedStringArray = DialogueData.wrap_length_errors(
		_content["sequences"], DialogueData.MAX_LINE_CHARS
	)
	assert_true(sequence_errors.is_empty(), ", ".join(sequence_errors))
	var log_errors: PackedStringArray = DialogueData.log_length_errors(
		_content["logs"], DialogueData.MAX_LINE_CHARS
	)
	assert_true(log_errors.is_empty(), ", ".join(log_errors))


func test_no_twist_words() -> void:
	var errors: PackedStringArray = DialogueData.forbidden_word_errors(
		_content["logs"], DialogueData.FORBIDDEN_WORDS
	)
	assert_true(errors.is_empty(), ", ".join(errors))


func test_unlock_ability_only_on_gh03() -> void:
	for key: Variant in _content["logs"] as Dictionary:
		var ability: String = String(
			((_content["logs"] as Dictionary)[key] as Dictionary).get("unlock_ability", "")
		)
		if String(key) == "log_gh_03":
			assert_eq(ability, "magnetic_claws", "garras no log_gh_03")
		else:
			assert_true(ability.is_empty(), "log '%s' não deveria liberar habilidade" % key)


func test_log_to_sequence_is_blocking() -> void:
	var entry: Dictionary = (_content["logs"] as Dictionary)[&"log_core_01"]
	var sequence: Dictionary = DialogueData.log_to_sequence(entry)
	assert_eq(String(sequence["mode"]), String(DialogueData.MODE_BLOCKING), "modo")
	assert_eq(
		String(sequence["header"]), "LOG DE MANUTENÇÃO 114 — ENGENHARIA CHEFE", "cabeçalho"
	)
	assert_eq((sequence["lines"] as Array).size(), (entry["lines"] as Array).size(), "linhas")


func test_invalid_json_reports_error() -> void:
	var missing: Dictionary = DialogueData.load_file("res://data/dialogue/nao_existe.json")
	assert_eq((missing["errors"] as PackedStringArray).size(), 1, "arquivo ausente vira erro")
