extends SceneTree

const TILE_SIZE: int = 16
const SOLID_ROWS: int = 2
const ATLAS_COLUMNS: int = 8
const FULL_MASK: int = 15
const SOURCE_ID: int = 0
const EXTRA_TILES: Array[Vector2i] = [
	Vector2i(0, 2),
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(4, 2),
	Vector2i(5, 2),
	Vector2i(6, 2),
	Vector2i(7, 2),
	Vector2i(0, 3),
]
const ONE_WAY_TILE: Vector2i = Vector2i(0, 2)
const WORLD_LAYER: int = 1
const ONE_WAY_LAYER: int = 64
const TILESETS: Array[Dictionary] = [
	{
		"texture": "res://assets/tiles/core_tiles.png",
		"output": "res://assets/tiles/core_tileset.tres",
	},
	{
		"texture": "res://assets/tiles/greenhouse_tiles.png",
		"output": "res://assets/tiles/greenhouse_tileset.tres",
	},
]


func _initialize() -> void:
	var written: int = 0
	for entry: Dictionary in TILESETS:
		if _write_tileset(String(entry["texture"]), String(entry["output"])):
			written += 1
	print("make_tileset: %d tileset(s) gerado(s)" % written)
	quit(0 if written == TILESETS.size() else 1)


func _write_tileset(texture_path: String, output_path: String) -> bool:
	var resolved: String = AssetResolver.resolve(texture_path)
	if resolved.is_empty():
		push_error("make_tileset: textura ausente para %s" % texture_path)
		return false
	var texture: Texture2D = AssetResolver.texture(texture_path)
	if texture == null:
		push_error("make_tileset: textura inválida em %s" % resolved)
		return false
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, WORLD_LAYER)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(1, ONE_WAY_LAYER)
	tile_set.set_physics_layer_collision_mask(1, 0)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, SOURCE_ID)
	for mask: int in range(FULL_MASK + 1):
		var coords := Vector2i(mask % ATLAS_COLUMNS, mask / ATLAS_COLUMNS)
		source.create_tile(coords)
		var data: TileData = source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, _square())
	for coords: Vector2i in EXTRA_TILES:
		source.create_tile(coords)
		if coords != ONE_WAY_TILE:
			continue
		var one_way: TileData = source.get_tile_data(coords, 0)
		one_way.add_collision_polygon(1)
		one_way.set_collision_polygon_points(1, 0, _square())
		one_way.set_collision_polygon_one_way(1, 0, true)
	var error: int = ResourceSaver.save(tile_set, output_path)
	if error != OK:
		push_error("make_tileset: falha ao salvar %s (%d)" % [output_path, error])
		return false
	if not _normalize_ids(output_path):
		return false
	print("make_tileset: %s <- %s" % [output_path, resolved])
	return true


func _normalize_ids(output_path: String) -> bool:
	var text: String = FileAccess.get_file_as_string(output_path)
	if text.is_empty():
		push_error("make_tileset: não foi possível reler %s" % output_path)
		return false
	var ext := RegEx.new()
	ext.compile("id=\"[0-9]+_[A-Za-z0-9]+\"")
	text = ext.sub(text, "id=\"tiles\"", true)
	var ext_use := RegEx.new()
	ext_use.compile("ExtResource\\(\"[^\"]+\"\\)")
	text = ext_use.sub(text, "ExtResource(\"tiles\")", true)
	var atlas_ids := RegEx.new()
	atlas_ids.compile("TileSetAtlasSource_[A-Za-z0-9]+")
	text = atlas_ids.sub(text, "atlas_source", true)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("make_tileset: não foi possível reescrever %s" % output_path)
		return false
	file.store_string(text)
	file.close()
	return true


func _square() -> PackedVector2Array:
	var half: float = TILE_SIZE * 0.5
	return PackedVector2Array(
		[Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	)
