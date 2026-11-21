extends TestCase

const MAP_SCENE: String = "res://scenes/ui/station_map.tscn"
const TEXTS_PATH: String = "res://data/ui/station_map.json"
const THEME_PATH: String = "res://assets/ui/theme.tres"
const LOGS_DIR: String = "res://data/logs/"
const SCREEN_WIDTH: float = 384.0
const FONT_SIZE: int = 16
const MISSING_GLYPHS: String = "←→↑↓✓—■□▮▼•"
const STATION_SECTORS: Array[StringName] = [
	&"core_hub", &"greenhouse", &"lab", &"infirmary", &"docks", &"memory", &"reactor"
]

var _sectors: Array[Dictionary] = []
var _logs: Dictionary = {}


func before_each() -> void:
	_sectors = StationMapModel.load_station()["sectors"]
	_logs = DialogueData.load_dir(LOGS_DIR)["logs"]


func test_the_station_has_the_seven_sectors_of_the_radial_hub() -> void:
	var ids: Array[StringName] = []
	for sector: Dictionary in _sectors:
		ids.append(sector[StationMapModel.KEY_ID])
	assert_eq(ids.size(), STATION_SECTORS.size(), "sete setores")
	for index: int in range(mini(ids.size(), STATION_SECTORS.size())):
		assert_eq(ids[index], STATION_SECTORS[index], "setor %d na ordem do hub" % index)
	assert_eq(StationMapModel.load_station()["hub"], &"core_hub", "o Núcleo é o centro")


func test_sector_cells_are_unique_and_match_the_gdd_drawing() -> void:
	var cells: Dictionary = {}
	for sector: Dictionary in _sectors:
		var cell: Vector2i = sector[StationMapModel.KEY_CELL]
		assert_false(cells.has(cell), "célula repetida %s" % cell)
		cells[cell] = sector[StationMapModel.KEY_ID]
	var hub: Vector2i = StationMapModel.find(_sectors, &"core_hub")[StationMapModel.KEY_CELL]
	var reactor: Vector2i = StationMapModel.find(_sectors, &"reactor")[StationMapModel.KEY_CELL]
	var memory: Vector2i = StationMapModel.find(_sectors, &"memory")[StationMapModel.KEY_CELL]
	assert_true(reactor.y < hub.y and reactor.x == hub.x, "Reator em cima do Núcleo")
	assert_true(memory.y > hub.y and memory.x == hub.x, "Memória embaixo do Núcleo")


func test_every_sector_scene_follows_its_level_key() -> void:
	for sector: Dictionary in _sectors:
		var expected: String = "res://scenes/levels/%s.tscn" % sector[StationMapModel.KEY_LEVEL]
		assert_eq(sector[StationMapModel.KEY_SCENE], expected, "cena de %s" % sector["id"])


func test_requirements_point_to_sectors_of_the_station() -> void:
	for sector: Dictionary in _sectors:
		var requirement: StringName = sector[StationMapModel.KEY_REQUIRES]
		if requirement == &"":
			continue
		assert_false(
			StationMapModel.find(_sectors, requirement).is_empty(),
			"%s exige um setor que existe" % sector["id"]
		)


func test_a_new_game_in_the_hub_shows_the_hub_visited_and_the_rest_ahead() -> void:
	var snap: Dictionary = _snap([], {}, [], "res://scenes/levels/core_hub.tscn")
	assert_eq(_state(&"core_hub", snap), StationMapModel.STATE_VISITED, "Núcleo visitado")
	assert_eq(_state(&"greenhouse", snap), StationMapModel.STATE_UNKNOWN, "Estufa sem dados")
	for sealed: StringName in [&"lab", &"infirmary", &"docks", &"memory", &"reactor"]:
		assert_eq(_state(sealed, snap), StationMapModel.STATE_SEALED, "%s selado" % sealed)
	assert_eq(StationMapModel.current_sector(_sectors, snap), &"core_hub", "você está aqui")


func test_restoring_a_sector_lights_it_and_unseals_the_next_door() -> void:
	var snap: Dictionary = _snap(
		[&"greenhouse"], {}, [], "res://scenes/levels/core_hub.tscn"
	)
	assert_eq(_state(&"greenhouse", snap), StationMapModel.STATE_RESTORED, "Estufa religada")
	assert_eq(_state(&"core_hub", snap), StationMapModel.STATE_RESTORED, "Núcleo religa junto")
	assert_eq(_state(&"lab", snap), StationMapModel.STATE_UNKNOWN, "Laboratório aberto")
	assert_eq(_state(&"infirmary", snap), StationMapModel.STATE_SEALED, "Enfermaria selada")
	assert_eq(StationMapModel.restored_count(_sectors, snap), 2, "dois setores religados")


