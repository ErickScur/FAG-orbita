class_name AssetResolver
extends RefCounted

const ASSETS_ROOT: String = "res://assets/"
const PLACEHOLDER_ROOT: String = "res://assets/placeholder/"
const AUDIO_EXTENSIONS: PackedStringArray = [".ogg", ".wav", ".mp3"]


static func placeholder_path(final_path: String) -> String:
	if final_path.begins_with(PLACEHOLDER_ROOT):
		return final_path
	if not final_path.begins_with(ASSETS_ROOT):
		return final_path
	return PLACEHOLDER_ROOT + final_path.substr(ASSETS_ROOT.length())


static func resolve(final_path: String) -> String:
	if ResourceLoader.exists(final_path):
		return final_path
	var fallback: String = placeholder_path(final_path)
	if fallback != final_path and ResourceLoader.exists(fallback):
		return fallback
	return ""


static func resolve_audio(final_path: String) -> String:
	var candidates: PackedStringArray = _audio_candidates(final_path)
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


static func has(final_path: String) -> bool:
	return not resolve(final_path).is_empty()


static func is_placeholder(final_path: String) -> bool:
	var resolved: String = resolve(final_path)
	return not resolved.is_empty() and resolved.begins_with(PLACEHOLDER_ROOT)


static func texture(final_path: String) -> Texture2D:
	var resolved: String = resolve(final_path)
	if resolved.is_empty():
		return null
	var resource: Resource = load(resolved)
	if resource is Texture2D:
		return resource
	return null


static func atlas(final_path: String, frame: Vector2i, column: int, row: int) -> AtlasTexture:
	var source: Texture2D = texture(final_path)
	if source == null or frame.x <= 0 or frame.y <= 0:
		return null
	var region := Rect2(Vector2(column * frame.x, row * frame.y), Vector2(frame))
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = region
	result.filter_clip = true
	return result


static func audio(final_path: String) -> AudioStream:
	var resolved: String = resolve_audio(final_path)
	if resolved.is_empty():
		return null
	var resource: Resource = load(resolved)
	if resource is AudioStream:
		return resource
	return null


static func _audio_candidates(final_path: String) -> PackedStringArray:
	var candidates: PackedStringArray = [final_path]
	var base: String = final_path.get_basename()
	for extension: String in AUDIO_EXTENSIONS:
		var variant: String = base + extension
		if not candidates.has(variant):
			candidates.append(variant)
	var fallback_base: String = placeholder_path(base)
	if fallback_base != base:
		for extension: String in AUDIO_EXTENSIONS:
			var variant: String = fallback_base + extension
			if not candidates.has(variant):
				candidates.append(variant)
	return candidates
