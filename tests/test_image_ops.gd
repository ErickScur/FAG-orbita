extends TestCase

const MAGENTA: Color = Color(1.0, 0.0, 1.0, 1.0)
const BLUE: Color = Color(0.0, 0.2, 1.0, 1.0)


func _checker(width: int, height: int) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y: int in range(height):
		for x: int in range(width):
			image.set_pixel(x, y, MAGENTA if (x + y) % 2 == 0 else BLUE)
	return image


func test_chroma_key_clears_only_the_key() -> void:
	var result: Image = ImageOps.chroma_key(_checker(4, 4), MAGENTA, 0.05)
	assert_almost_eq(result.get_pixel(0, 0).a, 0.0, 0.001, "magenta apagado")
	assert_almost_eq(result.get_pixel(1, 0).a, 1.0, 0.001, "azul intacto")
	assert_almost_eq(result.get_pixel(1, 0).b, 1.0, 0.01, "azul preservado")


func test_chroma_key_tolerance_reaches_near_colors() -> void:
	var image := Image.create_empty(2, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(0.92, 0.06, 0.94, 1.0))
	image.set_pixel(1, 0, BLUE)
	var result: Image = ImageOps.chroma_key(image, MAGENTA, 0.18)
	assert_almost_eq(result.get_pixel(0, 0).a, 0.0, 0.001, "quase magenta apagado")
	assert_almost_eq(result.get_pixel(1, 0).a, 1.0, 0.001, "azul intacto")


func test_resize_nearest_keeps_hard_blocks() -> void:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, MAGENTA)
	image.set_pixel(1, 0, BLUE)
	image.set_pixel(0, 1, BLUE)
	image.set_pixel(1, 1, MAGENTA)
	var result: Image = ImageOps.resize_nearest(image, 6, 6)
	assert_eq(result.get_size(), Vector2i(6, 6), "tamanho")
	for y: int in range(3):
		for x: int in range(3):
			assert_eq(result.get_pixel(x, y), MAGENTA, "bloco superior esquerdo")
			assert_eq(result.get_pixel(x + 3, y), BLUE, "bloco superior direito")


func test_slice_splits_the_sheet() -> void:
	var frames: Array[Image] = ImageOps.slice(_checker(64, 32), Vector2i(32, 32))
	assert_eq(frames.size(), 2, "dois frames")
	assert_eq(frames[0].get_size(), Vector2i(32, 32), "tamanho do frame")


func test_slice_rejects_invalid_frame() -> void:
	assert_eq(ImageOps.slice(_checker(8, 8), Vector2i(0, 8)).size(), 0, "frame inválido")


func test_reduce_palette_limits_colors() -> void:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	var index: int = 0
	for y: int in range(8):
		for x: int in range(8):
			var step: float = float(index) / 64.0
			image.set_pixel(x, y, Color(step, 1.0 - step, fmod(step * 3.0, 1.0), 1.0))
			index += 1
	assert_true(ImageOps.count_opaque_colors(image) > 16, "imagem de partida tem muitas cores")
	var reduced: Image = ImageOps.reduce_palette(image, 16)
	assert_true(
		ImageOps.count_opaque_colors(reduced) <= 16,
		"paleta reduzida a %d cores" % ImageOps.count_opaque_colors(reduced)
	)


func test_reduce_palette_ignores_transparent_pixels() -> void:
	var image := Image.create_empty(4, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(0.0, 0.0, 0.0, 0.0))
	image.set_pixel(1, 0, BLUE)
	image.set_pixel(2, 0, MAGENTA)
	image.set_pixel(3, 0, Color(1.0, 1.0, 1.0, 1.0))
	var reduced: Image = ImageOps.reduce_palette(image, 2)
	assert_almost_eq(reduced.get_pixel(0, 0).a, 0.0, 0.001, "transparente continua transparente")
	assert_true(ImageOps.count_opaque_colors(reduced) <= 2, "no máximo duas cores opacas")


func test_crop_returns_region() -> void:
	var result: Image = ImageOps.crop(_checker(8, 8), Rect2i(2, 2, 4, 4))
	assert_eq(result.get_size(), Vector2i(4, 4), "tamanho do recorte")