func test_a_visit_flag_or_a_pickup_marks_the_sector_as_visited() -> void:
	var flags: Dictionary = {StationMapModel.visited_flag("lab"): true}
	var by_flag: Dictionary = _snap([&"greenhouse"], flags, [], "")
	assert_eq(_state(&"lab", by_flag), StationMapModel.STATE_VISITED, "visitado pela marca")
	var by_pickup: Dictionary = _snap([], {}, [&"log_gh_01"], "")
	assert_eq(_state(&"greenhouse", by_pickup), StationMapModel.STATE_VISITED, "log achado lá")


func test_game_state_records_each_level_visited_once() -> void:
	var saved: Dictionary = GameState.flags.duplicate(true)
	GameState.flags = {}
	assert_true(GameState.mark_visited("res://scenes/levels/lab.tscn"), "primeira visita")
	assert_false(GameState.mark_visited("res://scenes/levels/lab.tscn"), "não repete")
	assert_false(GameState.mark_visited("res://scenes/ui/main_menu.tscn"), "menu não é fase")
	assert_true(GameState.has_visited("lab"), "lembra do Laboratório")
	assert_false(GameState.has_visited("infirmary"), "Enfermaria ainda não")
	GameState.flags = saved


func test_sector_counts_add_up_to_the_campaign_totals() -> void:
	var snap: Dictionary = _snap([], {}, [], "")
	var logs_total: int = 0
	var data_total: int = 0
	for sector: Dictionary in _sectors:
		var counts: Dictionary = StationMapModel.counts(sector, snap, _logs)
		logs_total += int(counts["logs_total"])
		data_total += int(counts["data_total"])
	assert_eq(logs_total, Balance.LOGS_TOTAL, "logs por setor fecham com o Balance")
	assert_eq(data_total, Balance.RESEARCH_TOTAL, "dados por setor fecham com o Balance")


func test_sector_counts_follow_what_was_collected() -> void:
	var collected: Array[StringName] = [&"log_core_01", &"data_core_01", &"log_gh_01"]
	var snap: Dictionary = _snap([], {}, collected, "")
	var core: Dictionary = StationMapModel.counts(
		StationMapModel.find(_sectors, &"core_hub"), snap, _logs
	)
	assert_eq(int(core["logs_found"]), 1, "um log do Núcleo")
	assert_eq(int(core["logs_total"]), 2, "dois logs no Núcleo")
	assert_eq(int(core["data_found"]), 1, "o dado do Núcleo")
	assert_eq(int(core["data_total"]), 1, "um dado no Núcleo")


func test_research_ids_come_from_the_level_map() -> void:
	StationMapModel.clear_cache()
	var core: Array[StringName] = StationMapModel.research_ids(&"core_hub")
	assert_eq(core.size(), 1, "um dado no Núcleo")
	assert_true(core.has(&"data_core_01"), "id do dado vem do JSON da fase")
	assert_true(StationMapModel.research_ids(&"zz_no_level").is_empty(), "fase inexistente")


func test_arrow_navigation_follows_the_radial_layout() -> void:
	assert_eq(_neighbor(&"core_hub", Vector2i.LEFT), &"infirmary", "esquerda")
	assert_eq(_neighbor(&"core_hub", Vector2i.RIGHT), &"lab", "direita")
	assert_eq(_neighbor(&"core_hub", Vector2i.UP), &"reactor", "cima")
	assert_eq(_neighbor(&"core_hub", Vector2i.DOWN), &"memory", "baixo")
	assert_eq(_neighbor(&"greenhouse", Vector2i.RIGHT), &"docks", "Estufa para Docas")
	assert_eq(_neighbor(&"memory", Vector2i.UP), &"core_hub", "Memória para Núcleo")
	assert_eq(_neighbor(&"reactor", Vector2i.UP), &"", "nada acima do Reator")


func test_every_sector_is_reachable_with_the_arrows() -> void:
	var seen: Dictionary = {&"core_hub": true}
	var frontier: Array[StringName] = [&"core_hub"]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_back()
		for direction: Vector2i in StationMapModel.DIRECTIONS:
			var next: StringName = _neighbor(current, direction)
			if next != &"" and not seen.has(next):
				seen[next] = true
				frontier.append(next)
	assert_eq(seen.size(), _sectors.size(), "todos os setores alcançáveis pelas setas")


func test_map_texts_exist_and_use_only_glyphs_of_the_pixel_font() -> void:
	var texts: Dictionary = HudModel.load_texts(TEXTS_PATH)
	for id: StringName in [
		&"title", &"restored_count", &"state_restored", &"state_visited", &"state_sealed",
		&"state_unknown", &"here", &"logs", &"data", &"sealed_hint", &"unknown_hint",
		&"footer_chassis", &"footer_overlay",
	]:
		assert_false(HudModel.text_for(id, texts).is_empty(), "texto '%s'" % id)
	for id: StringName in texts:
		for index: int in range(MISSING_GLYPHS.length()):
			assert_false(
				HudModel.text_for(id, texts).contains(MISSING_GLYPHS.substr(index, 1)),
				"'%s' usa glifo que a m5x7 não tem" % id
			)


