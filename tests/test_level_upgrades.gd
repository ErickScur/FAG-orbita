extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const CAMPAIGN_LEVELS: Array[String] = [
	"core_hub", "greenhouse", "lab", "infirmary", "docks", "memory_core", "reactor_core",
]
const ALL_ABILITIES: Array[StringName] = [
	&"dash", &"beam", &"magnetic_claws", &"heat_sink", &"heated_core", &"thruster",
	&"root_access",
]
const PLATE_SYMBOL: String = "B"
const CAPACITOR_SYMBOL: String = "C"
const UPGRADES: Dictionary = {
	"plate_core_01": {"level": "core_hub", "symbol": PLATE_SYMBOL, "needs": &"magnetic_claws"},
	"plate_gh_01": {"level": "greenhouse", "symbol": PLATE_SYMBOL, "needs": &"root_access"},
	"plate_lab_01": {"level": "lab", "symbol": PLATE_SYMBOL, "needs": &"root_access"},
	"plate_dk_01": {"level": "docks", "symbol": PLATE_SYMBOL, "needs": &"root_access"},
	"capacitor_gh_01": {"level": "greenhouse", "symbol": "C", "needs": &""},
	"capacitor_lab_01": {"level": "lab", "symbol": "C", "needs": &""},
	"capacitor_inf_01": {"level": "infirmary", "symbol": "C", "needs": &"heated_core"},
	"capacitor_dk_01": {"level": "docks", "symbol": "C", "needs": &""},
}
const SECTOR_ORDER: Array[String] = ["core_hub", "greenhouse", "lab", "infirmary", "docks"]
const ABILITY_SOURCE: Dictionary = {
	&"magnetic_claws": "greenhouse",
	&"heat_sink": "lab",
	&"heated_core": "infirmary",
	&"thruster": "docks",
	&"root_access": "memory_core",
}
const ROOT_DOOR_MINIMUM: int = 3
const ROOT_DOOR_LEVELS: Array[String] = ["greenhouse", "lab", "docks"]

var _cache: Dictionary = {}


func test_every_upgrade_of_the_table_is_on_its_map() -> void:
	for item_id: String in UPGRADES:
		var spec: Dictionary = UPGRADES[item_id]
		var cell: Vector2i = _cell_of(String(spec["level"]), item_id)
		assert_true(cell.x >= 0, "%s está em %s" % [item_id, spec["level"]])
		if cell.x < 0:
			continue
		var line: String = _lines(String(spec["level"]))[cell.y]
		assert_eq(line[cell.x], String(spec["symbol"]), "%s com o símbolo certo" % item_id)


func test_upgrade_totals_never_pass_the_gdd() -> void:
	var capacitors: int = 0
	var plates: int = 0
	for level: String in CAMPAIGN_LEVELS:
		if not FileAccess.file_exists(LEVELS_DIR + level + ".txt"):
			continue
		for line: String in _lines(level):
			capacitors += line.count(CAPACITOR_SYMBOL)
			plates += line.count(PLATE_SYMBOL)
	assert_true(capacitors <= Balance.CAPACITORS_TOTAL, "%d capacitores" % capacitors)
	assert_true(plates <= Balance.ARMOR_PLATES_TOTAL, "%d placas" % plates)
	assert_eq(capacitors, Balance.CAPACITORS_TOTAL, "o das Docas é o 4º capacitor")
	assert_eq(plates, Balance.ARMOR_PLATES_TOTAL, "a das Docas é a 4ª placa")


func test_each_upgrade_is_reachable_with_every_ability() -> void:
	for item_id: String in UPGRADES:
		var spec: Dictionary = UPGRADES[item_id]
		var result: Dictionary = _analyze(String(spec["level"]), ALL_ABILITIES)
		var cell: Vector2i = _cell_of(String(spec["level"]), item_id)
		assert_true(LevelReachability.is_touched(result, cell), "%s alcançável" % item_id)


func test_gated_upgrades_need_their_ability() -> void:
	for item_id: String in UPGRADES:
		var spec: Dictionary = UPGRADES[item_id]
		var needs: StringName = spec["needs"]
		if needs == &"":
			continue
		var without: Array[StringName] = ALL_ABILITIES.duplicate()
		without.erase(needs)
		var result: Dictionary = _analyze(String(spec["level"]), without)
		var cell: Vector2i = _cell_of(String(spec["level"]), item_id)
		assert_false(
			LevelReachability.is_touched(result, cell), "%s não sai sem %s" % [item_id, needs]
		)


