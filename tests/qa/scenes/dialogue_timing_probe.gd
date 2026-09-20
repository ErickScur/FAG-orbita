extends Node2D

const BACKGROUND_COLOR: Color = Color("#10161c")
const FLOOR_COLOR: Color = Color("#2f4f5a")
const ROOM: Vector2 = Vector2(384, 216)
const FLOOR_TOP: float = 168.0
const START_FRAME: int = 30
const SEQUENCE: StringName = &"gh_claws"

var _frame: int = 0
var _appeared_at: int = -1
var _reported: bool = false


func _ready() -> void:
	add_to_group(&"level")
	add_to_group(&"gameplay")
	_build_background()
	GameState.new_game()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == START_FRAME:
		DialogueManager.play(SEQUENCE)
		return
	if _frame < START_FRAME:
		return
	if DialogueManager.is_active():
		if _appeared_at < 0:
			_appeared_at = _frame
		return
	if _appeared_at < 0 or _reported:
		return
	_reported = true
	var frames: int = _frame - _appeared_at
	var lines: Array = (DialogueManager.sequences()[SEQUENCE] as Dictionary).get("lines", [])
	var text: String = String((lines[0] as Dictionary).get("text", ""))
	print(
		"[F39] %s %d caracteres · visível de %d a %d = %d quadros (%.2f s a 60 fps)"
		% [SEQUENCE, text.length(), _appeared_at, _frame, frames, float(frames) / 60.0]
	)


func _build_background() -> void:
	var background := ColorRect.new()
	background.size = ROOM
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)
	var floor_rect := ColorRect.new()
	floor_rect.position = Vector2(0.0, FLOOR_TOP)
	floor_rect.size = Vector2(ROOM.x, ROOM.y - FLOOR_TOP)
	floor_rect.color = FLOOR_COLOR
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_rect.z_index = -9
	add_child(floor_rect)
