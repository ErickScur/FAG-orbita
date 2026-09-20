extends TestCase

const TILE: int = 16
const SOURCE_ID: int = 0
const WORLD_LAYER: int = 0
const ONE_WAY_LAYER: int = 1
const SHEETS: Dictionary = {
	"core_hub": {
		"tileset": "res://assets/tiles/core_tileset.tres",
		"texture": "res://assets/tiles/core_tiles.png",
	},
	"greenhouse": {
		"tileset": "res://assets/tiles/greenhouse_tileset.tres",
		"texture": "res://assets/tiles/greenhouse_tiles.png",
	},
}
const YELLOW_MIN_WARM: float = 0.45
const YELLOW_MIN_GAP: float = 0.12
const LAMP_MIN_GAP: float = 0.20


func test_every_mask_tile_is_solid_and_opaque() -> void:
	for level_id: String in SHEETS:
		var source: TileSetAtlasSource = _source(level_id)
		var image: Image = _image(level_id)
		for mask: int in range(16):
			var coords: Vector2i = LevelParser.atlas_coords_for_mask(mask)
			assert_true(
				source.has_tile(coords),
				"%s: máscara %d ausente em %s" % [level_id, mask, coords]
			)
			var data: TileData = source.get_tile_data(coords, 0)
			assert_eq(
				data.get_collision_polygons_count(WORLD_LAYER),
				1,
				"%s: máscara %d sem colisão de mundo" % [level_id, mask]
			)
			assert_eq(
				_transparent_pixels(image, coords),
				0,
				"%s: máscara %d tem buraco e abriria costura" % [level_id, mask]
			)


func test_the_one_way_tile_is_a_thin_platform() -> void:
	for level_id: String in SHEETS:
		var source: TileSetAtlasSource = _source(level_id)
		var coords: Vector2i = LevelBuilder.ONE_WAY_TILE
		assert_true(source.has_tile(coords), "%s: tile one-way ausente" % level_id)
		var data: TileData = source.get_tile_data(coords, 0)
		assert_eq(
			data.get_collision_polygons_count(WORLD_LAYER),
			0,
			"%s: plataforma fina virou parede sólida" % level_id
		)
		assert_eq(
			data.get_collision_polygons_count(ONE_WAY_LAYER),
			1,
			"%s: plataforma fina sem colisão one-way" % level_id
		)
		assert_true(
			data.is_collision_polygon_one_way(ONE_WAY_LAYER, 0),
			"%s: colisão da plataforma fina não é one-way" % level_id
		)
		var image: Image = _image(level_id)
		assert_true(
			_opaque_in_row(image, coords, 0),
			"%s: plataforma fina sem desenho no topo do tile" % level_id
		)
		assert_false(
			_opaque_in_row(image, coords, TILE - 1),
			"%s: plataforma fina preenche o tile inteiro" % level_id
		)


func test_the_window_tile_lets_the_parallax_through() -> void:
	for level_id: String in SHEETS:
		var source: TileSetAtlasSource = _source(level_id)
		var coords: Vector2i = LevelBuilder.WINDOW_TILE
		assert_true(source.has_tile(coords), "%s: tile de janela ausente" % level_id)
		var data: TileData = source.get_tile_data(coords, 0)
		assert_eq(
			data.get_collision_polygons_count(WORLD_LAYER),
			0,
			"%s: janela não pode ter colisão" % level_id
		)
		var image: Image = _image(level_id)
		assert_true(
			_alpha(image, coords, Vector2i(TILE / 2, TILE / 2)) < 0.5,
			"%s: miolo da janela opaco, o espaço não aparece" % level_id
		)
		assert_true(
			_opaque_in_row(image, coords, 0) and _opaque_in_row(image, coords, TILE - 1),
			"%s: janela sem moldura" % level_id
		)


