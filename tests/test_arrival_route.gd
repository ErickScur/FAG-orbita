extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const LEVELS_DIR: String = "res://data/levels/"
const CORE_SCENE: String = "res://scenes/levels/core_hub.tscn"
const GREENHOUSE_SCENE: String = "res://scenes/levels/greenhouse.tscn"
const LAB_SCENE: String = "res://scenes/levels/lab.tscn"
const HUB_EXITS: Dictionary = {
	"res://scenes/levels/greenhouse.tscn": "core_hub_exit",
	"res://scenes/levels/lab.tscn": "core_hub_exit_lab",
	"res://scenes/levels/infirmary.tscn": "core_hub_exit_infirmary",
}
const SECTOR_RETURNS: Dictionary = {
	"greenhouse": "gh_exit_core",
	"lab": "lab_exit_core",
	"infirmary": "inf_exit_core",
}
const ICON_SIZE: int = 7

var _state: Node = null


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_state.new_game()


func after_each() -> void:
	if _state != null:
		_state.free()
		_state = null


func test_no_origin_means_no_arrival() -> void:
	var hub: Dictionary = _meta("core_hub")
	assert_eq(ArrivalRoute.exit_toward(hub, ""), "", "sem origem nasce no lugar de sempre")
	assert_eq(ArrivalRoute.exit_toward(hub, ScenePaths.MAIN_MENU), "", "menu não é porta")
	assert_eq(ArrivalRoute.exit_toward({}, GREENHOUSE_SCENE), "", "fase sem entidades")


func test_the_hub_receives_each_sector_at_its_own_door() -> void:
	var hub: Dictionary = _meta("core_hub")
	for origin: Variant in HUB_EXITS:
		assert_eq(
			ArrivalRoute.exit_toward(hub, String(origin)), String(HUB_EXITS[origin]),
			"quem volta de %s aparece na porta dele" % String(origin).get_file()
		)


func test_every_sector_has_a_door_back_at_its_entrance() -> void:
	for level_id: Variant in SECTOR_RETURNS:
		var meta: Dictionary = _meta(String(level_id))
		var exit_id: String = ArrivalRoute.exit_toward(meta, CORE_SCENE)
		assert_eq(exit_id, String(SECTOR_RETURNS[level_id]), "%s volta ao Núcleo" % level_id)
		var cell: Vector2i = _cell_of(meta, exit_id)
		var spawn: Vector2i = _spawn_of(String(level_id))
		assert_eq(cell.y, spawn.y, "%s: a porta fica no piso da entrada" % level_id)
		assert_true(absi(cell.x - spawn.x) <= 4, "%s: a porta fica junto da entrada" % level_id)
		var params: Dictionary = (meta["entities"] as Dictionary)[LevelParser.cell_key(cell)]
		assert_eq(String(params.get("sector", "")), "core", "%s: placa do Núcleo" % level_id)


func test_every_live_hub_exit_has_a_way_back() -> void:
	var hub: Dictionary = _meta("core_hub")
	var exits: Dictionary = ArrivalRoute.exits(hub)
	assert_true(exits.size() >= 3, "três setores ligados ao hub")
	for key: Variant in exits:
		var target: String = String((exits[key] as Dictionary)["target"])
		var meta: Dictionary = _meta(ScenePaths.level_key(target))
		assert_ne(
			ArrivalRoute.exit_toward(meta, CORE_SCENE), "",
			"%s tem porta de volta ao Núcleo" % target.get_file()
		)


func test_restored_sector_revisit_is_bright_and_silent() -> void:
	for level_id: Variant in SECTOR_RETURNS:
		var raw: Dictionary = _meta(String(level_id))
		var restored: Array = [StringName(String(level_id))]
		var meta: Dictionary = SectorRevisit.apply(raw, restored)
		assert_eq(
			String(meta.get("ambient_color", "")), String(raw.get("ambient_restored", "")),
			"%s volta religado: ambiente claro" % level_id
		)
		assert_eq(String(meta.get("objective", "x")), "", "%s não troca o objetivo" % level_id)
		assert_eq(
			String(meta.get("on_enter_dialogue", "x")), "", "%s não repete a fala de entrada" % level_id
		)
		assert_eq(SectorRevisit.spawn_dock(raw, restored), "", "%s nasce pela porta" % level_id)
		var first: Dictionary = SectorRevisit.apply(raw, [])
		assert_ne(String(first.get("objective", "")), "", "%s na 1a visita tem objetivo" % level_id)


