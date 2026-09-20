extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const NINETY_SECONDS: float = 90.0

var _tree: SceneTree = null
var _level: Node = null
var _previous_scene: Node = null
var _state: Node = null
var _previous_difficulty: StringName = &"normal"
var _previous_no_timer: bool = false


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_previous_difficulty = Settings.difficulty
	_previous_no_timer = Settings.no_timer
	Settings.difficulty = &"normal"
	Settings.no_timer = false
	_previous_scene = _tree.current_scene
	_level = Node.new()
	_level.name = "ReactorTestLevel"
	_level.add_to_group(&"level")
	_tree.root.add_child(_level)
	_tree.current_scene = _level
	_state = load(GAME_STATE_SCRIPT).new()
	_state.name = "ReactorTestState"
	_tree.root.add_child(_state)
	_state.set_process(false)


func after_each() -> void:
	Settings.difficulty = _previous_difficulty
	Settings.no_timer = _previous_no_timer
	if _state != null:
		_tree.root.remove_child(_state)
		_state.free()
		_state = null
	_tree.current_scene = _previous_scene
	if _level != null:
		_tree.root.remove_child(_level)
		_level.free()
		_level = null


func test_new_game_starts_offline() -> void:
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "começa em 100%")
	assert_false(_state.is_reactor_online(), "reactor_online desligado")
	assert_false(_state.is_reactor_running(), "não corre antes do alarme")


func test_offline_does_not_decay() -> void:
	_state._process(NINETY_SECONDS)
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "sem queda")


func test_decay_normal_after_alarm() -> void:
	_state.set_reactor_online(true)
	assert_true(_state.is_reactor_running(), "timer ligado em fase")
	_state._process(NINETY_SECONDS)
	assert_almost_eq(_state.reactor_percent, 99.0, 0.05, "99% após 90 s")


func test_decay_easy_and_hard() -> void:
	_state.set_reactor_online(true)
	Settings.difficulty = &"easy"
	_state._process(NINETY_SECONDS)
	assert_almost_eq(_state.reactor_percent, 99.5, 0.05, "fácil cai metade")
	_state.reactor_percent = Balance.REACTOR_START
	Settings.difficulty = &"hard"
	_state._process(NINETY_SECONDS)
	assert_almost_eq(_state.reactor_percent, 98.5, 0.05, "difícil cai 1,5%")


func test_no_timer_never_decays() -> void:
	_state.set_reactor_online(true)
	Settings.no_timer = true
	for difficulty: StringName in [&"easy", &"normal", &"hard"]:
		Settings.difficulty = difficulty
		_state.reactor_percent = Balance.REACTOR_START
		_state._process(NINETY_SECONDS)
		assert_almost_eq(
			_state.reactor_percent, Balance.REACTOR_START, 0.0001, "sem timer em %s" % difficulty
		)


func test_pause_freezes_decay() -> void:
	_state.set_reactor_online(true)
	EventBus.game_paused.emit(true)
	assert_true(_state.is_timer_frozen(), "pausado congela")
	_state._process(NINETY_SECONDS)
	EventBus.game_paused.emit(false)
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "congelado no pause")


func test_dialogue_and_log_freeze_decay() -> void:
	_state.set_reactor_online(true)
	EventBus.dialogue_started.emit()
	_state._process(NINETY_SECONDS)
	EventBus.dialogue_finished.emit()
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "diálogo congela")
	EventBus.log_opened.emit(&"log_core_01")
	_state._process(NINETY_SECONDS)
	EventBus.log_closed.emit(&"log_core_01")
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "log congela")


func test_outside_level_does_not_decay() -> void:
	_state.set_reactor_online(true)
	_tree.current_scene = null
	_state._process(NINETY_SECONDS)
	_tree.current_scene = _level
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "menu não decai")


func test_sector_bonus_and_cap() -> void:
	_state.reactor_percent = 80.0
	_state._on_sector_restored(&"greenhouse")
	assert_almost_eq(_state.reactor_percent, 95.0, 0.0001, "+15%")
	_state._on_sector_restored(&"greenhouse")
	assert_almost_eq(_state.reactor_percent, Balance.REACTOR_START, 0.0001, "teto de 100%")


