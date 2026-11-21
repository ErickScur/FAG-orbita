extends TestCase

const LEVEL_ID: String = "command_room"
const TEXT_PATH: String = "res://data/levels/command_room.txt"
const META_PATH: String = "res://data/levels/command_room.json"
const DIALOGUE_PATH: String = "res://data/dialogue/command_room.json"
const SCENE_PATH: String = "res://scenes/levels/command_room.tscn"
const CONSOLE_SCENE: String = "res://scenes/world/ending_console.tscn"
const MACHINE_SCENE: String = "res://scenes/world/ending_machine.tscn"
const MAX_LAMPS: int = 5

var _parsed: Dictionary = {}
var _meta: Dictionary = {}


func before_each() -> void:
	_parsed = LevelParser.parse(
		FileAccess.get_file_as_string(TEXT_PATH), LevelBuilder.entity_chars()
	)
	_meta = EndingData.read_json(META_PATH)


func test_map_parses_without_errors() -> void:
	var errors: PackedStringArray = _parsed.get("errors", [])
	assert_true(errors.is_empty(), ", ".join(errors))


func test_scene_paths_point_to_the_room() -> void:
	assert_eq(ScenePaths.COMMAND_ROOM, SCENE_PATH, "rota da F65")
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da sala")
	assert_true(ScenePaths.is_level(SCENE_PATH), "a sala é fase (passa pelo carregamento)")


func test_one_console_per_ending_and_one_machine_per_side() -> void:
	var consoles: Dictionary = {}
	var machines: Dictionary = {}
	for params: Dictionary in _params_by_scene(CONSOLE_SCENE):
		consoles[String(params.get("ending_id", ""))] = true
	for params: Dictionary in _params_by_scene(MACHINE_SCENE):
		machines[String(params.get("machine", ""))] = true
	assert_eq(consoles.size(), EndingData.ENDING_IDS.size(), "um console por final")
	for ending_id: StringName in EndingData.ENDING_IDS:
		assert_true(consoles.has(String(ending_id)), "console de %s" % ending_id)
	assert_true(machines.has("capsule"), "baia da cápsula")
	assert_true(machines.has("antenna"), "transmissor")


func test_each_console_stands_next_to_its_machine_on_opposite_sides() -> void:
	var seeding: Vector2i = _cell_of_param("ending_id", "seeding")
	var transmission: Vector2i = _cell_of_param("ending_id", "transmission")
	var capsule: Vector2i = _cell_of_param("machine", "capsule")
	var antenna: Vector2i = _cell_of_param("machine", "antenna")
	assert_true(capsule.x < seeding.x, "a cápsula fica do lado de fora do console dela")
	assert_true(seeding.x < transmission.x, "SEMEADURA à esquerda, TRANSMISSÃO à direita")
	assert_true(transmission.x < antenna.x, "o transmissor fica do lado de fora do console dele")
	assert_true(absi(seeding.x - capsule.x) <= 5, "console da semeadura perto da cápsula")
	assert_true(absi(antenna.x - transmission.x) <= 5, "console da transmissão perto da antena")


func test_the_floor_from_the_entrance_to_both_consoles_is_flat() -> void:
	var spawn: Vector2i = _parsed.get("spawn", Vector2i.ZERO)
	var solids: Dictionary = _parsed.get("solids", {})
	for ending_id: StringName in EndingData.ENDING_IDS:
		var console: Vector2i = _cell_of_param("ending_id", String(ending_id))
		assert_eq(console.y, spawn.y, "%s no piso da entrada" % ending_id)
		for column: int in range(spawn.x, console.x + 1):
			assert_false(solids.has(Vector2i(column, spawn.y)), "parede no caminho em %d" % column)
			assert_true(solids.has(Vector2i(column, spawn.y + 1)), "buraco no piso em %d" % column)


func test_the_room_is_silent_without_objective_and_off_the_clock() -> void:
	assert_eq(String(_meta.get("music", "x")), "", "sem música")
	assert_eq(String(_meta.get("objective", "")), "", "sem objetivo")
	assert_false(bool(_meta.get("reactor_online", true)), "reator fora do relógio")


func test_the_room_has_no_way_back_and_few_lights() -> void:
	var lamps: int = 0
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		var symbol: String = String(entry.get("symbol", ""))
		assert_ne(symbol, "E", "a escolha não tem saída")
		assert_ne(symbol, "T", "a escolha não tem puzzle")
		if symbol == "@":
			lamps += 1
	assert_true(lamps > 0 and lamps <= MAX_LAMPS, "poucas luzes: %d" % lamps)


func test_orbita_says_a_single_milestone_line() -> void:
	var data: Dictionary = EndingData.read_json(DIALOGUE_PATH)
	var sequences: Dictionary = data.get("sequences", {})
	assert_eq(sequences.size(), 1, "uma fala só")
	var sequence: Dictionary = sequences.get(String(_meta.get("on_enter_dialogue", "")), {})
	assert_eq((sequence.get("lines", []) as Array).size(), 1, "uma linha")
	assert_true(bool(sequence.get("once", false)), "não repete ao continuar")


func test_machine_and_console_scenes_load_their_art() -> void:
	var machine: Node = (load(MACHINE_SCENE) as PackedScene).instantiate()
	assert_true(machine is EndingMachine, "máquina")
	machine.free()
	var console: Node = (load(CONSOLE_SCENE) as PackedScene).instantiate()
	assert_true(console is EndingConsole, "console")
	assert_true(console is Interactable, "console é interativo")
	console.free()
	var sheet: Texture2D = AssetResolver.texture(EndingMachine.SHEET_PATH)
	assert_not_null(sheet, "folha da sala")
	if sheet != null:
		assert_eq(sheet.get_size(), Vector2(256, 128), "4x2 quadros de 64")


func _params_by_scene(scene: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var params: Dictionary = entities[key]
		if String(params.get("scene", "")) == scene:
			result.append(params)
	return result


func _cell_of_param(key: String, value: String) -> Vector2i:
	var entities: Dictionary = _meta.get("entities", {})
	for cell_key: Variant in entities:
		var params: Dictionary = entities[cell_key]
		if String(params.get(key, "")) != value:
			continue
		var parts: PackedStringArray = String(cell_key).split(",")
		return Vector2i(int(parts[0]), int(parts[1]))
	fail("entidade com %s=%s ausente" % [key, value])
	return Vector2i(-1, -1)
