extends TestCase

const SHEET_PATH: String = "res://assets/sprites/mu7/mu7_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)


func test_sheet_resolves_to_placeholder() -> void:
	assert_true(AssetResolver.has(SHEET_PATH), "folha do MU-7 disponível")


func test_sheet_matches_contract() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	assert_not_null(texture, "textura carregada")
	if texture == null:
		return
	assert_eq(texture.get_width(), FRAME_SIZE.x * 6, "6 colunas")
	assert_eq(texture.get_height(), FRAME_SIZE.y * 10, "10 linhas")


func test_build_frames_registers_every_animation() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		fail("textura ausente")
		return
	var rows: Array[Dictionary] = Mu7.ANIMATION_ROWS
	var frames: SpriteFrames = SpriteSheet.build_frames(texture, FRAME_SIZE, rows)
	assert_false(frames.has_animation(&"default"), "sem animação padrão")
	for entry: Dictionary in rows:
		var animation := StringName(String(entry.get("name", "")))
		assert_true(frames.has_animation(animation), "animação %s" % animation)
		if not frames.has_animation(animation):
			continue
		assert_eq(frames.get_frame_count(animation), int(entry.get("frames", 0)), String(animation))
		assert_eq(frames.get_animation_loop(animation), bool(entry.get("loop", true)), String(animation))


func test_build_frames_regions_follow_the_grid() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		fail("textura ausente")
		return
	var rows: Array[Dictionary] = [
		{"name": &"walk", "row": 1, "frames": 6, "fps": 10.0, "loop": true},
	]
	var frames: SpriteFrames = SpriteSheet.build_frames(texture, FRAME_SIZE, rows)
	var first: Texture2D = frames.get_frame_texture(&"walk", 0)
	var last: Texture2D = frames.get_frame_texture(&"walk", 5)
	assert_true(first is AtlasTexture, "frame é AtlasTexture")
	if first is AtlasTexture:
		assert_eq((first as AtlasTexture).region, Rect2(0, 32, 32, 32), "primeiro frame")
	if last is AtlasTexture:
		assert_eq((last as AtlasTexture).region, Rect2(160, 32, 32, 32), "último frame")


func test_build_frames_without_texture_is_safe() -> void:
	var frames: SpriteFrames = SpriteSheet.build_frames(null, FRAME_SIZE, [])
	assert_not_null(frames, "recurso criado")
	assert_eq(frames.get_animation_names().size(), 0, "sem animações")
