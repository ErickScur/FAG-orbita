extends TestCase

const DOOR_SCENE: String = "res://scenes/world/door.tscn"
const EXIT_SCENE: String = "res://scenes/world/level_exit.tscn"
const GREENHOUSE_SCENE: String = "res://scenes/levels/greenhouse.tscn"
const LAB_SCENE: String = "res://scenes/levels/lab.tscn"
const SEALED_DOOR: Dictionary = {
	"sealed_until_sector": "greenhouse", "terminal_id": "core_hub", "system_id": "x"
}
const META: Dictionary = {
	"objective": "obj_core_hub",
	"ambient_color": "#0d1219",
	"on_enter_dialogue": "core_wake",
	"music": "core",
	"revisit": {
		"after_sector": "greenhouse",
		"spawn_dock": "hab_dock_01",
		"objective": "obj_core_lab",
		"ambient_color": "#1b2a36",
		"on_enter_dialogue": "core_return",
	},
}

var _restored_before: Array[StringName] = []


func before_each() -> void:
	_restored_before = GameState.sectors_restored.duplicate()


func after_each() -> void:
	GameState.sectors_restored = _restored_before


func test_first_visit_keeps_the_top_level_values() -> void:
	var meta: Dictionary = SectorRevisit.apply(META, [])
	assert_eq(String(meta["objective"]), "obj_core_hub", "objetivo de topo")
	assert_eq(String(meta["on_enter_dialogue"]), "core_wake", "fala de topo")
	assert_false(meta.has("revisit"), "bloco consumido")
	assert_eq(SectorRevisit.spawn_dock(META, []), "", "sem doca de revisita")


func test_revisit_overrides_after_the_sector() -> void:
	var restored: Array = [&"greenhouse"]
	var meta: Dictionary = SectorRevisit.apply(META, restored)
	assert_eq(String(meta["objective"]), "obj_core_lab", "objetivo novo")
	assert_eq(String(meta["ambient_color"]), "#1b2a36", "ambiente mais claro")
	assert_eq(String(meta["on_enter_dialogue"]), "core_return", "fala de marco")
	assert_eq(String(meta["music"]), "core", "o que o bloco não cita fica")
	assert_false(meta.has("after_sector"), "chave de controle não vaza")
	assert_eq(SectorRevisit.spawn_dock(META, restored), "hab_dock_01", "nasce na doca indicada")


func test_other_sector_does_not_trigger_the_revisit() -> void:
	assert_eq(SectorRevisit.spawn_dock(META, [&"lab"]), "", "setor errado")
	var invalid: Dictionary = SectorRevisit.active_block({"revisit": "x"}, [&"greenhouse"])
	assert_true(invalid.is_empty(), "bloco inválido")


func test_door_seal_follows_the_sector() -> void:
	assert_true(SectorRevisit.door_sealed(&"greenhouse", []), "selada antes")
	assert_false(SectorRevisit.door_sealed(&"greenhouse", [&"greenhouse"]), "aberta depois")
	assert_false(SectorRevisit.door_sealed(&"", []), "sem parâmetro não sela")
	assert_true(SectorRevisit.exit_closed(&"greenhouse", ["greenhouse"]), "saída fecha depois")
	assert_false(SectorRevisit.exit_closed(&"greenhouse", []), "saída aberta antes")
	assert_false(SectorRevisit.exit_closed(&"", [&"greenhouse"]), "saída comum nunca fecha")


func test_door_scene_is_sealed_until_the_sector() -> void:
	GameState.sectors_restored = []
	var door: Door = _add(DOOR_SCENE)
	door.configure(SEALED_DOOR)
	assert_true(door.sealed, "selada antes da Estufa")
	assert_false(door.is_open(), "fechada")
	door.free()
	GameState.sectors_restored = [&"greenhouse"]
	door = _add(DOOR_SCENE)
	door.configure(SEALED_DOOR)
	assert_false(door.sealed, "destravada")
	assert_true(door.is_open(), "aberta")
	assert_eq(door.terminal_id, &"", "fora do terminal")
	door.set_powered(false)
	assert_true(door.is_open(), "terminal não fecha mais")
	door.free()


func test_exit_scene_closes_after_the_sector() -> void:
	GameState.sectors_restored = []
	var exit: LevelExit = _add(EXIT_SCENE)
	exit.configure({"closes_after_sector": "greenhouse", "target": GREENHOUSE_SCENE})
	assert_false(exit.is_closed(), "aberta antes")
	exit.free()
	GameState.sectors_restored = [&"greenhouse"]
	exit = _add(EXIT_SCENE)
	exit.configure({"closes_after_sector": "greenhouse", "target": GREENHOUSE_SCENE})
	assert_true(exit.is_closed(), "fechada depois")
	assert_false((exit.get_node("Light") as PointLight2D).enabled, "luz do portal apagada")
	exit.free()


func test_greenhouse_returns_to_the_core_and_lab_ends_the_demo() -> void:
	var greenhouse: Dictionary = _narrative(GREENHOUSE_SCENE)
	assert_eq(greenhouse.get("sector_id"), &"greenhouse", "setor da Estufa")
	assert_eq(greenhouse.get("ability_id"), ClimbLogic.ABILITY_ID, "garras")
	assert_eq(
		String(greenhouse.get("next_scene", "")), "res://scenes/levels/core_hub.tscn", "volta"
	)
	var lab: Dictionary = _narrative(LAB_SCENE)
	assert_eq(lab.get("sector_id"), &"lab", "setor do Laboratório")
	assert_eq(lab.get("ability_id"), HeatRules.ABILITY_ID, "Dissipador")
	assert_eq(String(lab.get("next_scene", "")), "", "sem próxima cena: tela de fim")
	assert_eq(lab.get("restored_dialogue"), &"lab_restored", "fala de fechamento")


func _narrative(scene_path: String) -> Dictionary:
	var values: Dictionary = {}
	var state: SceneState = (load(scene_path) as PackedScene).get_state()
	for index: int in range(state.get_node_count()):
		if String(state.get_node_name(index)) != "Narrative":
			continue
		for property: int in range(state.get_node_property_count(index)):
			var name: String = String(state.get_node_property_name(index, property))
			values[name] = state.get_node_property_value(index, property)
		return values
	fail("%s sem nó Narrative" % scene_path)
	return values


func _add(scene_path: String) -> Node:
	var node: Node = load(scene_path).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	return node
