extends TestCase

const TILESETS: PackedStringArray = [
	"res://assets/tiles/core_tileset.tres",
	"res://assets/tiles/greenhouse_tileset.tres",
]
const WALL_SCENES: PackedStringArray = [
	"res://scenes/world/magnetic_wall.tscn",
	"res://scenes/world/secret_wall.tscn",
]
const BACK_FACE_CULL: int = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE


func test_tiles_do_not_carry_their_own_occluder() -> void:
	for path: String in TILESETS:
		var tile_set: TileSet = load(path)
		assert_true(tile_set != null, "%s carrega" % path)
		assert_eq(tile_set.get_occlusion_layers_count(), 0, "%s sem camada de oclusão" % path)


func test_a_single_block_keeps_one_loop_with_four_corners() -> void:
	var loops: Array[PackedVector2Array] = LevelBuilder.silhouette_loops({Vector2i(3, 3): true})
	assert_eq(loops.size(), 1, "um bloco isolado produz um contorno")
	assert_eq(loops[0].size(), 4, "quatro cantos")


func test_neighbouring_blocks_share_one_silhouette() -> void:
	var solids: Dictionary = {}
	for column: int in range(4):
		for row: int in range(2):
			solids[Vector2i(column, row)] = true
	var loops: Array[PackedVector2Array] = LevelBuilder.silhouette_loops(solids)
	assert_eq(loops.size(), 1, "oito blocos vizinhos produzem um único contorno")
	assert_eq(loops[0].size(), 4, "o retângulo mantém só os quatro cantos")


func test_a_room_produces_an_outer_loop_and_a_hole() -> void:
	var solids: Dictionary = {}
	for column: int in range(5):
		for row: int in range(5):
			if column == 0 or row == 0 or column == 4 or row == 4:
				solids[Vector2i(column, row)] = true
	var loops: Array[PackedVector2Array] = LevelBuilder.silhouette_loops(solids)
	assert_eq(loops.size(), 2, "a sala tem contorno externo e furo interno")
	var first: float = _signed_area(loops[0])
	var second: float = _signed_area(loops[1])
	assert_true(first * second < 0.0, "o furo roda ao contrário do contorno externo")


func test_level_occluders_only_cast_from_the_far_face() -> void:
	var solids: Dictionary = {Vector2i(1, 1): true, Vector2i(2, 1): true}
	var layer := TileMapLayer.new()
	LevelBuilder.build_occluders({"solids": solids}, layer)
	var holder: Node = layer.get_node_or_null(NodePath(LevelBuilder.OCCLUDERS_NODE))
	assert_true(holder != null, "a fase ganha o nó de oclusores")
	assert_eq(holder.get_child_count(), 1, "um oclusor por contorno")
	var occluder: LightOccluder2D = holder.get_child(0) as LightOccluder2D
	assert_true(occluder != null, "o filho é um LightOccluder2D")
	assert_eq(occluder.occluder.cull_mode, BACK_FACE_CULL, "só a face oposta à luz projeta")
	layer.free()


func test_walls_with_their_own_occluder_also_cull_the_front_face() -> void:
	for path: String in WALL_SCENES:
		var scene: PackedScene = load(path)
		var instance: Node = scene.instantiate()
		var found: LightOccluder2D = _find_occluder(instance)
		assert_true(found != null, "%s tem oclusor" % path)
		assert_eq(found.occluder.cull_mode, BACK_FACE_CULL, "%s culla a face frontal" % path)
		instance.free()


func _find_occluder(node: Node) -> LightOccluder2D:
	if node is LightOccluder2D:
		return node
	for child: Node in node.get_children():
		var found: LightOccluder2D = _find_occluder(child)
		if found != null:
			return found
	return null


func _signed_area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(points.size()):
		var current: Vector2 = points[index]
		var next: Vector2 = points[(index + 1) % points.size()]
		total += current.x * next.y - next.x * current.y
	return total * 0.5
