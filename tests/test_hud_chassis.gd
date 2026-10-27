extends TestCase

const TEXTS_PATH: String = "res://data/ui/chassis_menu.json"
const MENU_SCENE: String = "res://scenes/ui/chassis_menu.tscn"
const MENU_SCRIPT: String = "res://scenes/ui/chassis_menu.gd"
const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const PAUSE_SCRIPT: String = "res://scenes/ui/pause_menu.gd"
const THEME_PATH: String = "res://assets/ui/theme.tres"
const OBJECTIVE_VARIATION: StringName = &"ObjectiveLabel"
const OBJECTIVE_SLOT_WIDTH: float = 136.0
const PANEL_WIDTH: float = 368.0
const PANEL_PADDING: float = 8.0
const SCREEN_HEIGHT: float = 216.0
const ALL_ABILITIES: Array[StringName] = [&"dash", &"beam", &"magnetic_claws", &"heat_sink"]
const REQUIRED_KEYS: Array[StringName] = [
	&"title",
	&"footer",
	&"reactor_label",
	&"reactor_value",
	&"reactor_offline",
	&"integrity_label",
	&"charge_label",
	&"value_pair",
	&"logs_label",
	&"research_label",
	&"abilities_title",
	&"abilities_empty",
	&"ability_magnetic_claws",
	&"ability_dash",
	&"ability_beam",
	&"ability_cost",
	&"locked_title",
	&"map_label",
	&"map_value",
	&"sectors_label",
	&"sectors_value",
]

var _texts: Dictionary = {}


func before_each() -> void:
	_texts = HudModel.load_texts(TEXTS_PATH)


func test_chassis_texts_exist() -> void:
	for id: StringName in REQUIRED_KEYS:
		assert_false(HudModel.text_for(id, _texts).is_empty(), "texto '%s'" % id)


func test_chassis_templates_format() -> void:
	assert_eq(
		HudModel.format_single(HudModel.text_for(&"reactor_value", _texts), 74),
		"74%",
		"porcentagem do reator"
	)
	assert_eq(
		HudModel.format_pair(HudModel.text_for(&"value_pair", _texts), 1, 4),
		"1/4",
		"par corrente/total"
	)


func test_chassis_texts_avoid_glyphs_the_pixel_font_lacks() -> void:
	var missing: String = "←→↑↓✓—"
	for id: StringName in _texts:
		var text: String = HudModel.text_for(id, _texts)
		for index: int in range(missing.length()):
			assert_false(
				text.contains(missing.substr(index, 1)),
				"'%s' usa um glifo que a m5x7 não tem" % id
			)


func test_chassis_names_the_claws_ability() -> void:
	assert_eq(
		HudModel.text_for(&"ability_magnetic_claws", _texts),
		"GARRAS MAGNÉTICAS",
		"nome da habilidade das garras"
	)
	assert_eq(ClimbLogic.ABILITY_ID, &"magnetic_claws", "id da habilidade não mudou")


func test_chassis_names_dash_and_beam_with_their_cost() -> void:
	assert_eq(HudModel.text_for(&"ability_dash", _texts), "IMPULSO MAGNÉTICO", "nome do dash")
	assert_eq(HudModel.text_for(&"ability_beam", _texts), "FEIXE DE MANUTENÇÃO", "nome do feixe")
	var template: String = HudModel.text_for(&"ability_cost", _texts)
	assert_eq(
		HudModel.format_single(template, HudModel.ability_cost(DashLogic.ABILITY_ID)),
		"20 CARGA",
		"custo do dash vem do Balance"
	)
	assert_eq(
		HudModel.format_single(template, HudModel.ability_cost(BeamLogic.ABILITY_ID)),
		"25 CARGA",
		"custo do feixe vem do Balance"
	)
	assert_eq(HudModel.ability_cost(ClimbLogic.ABILITY_ID), 0, "garras não gastam Carga")


func test_every_ability_with_its_cost_fits_half_the_panel() -> void:
	var font: Font = (load(THEME_PATH) as Theme).default_font
	var column: float = (PANEL_WIDTH - PANEL_PADDING - _scene_constant("h_separation")) * 0.5
	var template: String = HudModel.text_for(&"ability_cost", _texts)
	for ability_id: StringName in ALL_ABILITIES:
		var text: String = HudModel.text_for(StringName("ability_" + ability_id), _texts)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var cost: int = HudModel.ability_cost(ability_id)
		if cost > 0:
			var cost_text: String = HudModel.format_single(template, cost)
			width += 4.0 + font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		assert_true(
			width <= column, "'%s' ocupa %.0f px (coluna %.0f)" % [ability_id, width, column]
		)


