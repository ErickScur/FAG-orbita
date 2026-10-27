extends TestCase

const GDD_PATH: String = "res://docs/design/GDD.md"
const TABLE_ANCHOR: String = "<a id=\"gdd-p\"></a>"
const ROW_PATTERN: String = "(?m)^\\| `([A-Z][A-Z0-9_]+)` \\| ([^|]*?) \\|"
const TOLERANCE: float = 0.0001

var _rows: Dictionary = {}


func before_each() -> void:
	_rows = _read_table()


func test_gdd_table_is_found() -> void:
	assert_true(_rows.size() > 100, "tabela GDD-P não encontrada ou truncada em %s" % GDD_PATH)


func test_every_balance_constant_has_a_gdd_row() -> void:
	var constants: Dictionary = Balance.new().get_script().get_script_constant_map()
	for key: String in constants:
		assert_true(
			_rows.has(key),
			"Balance.%s não tem linha na GDD-P: registre o número no GDD antes do código" % key
		)


func test_numeric_values_match_gdd() -> void:
	var constants: Dictionary = Balance.new().get_script().get_script_constant_map()
	for key: String in _rows:
		var text: String = String(_rows[key])
		if not text.is_valid_float():
			continue
		assert_true(constants.has(key), "GDD-P cita %s, que não existe em Balance" % key)
		if not constants.has(key):
			continue
		var value: Variant = constants[key]
		if not (value is int or value is float):
			continue
		assert_almost_eq(
			float(value), text.to_float(), TOLERANCE,
			"Balance.%s difere da GDD-P (%s)" % [key, text]
		)


func _read_table() -> Dictionary:
	var result: Dictionary = {}
	var text: String = FileAccess.get_file_as_string(GDD_PATH)
	var start: int = text.find(TABLE_ANCHOR)
	if start < 0:
		return result
	var pattern := RegEx.new()
	pattern.compile(ROW_PATTERN)
	for found: RegExMatch in pattern.search_all(text.substr(start)):
		result[found.get_string(1)] = found.get_string(2).strip_edges()
	return result