func test_entering_levels_tracks_the_origin() -> void:
	assert_eq(_state.enter_level(CORE_SCENE), "", "jogo novo não tem origem")
	assert_eq(_state.enter_level(GREENHOUSE_SCENE), CORE_SCENE, "entrou na Estufa vindo do Núcleo")
	assert_eq(_state.enter_level(CORE_SCENE), GREENHOUSE_SCENE, "voltou da Estufa")
	assert_eq(_state.enter_level(CORE_SCENE), "", "recarregar a mesma fase não é porta")
	assert_eq(_state.current_level(), CORE_SCENE, "fase atual")


func test_new_game_and_continue_forget_the_origin() -> void:
	_state.enter_level(GREENHOUSE_SCENE)
	_state.new_game()
	assert_eq(_state.enter_level(CORE_SCENE), "", "jogo novo esquece a porta")
	_state.enter_level(LAB_SCENE)
	_state.from_dict(_state.to_dict())
	assert_eq(_state.enter_level(CORE_SCENE), "", "Continuar usa o checkpoint, não a porta")
	assert_false(_state.to_dict().has("level_path"), "a origem não vai para o save")


func test_catalog_describes_every_sector() -> void:
	var table: Dictionary = SectorCatalog.load_all()
	for sector: String in ["core", "greenhouse", "lab", "infirmary", "docks", "memory", "reactor"]:
		var id := StringName(sector)
		assert_true(SectorCatalog.has(id, table), "setor %s no catálogo" % sector)
		assert_false(SectorCatalog.display_name(id, table).is_empty(), "%s tem nome" % sector)
		assert_false(SectorCatalog.prompt(id, table).is_empty(), "%s tem convite" % sector)
		assert_true(
			Color.html_is_valid(String(SectorCatalog.entry(id, table).get("color", ""))),
			"%s tem cor" % sector
		)
		var icon: PackedStringArray = SectorCatalog.icon(id, table)
		assert_eq(icon.size(), ICON_SIZE, "%s: ícone de %d linhas" % [sector, ICON_SIZE])
		for row: String in icon:
			assert_eq(row.length(), ICON_SIZE, "%s: linha do ícone com %d colunas" % [sector, ICON_SIZE])
		assert_true(SectorCatalog.icon_cells(icon).size() >= 8, "%s: ícone legível" % sector)
		assert_eq(
			SectorCatalog.sector_for_scene(SectorCatalog.scene(id, table), table), id,
			"%s: cena aponta de volta para o setor" % sector
		)
	assert_true(SectorCatalog.is_hub(SectorCatalog.HUB_ID, table), "o Núcleo é o hub")
	assert_false(SectorCatalog.is_hub(&"docks", table), "as Docas não são o hub")


func test_sector_icons_are_distinct() -> void:
	var table: Dictionary = SectorCatalog.load_all()
	var seen: Dictionary = {}
	for key: Variant in table:
		var signature: String = "|".join(SectorCatalog.icon(StringName(key), table))
		assert_false(seen.has(signature), "ícone de %s repete o de %s" % [key, seen.get(signature)])
		seen[signature] = key
	var colors: Dictionary = {}
	for key: Variant in table:
		var color: String = String(SectorCatalog.entry(StringName(key), table).get("color", ""))
		assert_false(colors.has(color), "cor de %s repete a de %s" % [key, colors.get(color)])
		colors[color] = key


func _meta(level_id: String) -> Dictionary:
	var path: String = LEVELS_DIR + level_id + ".json"
	if not FileAccess.file_exists(path):
		fail("metadados ausentes em %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _cell_of(meta: Dictionary, entity_id: String) -> Vector2i:
	var entities: Dictionary = meta.get("entities", {})
	for key: Variant in entities:
		if String((entities[key] as Dictionary).get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _spawn_of(level_id: String) -> Vector2i:
	var text: String = FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".txt")
	var parsed: Dictionary = LevelParser.parse(text, LevelBuilder.entity_chars())
	return parsed.get("spawn", Vector2i(-1, -1))
