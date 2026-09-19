class_name SparkBurst
extends CPUParticles2D

const DEFAULT_TINT: Color = Color(0.372549, 0.831373, 0.784314, 1.0)

var _free_on_finish: bool = false


func _ready() -> void:
	finished.connect(_on_finished)


func emit(at: Vector2, tint: Color = DEFAULT_TINT, free_on_finish: bool = true) -> void:
	global_position = at
	color = tint
	_free_on_finish = free_on_finish
	restart()
	emitting = true


func _on_finished() -> void:
	emitting = false
	if _free_on_finish:
		queue_free()
