extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"

var _state: Node = null


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()


func after_each() -> void:
	if _state != null:
		_state.free()
		_state = null


func _fill_logs(amount: int) -> void:
	for index in range(amount):
		_state.logs_collected.append(StringName("log_%02d" % index))


func _fill_research(amount: int) -> void:
	for index in range(amount):
		_state.research_collected.append(StringName("res_%02d" % index))


func test_format_time_zero() -> void:
	assert_eq(RunStats.format_time(0.0), "00:00", "zero")


func test_format_time_minutes() -> void:
	assert_eq(RunStats.format_time(754.2), "12:34", "doze e trinta e quatro")


func test_format_time_hours() -> void:
	assert_eq(RunStats.format_time(3725.0), "1:02:05", "mais de uma hora")


func test_format_time_negative_is_zero() -> void:
	assert_eq(RunStats.format_time(-10.0), "00:00", "tempo negativo")


func test_summary_lines_shape() -> void:
	_state.play_time = 754.2
	_state.deaths = 2
	_fill_logs(6)
	_fill_research(4)
	_state.flags["secret_greenhouse_01"] = true
	var lines: PackedStringArray = RunStats.summary_lines(_state)
	assert_eq(lines.size(), 5, "cinco linhas")
	assert_eq(lines[0], "TEMPO      12:34", "tempo")
	assert_eq(lines[1], "LOGS       6/%d" % Balance.LOGS_TOTAL, "logs")
	assert_eq(lines[2], "DADOS      4/%d" % Balance.RESEARCH_TOTAL, "dados")
	assert_eq(lines[3], "MORTES     2", "mortes")
	assert_eq(lines[4], "SEGREDOS   1/%d" % Balance.SECRETS_TOTAL, "segredos")


func test_summary_rows_split_label_and_value() -> void:
	_state.play_time = 0.0
	var rows: Array = RunStats.summary_rows(_state)
	assert_eq(rows.size(), 5, "cinco pares")
	var first: PackedStringArray = rows[0]
	assert_eq(first.size(), 2, "rótulo e valor")
	assert_eq(first[0], "TEMPO", "rótulo")
	assert_eq(first[1], "00:00", "valor")


func test_summary_lines_on_new_game() -> void:
	var lines: PackedStringArray = RunStats.summary_lines(_state)
	assert_eq(lines[1], "LOGS       0/%d" % Balance.LOGS_TOTAL, "nenhum log")
	assert_eq(lines[4], "SEGREDOS   0/%d" % Balance.SECRETS_TOTAL, "nenhum segredo")


func test_secrets_found_counts_only_true_secret_flags() -> void:
	_state.flags["secret_greenhouse_01"] = true
	_state.flags["secret_core_01"] = false
	_state.flags["tutorial_done"] = true
	assert_eq(RunStats.secrets_found(_state), 1, "apenas segredos verdadeiros")


func test_secrets_found_without_flags() -> void:
	assert_eq(RunStats.secrets_found(_state), 0, "sem flags")


func test_unread_logs_line() -> void:
	_fill_logs(1)
	assert_eq(
		RunStats.unread_logs_line(_state),
		"VOCÊ NUNCA VAI LER %d LOGS." % (Balance.LOGS_TOTAL - 1),
		"logs que ficaram para trás"
	)


func test_unread_logs_line_singular() -> void:
	_fill_logs(Balance.LOGS_TOTAL - 1)
	assert_eq(RunStats.unread_logs_line(_state), "VOCÊ NUNCA VAI LER 1 LOG.", "singular")


func test_unread_logs_line_complete() -> void:
	_fill_logs(Balance.LOGS_TOTAL)
	assert_eq(
		RunStats.unread_logs_line(_state),
		"VOCÊ LEU TODOS OS %d LOGS." % Balance.LOGS_TOTAL,
		"coleção completa"
	)


func test_null_state_is_safe() -> void:
	assert_eq(RunStats.secrets_found(null), 0, "segredos")
	assert_eq(RunStats.unread_logs(null), Balance.LOGS_TOTAL, "logs não lidos")
	assert_eq(RunStats.summary_lines(null).size(), 5, "linhas mesmo sem estado")
