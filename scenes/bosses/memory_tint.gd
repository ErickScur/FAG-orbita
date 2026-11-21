class_name MemoryTint
extends CanvasLayer

const SHADER_PATH: String = "res://scenes/fx/memory_desaturate.gdshader"
const PARAM_AMOUNT: StringName = &"amount"
const SCREEN_SIZE: Vector2 = Vector2(384, 216)
const LAYER: int = UiLayers.MEMORY_TINT

var amount: float = 0.0

var _rect: ColorRect = null
var _material: ShaderMaterial = null
var _tween: Tween = null


func _ready() -> void:
	layer = LAYER
	_rect = ColorRect.new()
	_rect.name = "Desaturate"
	_rect.position = Vector2.ZERO
	_rect.size = SCREEN_SIZE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader != null:
		_material = ShaderMaterial.new()
		_material.shader = shader
		_rect.material = _material
	add_child(_rect)
	_apply(amount)


func set_amount(value: float, instant: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if instant or not is_inside_tree():
		_apply(value)
		return
	_tween = create_tween()
	_tween.tween_method(_apply, amount, value, Balance.MEMORY_COLOR_FADE_TIME)


func _apply(value: float) -> void:
	amount = clampf(value, 0.0, 1.0)
	if _material != null:
		_material.set_shader_parameter(PARAM_AMOUNT, amount)
	if _rect != null:
		_rect.visible = amount > 0.001 and _material != null
