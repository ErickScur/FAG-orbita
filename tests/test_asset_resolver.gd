extends TestCase

const MU7: String = "res://assets/sprites/mu7/mu7_sheet.png"
const CORE_TILES: String = "res://assets/tiles/core_tiles.png"
const LOGO: String = "res://assets/ui/logo.png"
const LIGHT: String = "res://assets/fx/light_radial.png"
const PENDING_SFX: String = "res://assets/audio/sfx/steam_hiss.ogg"
const NEVER: String = "res://assets/sprites/_sem_arte/fixture.png"


func test_placeholder_path_mirrors_the_final_path() -> void:
	assert_eq(
		AssetResolver.placeholder_path(MU7),
		"res://assets/placeholder/sprites/mu7/mu7_sheet.png",
		"espelho"
	)


func test_placeholder_path_is_stable_for_placeholders() -> void:
	var mirrored: String = AssetResolver.placeholder_path(MU7)
	assert_eq(AssetResolver.placeholder_path(mirrored), mirrored, "idempotente")


func test_placeholder_path_ignores_paths_outside_assets() -> void:
	assert_eq(
		AssetResolver.placeholder_path("res://scenes/boot/splash.tscn"),
		"res://scenes/boot/splash.tscn",
		"fora de assets"
	)


func test_texture_follows_the_contract_with_or_without_final_art() -> void:
	var texture: Texture2D = AssetResolver.texture(MU7)
	assert_not_null(texture, "textura do MU-7")
	assert_eq(texture.get_size(), Vector2(192, 320), "contrato 6x10 de 32x32")


func test_mirror_of_a_delivered_asset_still_resolves_as_placeholder() -> void:
	var mirror: String = AssetResolver.placeholder_path(MU7)
	assert_true(AssetResolver.has(mirror), "o espelho do MU-7 existe")
	assert_true(AssetResolver.is_placeholder(mirror), "o espelho resolve como placeholder")
	assert_false(
		AssetResolver.is_placeholder(MU7),
		"asset com arte final entregue resolve para o caminho definitivo"
	)


func test_asset_without_final_and_without_mirror_does_not_resolve() -> void:
	assert_eq(
		AssetResolver.placeholder_path(NEVER),
		"res://assets/placeholder/sprites/_sem_arte/fixture.png",
		"espelho calculado mesmo sem arquivo nenhum"
	)
	assert_false(AssetResolver.has(NEVER), "sem definitivo e sem espelho não resolve")
	assert_false(AssetResolver.is_placeholder(NEVER), "nada a resolver não é placeholder")
	assert_null(AssetResolver.texture(NEVER), "textura inexistente é nula")


func test_tiles_follow_the_contract() -> void:
	var texture: Texture2D = AssetResolver.texture(CORE_TILES)
	assert_not_null(texture, "tileset do Núcleo")
	assert_eq(texture.get_size(), Vector2(128, 64), "atlas 8x4 de 16x16")


func test_logo_follows_the_contract() -> void:
	var texture: Texture2D = AssetResolver.texture(LOGO)
	assert_not_null(texture, "logo")
	assert_eq(texture.get_size(), Vector2(192, 48), "192x48")


func test_generated_light_is_not_a_placeholder() -> void:
	assert_true(AssetResolver.has(LIGHT), "luz radial existe")
	assert_false(AssetResolver.is_placeholder(LIGHT), "luz radial é definitiva")


func test_atlas_returns_one_frame() -> void:
	var frame: AtlasTexture = AssetResolver.atlas(MU7, Vector2i(32, 32), 2, 1)
	assert_not_null(frame, "frame do sheet")
	assert_eq(frame.region, Rect2(64.0, 32.0, 32.0, 32.0), "região do frame")


func test_missing_asset_returns_null() -> void:
	assert_null(AssetResolver.texture("res://assets/sprites/nao_existe.png"), "inexistente")
	assert_false(AssetResolver.has("res://assets/sprites/nao_existe.png"), "has é falso")


func test_audio_falls_back_to_placeholder_wav() -> void:
	var stream: AudioStream = AssetResolver.audio(PENDING_SFX)
	assert_not_null(stream, "efeito ainda sem som definitivo")
	assert_true(stream.get_length() > 0.0, "áudio audível")
	assert_eq(
		AssetResolver.resolve_audio(PENDING_SFX),
		"res://assets/placeholder/audio/sfx/steam_hiss.wav",
		"caminho do placeholder"
	)
