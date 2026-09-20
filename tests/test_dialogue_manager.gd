extends TestCase

const DEMO_SEQUENCES: int = 30
const DEMO_LOGS: int = 4
const DEMO_SPEAKERS: int = 3

var _manager: Node = null
var _started: int = 0
var _finished: int = 0
var _opened: Array[StringName] = []
var _closed: Array[StringName] = []
var _abilities: Array[StringName] = []


func before_each() -> void:
	_manager = _find_manager()
	_started = 0
	_finished = 0
	_opened.clear()
	_closed.clear()
	_abilities.clear()
	if _manager == null:
		return
	GameState.flags.clear()
	GameState.abilities.clear()
	EventBus.dialogue_started.connect(_on_started)
	EventBus.dialogue_finished.connect(_on_finished)
	EventBus.log_opened.connect(_on_log_opened)
	EventBus.log_closed.connect(_on_log_closed)
	EventBus.ability_unlocked.connect(_on_ability)


func after_each() -> void:
	if _manager == null:
		return
	while _manager.call("is_active"):
		_manager.call("advance")
	EventBus.dialogue_started.disconnect(_on_started)
	EventBus.dialogue_finished.disconnect(_on_finished)
	EventBus.log_opened.disconnect(_on_log_opened)
	EventBus.log_closed.disconnect(_on_log_closed)
	EventBus.ability_unlocked.disconnect(_on_ability)
	GameState.flags.clear()
	GameState.abilities.clear()


func test_content_loaded() -> void:
	if _manager == null:
		fail("DialogueManager ausente")
		return
	assert_eq(
		(_manager.call("sequence_ids") as Array).size(), DEMO_SEQUENCES, "sequências da demo"
	)
	assert_eq((_manager.call("log_ids") as Array).size(), DEMO_LOGS, "logs da demo")
	assert_eq((_manager.call("speakers") as Dictionary).size(), DEMO_SPEAKERS, "falantes")


func test_play_blocking_freezes_timer() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_wake")
	assert_true(_manager.call("is_active"), "diálogo ativo")
	assert_true(_manager.call("freezes_timer"), "congela o timer")
	assert_eq(_started, 1, "dialogue_started emitido uma vez")
	assert_eq(String(_manager.call("current_speaker")), "orbita", "falante")
	assert_eq(
		_manager.call("current_text"), "Sistema de manutenção ÓRBITA... online.", "texto do JSON"
	)


func test_ambient_does_not_freeze_timer() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_bark_lights_on")
	assert_true(_manager.call("is_active"), "bark ativo")
	assert_false(_manager.call("freezes_timer"), "bark não congela o timer")
	assert_eq(_started, 0, "bark não emite dialogue_started")


func test_advance_walks_the_lines() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_terminal_first")
	_manager.call("skip")
	_manager.call("advance")
	assert_true(
		String(_manager.call("current_text")).begins_with("Para ligar a porta"), "segunda linha"
	)
	_manager.call("skip")
	_manager.call("advance")
	assert_false(_manager.call("is_active"), "sequência terminou")
	assert_eq(_finished, 1, "dialogue_finished emitido")


func test_once_does_not_repeat() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_lights_off")
	assert_true(_manager.call("has_played", &"core_lights_off"), "marcada como vista")
	while _manager.call("is_active"):
		_manager.call("advance")
	_manager.call("play", &"core_lights_off")
	assert_false(_manager.call("is_active"), "não repete")


func test_queue_keeps_order() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_terminal_first")
	_manager.call("enqueue", &"hab_body")
	assert_eq(int(_manager.call("queue_size")), 1, "uma sequência na fila")
	while _manager.call("is_active") and not String(_manager.call("current_text")).begins_with(
		"Anomalia"
	):
		_manager.call("advance")
	assert_true(
		String(_manager.call("current_text")).begins_with("Anomalia"), "segunda sequência na vez"
	)
	assert_eq(_started, 1, "dialogue_started uma única vez na cadeia")


func test_open_log_emits_signals_and_header() -> void:
	if _manager == null:
		return
	_manager.call("open_log", &"log_core_01")
	assert_eq(_opened.size(), 1, "log_opened")
	assert_eq(String(_opened[0]), "log_core_01", "id do log")
	assert_true(_manager.call("freezes_timer"), "log congela o timer")
	assert_eq(
		String(_manager.call("current_header")),
		"LOG DE MANUTENÇÃO 114 · ENGENHARIA CHEFE",
		"cabeçalho da gravação"
	)
	assert_eq(String(_manager.call("current_speaker")), "helena", "falante do log")
	while _manager.call("is_active"):
		_manager.call("advance")
	assert_eq(_closed.size(), 1, "log_closed")


func test_log_unlocks_ability() -> void:
	if _manager == null:
		return
	_manager.call("open_log", &"log_gh_02")
	while _manager.call("is_active"):
		_manager.call("advance")
	assert_eq(_abilities.size(), 1, "ability_unlocked emitido")
	assert_eq(String(_abilities[0]), "magnetic_claws", "garras magnéticas")
	assert_true(GameState.abilities.has(&"magnetic_claws"), "gravado no GameState")


func test_set_flags_applied_on_finish() -> void:
	if _manager == null:
		return
	_manager.call("play", &"core_alarm")
	assert_false(GameState.flags.has("reactor_online"), "flag só ao terminar")
	while _manager.call("is_active"):
		_manager.call("advance")
	assert_true(bool(GameState.flags.get("reactor_online", false)), "flag ligada")


func test_unknown_sequence_is_ignored() -> void:
	if _manager == null:
		return
	_manager.call("play", &"nao_existe")
	assert_false(_manager.call("is_active"), "nada acontece")


func _find_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("DialogueManager")


func _on_started() -> void:
	_started += 1


func _on_finished() -> void:
	_finished += 1


func _on_log_opened(log_id: StringName) -> void:
	_opened.append(log_id)


func _on_log_closed(log_id: StringName) -> void:
	_closed.append(log_id)


func _on_ability(ability_id: StringName) -> void:
	_abilities.append(ability_id)
