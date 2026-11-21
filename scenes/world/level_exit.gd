class_name LevelExit
extends Interactable

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const SHEET_PATH: String = "res://assets/sprites/world/door_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 48)
const FRAME_PORTAL: int = 5
const INTERACTABLE_LAYER: int = 8
const LIGHT_RADIUS: float = 80.0
const LIGHT_ENERGY: float = 0.7
const CLOSED_TINT: Color = Color("6b3a3a")
const DEFAULT_PROMPT: String = "ENTRAR"
const PLATE_OFFSET: Vector2 = Vector2(0.0, -57.0)

@export var target: String = ""
@export var sector: StringName = &""
@export var closes_after_sector: StringName = &""

var _used: bool = false
var _plate: SectorPlate = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	super()
	add_to_group(&"level_exit")
	collision_layer = INTERACTABLE_LAYER
	interacted.connect(_on_interacted)
	_apply_sprite()
	_apply_light()
	_apply_sector()
	_apply_closed_state()


func configure(params: Dictionary) -> void:
	if params.has("target"):
		target = String(params["target"])
	if params.has("sector"):
		sector = StringName(String(params["sector"]))
	if params.has("closes_after_sector"):
		closes_after_sector = StringName(String(params["closes_after_sector"]))
	if _sprite == null:
		return
	_apply_sector()
	_apply_closed_state()


func is_closed() -> bool:
	return SectorRevisit.exit_closed(closes_after_sector, GameState.sectors_restored)


func has_target() -> bool:
	return not target.is_empty() and ResourceLoader.exists(target)


func plate() -> SectorPlate:
	return _plate


func _apply_sprite() -> void:
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, FRAME_PORTAL, 0)
	if atlas == null:
		push_warning("LevelExit: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas


func _apply_light() -> void:
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("LevelExit: textura de luz ausente em %s" % LIGHT_TEXTURE)
		return
	_light.energy = LIGHT_ENERGY
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.texture_scale = LightMath.scale_for_radius(LIGHT_RADIUS, LightMath.TEXTURE_SIZE)


func _apply_sector() -> void:
	var table: Dictionary = SectorCatalog.load_all()
	_light.color = SectorCatalog.color(sector, table)
	var text: String = SectorCatalog.prompt(sector, table)
	prompt_text = text if not text.is_empty() else DEFAULT_PROMPT
	if sector == &"" or not SectorCatalog.has(sector, table):
		return
	if _plate == null:
		_plate = SectorPlate.new()
		_plate.name = "Plate"
		_plate.position = PLATE_OFFSET
		add_child(_plate)
	_plate.setup(sector, table)


func _apply_closed_state() -> void:
	var closed: bool = is_closed()
	_sprite.modulate = CLOSED_TINT if closed else Color.WHITE
	_light.enabled = not closed
	enabled = not closed


func _on_interacted(_actor: Node) -> void:
	if _used or is_closed():
		return
	if not has_target():
		push_error("LevelExit: saída sem cena de destino (%s)" % target)
		return
	_used = true
	AudioManager.play_sfx(&"door_open")
	SceneManager.goto(target)
