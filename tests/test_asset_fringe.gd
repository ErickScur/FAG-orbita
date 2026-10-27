extends TestCase

const ART_DIRS: Array[String] = ["res://assets/sprites/", "res://assets/tiles/", "res://assets/ui/"]
const MAX_FRINGE_PIXELS: int = 16
const MIN_RED: float = 110.0 / 255.0
const MIN_BLUE: float = 110.0 / 255.0
const MIN_GAP: float = 50.0 / 255.0


func test_final_art_has_no_magenta_cutout_fringe() -> void:
	var files: Array[String] = []
	for directory: String in ART_DIRS:
		_collect_pngs(directory, files)
	assert_true(files.size() > 10, "nenhuma arte final encontrada")
	for path: String in files:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null:
			fail("não abriu %s" % path)
			continue
		var count: int = _fringe_pixels(image)
		assert_true(
			count <= MAX_FRINGE_PIXELS,
			"%s tem %d px de franja magenta semitransparente (sobra do fundo de recorte)" % [
				path, count
			]
		)


func _collect_pngs(directory: String, files: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(directory):
		if file.ends_with(".png"):
			files.append(directory + file)
	for child: String in DirAccess.get_directories_at(directory):
		_collect_pngs(directory + child + "/", files)


func _fringe_pixels(image: Image) -> int:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var count: int = 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a <= 0.0 or pixel.a >= 1.0:
				continue
			if pixel.r < MIN_RED or pixel.b < MIN_BLUE:
				continue
			if pixel.r - pixel.g > MIN_GAP and pixel.b - pixel.g > MIN_GAP:
				count += 1
	return count
