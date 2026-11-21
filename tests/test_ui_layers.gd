extends TestCase

const SCAN_ROOTS: Array[String] = ["res://scenes", "res://autoload", "res://scripts"]
const SKIPPED_DIRS: Array[String] = ["res://scenes/dev"]
const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const DEFAULT_CANVAS_LAYER: int = 1
const SCENE_LAYERS: Dictionary = {
	"res://scenes/world/space_parallax.tscn::SpaceParallax": UiLayers.SPACE_BACKDROP,
	"res://scenes/fx/vignette.tscn::Vignette": UiLayers.VIGNETTE,
	"res://scenes/ui/tutorial_card.tscn::TutorialCard": UiLayers.TUTORIAL_CARD,
	"res://scenes/ui/hud.tscn::HUD": UiLayers.HUD,
	"res://scenes/ui/energy_terminal_ui.tscn::EnergyTerminalUI": UiLayers.ENERGY_TERMINAL,
	"res://scenes/ui/dialogue_box.tscn::DialogueBox": UiLayers.DIALOGUE,
	"res://scenes/ui/chassis_menu.tscn::ChassisMenu": UiLayers.CHASSIS_MENU,
	"res://scenes/ui/pause_menu.tscn::PauseMenu": UiLayers.PAUSE_MENU,
	"res://scenes/ui/save_toast.tscn::SaveToast": UiLayers.SAVE_TOAST,
	"res://scenes/ui/chassis_lost.tscn::ChassisLost": UiLayers.CHASSIS_LOST,
}
const NODE_HEADER: String = "[node name=\""
const CANVAS_TYPE: String = "type=\"CanvasLayer\""


func test_world_stays_below_hud_and_overlays_above() -> void:
	for layer: int in UiLayers.BELOW_HUD:
		assert_true(layer < UiLayers.HUD, "camada %d deveria ficar abaixo da HUD" % layer)
	for layer: int in UiLayers.ABOVE_HUD:
		assert_true(layer > UiLayers.HUD, "camada %d deveria ficar acima da HUD" % layer)
	assert_true(UiLayers.WORLD < UiLayers.HUD, "mundo abaixo da HUD")
	assert_true(UiLayers.HUD < UiLayers.DIALOGUE, "HUD abaixo do diálogo")
	assert_true(UiLayers.CHASSIS_MENU < UiLayers.PAUSE_MENU, "chassi abaixo da pausa")
	assert_true(UiLayers.CONFIRM_DIALOG < UiLayers.PAUSE_MENU, "escolha abaixo da pausa")
	assert_true(UiLayers.PAUSE_MENU < UiLayers.SCENE_TRANSITION, "fade cobre tudo")


func test_every_layer_has_its_own_number() -> void:
	var seen: Dictionary = {}
	for layer: int in UiLayers.all():
		assert_false(seen.has(layer), "camada %d repetida: empate segue a árvore" % layer)
		seen[layer] = true


func test_every_canvas_layer_in_a_scene_follows_ui_layers() -> void:
	var found: Dictionary = {}
	for path: String in _files_with_extension("tscn"):
		_collect_scene_layers(path, found)
	for key: String in found.keys():
		if not SCENE_LAYERS.has(key):
			fail("CanvasLayer sem lugar em UiLayers: %s (camada %d)" % [key, found[key]])
			continue
		assert_eq(found[key], SCENE_LAYERS[key], "camada de %s" % key)
	for key: String in SCENE_LAYERS.keys():
		assert_true(found.has(key), "CanvasLayer registrado e não encontrado: %s" % key)


func test_scripts_take_canvas_layers_from_ui_layers() -> void:
	var literal := RegEx.create_from_string(
		"(\\blayer\\s*=\\s*-?\\d|LAYER\\s*:\\s*int\\s*=\\s*-?\\d)"
	)
	for path: String in _files_with_extension("gd"):
		var source: String = FileAccess.get_file_as_string(path)
		if not source.contains("CanvasLayer"):
			continue
		var hit: RegExMatch = literal.search(source)
		assert_null(hit, "%s define camada com número solto; use UiLayers" % path)
		if source.contains("CanvasLayer.new()"):
			assert_true(source.contains("UiLayers."), "%s cria CanvasLayer sem UiLayers" % path)


func test_hud_labels_cast_a_shadow_for_bright_walls() -> void:
	var packed: PackedScene = load(HUD_SCENE) as PackedScene
	var hud: Node = packed.instantiate()
	var root: Control = hud.get_node("Root") as Control
	assert_not_null(root.theme, "HUD sem tema de legibilidade")
	if root.theme != null:
		assert_eq(root.theme.get_constant(&"shadow_offset_x", &"Label"), 1, "sombra x de 1 px")
		assert_eq(root.theme.get_constant(&"shadow_offset_y", &"Label"), 1, "sombra y de 1 px")
		var shadow: Color = root.theme.get_color(&"font_shadow_color", &"Label")
		assert_true(shadow.a > 0.9, "sombra opaca")
		assert_true(shadow.get_luminance() < 0.1, "sombra escura")
		assert_eq(root.theme.get_constant(&"outline_size", &"Label"), 0, "sem contorno grosso")
	hud.free()


func _collect_scene_layers(path: String, into: Dictionary) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	var index: int = 0
	while index < lines.size():
		var line: String = lines[index]
		index += 1
		if not (line.begins_with(NODE_HEADER) and line.contains(CANVAS_TYPE)):
			continue
		var name_end: int = line.find("\"", NODE_HEADER.length())
		var node_name: String = line.substr(NODE_HEADER.length(), name_end - NODE_HEADER.length())
		var layer: int = DEFAULT_CANVAS_LAYER
		while index < lines.size() and not lines[index].begins_with("["):
			if lines[index].begins_with("layer = "):
				layer = int(lines[index].trim_prefix("layer = "))
			index += 1
		into["%s::%s" % [path, node_name]] = layer


func _files_with_extension(extension: String) -> Array[String]:
	var result: Array[String] = []
	for root: String in SCAN_ROOTS:
		_walk(root, extension, result)
	return result


func _walk(dir_path: String, extension: String, into: Array[String]) -> void:
	if dir_path in SKIPPED_DIRS:
		return
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		if file_name.get_extension() == extension:
			into.append(dir_path.path_join(file_name))
	for sub: String in dir.get_directories():
		_walk(dir_path.path_join(sub), extension, into)
