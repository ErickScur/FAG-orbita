extends Node2D

const LEVELS_DIR: String = "res://data/levels/"
const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const DEFAULT_TILESET: String = "res://assets/tiles/core_tileset.tres"
const PARALLAX_SCENE: String = "res://scenes/world/space_parallax.tscn"

@export var level_id: String = ""

var _parsed: Dictionary = {}
var _meta: Dictionary = {}
var _player: Node2D = null
var _death_armed: bool = true

@onready var _background: TileMapLayer = $Background
@onready var _solid: TileMapLayer = $Solid
@onready var _parallax: Node2D = $Parallax
@onready var _entities: Node2D = $Entities
@onready var _triggers: Node2D = $Triggers
@onready var _death_zone: Area2D = $DeathZone
@onready var _energy_network: Node = $EnergyNetwork
@onready var _ambient: CanvasModulate = $CanvasModulate


func _ready() -> void:
	add_to_group(&"level")
	if level_id.is_empty():
		push_warning("level_base: cena-mãe carregada sem level_id")
		return
	if not _load_data():
		return
	_apply_tileset()
	_mount_parallax()
	LevelBuilder.build_tiles(_parsed, _solid, _background)
	LevelBuilder.build_entities(_parsed, _meta, _entities, level_id)
	LevelBuilder.build_triggers(_meta, _triggers)
	LevelBuilder.build_death_zone(_parsed, _death_zone)
	_death_zone.body_entered.connect(_on_death_zone_entered)
	EventBus.player_respawned.connect(_on_player_respawned)
	_load_energy()
	_spawn_player()
	_mount_hud()
	_apply_atmosphere()
	_apply_progress()


func spawn_position() -> Vector2:
	var dock: Node2D = _checkpoint_dock()
	if dock != null:
		return dock.global_position
	return LevelParser.cell_to_position(
		_parsed.get("spawn", Vector2i.ZERO), LevelParser.ANCHOR_FEET, Balance.TILE_SIZE
	)


func camera_rect() -> Rect2i:
	return LevelBuilder.camera_rect(_parsed)


func meta_color(key: String) -> Color:
	var value: String = String(_meta.get(key, ""))
	if value.is_empty():
		return _ambient.color
	return Color(value)


func _load_data() -> bool:
	var text_path: String = LEVELS_DIR + level_id + ".txt"
	var meta_path: String = LEVELS_DIR + level_id + ".json"
	if not FileAccess.file_exists(text_path):
		push_error("level_base: fase ausente em %s" % text_path)
		return false
	var text: String = FileAccess.get_file_as_string(text_path)
	_meta = _read_json(meta_path)
	_parsed = LevelParser.parse(text, LevelBuilder.entity_chars())
	for warning: String in _parsed.get("warnings", []) as PackedStringArray:
		push_warning("level_base (%s): %s" % [level_id, warning])
	var errors: PackedStringArray = _parsed.get("errors", [])
	if errors.is_empty():
		return true
	for message: String in errors:
		push_error("level_base (%s): %s" % [level_id, message])
	return false


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("level_base: metadados ausentes em %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("level_base: metadados inválidos em %s" % path)
	return {}


func _apply_tileset() -> void:
	var path: String = String(_meta.get("tileset", DEFAULT_TILESET))
	if not ResourceLoader.exists(path):
		push_warning("level_base: tileset ausente em %s" % path)
		return
	var tile_set: TileSet = load(path)
	_background.tile_set = tile_set
	_solid.tile_set = tile_set


func _mount_parallax() -> void:
	if not bool(_meta.get("parallax", false)):
		return
	if not ResourceLoader.exists(PARALLAX_SCENE):
		push_warning("level_base: parallax espacial ausente (F26)")
		return
	_parallax.add_child(load(PARALLAX_SCENE).instantiate())


func _load_energy() -> void:
	var terminals: Array = _meta.get("terminals", [])
	if _energy_network == null or terminals.is_empty():
		return
	if _energy_network.has_method("load_terminals"):
		_energy_network.call("load_terminals", terminals)


func _spawn_player() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		push_warning("level_base: cena do jogador ausente (F12)")
		return
	var scene: PackedScene = load(PLAYER_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_player = instance
	_player.name = "Player"
	add_child(_player)
	_player.global_position = spawn_position()
	var floor_sfx: String = String(_meta.get("floor_sfx", ""))
	if not floor_sfx.is_empty():
		_player.set(&"floor_sfx", StringName(floor_sfx))
	if _player.has_method("set_camera_limits"):
		_player.call("set_camera_limits", camera_rect())
	if _player.has_method("snap_camera"):
		_player.call("snap_camera")


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("level_base: HUD ainda não implementado (F15)")
		return
	add_child(load(HUD_SCENE).instantiate())


func _apply_atmosphere() -> void:
	var color_text: String = String(_meta.get("ambient_color", ""))
	_ambient.color = Color(color_text) if not color_text.is_empty() else Balance.AMBIENT_DARK
	var music: String = String(_meta.get("music", ""))
	if not music.is_empty():
		AudioManager.play_music(StringName(music))
	if bool(_meta.get("reactor_online", false)):
		GameState.flags["reactor_online"] = true


func _apply_progress() -> void:
	var objective: String = String(_meta.get("objective", ""))
	if not objective.is_empty() and GameState.has_method("set_objective"):
		GameState.call("set_objective", StringName(objective))
	var enter_dialogue: String = String(_meta.get("on_enter_dialogue", ""))
	if not enter_dialogue.is_empty():
		DialogueManager.play(StringName(enter_dialogue))


func _checkpoint_dock() -> Node2D:
	var checkpoint: Dictionary = GameState.checkpoint
	if String(checkpoint.get("scene", "")) != scene_file_path:
		return null
	var dock_id: String = String(checkpoint.get("dock_id", ""))
	if dock_id.is_empty():
		return null
	var docks: Array = get_tree().get_nodes_in_group(StringName("entity:" + dock_id))
	for dock: Node in docks:
		if dock is Node2D:
			return dock
	return null


func _on_death_zone_entered(body: Node2D) -> void:
	if not _death_armed or not body.is_in_group(&"player"):
		return
	_death_armed = false
	GameState.apply_damage(GameState.integrity_max * 2)


func _on_player_respawned() -> void:
	_death_armed = true
