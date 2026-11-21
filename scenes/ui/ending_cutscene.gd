class_name EndingCutscene
extends Node2D

const SHEET_PATH: String = "res://assets/sprites/fx/ending_space_sheet.png"
const STARS_PATH: String = "res://assets/backgrounds/space_far.png"
const FRAME_SIZE: Vector2i = Vector2i(64, 64)
const CELL_STATION_LIT: Vector2i = Vector2i(0, 0)
const CELL_STATION_DARK: Vector2i = Vector2i(1, 0)
const CELL_CAPSULE_FLAME: Vector2i = Vector2i(2, 0)
const CELL_PLANET: Vector2i = Vector2i(0, 1)
const CELL_EARTH: Vector2i = Vector2i(1, 1)
const CELL_FLARE: Vector2i = Vector2i(2, 1)
const CELL_RING: Vector2i = Vector2i(3, 1)
const SCREEN_SIZE: Vector2 = Vector2(384, 216)
const LETTERBOX_HEIGHT: float = 20.0
const STATION_SCALE: float = 2.0
const DISH_OFFSET: Vector2 = Vector2(-34, -30)
const DOCK_OFFSET: Vector2 = Vector2(18, 20)
const DRIFT: Vector2 = Vector2(-14, -2)
const STARS_DRIFT: Vector2 = Vector2(-5, 0)
const CAPSULE_END_SCALE: float = 0.4
const RING_TRAVEL_TIME: float = 6.0
const FLICKER_TIME: float = 0.18
const LAYOUTS: Dictionary = {
	&"seeding": {
		"station": Vector2(104, 108),
		"planet": Vector2(330, 112),
		"planet_scale": 2.0,
		"earth": Vector2(-100, -100),
	},
	&"transmission": {
		"station": Vector2(96, 112),
		"planet": Vector2(318, 178),
		"planet_scale": 1.5,
		"earth": Vector2(338, 52),
	},
}
const CAPTION_COLOR: Color = Color(0.541176, 0.607843, 0.658824)
const HINT_COLOR: Color = Color(0.372549, 0.831373, 0.784314)

var ending_id: StringName = EndingData.SEEDING

var _events: Array[Dictionary] = []
var _next_event: int = 0
var _elapsed: float = 0.0
var _length: float = 0.0
var _cut: bool = false
var _lights_total: int = 0
var _lights_done: int = 0
var _armed: bool = false
var _hold: float = 0.0
var _layout: Dictionary = {}
var _world: Node2D = null
var _stars: Sprite2D = null
var _station_dark: Sprite2D = null
var _station_lit: Sprite2D = null
var _planet: Sprite2D = null
var _earth: Sprite2D = null
var _capsule: Sprite2D = null
var _flare: Sprite2D = null
var _black: ColorRect = null
var _caption: Label = null
var _hint: Label = null
var _hint_bar: ColorRect = null


func _ready() -> void:
	get_tree().paused = false
	var table: Dictionary = EndingData.load_table()
	ending_id = EndingData.chosen_or_default(GameState.flags)
	_layout = LAYOUTS.get(ending_id, LAYOUTS[EndingData.SEEDING])
	_events = EndingData.cutscene_events(table, ending_id)
	_length = EndingData.cutscene_length(_events)
	_lights_total = EndingData.count_action(_events, "lights_step")
	AudioManager.stop_all()
	_build_world()
	_build_overlay(table)
	_start_drift()


func _process(delta: float) -> void:
	if _cut:
		return
	_elapsed += delta
	while _next_event < _events.size():
		var event: Dictionary = _events[_next_event]
		if float(event.get("at", 0.0)) > _elapsed:
			break
		_next_event += 1
		_run(String(event.get("do", "")))
		if _cut:
			return
	_update_skip(delta)


func elapsed() -> float:
	return _elapsed


func is_cut() -> bool:
	return _cut


func lights_left() -> int:
	return _lights_total - _lights_done


