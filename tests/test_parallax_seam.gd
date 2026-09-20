extends TestCase

const LAYERS: PackedStringArray = [
	"res://assets/backgrounds/space_far.png",
	"res://assets/backgrounds/space_mid.png",
	"res://assets/backgrounds/space_near.png",
]
const LAYER_SIZE: Vector2i = Vector2i(1152, 216)
const SEAM_LAYERS: PackedStringArray = [
	"res://assets/backgrounds/space_far.png",
	"res://assets/backgrounds/space_mid.png",
]
const SEAM_TOLERANCE: float = 2.5
const SAMPLE_COLUMNS: int = 24


func test_layers_share_the_contract_size() -> void:
	for path: String in LAYERS:
		var image: Image = _image(path)
		assert_not_null(image, "camada %s" % path)
		assert_eq(image.get_size(), LAYER_SIZE, "contrato de %s" % path)


func test_layers_repeat_without_a_visible_seam() -> void:
	for path: String in SEAM_LAYERS:
		var image: Image = _image(path)
		if image == null:
			continue
		var seam: float = _column_distance(image, image.get_width() - 1, 0)
		var typical: float = _typical_distance(image)
		assert_true(
			seam <= typical * SEAM_TOLERANCE,
			"%s: emenda %.2f contra vizinhança típica %.2f" % [path, seam, typical]
		)


func test_only_the_far_layer_is_opaque() -> void:
	var far: Image = _image(LAYERS[0])
	var mid: Image = _image(LAYERS[1])
	var near: Image = _image(LAYERS[2])
	assert_true(_transparent_ratio(far) < 0.02, "o campo de estrelas é a camada de fundo")
	assert_true(_transparent_ratio(mid) > 0.05, "a nebulosa deixa as estrelas aparecerem")
	assert_true(_transparent_ratio(near) > 0.40, "a estrutura é silhueta sobre o vazio")


func _image(path: String) -> Image:
	var texture: Texture2D = AssetResolver.texture(path)
	if texture == null:
		return null
	return texture.get_image()


func _column_distance(image: Image, left: int, right: int) -> float:
	var total: float = 0.0
	var height: int = image.get_height()
	for y: int in range(height):
		var a: Color = image.get_pixel(left, y)
		var b: Color = image.get_pixel(right, y)
		total += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)
	return total / float(height)


func _typical_distance(image: Image) -> float:
	var width: int = image.get_width()
	var total: float = 0.0
	for index: int in range(SAMPLE_COLUMNS):
		var x: int = int(float(index + 1) * float(width) / float(SAMPLE_COLUMNS + 1))
		total += _column_distance(image, x, x + 1)
	return total / float(SAMPLE_COLUMNS)


func _transparent_ratio(image: Image) -> float:
	if image == null:
		return 0.0
	var clear: int = 0
	var total: int = 0
	for y: int in range(0, image.get_height(), 3):
		for x: int in range(0, image.get_width(), 3):
			total += 1
			if image.get_pixel(x, y).a < 0.5:
				clear += 1
	return float(clear) / float(maxi(total, 1))
