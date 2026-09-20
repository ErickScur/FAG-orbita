extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const PLAYABLE_LEVELS: PackedStringArray = ["core_hub", "greenhouse"]
const TILESETS: Dictionary = {
	"core_hub": "res://assets/placeholder/tiles/core_tiles.png",
	"greenhouse": "res://assets/placeholder/tiles/greenhouse_tiles.png",
}
const SOLID_TILE_ROWS: int = 2
const TILE_SIZE: int = 16
const AMBIENT_MAX_LUMA: float = 0.10
const TILE_MIN_LUMA: float = 0.45
const UNLIT_MAX_LUMA: float = 0.06
const LAMP_MIN_ENERGY: float = 0.8
const LAMP_MAX_ENERGY: float = 2.0
const LAMP_MIN_RADIUS: float = 48.0
const LAMP_MAX_RADIUS: float = 128.0


func test_ambient_of_playable_levels_is_dark() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var meta: Dictionary = _meta(level_id)
		var ambient: String = String(meta.get("ambient_color", ""))
		assert_false(ambient.is_empty(), "%s tem ambient_color" % level_id)
		assert_true(
			_luma(Color(ambient)) <= AMBIENT_MAX_LUMA,
			"%s: ambiente %s claro demais (%.3f)" % [level_id, ambient, _luma(Color(ambient))]
		)


func test_solid_tiles_are_mid_bright() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var luma: float = _solid_tile_luma(String(TILESETS[level_id]))
		assert_true(
			luma >= TILE_MIN_LUMA,
			"%s: tileset escuro demais (%.3f)" % [level_id, luma]
		)


func test_unlit_scenery_is_illegible() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var meta: Dictionary = _meta(level_id)
		var ambient: float = _luma(Color(String(meta.get("ambient_color", "#000000"))))
		var tiles: float = _solid_tile_luma(String(TILESETS[level_id]))
		assert_true(
			ambient * tiles <= UNLIT_MAX_LUMA,
			"%s: cenário sem lâmpada legível demais (%.3f)" % [level_id, ambient * tiles]
		)


func test_restored_ambient_stays_readable() -> void:
	var meta: Dictionary = _meta("greenhouse")
	var restored: String = String(meta.get("ambient_restored", ""))
	assert_false(restored.is_empty(), "estufa tem ambient_restored")
	var luma: float = _luma(Color(restored))
	assert_true(luma > AMBIENT_MAX_LUMA, "setor religado clareia (%.3f)" % luma)
	assert_true(luma < 0.5, "setor religado não estoura (%.3f)" % luma)


func test_lamps_stay_inside_the_tuned_range() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var entities: Dictionary = _meta(level_id).get("entities", {})
		for key: Variant in entities:
			var entity: Dictionary = entities[key]
			if not entity.has("radius"):
				continue
			var radius: float = float(entity.get("radius", 0.0))
			var energy: float = float(entity.get("energy", 0.0))
			var id: String = String(entity.get("id", key))
			assert_true(
				radius >= LAMP_MIN_RADIUS and radius <= LAMP_MAX_RADIUS,
				"%s: raio fora da faixa (%.1f)" % [id, radius]
			)
			assert_true(
				energy >= LAMP_MIN_ENERGY and energy <= LAMP_MAX_ENERGY,
				"%s: energia fora da faixa (%.2f)" % [id, energy]
			)


func _meta(level_id: String) -> Dictionary:
	var path: String = LEVELS_DIR + level_id + ".json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _solid_tile_luma(texture_path: String) -> float:
	var texture: Texture2D = load(texture_path)
	if texture == null:
		return 0.0
	var image: Image = texture.get_image()
	var height: int = mini(SOLID_TILE_ROWS * TILE_SIZE, image.get_height())
	var total: float = 0.0
	var count: int = 0
	for y: int in range(height):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			total += _luma(pixel)
			count += 1
	return total / maxf(float(count), 1.0)


func _luma(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
