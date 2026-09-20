class_name MagneticWall
extends StaticBody2D

const TILE_SHEET: String = "res://assets/tiles/greenhouse_tiles.png"
const TILE_FRAME: Vector2i = Vector2i(16, 16)
const TILE_COLUMN: int = 0
const TILE_ROW: int = 3
const WORLD_LAYER: int = 1
const GLOW_TEXTURE: String = "res://assets/fx/light_radial.png"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group(ClimbLogic.MAGNETIC_GROUP)
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_apply_texture()
	_setup_glow()
	_merge_glow.call_deferred()


func glow_energy() -> float:
	return _glow.energy if _glow.enabled else 0.0


func glow_enabled() -> bool:
	return _glow.enabled


func cell() -> Vector2i:
	return Vector2i(
		floori(global_position.x / float(TILE_FRAME.x)),
		floori(global_position.y / float(TILE_FRAME.y))
	)


func _apply_texture() -> void:
	var texture: AtlasTexture = AssetResolver.atlas(
		TILE_SHEET, TILE_FRAME, TILE_COLUMN, TILE_ROW
	)
	if texture == null:
		push_warning("MagneticWall: tile de parede magnética ausente em %s" % TILE_SHEET)
		return
	_sprite.texture = texture
	var self_light: float = Balance.MAGNETIC_SELF_LIGHT
	_sprite.self_modulate = Color(self_light, self_light, self_light, 1.0)


func _setup_glow() -> void:
	_glow.texture = AssetResolver.texture(GLOW_TEXTURE)
	if _glow.texture == null:
		push_warning("MagneticWall: textura de luz ausente em %s" % GLOW_TEXTURE)
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.color = Balance.MAGNETIC_GLOW_COLOR
	_glow.energy = Balance.MAGNETIC_GLOW_ENERGY
	_glow.texture_scale = LightMath.scale_for_radius(
		Balance.MAGNETIC_GLOW_RADIUS, LightMath.TEXTURE_SIZE
	)


func _merge_glow() -> void:
	var column: Dictionary = _column_cells()
	var here: Vector2i = cell()
	var top: int = here.y
	while column.has(top - 1):
		top -= 1
	if (here.y - top) % Balance.MAGNETIC_GLOW_SEGMENT_TILES != 0:
		_glow.enabled = false
		return
	var span: int = 1
	while span < Balance.MAGNETIC_GLOW_SEGMENT_TILES and column.has(here.y + span):
		span += 1
	_stretch_glow(span)


func _column_cells() -> Dictionary:
	var column: Dictionary = {}
	var here: Vector2i = cell()
	for node: Node in get_tree().get_nodes_in_group(ClimbLogic.MAGNETIC_GROUP):
		var wall: MagneticWall = node as MagneticWall
		if wall == null:
			continue
		var other: Vector2i = wall.cell()
		if other.x == here.x:
			column[other.y] = true
	return column


func _stretch_glow(span: int) -> void:
	var tile_height: float = float(TILE_FRAME.y)
	var covered: float = (float(span) + Balance.MAGNETIC_GLOW_SEGMENT_OVERLAP) * tile_height
	var diameter: float = Balance.MAGNETIC_GLOW_RADIUS * 2.0
	_glow.position = Vector2(0.0, (float(span) - 1.0) * tile_height * 0.5)
	_glow.scale = Vector2(1.0, maxf(1.0, covered / diameter))
	_glow.energy = Balance.MAGNETIC_GLOW_ENERGY * Balance.MAGNETIC_GLOW_MERGE_GAIN
