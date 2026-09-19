extends SceneTree

const USAGE: String = """uso: Godot --headless --path . -s res://tools/process_image.gd -- \\
  --in=<arquivo de entrada> --out=res://assets/... \\
  [--crop=x,y,w,h] [--key=FF00FF] [--tolerance=0.18] \\
  [--frame=32x32] [--grid=6x10] [--colors=16 | --palette=16] [--slice]"""
const DEFAULT_KEY: String = "FF00FF"
const DEFAULT_TOLERANCE: float = 0.18


func _initialize() -> void:
	var options: Dictionary = _parse_arguments(OS.get_cmdline_user_args())
	var input: String = String(options.get("in", ""))
	var output: String = String(options.get("out", ""))
	if input.is_empty() or output.is_empty():
		print(USAGE)
		quit(2)
		return
	var absolute_input: String = _absolute(input)
	if not FileAccess.file_exists(absolute_input):
		print("entrada inexistente: %s" % absolute_input)
		quit(2)
		return
	var image: Image = Image.load_from_file(absolute_input)
	if image == null:
		print("não foi possível carregar a imagem: %s" % absolute_input)
		quit(2)
		return
	image = ImageOps.to_rgba8(image)
	if options.has("crop"):
		var rect: Rect2i = _parse_rect(String(options["crop"]))
		if rect.size.x <= 0 or rect.size.y <= 0:
			print(USAGE)
			quit(2)
			return
		image = ImageOps.crop(image, rect)
	var key_text: String = String(options.get("key", DEFAULT_KEY))
	if key_text != "none":
		var tolerance: float = float(options.get("tolerance", DEFAULT_TOLERANCE))
		image = ImageOps.chroma_key(image, Color(_hex(key_text)), tolerance)
	var frame: Vector2i = _parse_size(String(options.get("frame", "")))
	var grid: Vector2i = _parse_size(String(options.get("grid", "1x1")))
	if frame.x > 0 and frame.y > 0:
		if grid.x <= 0 or grid.y <= 0:
			print(USAGE)
			quit(2)
			return
		image = ImageOps.resize_nearest(image, frame.x * grid.x, frame.y * grid.y)
	var colors: int = int(options.get("colors", options.get("palette", 0)))
	if colors > 0:
		image = ImageOps.reduce_palette(image, colors)
	var absolute_output: String = _absolute(output)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	if image.save_png(absolute_output) != OK:
		print("falha ao gravar %s" % absolute_output)
		quit(2)
		return
	var written: int = 1
	if options.has("slice") and frame.x > 0 and frame.y > 0:
		written += _write_slices(image, frame, absolute_output)
	print(
		"OK %s %dx%d cores=%d arquivos=%d"
		% [
			output,
			image.get_width(),
			image.get_height(),
			ImageOps.count_opaque_colors(image),
			written
		]
	)
	quit(0)


func _write_slices(image: Image, frame: Vector2i, absolute_output: String) -> int:
	var columns: int = image.get_width() / frame.x
	var frames: Array[Image] = ImageOps.slice(image, frame)
	var base: String = absolute_output.get_basename()
	var written: int = 0
	for index: int in range(frames.size()):
		var row: int = index / maxi(columns, 1)
		var column: int = index % maxi(columns, 1)
		if frames[index].save_png("%s_%d_%d.png" % [base, row, column]) == OK:
			written += 1
	return written


func _parse_arguments(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	for argument: String in arguments:
		if not argument.begins_with("--"):
			continue
		var body: String = argument.substr(2)
		var separator: int = body.find("=")
		if separator < 0:
			options[body] = true
			continue
		options[body.substr(0, separator)] = body.substr(separator + 1)
	return options


func _absolute(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	if path.begins_with("~/"):
		return OS.get_environment("HOME").path_join(path.substr(2))
	return path


func _hex(text: String) -> String:
	var clean: String = text.strip_edges().trim_prefix("#")
	return "#" + clean


func _parse_size(text: String) -> Vector2i:
	var parts: PackedStringArray = text.to_lower().split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _parse_rect(text: String) -> Rect2i:
	var parts: PackedStringArray = text.split(",")
	if parts.size() != 4:
		return Rect2i()
	return Rect2i(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]))