func capsule_launched() -> bool:
	return _capsule != null and _capsule.visible


func _run(action: String) -> void:
	match action:
		"charge":
			_charge()
		"launch":
			_launch()
		"lights_step":
			_lights_step()
		"fire":
			_fire()
		"ring":
			_ring()
		"cut":
			_cut_to_black()


func _station_position() -> Vector2:
	return _layout.get("station", SCREEN_SIZE * 0.5)


func _charge() -> void:
	AudioManager.play_sfx(&"power_on")
	if ending_id == EndingData.TRANSMISSION:
		_flare.position = _station_position() + DISH_OFFSET
		_flare.scale = Vector2(0.4, 0.4)
		_flare.visible = true
		var tween: Tween = create_tween().set_loops(4)
		tween.tween_property(_flare, ^"modulate:a", 0.35, 0.35)
		tween.tween_property(_flare, ^"modulate:a", 1.0, 0.35)
		return
	_capsule.position = _station_position() + DOCK_OFFSET
	_capsule.scale = Vector2.ONE
	_capsule.visible = true
	_capsule.modulate.a = 0.0
	create_tween().tween_property(_capsule, ^"modulate:a", 1.0, 0.6)


func _launch() -> void:
	AudioManager.play_sfx(&"sector_restored")
	var target: Vector2 = Vector2(_layout.get("planet", SCREEN_SIZE))
	var away: Vector2 = target - Vector2(48, 0)
	var flight: float = maxf(1.0, (_length - _elapsed) * 1.25)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_capsule, ^"position", away, flight).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(
		_capsule, ^"scale", Vector2(CAPSULE_END_SCALE, CAPSULE_END_SCALE), flight
	)


func _lights_step() -> void:
	if _lights_total <= 0:
		return
	_lights_done += 1
	AudioManager.play_sfx(&"power_off")
	var target: float = 1.0 - float(_lights_done) / float(_lights_total)
	var tween: Tween = create_tween()
	tween.tween_property(_station_lit, ^"modulate:a", 0.0, FLICKER_TIME * 0.5)
	tween.tween_property(_station_lit, ^"modulate:a", target + 0.2, FLICKER_TIME * 0.5)
	tween.tween_property(_station_lit, ^"modulate:a", target, FLICKER_TIME)


func _fire() -> void:
	AudioManager.play_sfx(&"sector_restored")
	_flare.visible = true
	_flare.position = _station_position() + DISH_OFFSET + Vector2(20, 0)
	_flare.scale = Vector2(1.2, 1.2)
	_flare.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(_flare, ^"scale", Vector2(0.8, 0.8), 0.8)
	_ring()


func _ring() -> void:
	var ring := Sprite2D.new()
	ring.texture = _cell(CELL_RING)
	ring.position = _station_position() + DISH_OFFSET + Vector2(24, 0)
	ring.scale = Vector2(0.5, 0.5)
	_world.add_child(ring)
	var target: Vector2 = Vector2(_layout.get("earth", SCREEN_SIZE))
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(ring, ^"position", target, RING_TRAVEL_TIME)
	tween.tween_property(ring, ^"scale", Vector2(0.2, 0.2), RING_TRAVEL_TIME)
	tween.tween_property(ring, ^"modulate:a", 0.0, RING_TRAVEL_TIME).set_ease(Tween.EASE_IN)


func _cut_to_black() -> void:
	if _cut:
		return
	_cut = true
	_world.visible = false
	_stars.visible = false
	_caption.visible = false
	_hint.visible = false
	_hint_bar.visible = false
	_black.visible = true
	AudioManager.stop_all()
	get_tree().create_timer(Balance.ENDING_BLACK_TIME).timeout.connect(_go_to_epilogue)


func _go_to_epilogue() -> void:
	SceneManager.goto(ScenePaths.ENDING_EPILOGUE)