func test_the_background_tile_is_opaque_and_free_of_collision() -> void:
	for level_id: String in SHEETS:
		var source: TileSetAtlasSource = _source(level_id)
		var coords: Vector2i = LevelBuilder.BACKGROUND_TILE
		assert_true(source.has_tile(coords), "%s: parede de fundo ausente" % level_id)
		var data: TileData = source.get_tile_data(coords, 0)
		assert_eq(
			data.get_collision_polygons_count(WORLD_LAYER),
			0,
			"%s: parede de fundo não pode ter colisão" % level_id
		)
		assert_eq(
			_transparent_pixels(_image(level_id), coords),
			0,
			"%s: parede de fundo com buraco" % level_id
		)


func test_the_magnetic_wall_frame_is_yellow_striped() -> void:
	var coords := Vector2i(MagneticWall.TILE_COLUMN, MagneticWall.TILE_ROW)
	var source: TileSetAtlasSource = _source("greenhouse")
	assert_true(source.has_tile(coords), "estufa: quadro da parede magnética ausente")
	var image: Image = _image("greenhouse")
	assert_eq(_transparent_pixels(image, coords), 0, "parede magnética com buraco")
	var warm: float = 0.0
	var cold: float = 0.0
	for y: int in range(TILE):
		for x: int in range(TILE):
			var pixel: Color = _pixel(image, coords, Vector2i(x, y))
			warm = maxf(warm, minf(pixel.r, pixel.g))
			cold = maxf(cold, pixel.b)
	assert_true(
		warm >= YELLOW_MIN_WARM,
		"parede magnética sem amarelo forte (%.2f)" % warm
	)
	assert_true(
		warm - cold >= YELLOW_MIN_GAP,
		"parede magnética sem listra amarela contra o fundo (%.2f vs %.2f)" % [warm, cold]
	)


func test_the_lamp_has_a_lit_and_an_unlit_frame() -> void:
	var image: Image = _image("core_hub")
	var on: float = _frame_luma(image, PoweredLamp.FRAME_ON)
	var off: float = _frame_luma(image, PoweredLamp.FRAME_OFF)
	assert_true(on > 0.0, "quadro de luminária acesa vazio")
	assert_true(off > 0.0, "quadro de luminária apagada vazio")
	assert_true(
		on - off >= LAMP_MIN_GAP,
		"luminária apagada não é mais escura que a acesa (%.2f vs %.2f)" % [on, off]
	)


func _frame_luma(image: Image, index: int) -> float:
	var coords := Vector2i(index % 8, index / 8)
	var total: float = 0.0
	var count: int = 0
	for y: int in range(TILE):
		for x: int in range(TILE):
			var pixel: Color = _pixel(image, coords, Vector2i(x, y))
			if pixel.a <= 0.5:
				continue
			total += 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
			count += 1
	return total / maxf(float(count), 1.0)


func _source(level_id: String) -> TileSetAtlasSource:
	var tile_set: TileSet = load(String(SHEETS[level_id]["tileset"]))
	assert_not_null(tile_set, "%s: tileset não carregou" % level_id)
	return tile_set.get_source(SOURCE_ID) as TileSetAtlasSource


func _image(level_id: String) -> Image:
	var texture: Texture2D = AssetResolver.texture(String(SHEETS[level_id]["texture"]))
	assert_not_null(texture, "%s: textura de tiles ausente" % level_id)
	return texture.get_image()


func _pixel(image: Image, coords: Vector2i, at: Vector2i) -> Color:
	return image.get_pixel(coords.x * TILE + at.x, coords.y * TILE + at.y)


func _alpha(image: Image, coords: Vector2i, at: Vector2i) -> float:
	return _pixel(image, coords, at).a


func _transparent_pixels(image: Image, coords: Vector2i) -> int:
	var count: int = 0
	for y: int in range(TILE):
		for x: int in range(TILE):
			if _alpha(image, coords, Vector2i(x, y)) <= 0.5:
				count += 1
	return count


func _opaque_in_row(image: Image, coords: Vector2i, row: int) -> bool:
	for x: int in range(TILE):
		if _alpha(image, coords, Vector2i(x, row)) > 0.5:
			return true
	return false
