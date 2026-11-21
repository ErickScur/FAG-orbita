class_name Cx2Armored
extends Cx2

const ARMORED_SHEET: String = "res://assets/sprites/enemies/cx2_armored_sheet.png"
const TOWER_GROUP: StringName = &"argos_tower"


func _ready() -> void:
	super()
	add_to_group(TOWER_GROUP)


func shutdown(duration: float) -> void:
	super.shutdown(minf(duration, Balance.ARGOS_TOWER_STUN_TIME))


func set_sweep_scale(scale: float) -> void:
	_logic.sweep_speed = Balance.CX2_SWEEP_SPEED * maxf(scale, 0.0)


func sweep_speed() -> float:
	return _logic.sweep_speed


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(ARMORED_SHEET)
	if texture == null:
		push_warning("Cx2Armored: sprite sheet ausente em %s" % ARMORED_SHEET)
		return
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	for entry: Dictionary in ANIMATIONS:
		var animation: StringName = entry["name"]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, float(entry["fps"]))
		frames.set_animation_loop(animation, bool(entry["loop"]))
		for column: Variant in entry["columns"] as Array:
			var atlas: AtlasTexture = AssetResolver.atlas(
				ARMORED_SHEET, FRAME_SIZE, int(column), int(entry["row"])
			)
			if atlas != null:
				atlas.filter_clip = true
				frames.add_frame(animation, atlas)
	_sprite.sprite_frames = frames
