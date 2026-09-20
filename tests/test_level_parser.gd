extends TestCase

const LEGEND_CHARS: String = "DTLlrckC|ESM~mgx@obvz"
const ROOM: String = "#####\n#P  #\n#####"


func test_dimensions() -> void:
	var parsed: Dictionary = LevelParser.parse("P....\n.....\n.....".replace(".", " "), "")
	assert_eq(int(parsed["width"]), 5, "width")
	assert_eq(int(parsed["height"]), 3, "height")


func test_solids_and_oneways() -> void:
	var parsed: Dictionary = LevelParser.parse(ROOM, LEGEND_CHARS)
	var solids: Dictionary = parsed["solids"]
	assert_true(solids.has(Vector2i(0, 0)), "canto superior esquerdo sólido")
	assert_true(solids.has(Vector2i(4, 2)), "canto inferior direito sólido")
	assert_false(solids.has(Vector2i(2, 1)), "interior vazio")
	var one_ways: Array = LevelParser.parse("#####\n#P= #\n#####", LEGEND_CHARS)["one_ways"]
	assert_eq(one_ways.size(), 1, "uma plataforma one-way")
	assert_eq(one_ways[0], Vector2i(2, 1), "posição da one-way")


func test_spawn_required() -> void:
	var missing: Dictionary = LevelParser.parse("#####\n#   #\n#####", LEGEND_CHARS)
	assert_eq((missing["errors"] as PackedStringArray).size(), 1, "erro por falta de spawn")
	var duplicated: Dictionary = LevelParser.parse("#####\n#P P#\n#####", LEGEND_CHARS)
	assert_eq((duplicated["errors"] as PackedStringArray).size(), 1, "erro por dois spawns")
	var ok: Dictionary = LevelParser.parse(ROOM, LEGEND_CHARS)
	assert_true((ok["errors"] as PackedStringArray).is_empty(), "sem erros")
	assert_eq(ok["spawn"], Vector2i(1, 1), "spawn")


func test_unknown_char_error() -> void:
	var parsed: Dictionary = LevelParser.parse("#####\n#P &#\n#####", LEGEND_CHARS)
	var errors: PackedStringArray = parsed["errors"]
	assert_eq(errors.size(), 1, "um erro")
	assert_eq(errors[0], "linha 2, coluna 4: caractere '&' desconhecido", "mensagem")


func test_ragged_lines_pad() -> void:
	var parsed: Dictionary = LevelParser.parse("#####\n#P\n#####", LEGEND_CHARS)
	assert_eq(int(parsed["width"]), 5, "largura da maior linha")
	assert_eq((parsed["warnings"] as PackedStringArray).size(), 1, "um aviso")
	assert_true((parsed["errors"] as PackedStringArray).is_empty(), "sem erro")


func test_neighbor_mask_all_16() -> void:
	var center := Vector2i(1, 1)
	for mask: int in range(16):
		var solids: Dictionary = {center: true}
		if mask & LevelParser.MASK_UP:
			solids[Vector2i(1, 0)] = true
		if mask & LevelParser.MASK_RIGHT:
			solids[Vector2i(2, 1)] = true
		if mask & LevelParser.MASK_DOWN:
			solids[Vector2i(1, 2)] = true
		if mask & LevelParser.MASK_LEFT:
			solids[Vector2i(0, 1)] = true
		assert_eq(LevelParser.neighbor_mask(solids, center, 3, 3), mask, "máscara %d" % mask)


func test_mask_out_of_bounds_is_solid() -> void:
	var solids: Dictionary = {Vector2i(0, 0): true}
	assert_eq(LevelParser.neighbor_mask(solids, Vector2i(0, 0), 1, 1), 15, "borda conta como sólida")


func test_atlas_coords_for_mask() -> void:
	assert_eq(LevelParser.atlas_coords_for_mask(0), Vector2i(0, 0), "0")
	assert_eq(LevelParser.atlas_coords_for_mask(7), Vector2i(7, 0), "7")
	assert_eq(LevelParser.atlas_coords_for_mask(8), Vector2i(0, 1), "8")
	assert_eq(LevelParser.atlas_coords_for_mask(15), Vector2i(7, 1), "15")


func test_cell_to_position_anchors() -> void:
	var cell := Vector2i(2, 3)
	assert_eq(LevelParser.cell_to_position(cell, &"feet", 16), Vector2(40, 64), "pés")
	assert_eq(LevelParser.cell_to_position(cell, &"center", 16), Vector2(40, 56), "centro")


func test_entities_collected() -> void:
	var parsed: Dictionary = LevelParser.parse("#####\n#PD@#\n#####", LEGEND_CHARS)
	var entities: Array = parsed["entities"]
	assert_eq(entities.size(), 2, "duas entidades")
	assert_eq(String((entities[0] as Dictionary)["symbol"]), "D", "primeiro símbolo")
	assert_eq((entities[0] as Dictionary)["cell"], Vector2i(2, 1), "célula do D")
	assert_eq(String((entities[1] as Dictionary)["symbol"]), "@", "segundo símbolo")
	assert_eq((entities[1] as Dictionary)["cell"], Vector2i(3, 1), "célula do @")


func test_windows_are_background() -> void:
	var parsed: Dictionary = LevelParser.parse("#####\n#PW #\n#####", LEGEND_CHARS)
	assert_eq((parsed["windows"] as Array).size(), 1, "uma janela")
	assert_eq((parsed["entities"] as Array).size(), 0, "janela não é entidade")


func test_cell_key_round_trip() -> void:
	assert_eq(LevelParser.cell_key(Vector2i(12, 30)), "12,30", "chave")
	assert_eq(LevelParser.key_to_cell("12,30"), Vector2i(12, 30), "célula")
	assert_eq(LevelParser.key_to_cell("abc"), Vector2i(-1, -1), "chave inválida")


func test_legend_covers_all_entity_chars() -> void:
	for symbol: String in LEGEND_CHARS:
		assert_true(LevelBuilder.LEGEND.has(symbol), "legenda tem '%s'" % symbol)
	assert_eq(LevelBuilder.LEGEND.size(), LEGEND_CHARS.length(), "tamanho da legenda")
