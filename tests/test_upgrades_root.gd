extends TestCase

const COLLECTIBLE_SCENE: String = "res://scenes/world/collectible.tscn"
const DOOR_SCENE: String = "res://scenes/world/door.tscn"
const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const MENU_SCENE: String = "res://scenes/ui/chassis_menu.tscn"
const ROOT: StringName = &"root_access"
const VITALS_SLOT: int = 72
const GRID_DATA: Dictionary = {
	"id": "overload_test",
	"title": "TESTE",
	"budget": 1,
	"goal_text": "ligar a",
	"goal_done_text": "a ligado",
	"goal_systems": ["a"],
	"systems": [
		{"id": "a", "name": "A", "description": "a", "tag": "A", "effect_off": "a", "cost": 1},
		{"id": "b", "name": "B", "description": "b", "tag": "B", "effect_off": "b", "cost": 1},
		{
			"id": "c", "name": "C", "description": "c", "tag": "C", "effect_off": "c", "cost": 1,
			"locked": true,
		},
	],
	"initial": ["a"],
}

var _root: Node = null
var _spawned: Array[Node] = []


func before_each() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	_root = loop.root if loop != null else null
	GameState.new_game()
	GameState.flags.clear()


func after_each() -> void:
	for node: Node in _spawned:
		if not is_instance_valid(node):
			continue
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		if not node.is_queued_for_deletion():
			node.free()
	_spawned.clear()
	GameState.new_game()
	GameState.flags.clear()


func test_upgrade_numbers_come_from_the_gdd() -> void:
	assert_eq(Balance.ARMOR_PLATE_BONUS, 25, "placa +25")
	assert_eq(Balance.CAPACITORS_TOTAL, 4, "4 capacitores no jogo")
	assert_eq(Balance.ARMOR_PLATES_TOTAL, 4, "4 placas no jogo")
	assert_eq(Balance.INTEGRITY_PER_CELL * Balance.INTEGRITY_CELLS, Balance.INTEGRITY_MAX, "4×25")


func test_installed_counts_follow_the_maximums() -> void:
	assert_eq(UpgradeRules.capacitors_installed(Balance.CHARGE_MAX), 0, "sem capacitor")
	assert_eq(UpgradeRules.capacitors_installed(Balance.CHARGE_MAX + 50.0), 2, "dois")
	assert_eq(UpgradeRules.plates_installed(Balance.INTEGRITY_MAX), 0, "sem placa")
	assert_eq(UpgradeRules.plates_installed(Balance.INTEGRITY_MAX + 75), 3, "três")


func test_cells_grow_one_per_plate_and_never_leave_the_slot() -> void:
	assert_eq(UpgradeRules.cell_count(Balance.INTEGRITY_MAX), 4, "4 células no início")
	var previous_width: int = 99
	for plates: int in range(Balance.ARMOR_PLATES_TOTAL + 1):
		var maximum: int = Balance.INTEGRITY_MAX + plates * Balance.ARMOR_PLATE_BONUS
		var cells: int = UpgradeRules.cell_count(maximum)
		assert_eq(cells, 4 + plates, "uma célula por placa")
		var layout: Vector2i = UpgradeRules.cell_layout(cells, VITALS_SLOT)
		assert_true(layout.x >= UpgradeRules.CELL_MIN_WIDTH, "célula inteira (%d)" % cells)
		assert_true(layout.x <= previous_width, "célula só encolhe")
		previous_width = layout.x
		assert_true(
			UpgradeRules.cells_width(cells, VITALS_SLOT) <= VITALS_SLOT,
			"%d células cabem em %d px" % [cells, VITALS_SLOT]
		)
	assert_eq(UpgradeRules.cell_layout(4, VITALS_SLOT).x, 16, "4 células no tamanho original")


func test_charge_frame_grows_with_each_capacitor_up_to_the_slot() -> void:
	var base: float = UpgradeRules.charge_frame_width(Balance.CHARGE_MAX, 60.0, 72.0)
	assert_almost_eq(base, 60.0, 0.01, "barra de 60 px sem capacitor")
	var previous: float = base
	for count: int in range(1, Balance.CAPACITORS_TOTAL + 1):
		var maximum: float = Balance.CHARGE_MAX + float(count) * Balance.CAPACITOR_BONUS
		var width: float = UpgradeRules.charge_frame_width(maximum, 60.0, 72.0)
		assert_true(width > previous, "capacitor %d alonga a barra" % count)
		previous = width
	assert_almost_eq(previous, 72.0, 0.01, "4 capacitores enchem o espaço")


