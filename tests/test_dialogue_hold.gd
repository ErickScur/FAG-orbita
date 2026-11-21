extends TestCase

const PREFERRED: StringName = &"rc_argos"
const LONG_WAIT: float = 30.0
const STEP: float = 0.1

var _manager: Node = null


func before_each() -> void:
	_manager = Engine.get_main_loop().root.get_node_or_null(^"DialogueManager")
	if _manager == null:
		return
	GameState.flags.clear()
	_manager.call("hold_ambient", false)


func after_each() -> void:
	if _manager == null:
		return
	_manager.call("hold_ambient", false)
	_manager.call("clear")
	GameState.flags.clear()


func test_holding_hides_an_ambient_line_and_stops_its_clock() -> void:
	var id: StringName = _ambient_id()
	if id == &"":
		fail("nenhuma fala ambiente para o teste")
		return
	_manager.call("play", id)
	assert_true(_manager.call("is_box_visible"), "fala ambiente na tela")
	_manager.call("hold_ambient", true)
	assert_false(_manager.call("is_box_visible"), "terminal aberto esconde a fala ambiente")
	_tick(LONG_WAIT)
	assert_true(_manager.call("is_active"), "a fala espera o terminal fechar")
	_manager.call("hold_ambient", false)
	assert_true(_manager.call("is_box_visible"), "fala volta quando o terminal fecha")
	_tick(LONG_WAIT)
	assert_false(_manager.call("is_active"), "depois a fala segue o tempo normal")


func test_an_ambient_line_queued_while_held_stays_hidden() -> void:
	var id: StringName = _ambient_id()
	if id == &"":
		return
	_manager.call("hold_ambient", true)
	_manager.call("play", id)
	assert_true(_manager.call("is_active"), "na fila")
	assert_false(_manager.call("is_box_visible"), "não aparece por cima do terminal")


func test_the_reactor_line_plays_before_the_dock() -> void:
	var meta: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/reactor_core.json")
	)
	var dock := Vector2i(-1, -1)
	var entities: Dictionary = meta.get("entities", {})
	for key: Variant in entities:
		if String((entities[key] as Dictionary).get("id", "")) == "rc_dock_02":
			dock = LevelParser.key_to_cell(String(key))
	var trigger: Dictionary = {}
	for value: Variant in meta.get("triggers", []) as Array:
		if String((value as Dictionary).get("dialogue", "")) == String(PREFERRED):
			trigger = value
	assert_false(trigger.is_empty(), "gatilho da fala do ARGOS no JSON")
	assert_true(bool(trigger.get("once", false)), "uma vez só")
	var rect: Array = trigger.get("rect", [])
	assert_eq(rect.size(), 4, "retângulo do gatilho")
	if rect.size() < 4 or dock.x < 0:
		return
	var walk_tiles: float = absf(float(dock.x) - float(rect[0]) - float(rect[2])) + absf(
		float(dock.y) - float(rect[1])
	)
	var seconds: float = walk_tiles * Balance.TILE_SIZE / Balance.WALK_SPEED
	assert_true(seconds > _line_seconds(), "a fala termina antes de o MU-7 chegar à doca")


func _line_seconds() -> float:
	var sequences: Dictionary = _manager.call("sequences") if _manager != null else {}
	var data: Dictionary = sequences.get(PREFERRED, {})
	var total: float = 0.0
	for line: Variant in data.get("lines", []) as Array:
		var length: float = float(String((line as Dictionary).get("text", "")).length())
		total += length / Balance.DIALOGUE_CPS
		total += maxf(Balance.DIALOGUE_AMBIENT_MIN_TIME, length / Balance.DIALOGUE_READ_CPS)
	return total


func _ambient_id() -> StringName:
	if _manager == null:
		return &""
	var sequences: Dictionary = _manager.call("sequences")
	if String((sequences.get(PREFERRED, {}) as Dictionary).get("mode", "")) == "ambient":
		return PREFERRED
	for key: Variant in sequences:
		if String((sequences[key] as Dictionary).get("mode", "")) == "ambient":
			return StringName(String(key))
	return &""


func _tick(seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		_manager.call("_process", STEP)
		elapsed += STEP
