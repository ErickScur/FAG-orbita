extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const SR3_SCENE: String = "res://scenes/enemies/sr3.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const SPAWN: Vector2 = Vector2(240, 160)
const FLOOR: Rect2 = Rect2(0, 160, 320, 56)
const PIT_FLOOR: Rect2 = Rect2(320, 200, 64, 16)
const WALL_STUB: Rect2 = Rect2(96, 136, 8, 24)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(384, -64, 16, 280)
const SR3_SPAWN: Vector2 = Vector2(160, 160)
const SHUTDOWN_FRAME: int = 260

var _sr3: Sr3 = null
var _status: Label = null
var _frame: int = 0


func _ready() -> void:
	add_to_group(&"level")
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(PIT_FLOOR)
	add_solid(WALL_STUB)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	Settings.difficulty = &"normal"
	GameState.new_game()
	_spawn_sr3()
	spawn_player(SPAWN)
	_mount_hud()
	_status = add_label(Control.PRESET_CENTER_TOP, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == SHUTDOWN_FRAME and _sr3 != null:
		_sr3.shutdown(Balance.BEAM_SHUTDOWN_TIME)
	if _status == null:
		return
	_status.text = "INTEGRIDADE %d/%d\nSR3 %s  X %d  DIR %d\n%s\nMU7 X %d" % [
		GameState.integrity,
		GameState.integrity_max,
		"DESLIGADA" if _sr3 != null and _sr3.is_shut_down() else "PATRULHANDO",
		roundi(_sr3.global_position.x) if _sr3 != null else 0,
		_sr3.dir if _sr3 != null else 0,
		_animation_status(),
		roundi(player.global_position.x) if player != null else 0,
	]


func _animation_status() -> String:
	if _sr3 == null:
		return "SEM SR3"
	var sprite: AnimatedSprite2D = _sr3.get_node_or_null("AnimatedSprite2D")
	if sprite == null or sprite.sprite_frames == null:
		return "SEM FOLHA"
	return "%s Q%d TOCA %s" % [
		String(sprite.animation), sprite.frame, "SIM" if sprite.is_playing() else "NAO"
	]


func spawn_position() -> Vector2:
	return SPAWN


func _spawn_sr3() -> void:
	if not ResourceLoader.exists(SR3_SCENE):
		push_warning("enemy_sandbox: SR-3 ausente")
		return
	var instance: Node = load(SR3_SCENE).instantiate()
	if not (instance is Sr3):
		instance.free()
		return
	_sr3 = instance
	_sr3.dir = -1
	_sr3.position = SR3_SPAWN
	add_child(_sr3)


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("enemy_sandbox: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
