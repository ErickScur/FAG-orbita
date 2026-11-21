extends TestCase

const SETTINGS_SCRIPT: String = "res://autoload/settings.gd"
const TEST_PATH: String = "user://test_accessibility_settings.cfg"
const MIN_COLORBLIND_CONTRAST: float = 0.5

var _settings: Node = null


func before_each() -> void:
	_settings = load(SETTINGS_SCRIPT).new()


func after_each() -> void:
	if _settings != null:
		_settings.free()
		_settings = null
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	InputMap.load_from_project_settings()


func test_subtitle_sizes_stay_on_the_pixel_font_grid() -> void:
	for size_id: StringName in Accessibility.SUBTITLE_SIZES:
		var size: int = Accessibility.subtitle_font_size(size_id)
		assert_eq(size % Accessibility.FONT_GRID, 0, "%s = %d fora da grade" % [size_id, size])
	assert_eq(Accessibility.subtitle_font_size(Accessibility.SUBTITLE_NORMAL), 16, "normal")
	assert_eq(Accessibility.subtitle_font_size(Accessibility.SUBTITLE_LARGE), 32, "grande")
	assert_eq(Accessibility.subtitle_font_size(&"gigante"), 16, "valor estranho cai no normal")
	assert_eq(Accessibility.valid_subtitle(&"gigante"), Accessibility.SUBTITLE_NORMAL, "valida")


func test_every_signal_role_changes_in_colorblind_mode() -> void:
	for role: StringName in Accessibility.PALETTE:
		assert_ne(
			Accessibility.color(role, false), Accessibility.color(role, true),
			"%s igual nos dois modos" % role
		)


func test_colorblind_palette_survives_deutan_and_protan_vision() -> void:
	var weakest: float = Accessibility.weakest_contrast(true)
	assert_true(
		weakest >= MIN_COLORBLIND_CONTRAST,
		"par de cores some para daltônico: distância %.3f" % weakest
	)
	assert_true(
		weakest > Accessibility.weakest_contrast(false),
		"a paleta alternativa precisa separar mais que a normal"
	)


func test_simulation_merges_red_and_green_axis() -> void:
	var red := Color("d04040")
	var green := Color("40a040")
	var seen_red: Color = Accessibility.simulate(red, Accessibility.VISION_DEUTAN)
	assert_almost_eq(seen_red.r, seen_red.g, 0.001, "deuteranopia não separa vermelho de verde")
	var plain: float = Vector3(red.r - green.r, red.g - green.g, red.b - green.b).length()
	assert_true(
		Accessibility.perceived_distance(red, green, Accessibility.VISION_DEUTAN) < plain,
		"vermelho e verde se aproximam"
	)


func test_settings_round_trip_with_accessibility_and_keys() -> void:
	_settings.subtitle_size = Accessibility.SUBTITLE_LARGE
	_settings.colorblind = true
	_settings.key_overrides = {"jump": KEY_K, "interact": KEY_SPACE}
	assert_true(_settings.save_settings(TEST_PATH), "salva em arquivo de teste")
	var loaded: Node = load(SETTINGS_SCRIPT).new()
	assert_true(loaded.load_settings(TEST_PATH), "carrega")
	assert_eq(loaded.subtitle_size, Accessibility.SUBTITLE_LARGE, "legenda")
	assert_true(loaded.colorblind, "daltônico")
	assert_eq(loaded.key_overrides, {"jump": KEY_K, "interact": KEY_SPACE}, "teclas")
	assert_eq(loaded.subtitle_font_size(), 32, "fonte grande")
	assert_eq(
		loaded.signal_color(Accessibility.ROLE_SECTOR_RESTORED),
		Accessibility.color(Accessibility.ROLE_SECTOR_RESTORED, true),
		"cor de sinal pela paleta central"
	)
	loaded.free()


func test_defaults_without_file() -> void:
	assert_false(_settings.load_settings("user://inexistente_access.cfg"), "sem arquivo")
	assert_eq(_settings.subtitle_size, Accessibility.SUBTITLE_NORMAL, "legenda normal")
	assert_false(_settings.colorblind, "daltônico desligado")
	assert_eq(_settings.key_overrides, {}, "sem teclas trocadas")


func test_loading_does_not_touch_the_input_map() -> void:
	_settings.key_overrides = {"jump": KEY_K}
	_settings.save_settings(TEST_PATH)
	var loaded: Node = load(SETTINGS_SCRIPT).new()
	loaded.load_settings(TEST_PATH)
	assert_eq(KeyBindings.action_label(&"jump"), "[ESPAÇO]", "ler o arquivo não remapeia")
	loaded.apply_bindings()
	assert_eq(KeyBindings.action_label(&"jump"), "[K]", "aplicar remapeia")
	loaded.free()


func test_rebind_and_restore_through_settings() -> void:
	var outcome: Dictionary = _settings.rebind(&"jump", KEY_E)
	assert_eq(outcome["result"], KeyBindings.RESULT_SWAPPED, "troca")
	assert_eq(_settings.key_overrides, {"jump": KEY_E, "interact": KEY_SPACE}, "lembra as duas")
	assert_eq(KeyBindings.action_label(&"interact"), "[ESPAÇO]", "InputMap trocado")
	_settings.restore_default_bindings()
	assert_eq(_settings.key_overrides, {}, "padrão")
	assert_eq(KeyBindings.action_label(&"jump"), "[ESPAÇO]", "pulo de volta")
	assert_eq(KeyBindings.action_label(&"interact"), "[E]", "interagir de volta")


func test_toggles_emit_change_once() -> void:
	var counter: Array[int] = [0]
	_settings.accessibility_changed.connect(func() -> void: counter[0] += 1)
	_settings.set_colorblind(true)
	_settings.set_colorblind(true)
	_settings.set_subtitle_size(Accessibility.SUBTITLE_LARGE)
	_settings.set_subtitle_size(&"gigante")
	assert_eq(counter[0], 3, "liga, aumenta e volta ao normal")
	assert_eq(_settings.subtitle_size, Accessibility.SUBTITLE_NORMAL, "valor estranho vira normal")
