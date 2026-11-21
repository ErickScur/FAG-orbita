extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const DOOR_SYMBOL: String = "|"
const REACH_TILES: int = 2
const SPAWN_MARGIN_TILES: int = 4
const STEP_PX: float = 2.0
const ROOT: StringName = &"root_access"

var _holders: Array[Node] = []
var _saved_restored: Array[StringName] = []
var _saved_abilities: Array[StringName] = []


func before_each() -> void:
	_saved_restored = GameState.sectors_restored.duplicate()
	_saved_abilities = GameState.abilities.duplicate()
	GameState.new_game()


func after_each() -> void:
	for holder: Node in _holders:
		if is_instance_valid(holder):
			holder.get_parent().remove_child(holder)
			holder.free()
	_holders.clear()
	GameState.new_game()
	GameState.sectors_restored = _saved_restored
	GameState.abilities = _saved_abilities


func test_every_root_door_beats_whatever_sits_next_to_it() -> void:
	GameState.abilities.append(ROOT)
	for sector: Dictionary in StationMapModel.load_station()["sectors"]:
		GameState.sectors_restored.append(sector["id"])
	var doors: int = 0
	var rivals: int = 0
	for level_id: String in _level_ids():
		var holder: Node2D = _build_near_root_doors(level_id)
		if holder == null:
			continue
		for door: Door in _doors_in(holder):
			doors += 1
			var panel: Interactable = door.root_panel()
			assert_not_null(panel, "%s: porta ROOT com painel" % level_id)
			if panel == null:
				continue
			assert_true(panel.is_actionable(), "%s: com Root o painel age" % level_id)
			var nearby: Array[Interactable] = _rivals_of(door, holder)
			rivals += nearby.size() - 1
			_assert_door_wins(level_id, door, panel, nearby)
	assert_true(doors >= 4, "as portas ROOT das fases foram conferidas (%d)" % doors)
	assert_true(rivals >= 1, "pelo menos um vizinho disputou (o log do Laboratório)")


func test_the_lab_log_next_to_the_root_door_still_reads_without_root() -> void:
	var holder: Node2D = _build_near_root_doors("lab")
	assert_not_null(holder, "Laboratório tem porta ROOT")
	if holder == null:
		return
	var door: Door = _doors_in(holder)[0]
	var nearby: Array[Interactable] = _rivals_of(door, holder)
	assert_true(nearby.size() >= 2, "o log fica junto da porta")
	var origin: Vector2 = door.global_position + Vector2(float(Balance.TILE_SIZE), 0.0)
	var chosen: Interactable = Interactable.pick(nearby, origin)
	assert_true(chosen != door.root_panel(), "sem Root, a porta selada não rouba o log")


func _assert_door_wins(
	level_id: String, door: Door, panel: Interactable, nearby: Array[Interactable]
) -> void:
	var reach: float = float(REACH_TILES * Balance.TILE_SIZE)
	var x: float = -reach
	while x <= reach:
		var origin: Vector2 = door.global_position + Vector2(x, 0.0)
		var chosen: Interactable = Interactable.pick(nearby, origin)
		assert_true(
			chosen == panel,
			"%s: MU-7 a %d px da porta %s escolhe %s"
			% [level_id, int(x), door.door_id, chosen.name if chosen != null else "nada"]
		)
		if chosen != panel:
			return
		x += STEP_PX


func _rivals_of(door: Door, holder: Node) -> Array[Interactable]:
	var result: Array[Interactable] = []
	var reach: float = float((REACH_TILES + 1) * Balance.TILE_SIZE)
	for item: Interactable in _interactables_in(holder):
		if not item.enabled:
			continue
		var offset: Vector2 = item.global_position - door.global_position
		if absf(offset.x) <= reach and absf(offset.y) <= reach * 2.0:
			result.append(item)
	return result


func _build_near_root_doors(level_id: String) -> Node2D:
	var text_path: String = LEVELS_DIR + level_id + ".txt"
	var meta: Dictionary = _read_json(LEVELS_DIR + level_id + ".json")
	var parsed: Dictionary = LevelParser.parse(
		FileAccess.get_file_as_string(text_path), LevelBuilder.entity_chars()
	)
	var entities_meta: Dictionary = meta.get("entities", {})
	var doors: Array[Vector2i] = []
	for entry: Dictionary in parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) != DOOR_SYMBOL:
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		var params: Variant = entities_meta.get(LevelParser.cell_key(cell), {})
		if params is Dictionary and (params as Dictionary).has("requires_ability"):
			doors.append(cell)
	if doors.is_empty():
		return null
	var kept: Array = []
	for entry: Dictionary in parsed.get("entities", []) as Array:
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		for door_cell: Vector2i in doors:
			if (
				absi(cell.x - door_cell.x) <= SPAWN_MARGIN_TILES
				and absi(cell.y - door_cell.y) <= SPAWN_MARGIN_TILES
			):
				kept.append(entry)
				break
	var nearby: Dictionary = parsed.duplicate()
	nearby["entities"] = kept
	var holder := Node2D.new()
	holder.name = "RootDoorProbe_%s" % level_id
	Engine.get_main_loop().root.add_child(holder)
	_holders.append(holder)
	LevelBuilder.build_entities(nearby, meta, holder, level_id)
	return holder


func _doors_in(holder: Node) -> Array[Door]:
	var result: Array[Door] = []
	for child: Node in holder.get_children():
		if child is Door and (child as Door).is_root_locked():
			result.append(child as Door)
	return result


func _interactables_in(node: Node) -> Array[Interactable]:
	var result: Array[Interactable] = []
	for child: Node in node.get_children():
		if child is Interactable:
			result.append(child as Interactable)
		result.append_array(_interactables_in(child))
	return result


func _level_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for file: String in DirAccess.get_files_at(LEVELS_DIR):
		var level_id: String = file.get_basename()
		if file.ends_with(".txt") and FileAccess.file_exists(LEVELS_DIR + level_id + ".json"):
			result.append(level_id)
	return result


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