func test_log_bonus_only_for_logs() -> void:
	_state.reactor_percent = 50.0
	_state._on_collectible_picked(&"log", &"log_core_01")
	assert_almost_eq(_state.reactor_percent, 50.5, 0.0001, "+0,5% por log")
	_state._on_collectible_picked(&"research", &"res_01")
	assert_almost_eq(_state.reactor_percent, 50.5, 0.0001, "dado não dá bônus")


func test_death_penalty_ignores_difficulty() -> void:
	for difficulty: StringName in [&"easy", &"normal", &"hard"]:
		Settings.difficulty = difficulty
		_state.reactor_percent = 50.0
		_state._on_player_died()
		assert_almost_eq(_state.reactor_percent, 47.0, 0.0001, "-3%% em %s" % difficulty)


func test_critical_edges_emit_once() -> void:
	var events: Array[bool] = []
	var handler: Callable = func(active: bool) -> void:
		events.append(active)
	EventBus.reactor_critical.connect(handler)
	_state.reactor_percent = 26.0
	_state.change_reactor(-2.0)
	_state.change_reactor(-1.0)
	assert_eq(events.size(), 1, "entra em crítico uma vez")
	assert_true(events[0], "crítico ligado")
	_state.change_reactor(10.0)
	assert_eq(events.size(), 2, "sai do crítico")
	assert_false(events[1], "crítico desligado")
	EventBus.reactor_critical.disconnect(handler)


func test_zero_emits_game_over_once() -> void:
	var saved: Array[Callable] = _isolate_game_over()
	var reasons: Array[StringName] = []
	var handler: Callable = func(reason: StringName) -> void:
		reasons.append(reason)
	EventBus.game_over.connect(handler)
	_state.set_reactor_online(true)
	_state.reactor_percent = 0.2
	_state._process(NINETY_SECONDS)
	_state._process(NINETY_SECONDS)
	EventBus.game_over.disconnect(handler)
	_restore_game_over(saved)
	assert_almost_eq(_state.reactor_percent, 0.0, 0.0001, "chegou a zero")
	assert_eq(reasons.size(), 1, "game over uma única vez")
	assert_eq(reasons[0], &"reactor", "motivo reactor")


func test_reactor_changed_uses_display_steps() -> void:
	var values: Array[float] = []
	var handler: Callable = func(percent: float) -> void:
		values.append(percent)
	_state.set_reactor_online(true)
	EventBus.reactor_changed.connect(handler)
	for frame: int in range(60):
		_state._process(1.0 / 60.0)
	assert_eq(values.size(), 0, "sem emissão enquanto o inteiro não muda")
	_state._process(NINETY_SECONDS)
	assert_eq(values.size(), 1, "emite ao mudar o inteiro exibido")
	EventBus.reactor_changed.disconnect(handler)


func test_set_objective_emits_text() -> void:
	var texts: Array[String] = []
	var handler: Callable = func(text: String) -> void:
		texts.append(text)
	EventBus.objective_changed.connect(handler)
	_state.set_objective(&"obj_greenhouse")
	_state.set_objective(&"obj_greenhouse")
	_state.set_objective(&"obj_inexistente")
	EventBus.objective_changed.disconnect(handler)
	assert_eq(texts.size(), 1, "emite uma vez por objetivo novo")
	assert_eq(texts[0], "Religar o Nó do Setor da Estufa", "texto do objetivo")
	assert_eq(_state.current_objective, texts[0], "estado guarda o texto")


func test_from_dict_restores_critical_state() -> void:
	var data: Dictionary = _state.to_dict()
	data["reactor_percent"] = 12.0
	_state.from_dict(data)
	assert_true(_state.is_reactor_critical(), "crítico após carregar")
	assert_almost_eq(_state.reactor_percent, 12.0, 0.0001, "percentual carregado")


func _isolate_game_over() -> Array[Callable]:
	var saved: Array[Callable] = []
	for connection: Dictionary in EventBus.game_over.get_connections():
		var callable: Callable = connection.get("callable")
		saved.append(callable)
		EventBus.game_over.disconnect(callable)
	return saved


func _restore_game_over(saved: Array[Callable]) -> void:
	for callable: Callable in saved:
		if not EventBus.game_over.is_connected(callable):
			EventBus.game_over.connect(callable)
