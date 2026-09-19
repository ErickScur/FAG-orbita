class_name ImageOps
extends RefCounted

const FORMAT: int = Image.FORMAT_RGBA8
const QUANTIZE_BITS: int = 3
const TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)


static func to_rgba8(source: Image) -> Image:
	var copy: Image = source.duplicate()
	if copy.get_format() != FORMAT:
		copy.convert(FORMAT)
	return copy


static func chroma_key(source: Image, key: Color, tolerance: float) -> Image:
	var result: Image = to_rgba8(source)
	for y: int in range(result.get_height()):
		for x: int in range(result.get_width()):
			var pixel: Color = result.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var distance: float = maxf(
				maxf(absf(pixel.r - key.r), absf(pixel.g - key.g)), absf(pixel.b - key.b)
			)
			if distance <= tolerance:
				result.set_pixel(x, y, TRANSPARENT)
	return result


static func resize_nearest(source: Image, width: int, height: int) -> Image:
	var result: Image = to_rgba8(source)
	if width <= 0 or height <= 0:
		return result
	result.resize(width, height, Image.INTERPOLATE_NEAREST)
	return result


static func crop(source: Image, rect: Rect2i) -> Image:
	var result: Image = to_rgba8(source)
	var clamped := rect.intersection(Rect2i(Vector2i.ZERO, result.get_size()))
	if clamped.size.x <= 0 or clamped.size.y <= 0:
		return result
	return result.get_region(clamped)


static func reduce_palette(source: Image, max_colors: int) -> Image:
	var result: Image = to_rgba8(source)
	if max_colors <= 0:
		return result
	var counts: Dictionary = {}
	for y: int in range(result.get_height()):
		for x: int in range(result.get_width()):
			var pixel: Color = result.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var key: int = _quantize_key(pixel)
			counts[key] = int(counts.get(key, 0)) + 1
	if counts.size() <= max_colors:
		return result
	var keys: Array = counts.keys()
	keys.sort_custom(
		func(a: int, b: int) -> bool:
			var count_a: int = int(counts[a])
			var count_b: int = int(counts[b])
			if count_a == count_b:
				return a < b
			return count_a > count_b
	)
	var kept: Array[Vector3i] = []
	for index: int in range(mini(max_colors, keys.size())):
		kept.append(_key_to_rgb(int(keys[index])))
	var cache: Dictionary = {}
	for y: int in range(result.get_height()):
		for x: int in range(result.get_width()):
			var pixel: Color = result.get_pixel(x, y)
			if pixel.a <= 0.0:
				result.set_pixel(x, y, TRANSPARENT)
				continue
			var key: int = _quantize_key(pixel)
			if not cache.has(key):
				cache[key] = _nearest(_key_to_rgb(key), kept)
			var rgb: Vector3i = cache[key]
			result.set_pixel(
				x,
				y,
				Color(
					float(rgb.x) / 255.0, float(rgb.y) / 255.0, float(rgb.z) / 255.0, pixel.a
				)
			)
	return result


static func slice(source: Image, frame: Vector2i) -> Array[Image]:
	var frames: Array[Image] = []
	if frame.x <= 0 or frame.y <= 0:
		return frames
	var base: Image = to_rgba8(source)
	var columns: int = base.get_width() / frame.x
	var rows: int = base.get_height() / frame.y
	for row: int in range(rows):
		for column: int in range(columns):
			frames.append(base.get_region(Rect2i(Vector2i(column * frame.x, row * frame.y), frame)))
	return frames


static func count_opaque_colors(source: Image) -> int:
	var base: Image = to_rgba8(source)
	var seen: Dictionary = {}
	for y: int in range(base.get_height()):
		for x: int in range(base.get_width()):
			var pixel: Color = base.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			seen[_rgb_key(pixel)] = true
	return seen.size()


static func _quantize_key(pixel: Color) -> int:
	var red: int = int(pixel.r * 255.0) >> QUANTIZE_BITS
	var green: int = int(pixel.g * 255.0) >> QUANTIZE_BITS
	var blue: int = int(pixel.b * 255.0) >> QUANTIZE_BITS
	return (red << 16) | (green << 8) | blue


static func _key_to_rgb(key: int) -> Vector3i:
	var red: int = (key >> 16) & 0xFF
	var green: int = (key >> 8) & 0xFF
	var blue: int = key & 0xFF
	var step: int = 1 << QUANTIZE_BITS
	var half: int = step / 2
	return Vector3i(
		mini(255, red * step + half), mini(255, green * step + half), mini(255, blue * step + half)
	)


static func _rgb_key(pixel: Color) -> int:
	return (int(pixel.r * 255.0) << 16) | (int(pixel.g * 255.0) << 8) | int(pixel.b * 255.0)


static func _nearest(target: Vector3i, options: Array[Vector3i]) -> Vector3i:
	var best: Vector3i = target
	var best_distance: int = -1
	for option: Vector3i in options:
		var dr: int = option.x - target.x
		var dg: int = option.y - target.y
		var db: int = option.z - target.z
		var distance: int = dr * dr + dg * dg + db * db
		if best_distance < 0 or distance < best_distance:
			best_distance = distance
			best = option
	return best