func _update_skip(delta: float) -> void:
	var pressed: bool = _any_action_pressed()
	if not _armed:
		_armed = not pressed
		return
	_hold = _hold + delta if pressed else 0.0
	_hint.visible = _hold > 0.0
	_hint_bar.visible = _hold > 0.0
	_hint_bar.size.x = _hint.size.x * clampf(_hold / Balance.ENDING_SKIP_HOLD_TIME, 0.0, 1.0)
	if _hold >= Balance.ENDING_SKIP_HOLD_TIME:
		_cut_to_black()


func _any_action_pressed() -> bool:
	for action: StringName in InputMap.get_actions():
		if Input.is_action_pressed(action):
			return true
	return false


func _cell(cell: Vector2i) -> AtlasTexture:
	return AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, cell.x, cell.y)


func _sprite(cell: Vector2i, at: Vector2, scale_value: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _cell(cell)
	sprite.position = at
	sprite.scale = Vector2(scale_value, scale_value)
	_world.add_child(sprite)
	return sprite


func _build_world() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.size = SCREEN_SIZE
	add_child(background)
	_stars = Sprite2D.new()
	_stars.texture = AssetResolver.texture(STARS_PATH)
	_stars.centered = false
	_stars.modulate = Color(1, 1, 1, 0.8)
	add_child(_stars)
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	_planet = _sprite(
		CELL_PLANET, _layout.get("planet", SCREEN_SIZE), float(_layout.get("planet_scale", 1.0))
	)
	_earth = _sprite(CELL_EARTH, _layout.get("earth", Vector2(-100, -100)), 0.5)
	_earth.visible = ending_id == EndingData.TRANSMISSION
	_station_dark = _sprite(CELL_STATION_DARK, _station_position(), STATION_SCALE)
	_station_lit = _sprite(CELL_STATION_LIT, _station_position(), STATION_SCALE)
	_capsule = _sprite(CELL_CAPSULE_FLAME, _station_position(), 1.0)
	_capsule.visible = false
	_flare = _sprite(CELL_FLARE, _station_position(), 1.0)
	_flare.visible = false


func _build_overlay(table: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.name = "Overlay"
	add_child(layer)
	for top: float in [0.0, SCREEN_SIZE.y - LETTERBOX_HEIGHT]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, top)
		bar.size = Vector2(SCREEN_SIZE.x, LETTERBOX_HEIGHT)
		layer.add_child(bar)
	_caption = _label(_caption_text(table), CAPTION_COLOR)
	_caption.position = Vector2(8, SCREEN_SIZE.y - LETTERBOX_HEIGHT)
	_caption.size = Vector2(SCREEN_SIZE.x - 16, LETTERBOX_HEIGHT)
	_caption.modulate.a = 0.0
	layer.add_child(_caption)
	create_tween().tween_property(_caption, ^"modulate:a", 1.0, 1.0)
	_hint = _label(EndingData.ui_text(table, "skip_hint"), HINT_COLOR)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.position = Vector2(SCREEN_SIZE.x - 160, 0)
	_hint.size = Vector2(152, LETTERBOX_HEIGHT - 4)
	_hint.visible = false
	layer.add_child(_hint)
	_hint_bar = ColorRect.new()
	_hint_bar.color = HINT_COLOR
	_hint_bar.position = Vector2(SCREEN_SIZE.x - 160, LETTERBOX_HEIGHT - 4)
	_hint_bar.size = Vector2(0, 1)
	_hint_bar.visible = false
	layer.add_child(_hint_bar)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = SCREEN_SIZE
	_black.visible = false
	layer.add_child(_black)


func _caption_text(table: Dictionary) -> String:
	var cutscene: Dictionary = EndingData.entry(table, ending_id).get("cutscene", {})
	return String(cutscene.get("caption", ""))


func _label(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	return label


func _start_drift() -> void:
	if _length <= 0.0:
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_world, ^"position", DRIFT, _length).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_stars, ^"position", STARS_DRIFT, _length).set_trans(Tween.TRANS_SINE)