func test_armor_plate_raises_and_fills_integrity_for_good() -> void:
	GameState.integrity = 40
	var item: Collectible = _spawn_pickup(PickupRules.KIND_ARMOR_PLATE, &"it_plate")
	assert_true(item.collect(), "placa coletada")
	assert_eq(GameState.integrity_max, Balance.INTEGRITY_MAX + Balance.ARMOR_PLATE_BONUS, "máx.")
	assert_eq(GameState.integrity, GameState.integrity_max, "a placa enche a Integridade")
	assert_eq(GameState.plates_installed(), 1, "uma placa instalada")
	assert_true(GameState.collected_ids.has(&"it_plate"), "não reaparece")
	var again: Collectible = _spawn_pickup(PickupRules.KIND_ARMOR_PLATE, &"it_plate")
	assert_true(again.is_queued_for_deletion(), "placa já coletada não nasce de novo")


func test_capacitor_fills_charge_and_counts() -> void:
	GameState.charge = 5.0
	var item: Collectible = _spawn_pickup(PickupRules.KIND_CAPACITOR, &"it_cap_f69")
	assert_true(item.collect(), "capacitor coletado")
	assert_almost_eq(GameState.charge, GameState.charge_max, 0.001, "enche a Carga")
	assert_eq(GameState.capacitors_installed(), 1, "um capacitor instalado")


