class_name Vignette
extends CanvasLayer

const PARAM_STRENGTH: StringName = &"strength"
const PARAM_INNER: StringName = &"inner"
const PARAM_OUTER: StringName = &"outer"
const PARAM_ASPECT: StringName = &"aspect"
const PARAM_COLOR: StringName = &"edge_color"

@onready var _shade: ColorRect = $Shade


func _ready() -> void:
	apply(Balance.VIGNETTE_COLOR, Balance.VIGNETTE_STRENGTH)


func apply(edge_color: Color, strength: float) -> void:
	var material: ShaderMaterial = _shade.material as ShaderMaterial
	if material == null:
		push_warning("Vignette: material de shader ausente")
		return
	material.set_shader_parameter(PARAM_COLOR, edge_color)
	material.set_shader_parameter(PARAM_STRENGTH, strength)
	material.set_shader_parameter(PARAM_INNER, Balance.VIGNETTE_INNER)
	material.set_shader_parameter(PARAM_OUTER, Balance.VIGNETTE_OUTER)
	material.set_shader_parameter(PARAM_ASPECT, _aspect())


func _aspect() -> float:
	var size: Vector2 = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 384),
		ProjectSettings.get_setting("display/window/size/viewport_height", 216)
	)
	if size.y <= 0.0:
		return 1.0
	return size.x / size.y
