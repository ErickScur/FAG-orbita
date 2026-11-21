extends TestCase

const TEST_SAVE: String = "user://test_f45_round_trip.json"
const CORE_SCENE: String = "res://scenes/levels/core_hub.tscn"
const GREENHOUSE_SCENE: String = "res://scenes/levels/greenhouse.tscn"
const PLAYED_FLAGS: Dictionary = {
	"dlg_core_wake": true,
	"dlg_core_return": true,
	"dlg_core_return_lab": true,
	"dlg_gh_enter": true,
}

var _previous_path: String = ""
var _snapshot: Dictionary = {}
var _level: Node = null


func before_each() -> void:
	_previous_path = SaveManager.save_path
	_snapshot = GameState.to_dict()
	SaveManager.save_path = TEST_SAVE
	_remove_save()
	GameState.new_game()
	GameState.flags = PLAYED_FLAGS.duplicate()


func after_each() -> void:
	_free_level()
	DialogueManager.clear()
	_remove_save()
	SaveManager.save_path = _previous_path
	GameState.from_dict(_snapshot)


func test_leaving_a_sector_by_its_door_lands_at_that_door() -> void:
	GameState.checkpoint = {"scene": GREENHOUSE_SCENE, "dock_id": "gh_dock_01"}
	GameState.enter_level(GREENHOUSE_SCENE)
	var level: Node = _open(CORE_SCENE)
	assert_eq(String(level.call(&"arrival_point")), "core_hub_exit", "chegou pela porta da Estufa")
	assert_true(
		_player_position(level).distance_to(_entity_position("core_hub_exit")) < 1.0,
		"o MU-7 aparece na frente da porta da Estufa"
	)
	assert_eq(String(GameState.checkpoint.get("scene", "")), CORE_SCENE, "backup no Núcleo")
	assert_eq(String(GameState.checkpoint.get("dock_id", "")), "hab_dock_02", "doca mais perto")
	assert_true(FileAccess.file_exists(TEST_SAVE), "o backup ao entrar foi gravado")


func test_continue_after_leaving_by_the_door_returns_to_the_hub_dock() -> void:
	GameState.checkpoint = {"scene": GREENHOUSE_SCENE, "dock_id": "gh_dock_01"}
	GameState.enter_level(GREENHOUSE_SCENE)
	_open(CORE_SCENE)
	_free_level()
	GameState.new_game()
	assert_true(SaveManager.load_game(), "o save carrega")
	assert_eq(String(GameState.checkpoint.get("scene", "")), CORE_SCENE, "Continuar vai ao Núcleo")
	var level: Node = _open(CORE_SCENE)
	assert_eq(String(level.call(&"arrival_point")), "", "Continuar não é porta")
	assert_true(
		_player_position(level).distance_to(_entity_position("hab_dock_02")) < 1.0,
		"Continuar nasce na doca gravada"
	)


func test_a_restored_sector_reopens_restored() -> void:
	var restored: Array[StringName] = [&"greenhouse"]
	GameState.sectors_restored = restored
	GameState.set_objective(&"obj_core_lab")
	var objective: String = GameState.current_objective
	GameState.checkpoint = {"scene": CORE_SCENE, "dock_id": "hab_dock_02"}
	GameState.enter_level(CORE_SCENE)
	var level: Node = _open(GREENHOUSE_SCENE)
	assert_eq(String(level.call(&"arrival_point")), "gh_exit_core", "entrou pela porta da Estufa")
	assert_true(
		_player_position(level).distance_to(_entity_position("gh_exit_core")) < 1.0,
		"o MU-7 aparece na porta de volta"
	)
	var ambient: CanvasModulate = level.get_node("CanvasModulate")
	assert_eq(ambient.color, Color("3d5a36"), "a Estufa religada continua clara")
	assert_eq(GameState.current_objective, objective, "o objetivo do Núcleo continua valendo")
	assert_eq(String(GameState.checkpoint.get("scene", "")), GREENHOUSE_SCENE, "backup ao entrar")
	assert_eq(String(GameState.checkpoint.get("dock_id", "")), "gh_dock_01", "doca da entrada")
	assert_false(DialogueManager.is_active(), "nenhuma fala de entrada repete")


func test_hub_exits_stay_open_after_their_sector_is_restored() -> void:
	var restored: Array[StringName] = [&"greenhouse", &"lab"]
	GameState.sectors_restored = restored
	GameState.checkpoint = {"scene": CORE_SCENE, "dock_id": "hab_dock_02"}
	_open(CORE_SCENE)
	for exit_id: String in ["core_hub_exit", "core_hub_exit_lab", "core_hub_exit_infirmary"]:
		var exit := _entity(exit_id) as LevelExit
		assert_not_null(exit, "%s existe" % exit_id)
		if exit == null:
			continue
		assert_false(exit.is_closed(), "%s aberta" % exit_id)
		assert_true(exit.enabled, "%s aceita interagir" % exit_id)
		assert_not_null(exit.plate(), "%s tem placa de setor" % exit_id)
	assert_true((_entity("core_hub_exit") as LevelExit).plate().is_restored(), "LED verde")
	assert_false(
		(_entity("core_hub_exit_infirmary") as LevelExit).plate().is_restored(), "LED vermelho"
	)
	for door_id: String in ["door_docks", "door_memory", "door_reactor"]:
		var door := _entity(door_id) as Door
		assert_not_null(door, "%s existe" % door_id)
		if door == null:
			continue
		assert_true(door.sealed, "%s selada" % door_id)
		assert_not_null(door.plate(), "%s tem placa de setor" % door_id)


func _open(scene_path: String) -> Node:
	_free_level()
	_level = (load(scene_path) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_level)
	return _level


func _free_level() -> void:
	if _level != null and is_instance_valid(_level):
		_level.get_parent().remove_child(_level)
		_level.free()
	_level = null


func _entity(entity_id: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	for node: Node in tree.get_nodes_in_group(StringName("entity:" + entity_id)):
		if _level != null and _level.is_ancestor_of(node):
			return node
	return null


func _entity_position(entity_id: String) -> Vector2:
	var node := _entity(entity_id) as Node2D
	if node == null:
		fail("entidade '%s' ausente" % entity_id)
		return Vector2(-9999.0, -9999.0)
	return node.global_position


func _player_position(level: Node) -> Vector2:
	var player := level.get_node_or_null("Player") as Node2D
	if player == null:
		fail("MU-7 ausente na fase")
		return Vector2(9999.0, 9999.0)
	return player.global_position


func _remove_save() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
