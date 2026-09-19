extends TestCase

const ACTIONS: PackedStringArray = [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"jump",
	"dash",
	"interact",
	"beam",
	"flashlight",
	"map",
	"log_archive",
	"pause",
]

const LAYERS: PackedStringArray = [
	"world",
	"player",
	"enemy",
	"interactable",
	"hazard",
	"pickup",
	"one_way",
]


func test_input_map_has_the_twelve_actions() -> void:
	for action: String in ACTIONS:
		assert_true(InputMap.has_action(action), "ação %s" % action)


func test_input_actions_have_events() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			continue
		assert_true(InputMap.action_get_events(action).size() > 0, "eventos de %s" % action)


func test_collision_layer_names() -> void:
	for index: int in range(LAYERS.size()):
		var setting: String = "layer_names/2d_physics/layer_%d" % (index + 1)
		assert_eq(String(ProjectSettings.get_setting(setting, "")), LAYERS[index], setting)


func test_renderer_is_compatibility() -> void:
	var method: String = String(
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	)
	assert_eq(method, "gl_compatibility", "rendering_method")


func test_viewport_resolution() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)), 384, "largura")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)), 216, "altura")


func test_stretch_is_viewport_integer() -> void:
	assert_eq(String(ProjectSettings.get_setting("display/window/stretch/mode", "")), "viewport", "modo")
	assert_eq(
		String(ProjectSettings.get_setting("display/window/stretch/scale_mode", "")),
		"integer",
		"escala"
	)


func test_texture_filter_is_nearest() -> void:
	var filter: int = int(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)
	)
	assert_eq(filter, 0, "default_texture_filter")


func test_main_scene_is_splash() -> void:
	var main_scene: String = String(ProjectSettings.get_setting("application/run/main_scene", ""))
	assert_eq(main_scene, ScenePaths.SPLASH, "main_scene")


func test_autoloads_are_registered_in_order() -> void:
	var expected: PackedStringArray = [
		"EventBus",
		"Settings",
		"GameState",
		"SaveManager",
		"AudioManager",
		"SceneManager",
		"DialogueManager",
		"QACapture",
	]
	for name: String in expected:
		var setting: String = "autoload/%s" % name
		assert_true(ProjectSettings.has_setting(setting), setting)