func test_upgrades_survive_save_and_load() -> void:
	GameState.install_capacitor()
	GameState.expand_integrity_max(Balance.ARMOR_PLATE_BONUS)
	GameState.expand_integrity_max(Balance.ARMOR_PLATE_BONUS)
	GameState.register_pickup(PickupRules.KIND_ARMOR_PLATE, &"plate_x")
	GameState.unlock_ability(ROOT)
	assert_true(GameState.open_root_door(&"door_x"), "abre com o Root")
	var saved: Dictionary = GameState.to_dict()
	GameState.new_game()
	assert_eq(GameState.plates_installed(), 0, "new_game zera")
	GameState.from_dict(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(GameState.capacitors_installed(), 1, "capacitor volta do save")
	assert_eq(GameState.plates_installed(), 2, "placas voltam do save")
	assert_true(GameState.has_ability(ROOT), "Root volta do save")
	assert_true(GameState.is_root_door_open(&"door_x"), "porta ROOT continua aberta")
	assert_true(GameState.collected_ids.has(&"plate_x"), "placa não reaparece")


func test_root_door_needs_the_ability() -> void:
	assert_false(GameState.open_root_door(&"door_y"), "sem Root a porta não abre")
	assert_false(GameState.is_root_door_open(&"door_y"), "nada gravado")
	assert_true(UpgradeRules.door_locked(ROOT, []), "trancada sem a habilidade")
	assert_false(UpgradeRules.door_locked(ROOT, [ROOT]), "livre com a habilidade")
	assert_false(UpgradeRules.door_locked(&"", []), "porta comum não pede nada")


func test_root_door_scene_without_and_with_the_ability() -> void:
	var door: Door = _spawn_door({"id": "test_root_door", "requires_ability": "root_access"})
	assert_true(door.is_root_locked(), "nasce trancada")
	assert_false(door.is_open(), "fechada")
	assert_not_null(door.root_plate(), "placa ROOT visível")
	assert_not_null(door.root_panel(), "painel de interação")
	assert_eq(door.root_prompt(), InteractionRules.text(Door.PROMPT_SEALED), "sem Root: selada")
	assert_false(door.root_panel().is_actionable(), "sem Root o painel só informa")
	assert_eq(door.root_panel().prompt_with("[E]"), "PORTA SELADA", "sem [E] no que não age")
	assert_false(door.try_root_access(), "interagir sem Root não abre")
	assert_eq(door.root_prompt(), InteractionRules.text(Door.PROMPT_ROOT_MISSING), "avisa")
	GameState.unlock_ability(ROOT)
	assert_eq(door.root_prompt(), InteractionRules.text(Door.PROMPT_ROOT), "com Root: ACESSO ROOT")
	assert_true(door.root_panel().is_actionable(), "com Root o painel age")
	assert_eq(door.root_panel().prompt_with("[E]"), "[E] ACESSO ROOT", "com a tecla")
	assert_eq(
		door.root_panel().pick_priority(), InteractionRules.PRIORITY_GATE, "porta vence o log"
	)
	assert_true(door.root_plate().ready_to_open, "LED verde")
	assert_true(door.try_root_access(), "abre com o Root")
	assert_false(door.is_root_locked(), "destrancada")
	assert_true(GameState.is_root_door_open(&"test_root_door"), "flag gravada")
	var again: Door = _spawn_door({"id": "test_root_door", "requires_ability": "root_access"})
	assert_false(again.is_root_locked(), "na volta já nasce aberta")
	assert_true(again.is_open(), "aberta")


func test_reactor_door_needs_memory_and_root() -> void:
	var params: Dictionary = {
		"id": "door_reactor", "sealed_until_sector": "memory", "requires_ability": "root_access",
	}
	var sealed: Door = _spawn_door(params)
	assert_true(sealed.sealed, "selada antes da Memória")
	assert_false(sealed.root_panel().enabled, "sem convite enquanto o setor está selado")
	GameState.sectors_restored.append(&"memory")
	var waiting: Door = _spawn_door(params)
	assert_false(waiting.sealed, "Memória religada tira o selo do setor")
	assert_true(waiting.is_root_locked(), "mas ainda pede o Root")
	assert_false(waiting.is_open(), "fechada sem Root")
	GameState.unlock_ability(ROOT)
	assert_true(waiting.try_root_access(), "abre com Memória e Root")
	assert_true(_spawn_door(params).is_open(), "e continua aberta")


func test_hub_reactor_door_declares_the_root() -> void:
	var meta: Dictionary = _meta("core_hub")
	var door: Dictionary = (meta["entities"] as Dictionary)["143,5"]
	assert_eq(String(door.get("id", "")), "door_reactor", "comporta do Reator")
	assert_eq(String(door.get("sealed_until_sector", "")), "memory", "exige a Memória")
	assert_eq(String(door.get("requires_ability", "")), "root_access", "e o Acesso Root")


func test_overload_adds_budget_for_a_while_then_sheds_the_last_system() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(GRID_DATA)
	assert_eq(grid.validate().size(), 0, "grade de teste válida")
	assert_eq(grid.toggle(&"b")["result"], EnergyGrid.Result.NO_BUDGET, "sem orçamento")
	assert_true(grid.start_overload(Balance.ROOT_OVERLOAD_UNITS, Balance.ROOT_OVERLOAD_TIME))
	assert_false(grid.start_overload(1, 5.0), "não empilha sobrecarga")
	assert_eq(grid.effective_budget(), 1 + Balance.ROOT_OVERLOAD_UNITS, "+1 de orçamento")
	assert_eq(grid.toggle(&"b")["result"], EnergyGrid.Result.OK, "b cabe na sobrecarga")
	assert_eq(grid.used(), 2, "dois ligados")
	assert_eq(grid.tick_overload(Balance.ROOT_OVERLOAD_TIME * 0.5).size(), 0, "ainda vale")
	var shed: Array[StringName] = grid.tick_overload(Balance.ROOT_OVERLOAD_TIME)
	assert_false(grid.is_overloaded(), "acabou")
	assert_eq(shed, [&"b"] as Array[StringName], "desliga o último ligado")
	assert_true(grid.is_powered(&"a"), "o primeiro fica")
	assert_eq(grid.used(), grid.budget, "volta a caber no orçamento")


func test_overload_never_sheds_a_locked_system() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(GRID_DATA)
	grid.power_off(&"a")
	grid.start_overload(1, 1.0)
	grid.toggle(&"a")
	grid.toggle(&"b")
	assert_eq(grid.used(), 2, "dois ligados na sobrecarga")
	var shed: Array[StringName] = grid.end_overload()
	assert_eq(shed.size(), 1, "só um desliga")
	assert_false(grid.is_locked(shed[0]), "nunca um sistema selado")


func test_overload_is_root_only_and_costs_charge() -> void:
	var network := EnergyNetwork.new()
	_root.add_child(network)
	_spawned.append(network)
	network.load_terminals(["core_hub"])
	assert_true(network.has_terminal(&"core_hub"), "terminal carregado")
	assert_false(network.can_overload(&"core_hub"), "sem Root não sobrecarrega")
	assert_false(network.overload(&"core_hub"), "nem tentando")
	GameState.unlock_ability(ROOT)
	GameState.charge = Balance.ROOT_OVERLOAD_COST - 1.0
	assert_false(network.can_overload(&"core_hub"), "sem Carga não sobrecarrega")
	GameState.charge = GameState.charge_max
	assert_true(network.overload(&"core_hub"), "com Root e Carga sobrecarrega")
	assert_almost_eq(
		GameState.charge, GameState.charge_max - Balance.ROOT_OVERLOAD_COST, 0.01, "custa Carga"
	)
	assert_true(network.is_overloaded(&"core_hub"), "sobrecarregado")
	assert_false(network.can_overload(&"core_hub"), "uma de cada vez")
	network.end_overload(&"core_hub")
	assert_false(network.is_overloaded(&"core_hub"), "encerrada")


func test_station_map_shows_the_root_lock_on_the_reactor() -> void:
	var sectors: Array[Dictionary] = StationMapModel.load_station()["sectors"]
	var reactor: Dictionary = StationMapModel.find(sectors, &"reactor")
	assert_eq(reactor[StationMapModel.KEY_REQUIRES_ABILITY], ROOT, "Reator pede o Root")
	var snap: Dictionary = {
		StationMapModel.SNAP_RESTORED: [&"memory"], StationMapModel.SNAP_ABILITIES: [],
	}
	assert_true(StationMapModel.is_sealed(reactor, snap), "selado sem Root")
	assert_true(StationMapModel.sealed_by_ability_only(reactor, snap), "cadeado ROOT")
	snap[StationMapModel.SNAP_ABILITIES] = [ROOT]
	assert_false(StationMapModel.is_sealed(reactor, snap), "aberto com Memória e Root")
	var early: Dictionary = {
		StationMapModel.SNAP_RESTORED: [], StationMapModel.SNAP_ABILITIES: [ROOT],
	}
	assert_true(StationMapModel.is_sealed(reactor, early), "o Root não pula a Memória")
	assert_false(StationMapModel.sealed_by_ability_only(reactor, early), "o cadeado é do setor")


func test_hud_draws_one_more_cell_per_plate_in_the_same_space() -> void:
	var hud: CanvasLayer = (load(HUD_SCENE) as PackedScene).instantiate()
	_root.add_child(hud)
	_spawned.append(hud)
	assert_eq(int(hud.call(&"cell_count")), 4, "4 células")
	var base_width: float = float(hud.call(&"cells_width"))
	for plate: int in range(Balance.ARMOR_PLATES_TOTAL):
		GameState.expand_integrity_max(Balance.ARMOR_PLATE_BONUS)
		assert_eq(int(hud.call(&"cell_count")), 5 + plate, "célula nova da placa %d" % (plate + 1))
		assert_true(float(hud.call(&"cells_width")) <= float(VITALS_SLOT), "não cresce")
	assert_true(base_width <= float(VITALS_SLOT), "começa dentro do espaço")
	var before: float = float(hud.call(&"charge_frame_width"))
	GameState.install_capacitor()
	assert_true(float(hud.call(&"charge_frame_width")) > before, "barra de Carga alonga")
	assert_true(String(hud.call(&"upgrade_toast_text", PickupRules.KIND_ARMOR_PLATE)).contains(
		"4/4"
	), "aviso traz a contagem")


func test_chassis_terminal_lists_the_upgrades() -> void:
	GameState.install_capacitor()
	GameState.expand_integrity_max(Balance.ARMOR_PLATE_BONUS)
	var menu: CanvasLayer = (load(MENU_SCENE) as PackedScene).instantiate()
	_root.add_child(menu)
	_spawned.append(menu)
	menu.call(&"_refresh")
	var texts: PackedStringArray = menu.call(&"upgrade_texts")
	assert_eq(texts[0], "1/4", "capacitores")
	assert_eq(texts[1], "1/4", "placas")


func _spawn_pickup(kind: StringName, item_id: StringName) -> Collectible:
	var item: Collectible = (load(COLLECTIBLE_SCENE) as PackedScene).instantiate()
	item.kind = kind
	item.item_id = item_id
	_root.add_child(item)
	_spawned.append(item)
	return item


func _spawn_door(params: Dictionary) -> Door:
	var door: Door = (load(DOOR_SCENE) as PackedScene).instantiate()
	door.configure(params)
	_root.add_child(door)
	_spawned.append(door)
	return door


func _meta(level: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/%s.json" % level)
	)
	return raw if raw is Dictionary else {}
