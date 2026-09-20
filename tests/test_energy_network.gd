extends TestCase

const LEVEL: String = "res://scenes/dev/core_test.tscn"
const TERMINAL: StringName = &"core_hub"

var _level: Node = null
var _events: Array = []


func before_each() -> void:
	GameState.new_game()
	_events = []
	EventBus.energy_changed.connect(_on_energy_changed)


func after_each() -> void:
	if EventBus.energy_changed.is_connected(_on_energy_changed):
		EventBus.energy_changed.disconnect(_on_energy_changed)
	_drop_level()
	GameState.new_game()


func test_network_loads_and_validates_terminal() -> void:
	_build_level()
	var network: EnergyNetwork = _network()
	assert_not_null(network, "fase tem EnergyNetwork")
	if network == null:
		return
	assert_true(network.has_terminal(TERMINAL), "terminal do núcleo carregado")
	assert_eq(network.grid(TERMINAL).budget, 1, "orçamento do tutorial")
	assert_true(network.grid(TERMINAL).validate().is_empty(), "dados válidos")


func test_initial_state_reaches_the_world() -> void:
	_build_level()
	assert_true(_lamp().is_lit(), "lâmpada acesa pelo estado inicial")
	assert_false(_door().is_open(), "porta fechada pelo estado inicial")
	assert_eq(_names(GameState.energy_states.get(TERMINAL, [])), _text(["lights_core"]), "estado")
	assert_true(_events.is_empty(), "restauração silenciosa não emite energy_changed")


func test_toggle_swaps_light_for_door() -> void:
	_build_level()
	var network: EnergyNetwork = _network()
	assert_eq(
		network.toggle(TERMINAL, &"door_habitat")["result"],
		EnergyGrid.Result.NO_BUDGET,
		"porta recusada com a luz ligada"
	)
	assert_true(_lamp().is_lit(), "mundo intacto após a recusa")
	network.toggle(TERMINAL, &"lights_core")
	network.toggle(TERMINAL, &"door_habitat")
	assert_false(_lamp().is_lit(), "lâmpada apagou")
	assert_true(_door().is_open(), "porta abriu")
	assert_eq(
		_names(GameState.energy_states.get(TERMINAL, [])), _text(["door_habitat"]), "estado salvo"
	)


func test_toggle_emits_one_event_per_system() -> void:
	_build_level()
	var network: EnergyNetwork = _network()
	network.toggle(TERMINAL, &"lights_core")
	assert_eq(_events.size(), 1, "um evento por sistema afetado")
	assert_eq(String(_events[0]["terminal"]), "core_hub", "terminal do evento")
	assert_eq(String(_events[0]["system"]), "lights_core", "sistema do evento")
	assert_false(bool(_events[0]["powered"]), "evento de desligamento")
	network.toggle(TERMINAL, &"door_habitat")
	assert_eq(_events.size(), 2, "segundo evento")
	assert_true(bool(_events[1]["powered"]), "evento de ligamento")


func test_refused_toggle_emits_nothing() -> void:
	_build_level()
	_network().toggle(TERMINAL, &"door_habitat")
	assert_true(_events.is_empty(), "recusa não mexe no mundo")


func test_saved_state_is_restored_silently() -> void:
	GameState.energy_states[TERMINAL] = [&"door_habitat"]
	_build_level()
	assert_false(_lamp().is_lit(), "lâmpada apagada ao recarregar")
	assert_true(_door().is_open(), "porta aberta ao recarregar")
	assert_eq(_door().current_animation(), &"open", "porta não reanima ao restaurar")
	assert_true(_events.is_empty(), "restauração não emite energy_changed")


func test_two_consoles_share_the_same_grid() -> void:
	_build_level()
	var network: EnergyNetwork = _network()
	var first: EnergyGrid = network.grid(TERMINAL)
	var second: EnergyGrid = network.grid(TERMINAL)
	assert_true(first == second, "mesma EnergyGrid para o mesmo terminal_id")


func test_console_reads_the_network() -> void:
	_build_level()
	var console: DistributionTerminal = _console()
	assert_not_null(console, "console instanciado pelo LevelBuilder")
	if console == null:
		return
	assert_eq(console.terminal_id, TERMINAL, "terminal_id vindo do JSON da fase")
	assert_false(console.is_sector_node(), "papel padrão é console")
	assert_true(console.network() == _network(), "console encontra a rede da fase")


func _build_level() -> void:
	_drop_level()
	_level = load(LEVEL).instantiate()
	_tree().root.add_child(_level)


func _drop_level() -> void:
	if _level != null and is_instance_valid(_level):
		_tree().root.remove_child(_level)
		_level.free()
	_level = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _network() -> EnergyNetwork:
	if _level == null:
		return null
	return _level.get_node_or_null("EnergyNetwork") as EnergyNetwork


func _lamp() -> PoweredLamp:
	return _first(&"entity:core_lamp_left") as PoweredLamp


func _door() -> Door:
	return _first(&"entity:door_habitat") as Door


func _console() -> DistributionTerminal:
	return _first(&"entity:core_console") as DistributionTerminal


func _first(group: StringName) -> Node:
	for node: Node in _tree().get_nodes_in_group(group):
		return node
	return null


func _names(values: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if values is Array:
		for value: Variant in values as Array:
			result.append(String(value))
	return result


func _text(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result


func _on_energy_changed(terminal: StringName, system: StringName, powered: bool) -> void:
	_events.append({"terminal": terminal, "system": system, "powered": powered})