func test_new_plates_ask_for_an_ability_from_a_later_sector() -> void:
	for item_id: String in UPGRADES:
		var spec: Dictionary = UPGRADES[item_id]
		if String(spec["symbol"]) != PLATE_SYMBOL:
			continue
		var needs: StringName = spec["needs"]
		assert_true(ABILITY_SOURCE.has(needs), "%s pede habilidade de setor" % item_id)
		var source: String = String(ABILITY_SOURCE.get(needs, ""))
		var here: int = SECTOR_ORDER.find(String(spec["level"]))
		var later: int = SECTOR_ORDER.find(source)
		assert_true(later < 0 or later > here, "%s exige volta (%s depois)" % [item_id, source])


func test_at_least_two_upgrades_sit_behind_root_doors() -> void:
	var behind_root: int = 0
	for item_id: String in UPGRADES:
		if (UPGRADES[item_id] as Dictionary)["needs"] == &"root_access":
			behind_root += 1
	assert_true(behind_root >= ROOT_DOOR_MINIMUM, "%d upgrades atrás de ROOT" % behind_root)
	for level: String in ROOT_DOOR_LEVELS:
		var doors: int = 0
		for key: Variant in _meta(level).get("entities", {}):
			var params: Dictionary = (_meta(level)["entities"] as Dictionary)[key]
			if String(params.get("requires_ability", "")) == "root_access":
				doors += 1
				var cell: Vector2i = LevelParser.key_to_cell(String(key))
				assert_eq(_lines(level)[cell.y][cell.x], "|", "porta ROOT em %s" % key)
		assert_eq(doors, 1, "%s tem uma porta ROOT" % level)


func test_reactor_needs_root_in_the_hub_geometry() -> void:
	var exit_cell := Vector2i(146, 5)
	var without: Array[StringName] = ALL_ABILITIES.duplicate()
	without.erase(&"root_access")
	var text: String = FileAccess.get_file_as_string(LEVELS_DIR + "core_hub.txt")
	var meta: Dictionary = _meta("core_hub")
	var lines: PackedStringArray = text.split("\n")
	var row: String = lines[exit_cell.y]
	lines[exit_cell.y] = row.substr(0, exit_cell.x) + "E" + row.substr(exit_cell.x + 1)
	var opened: Dictionary = LevelReachability.analyze_with_abilities(
		"\n".join(lines), meta, ALL_ABILITIES
	)
	var closed: Dictionary = LevelReachability.analyze_with_abilities(
		"\n".join(lines), meta, without
	)
	assert_true(LevelReachability.can_stand_at(opened, exit_cell), "Reator com o Root")
	assert_false(LevelReachability.can_stand_at(closed, exit_cell), "Reator fechado sem o Root")


func test_the_campaign_route_still_works_without_root() -> void:
	var without: Array[StringName] = ALL_ABILITIES.duplicate()
	without.erase(&"root_access")
	for level: String in ROOT_DOOR_LEVELS:
		var result: Dictionary = _analyze(level, without)
		for entry: Dictionary in LevelReachability.entities(result, "o"):
			var params: Dictionary = (_meta(level).get("entities", {}) as Dictionary).get(
				LevelParser.cell_key(entry["cell"]), {}
			)
			if String(params.get("scene", "")).ends_with("sector_node.tscn"):
				assert_true(
					LevelReachability.can_interact_with(result, entry["cell"]),
					"Nó de %s sem o Root" % level
				)


func _analyze(level: String, abilities: Array[StringName]) -> Dictionary:
	var key: String = "%s|%s" % [level, ",".join(PackedStringArray(abilities))]
	if _cache.has(key):
		return _cache[key]
	var result: Dictionary = LevelReachability.analyze_with_abilities(
		FileAccess.get_file_as_string(LEVELS_DIR + level + ".txt"), _meta(level), abilities
	)
	_cache[key] = result
	return result


func _meta(level: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEVELS_DIR + level + ".json")
	)
	return raw if raw is Dictionary else {}


func _lines(level: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(LEVELS_DIR + level + ".txt").split("\n")


func _cell_of(level: String, item_id: String) -> Vector2i:
	var entities: Dictionary = _meta(level).get("entities", {})
	for key: Variant in entities:
		if String((entities[key] as Dictionary).get("id", "")) == item_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func test_the_ability_profile_knows_the_thruster() -> void:
	var without: Dictionary = LevelReachability.profile_with_abilities([&"magnetic_claws"])
	var with_thruster: Dictionary = LevelReachability.profile_with_abilities([VacuumRules.ABILITY_ID])
	assert_false(bool(without[LevelReachability.PROFILE_DOUBLE_JUMP]), "sem Propulsor")
	assert_true(bool(with_thruster[LevelReachability.PROFILE_DOUBLE_JUMP]), "com Propulsor")
