extends SceneTree

const DEFAULT_SCALE: int = 6
const BACKDROP: Color = Color("1b2430")


func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var source: String = _arg(arguments, "--in", "")
	var target: String = _arg(arguments, "--out", "")
	var scale: int = maxi(1, int(_arg(arguments, "--scale", str(DEFAULT_SCALE))))
	if source.is_empty() or target.is_empty():
		print("uso: -s res://tools/preview_sheet.gd -- --in=<png> --out=<png> [--scale=6]")
		quit(64)
		return
	var image: Image = Image.load_from_file(source)
	if image == null or image.is_empty():
		print("ERRO imagem ilegível: %s" % source)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var canvas: Image = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	canvas.fill(BACKDROP)
	canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	var error: int = canvas.save_png(target)
	if error != OK:
		print("ERRO ao salvar %s (%d)" % [target, error])
		quit(1)
		return
	print("OK %s (%dx%d, %dx)" % [target, canvas.get_width(), canvas.get_height(), scale])
	quit(0)


func _arg(arguments: PackedStringArray, name: String, fallback: String) -> String:
	var prefix: String = name + "="
	for argument: String in arguments:
		if argument.begins_with(prefix):
			return argument.substr(prefix.length())
	return fallback
