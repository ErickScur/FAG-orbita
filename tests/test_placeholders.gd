extends TestCase

const MANIFEST_PATH: String = "res://tools/placeholders.json"
const ASSETS_ROOT: String = "res://assets/"
const PLACEHOLDER_ROOT: String = "res://assets/placeholder/"


func _manifest() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed is Dictionary:
		return parsed
	return {}


func _entries() -> Array:
	return _manifest().get("images", [])


func _target(entry: Dictionary) -> String:
	var relative: String = String(entry.get("path", ""))
	if bool(entry.get("final", false)):
		return ASSETS_ROOT + relative
	return PLACEHOLDER_ROOT + relative


func test_manifest_is_readable() -> void:
	assert_true(FileAccess.file_exists(MANIFEST_PATH), "manifesto existe")
	assert_true(_entries().size() >= 20, "pelo menos 20 imagens no manifesto")


func test_every_entry_exists_with_the_contract_size() -> void:
	for value: Variant in _entries():
		var entry: Dictionary = value
		var id: String = String(entry.get("id", "?"))
		var path: String = _target(entry)
		var absolute: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(absolute):
			fail("%s: arquivo ausente em %s" % [id, path])
			continue
		var image: Image = Image.load_from_file(absolute)
		if image == null:
			fail("%s: PNG ilegível" % id)
			continue
		var frame: Array = entry.get("frame", [0, 0])
		var grid: Array = entry.get("grid", [1, 1])
		var expected := Vector2i(int(frame[0]) * int(grid[0]), int(frame[1]) * int(grid[1]))
		assert_eq(image.get_size(), expected, "%s: dimensão do contrato" % id)


func test_every_entry_is_reachable_by_the_resolver() -> void:
	for value: Variant in _entries():
		var entry: Dictionary = value
		var final_path: String = ASSETS_ROOT + String(entry.get("path", ""))
		assert_true(AssetResolver.has(final_path), "%s resolvido" % String(entry.get("id", "?")))


func test_sprite_sheets_have_transparency() -> void:
	var sheet: String = ProjectSettings.globalize_path(
		PLACEHOLDER_ROOT + "sprites/mu7/mu7_sheet.png"
	)
	var image: Image = Image.load_from_file(sheet)
	assert_not_null(image, "sheet do MU-7")
	assert_almost_eq(image.get_pixel(0, 0).a, 0.0, 0.001, "canto transparente")


func test_generated_light_goes_to_the_final_path() -> void:
	for value: Variant in _entries():
		var entry: Dictionary = value
		if not bool(entry.get("final", false)):
			continue
		var path: String = _target(entry)
		assert_true(path.begins_with(ASSETS_ROOT), "%s no caminho final" % String(entry["id"]))
		assert_false(path.begins_with(PLACEHOLDER_ROOT), "%s fora do espelho" % String(entry["id"]))