func test_sector_names_fit_their_boxes_and_info_lines_fit_the_screen() -> void:
	var font: Font = (load(THEME_PATH) as Theme).default_font
	var script: GDScript = load("res://scenes/ui/station_map.gd")
	var constants: Dictionary = script.get_script_constant_map()
	var center_width: float = constants["CENTER_BOX_WIDTH"]
	var side_width: float = constants["SIDE_BOX_WIDTH"]
	for sector: Dictionary in _sectors:
		var cell: Vector2i = sector[StationMapModel.KEY_CELL]
		var box: float = center_width if cell.x == 0 else side_width
		var width: float = _width(font, String(sector[StationMapModel.KEY_NAME]))
		assert_true(
			width <= box - 4.0, "%s ocupa %.0f px (caixa %.0f)" % [sector["id"], width, box]
		)
	var texts: Dictionary = HudModel.load_texts(TEXTS_PATH)
	var longest_name: String = ""
	for sector: Dictionary in _sectors:
		if String(sector["name"]).length() > longest_name.length():
			longest_name = String(sector["name"])
	var hint: String = HudModel.text_for(&"sealed_hint", texts) % longest_name
	var state: String = HudModel.text_for(&"state_visited", texts)
	assert_true(
		_width(font, state) + _width(font, hint) <= SCREEN_WIDTH - 24.0 - 8.0,
		"estado + dica de setor selado cabem numa linha"
	)
	var counts: String = "%s   %s" % [
		HudModel.text_for(&"logs", texts) % [9, 9], HudModel.text_for(&"data", texts) % [9, 9]
	]
	assert_true(_width(font, counts) <= SCREEN_WIDTH - 120.0 - 12.0, "contagem cabe à direita")
	for footer: StringName in [&"footer_chassis", &"footer_overlay"]:
		assert_true(
			_width(font, HudModel.text_for(footer, texts)) <= SCREEN_WIDTH - 16.0,
			"rodapé '%s' cabe" % footer
		)


func test_the_map_scene_builds_a_trapped_button_per_sector() -> void:
	var map: Control = (load(MAP_SCENE) as PackedScene).instantiate()
	map.set(&"standalone", false)
	(Engine.get_main_loop() as SceneTree).root.add_child(map)
	for sector: Dictionary in _sectors:
		var button: Button = map.call(&"button_for", sector[StationMapModel.KEY_ID])
		assert_not_null(button, "botão de %s" % sector["id"])
		if button == null:
			continue
		for side: String in ["focus_neighbor_left", "focus_neighbor_right",
				"focus_neighbor_top", "focus_neighbor_bottom", "focus_next", "focus_previous"]:
			var path: NodePath = button.get(side)
			assert_false(path.is_empty(), "%s de %s definido" % [side, sector["id"]])
			var target: Node = button.get_node_or_null(path)
			assert_true(
				target is Button and map.is_ancestor_of(target),
				"%s de %s fica dentro do mapa" % [side, sector["id"]]
			)
	map.free()


func test_the_map_is_registered_in_the_smoke_and_reachable_from_chassis_and_pause() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://tests/scenes.txt")
	assert_true(smoke.contains(MAP_SCENE), "mapa no smoke")
	var chassis: String = FileAccess.get_file_as_string("res://scenes/ui/chassis_menu.tscn")
	assert_true(chassis.contains(MAP_SCENE), "o terminal do chassi tem a página do mapa")
	var pause: String = FileAccess.get_file_as_string("res://scenes/ui/pause_menu.gd")
	assert_true(pause.contains(MAP_SCENE), "o pause abre o mapa")
	var pause_scene: String = FileAccess.get_file_as_string("res://scenes/ui/pause_menu.tscn")
	assert_true(pause_scene.contains('text = "MAPA"'), "item MAPA no pause")


func _snap(restored: Array, flags: Dictionary, collected: Array, scene: String) -> Dictionary:
	return {
		StationMapModel.SNAP_RESTORED: restored,
		StationMapModel.SNAP_FLAGS: flags,
		StationMapModel.SNAP_COLLECTED: collected,
		StationMapModel.SNAP_CHECKPOINT: "",
		StationMapModel.SNAP_CURRENT: scene,
	}


func _state(sector_id: StringName, snap: Dictionary) -> StringName:
	return StationMapModel.state_of(StationMapModel.find(_sectors, sector_id), snap, _logs)


func _neighbor(sector_id: StringName, direction: Vector2i) -> StringName:
	return StationMapModel.neighbor(_sectors, sector_id, direction)


func _width(font: Font, text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


func test_the_command_room_counts_as_the_reactor_on_the_map() -> void:
	var snap: Dictionary = _snap(
		[&"greenhouse", &"lab", &"infirmary", &"docks", &"memory", &"reactor"],
		{},
		[],
		ScenePaths.COMMAND_ROOM
	)
	assert_eq(StationMapModel.current_sector(_sectors, snap), &"reactor", "sala é do Reator")
	assert_false(
		StationMapModel.is_current(StationMapModel.find(_sectors, &"core_hub"), snap),
		"o Núcleo Central não diz VOCÊ ESTÁ AQUI na sala de comando"
	)
