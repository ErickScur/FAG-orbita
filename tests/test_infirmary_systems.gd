extends TestCase

const DEMO_END_SCRIPT: String = "res://scenes/ui/demo_end.gd"
const INFIRMARY_PROPS: String = "res://assets/sprites/props/infirmary_props_sheet.png"


func test_legend_knows_the_infirmary_letters() -> void:
	var scenes: Dictionary = {
		"Y": "res://scenes/enemies/v9.tscn",
		"_": "res://scenes/world/thin_ice.tscn",
		"I": "res://scenes/world/ice_wall.tscn",
	}
	for symbol: String in scenes:
		assert_true(LevelBuilder.LEGEND.has(symbol), "legenda tem '%s'" % symbol)
		var scene: String = String(LevelBuilder.LEGEND[symbol]["scene"])
		assert_eq(scene, scenes[symbol], "cena '%s'" % symbol)
		assert_true(ResourceLoader.exists(scenes[symbol]), "cena existe: %s" % symbol)
	for reserved: String in LevelParser.TILE_CHARS:
		assert_false(LevelBuilder.LEGEND.has(reserved), "letra de tile '%s' livre" % reserved)


func test_infirmary_letters_parse_and_only_thin_ice_is_floor() -> void:
	var room: String = "\n".join([
		"############",
		"#   Y      #",
		"#      I   #",
		"#P  ___I  r#",
		"############",
	])
	var parsed: Dictionary = LevelParser.parse(room, LevelBuilder.entity_chars())
	assert_true((parsed["errors"] as PackedStringArray).is_empty(), "letras reconhecidas")
	assert_eq((parsed["entities"] as Array).size(), 7, "V-9, 3 gelos finos, 2 paredes, dado")
	var result: Dictionary = LevelReachability.analyze(room)
	assert_true(LevelReachability.unreachable_pickups(result).is_empty(), "V-9 e parede abertas")


func test_prop_sheet_frames_wrap_by_sheet_width() -> void:
	assert_eq(LevelBuilder.prop_cell(5, 192), Vector2i(5, 0), "folha antiga de 6 colunas")
	assert_eq(LevelBuilder.prop_cell(4, 128), Vector2i(0, 1), "folha 4x2: quadro 4 na linha 2")
	assert_eq(LevelBuilder.prop_cell(7, 128), Vector2i(3, 1), "último quadro")
	assert_eq(LevelBuilder.prop_cell(-1, 128), Vector2i(0, 0), "negativo vira 0")


func test_prop_accepts_another_sheet() -> void:
	var prop: Node2D = LevelBuilder._make_prop({"sheet": INFIRMARY_PROPS, "frame": 6})
	var sprite: Sprite2D = prop as Sprite2D
	assert_not_null(sprite.texture, "quadro carregado (definitivo ou placeholder)")
	var atlas: AtlasTexture = sprite.texture as AtlasTexture
	assert_eq(atlas.region.position, Vector2(64.0, 32.0), "quadro 6 = coluna 2, linha 1")
	prop.free()
	var legacy: Sprite2D = LevelBuilder._make_prop({"frame": 2}) as Sprite2D
	assert_eq((legacy.texture as AtlasTexture).region.position, Vector2(64.0, 0.0), "padrão")
	legacy.free()


func test_closing_text_follows_the_last_restored_sector() -> void:
	var script: GDScript = load(DEMO_END_SCRIPT)
	assert_eq(
		String(script.call(&"closing_text", [&"greenhouse"])),
		"A ESTUFA VOLTOU A RESPIRAR. A ESTAÇÃO AINDA NÃO.", "Estufa"
	)
	assert_eq(
		String(script.call(&"closing_text", [&"greenhouse", &"lab"])),
		"O LABORATÓRIO ESFRIOU. A ESTAÇÃO AINDA NÃO.", "Laboratório"
	)
	assert_eq(
		String(script.call(&"closing_text", [&"greenhouse", &"lab", &"infirmary"])),
		"A ENFERMARIA AQUECEU. A ESTAÇÃO AINDA NÃO.", "Enfermaria"
	)
	assert_eq(
		String(script.call(&"closing_text", [&"greenhouse", &"lab", &"infirmary", &"docks"])),
		"AS DOCAS SEGURARAM O AR. A ESTAÇÃO AINDA NÃO.", "Docas"
	)
	var memory: Array = [&"greenhouse", &"lab", &"infirmary", &"docks", &"memory"]
	assert_eq(
		String(script.call(&"closing_text", memory)),
		"A MEMÓRIA VOLTOU INTEIRA. A ESTAÇÃO AINDA NÃO.", "Memória"
	)
	assert_eq(
		String(script.call(&"closing_text", [])),
		"A MEMÓRIA VOLTOU INTEIRA. A ESTAÇÃO AINDA NÃO.", "padrão: o último setor pronto"
	)


func test_heated_core_has_a_chassis_label() -> void:
	var texts: Dictionary = HudModel.load_texts("res://data/ui/chassis_menu.json")
	assert_eq(HudModel.text_for(&"ability_heated_core", texts), "NÚCLEO AQUECIDO", "rótulo")
	assert_eq(HudModel.ability_cost(FreezeRules.ABILITY_ID), 0, "sem custo")
	assert_true(HudModel.status_icon_index(StatusEffects.FREEZE) >= 0, "ícone do frio no HUD")
