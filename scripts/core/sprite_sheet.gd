class_name SpriteSheet
extends RefCounted


static func build_frames(
	texture: Texture2D, frame_size: Vector2i, rows: Array[Dictionary]
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	if texture == null or frame_size.x <= 0 or frame_size.y <= 0:
		return frames
	var columns: int = int(texture.get_width() / frame_size.x)
	var lines: int = int(texture.get_height() / frame_size.y)
	for entry: Dictionary in rows:
		var animation := StringName(String(entry.get("name", "")))
		if String(animation).is_empty():
			continue
		var row: int = int(entry.get("row", 0))
		if row < 0 or row >= lines:
			continue
		var count: int = clampi(int(entry.get("frames", 1)), 1, columns)
		frames.add_animation(animation)
		frames.set_animation_speed(animation, float(entry.get("fps", 8.0)))
		frames.set_animation_loop(animation, bool(entry.get("loop", true)))
		for column: int in range(count):
			frames.add_frame(animation, _atlas(texture, frame_size, column, row))
	return frames


static func _atlas(texture: Texture2D, frame_size: Vector2i, column: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(
		Vector2(column * frame_size.x, row * frame_size.y), Vector2(frame_size)
	)
	atlas.filter_clip = true
	return atlas
