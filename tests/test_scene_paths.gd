extends TestCase

const LOADING_DATA: String = "res://data/ui/loading.json"
const RETIRED_DEMO_END: String = "res://scenes/ui/demo_end.tscn"


func test_is_level_accepts_level_scenes() -> void:
	assert_true(ScenePaths.is_level("res://scenes/levels/greenhouse.tscn"), "fase")
	assert_true(ScenePaths.is_level("res://scenes/levels/core_hub.tscn"), "fase hub")


func test_is_level_rejects_other_scenes() -> void:
	assert_false(ScenePaths.is_level("res://scenes/ui/main_menu.tscn"), "menu")
	assert_false(ScenePaths.is_level("res://scenes/boot/loading.tscn"), "loading")
	assert_false(ScenePaths.is_level("res://scenes/levels/greenhouse.txt"), "extensão errada")


func test_menu_scenes_never_count_as_playable() -> void:
	for path: String in [
		ScenePaths.MAIN_MENU,
		ScenePaths.SPLASH,
		ScenePaths.LOADING,
		"res://scenes/ui/options_menu.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/confirm_dialog.tscn",
		ScenePaths.GAME_OVER,
		ScenePaths.CREDITS,
		ScenePaths.CHASSIS_LOST,
	]:
		assert_false(ScenePaths.is_level(path), "cena de UI não é fase: %s" % path)


func test_ui_scenes_exist() -> void:
	for path: String in [
		ScenePaths.MAIN_MENU,
		"res://scenes/ui/options_menu.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/confirm_dialog.tscn",
		ScenePaths.GAME_OVER,
		ScenePaths.CREDITS,
		ScenePaths.CHASSIS_LOST,
		"res://scenes/ui/save_toast.tscn",
	]:
		assert_true(ResourceLoader.exists(path), "cena existe: %s" % path)


func test_level_key() -> void:
	assert_eq(ScenePaths.level_key("res://scenes/levels/greenhouse.tscn"), "greenhouse", "chave")
	assert_eq(ScenePaths.level_key("res://scenes/levels/core_hub.tscn"), "core_hub", "chave hub")


func test_loading_data_is_valid() -> void:
	assert_true(FileAccess.file_exists(LOADING_DATA), "arquivo existe")
	var file := FileAccess.open(LOADING_DATA, FileAccess.READ)
	assert_not_null(file, "abriu o arquivo")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary, "json é objeto")
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	var tips: Array = data.get("tips", [])
	assert_true(tips.size() > 0, "dicas não vazias")
	var names: Dictionary = data.get("sector_names", {})
	assert_true(names.has("core_hub"), "nome do núcleo central")
	assert_true(names.has("greenhouse"), "nome da estufa")


func test_the_only_ending_is_argos() -> void:
	var bus: GDScript = load("res://autoload/event_bus.gd")
	assert_false(bus.has_script_signal(&"demo_completed"), "o FIM DA DEMO foi aposentado")
	assert_true(bus.has_script_signal(&"argos_defeated"), "ARGOS leva à sala de comando")
	assert_false(ResourceLoader.exists(RETIRED_DEMO_END), "a tela de FIM DA DEMO não existe mais")
	assert_true(ResourceLoader.exists(ScenePaths.COMMAND_ROOM), "sala de comando")
	for file: String in DirAccess.get_files_at(ScenePaths.LEVELS_DIR):
		if not file.ends_with(".tscn"):
			continue
		var state: SceneState = (load(ScenePaths.LEVELS_DIR + file) as PackedScene).get_state()
		for node: int in range(state.get_node_count()):
			for index: int in range(state.get_node_property_count(node)):
				var property: StringName = state.get_node_property_name(node, index)
				assert_ne(String(property), "demo_end_until", "%s sem fim provisório" % file)
				if property != &"next_scene":
					continue
				var next: String = String(state.get_node_property_value(node, index))
				assert_true(ResourceLoader.exists(next), "%s segue para %s" % [file, next])