func test_the_open_menu_fits_the_screen_with_every_ability() -> void:
	var saved: Array[StringName] = GameState.abilities.duplicate()
	GameState.abilities = ALL_ABILITIES.duplicate()
	var menu: CanvasLayer = (load(MENU_SCENE) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	menu.call("_refresh")
	var panel: Control = menu.get_node("Root/Center/Panel")
	var height: float = panel.get_combined_minimum_size().y
	var width: float = panel.get_combined_minimum_size().x
	menu.free()
	GameState.abilities = saved
	assert_true(height <= SCREEN_HEIGHT, "painel com %.0f px de altura" % height)
	assert_true(width <= PANEL_WIDTH, "painel com %.0f px de largura" % width)


func _scene_constant(name: String) -> float:
	var scene: String = FileAccess.get_file_as_string(MENU_SCENE)
	var key: String = "theme_override_constants/%s = " % name
	var start: int = scene.find(key)
	if start < 0:
		return 0.0
	return float(scene.substr(start + key.length()).split("\n")[0])


func test_scene_exists_and_is_registered_in_the_smoke() -> void:
	assert_true(ResourceLoader.exists(MENU_SCENE), "cena do terminal do chassi")
	var smoke: String = FileAccess.get_file_as_string("res://tests/scenes.txt")
	assert_true(smoke.contains(MENU_SCENE), "cena no smoke")


func test_the_hud_mounts_the_chassis_menu() -> void:
	var text: String = FileAccess.get_file_as_string(HUD_SCENE)
	assert_true(text.contains(MENU_SCENE), "o HUD instancia o terminal do chassi")


func test_the_menu_opens_with_the_map_action_and_closes_with_esc() -> void:
	var source: String = FileAccess.get_file_as_string(MENU_SCRIPT)
	assert_true(source.contains('is_action_pressed(&"map")'), "abre e fecha com a ação 'map'")
	assert_true(source.contains('is_action_pressed(&"ui_cancel")'), "fecha com ESC")
	assert_true(source.contains("get_tree().paused = true"), "pausa o jogo enquanto aberto")
	assert_true(
		source.contains("PROCESS_MODE_ALWAYS"), "processa com a árvore pausada"
	)


func test_the_menu_refuses_to_open_during_a_blocking_line() -> void:
	var source: String = FileAccess.get_file_as_string(MENU_SCRIPT)
	assert_true(
		source.contains("DialogueManager.is_active() and DialogueManager.freezes_timer()"),
		"fala travante e leitura de log bloqueiam o terminal do chassi"
	)
	assert_true(source.contains("gui_get_focus_owner"), "modal com foco bloqueia o terminal")


func test_the_pause_menu_does_not_open_over_the_chassis_menu() -> void:
	var source: String = FileAccess.get_file_as_string(PAUSE_SCRIPT)
	assert_true(
		source.contains("if get_tree().paused:\n\t\treturn false"),
		"can_pause recusa quando a árvore já está pausada"
	)


func test_the_pause_panel_lists_the_chassis_key() -> void:
	var source: String = FileAccess.get_file_as_string(PAUSE_SCRIPT)
	assert_true(source.contains('{"label": "CHASSI", "actions": [&"map"]}'), "linha CHASSI")


func test_the_hud_lost_the_permanent_counters() -> void:
	var text: String = FileAccess.get_file_as_string(HUD_SCENE)
	assert_false(text.contains('name="Counters"'), "contadores saíram do HUD")
	assert_false(text.contains("LOGS 0/4"), "nenhum contador de logs fixo no HUD")
	assert_false(text.contains("DADOS 0/4"), "nenhum contador de dados fixo no HUD")
	var source: String = FileAccess.get_file_as_string("res://scenes/ui/hud.gd")
	assert_false(source.contains("_refresh_counters"), "hud.gd não desenha mais contadores")


func test_the_hud_only_shows_the_reactor_when_it_is_critical() -> void:
	var source: String = FileAccess.get_file_as_string("res://scenes/ui/hud.gd")
	assert_true(
		source.contains("return GameState.is_reactor_online() and _critical"),
		"o bloco do reator só aparece em estado crítico"
	)


func test_the_objective_font_comes_from_the_theme() -> void:
	var theme: Theme = load(THEME_PATH)
	assert_not_null(theme, "tema carregou")
	assert_eq(
		theme.get_type_variation_base(OBJECTIVE_VARIATION), &"Label", "variação deriva de Label"
	)
	assert_true(
		theme.has_font(&"font", OBJECTIVE_VARIATION), "a variação declara a própria fonte"
	)
	assert_eq(
		theme.get_font_size(&"font_size", OBJECTIVE_VARIATION), 16, "tamanho múltiplo de 16"
	)
	var hud: String = FileAccess.get_file_as_string(HUD_SCENE)
	assert_eq(
		hud.count('theme_type_variation = &"ObjectiveLabel"'),
		2,
		"rótulo e texto do objetivo usam a variação"
	)


func test_every_objective_fits_on_a_single_line() -> void:
	var theme: Theme = load(THEME_PATH)
	var font: Font = theme.get_font(&"font", OBJECTIVE_VARIATION)
	var size: int = theme.get_font_size(&"font_size", OBJECTIVE_VARIATION)
	assert_not_null(font, "fonte do objetivo")
	var table: Dictionary = Objectives.load_all()
	assert_false(table.is_empty(), "objetivos carregaram")
	for id: StringName in table:
		var text: String = Objectives.text_for(id, table)
		var width: float = font.get_string_size(
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, size
		).x
		assert_true(
			width <= OBJECTIVE_SLOT_WIDTH,
			"objetivo '%s' ocupa %.0f px (limite %.0f)" % [id, width, OBJECTIVE_SLOT_WIDTH]
		)
