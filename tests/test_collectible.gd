extends TestCase

const SCENE_PATH: String = "res://scenes/world/collectible.tscn"
const KNOWN_LOG: StringName = &"log_core_01"
const OTHER_LOG: StringName = &"log_hab_01"

var _root: Node = null
var _spawned: Array[Node] = []
var _picked: Array[StringName] = []


func before_each() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	_root = loop.root if loop != null else null
	_picked.clear()
	GameState.new_game()
	EventBus.collectible_picked.connect(_on_picked)


func after_each() -> void:
	EventBus.collectible_picked.disconnect(_on_picked)
	_drain_dialogue()
	for node: Node in _spawned:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		_root.remove_child(node)
		node.free()
	_spawned.clear()
	GameState.new_game()
	GameState.flags.clear()


func test_energy_cell_gives_charge() -> void:
	GameState.charge = 30.0
	var item: Collectible = _spawn(&"cell", &"it_cell")
	assert_true(item.collect(), "célula coletada")
	assert_almost_eq(GameState.charge, 30.0 + Balance.ENERGY_CELL_CHARGE, 0.001, "carga")
	assert_eq(_picked, [StringName("cell")], "evento emitido")
	assert_true(GameState.collected_ids.has(&"it_cell"), "id registrado")


func test_energy_cell_is_not_consumed_when_charge_is_full() -> void:
	GameState.charge = GameState.charge_max
	var item: Collectible = _spawn(&"cell", &"it_cell_full")
	assert_false(item.collect(), "célula não coletada")
	assert_false(item.was_collected(), "item continua no mundo")
	assert_eq(GameState.collected_ids.size(), 0, "nada registrado")
	assert_eq(_picked.size(), 0, "nenhum evento")


func test_repair_kit_repairs_integrity() -> void:
	GameState.integrity = 40
	var item: Collectible = _spawn(&"repair_kit", &"it_kit")
	assert_true(item.collect(), "kit coletado")
	assert_eq(GameState.integrity, 40 + Balance.REPAIR_KIT_INTEGRITY, "integridade")


func test_repair_kit_is_not_consumed_when_integrity_is_full() -> void:
	var item: Collectible = _spawn(&"repair_kit", &"it_kit_full")
	assert_false(item.collect(), "kit não coletado")
	assert_eq(GameState.collected_ids.size(), 0, "nada registrado")


func test_capacitor_raises_charge_maximum() -> void:
	GameState.charge = 10.0
	var item: Collectible = _spawn(&"capacitor", &"it_cap")
	assert_true(item.collect(), "capacitor coletado")
	assert_almost_eq(
		GameState.charge_max, Balance.CHARGE_MAX + Balance.CAPACITOR_BONUS, 0.001, "carga máxima"
	)
	assert_almost_eq(GameState.charge, 10.0 + Balance.CAPACITOR_BONUS, 0.001, "carga atual")


func test_capacitor_is_collected_even_with_full_charge() -> void:
	var item: Collectible = _spawn(&"capacitor", &"it_cap_full")
	assert_true(item.collect(), "capacitor sempre coletável")
	assert_almost_eq(
		GameState.charge, Balance.CHARGE_MAX + Balance.CAPACITOR_BONUS, 0.001, "carga cheia nova"
	)


func test_research_only_counts() -> void:
	var item: Collectible = _spawn(&"research", &"it_data")
	assert_true(item.collect(), "dado coletado")
	assert_eq(GameState.research_collected.size(), 1, "contador de dados")
	assert_almost_eq(GameState.charge, Balance.CHARGE_MAX, 0.001, "carga intacta")
	assert_eq(GameState.integrity, GameState.integrity_max, "integridade intacta")


func test_log_fragment_counts_once() -> void:
	var item: Collectible = _spawn(&"log", KNOWN_LOG)
	assert_true(item.collect(), "fragmento coletado")
	_drain_dialogue()
	assert_eq(GameState.logs_collected.size(), 1, "um log")
	assert_true(GameState.logs_collected.has(KNOWN_LOG), "id do log")
	DialogueManager.open_log(KNOWN_LOG)
	_drain_dialogue()
	assert_eq(GameState.logs_collected.size(), 1, "reler não conta de novo")
	assert_eq(_picked.size(), 1, "um único evento")


func test_log_terminal_feeds_the_same_counter() -> void:
	DialogueManager.open_log(OTHER_LOG)
	_drain_dialogue()
	assert_eq(GameState.logs_collected.size(), 1, "log lido no mundo conta")
	assert_true(GameState.collected_ids.has(OTHER_LOG), "id registrado")
	assert_eq(_picked, [StringName("log")], "evento de log")


func test_collected_item_does_not_come_back() -> void:
	GameState.register_pickup(&"research", &"it_gone")
	var item: Collectible = _spawn(&"research", &"it_gone")
	assert_true(item.is_queued_for_deletion(), "item já coletado se destrói")


func test_log_fragment_defaults_its_log_id_from_the_item_id() -> void:
	var item: Collectible = _spawn(&"log", KNOWN_LOG)
	assert_eq(item.log_id, KNOWN_LOG, "log_id herdado do item_id")


func test_configure_reads_builder_params() -> void:
	var item: Collectible = _spawn(&"cell", &"it_cfg")
	item.configure({"kind": "log", "item_id": "it_cfg_log"})
	assert_eq(item.kind, StringName("log"), "tipo")
	assert_eq(item.item_id, StringName("it_cfg_log"), "id")
	assert_eq(item.log_id, StringName("it_cfg_log"), "log_id padrão")


func _spawn(kind: StringName, item_id: StringName) -> Collectible:
	var instance: Node = load(SCENE_PATH).instantiate()
	var item: Collectible = instance
	item.kind = kind
	item.item_id = item_id
	_root.add_child(item)
	_spawned.append(item)
	return item


func _drain_dialogue() -> void:
	var guard: int = 0
	while DialogueManager.is_active() and guard < 200:
		DialogueManager.advance()
		guard += 1


func _on_picked(kind: StringName, _item_id: StringName) -> void:
	_picked.append(kind)
