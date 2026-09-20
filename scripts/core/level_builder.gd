class_name LevelBuilder
extends RefCounted

const LEGEND: Dictionary = {
	"D": {
		"name": "doca de backup",
		"scene": "res://scenes/world/backup_dock.tscn",
		"anchor": &"feet",
		"feature": "F13",
		"id_property": "dock_id",
	},
	"T": {
		"name": "terminal de distribuição",
		"scene": "res://scenes/world/distribution_terminal.tscn",
		"anchor": &"feet",
		"feature": "F17",
		"aliases": {"terminal": "terminal_id"},
	},
	"L": {
		"name": "terminal de registros",
		"scene": "res://scenes/world/log_object.tscn",
		"anchor": &"feet",
		"feature": "F19",
		"id_property": "log_id",
		"defaults": {"style": &"terminal"},
	},
	"l": {
		"name": "fragmento de log",
		"scene": "res://scenes/world/collectible.tscn",
		"anchor": &"center",
		"feature": "F20",
		"kind": &"log",
	},
	"r": {
		"name": "dado de pesquisa",
		"scene": "res://scenes/world/collectible.tscn",
		"anchor": &"center",
		"feature": "F20",
		"kind": &"research",
	},
	"c": {
		"name": "célula de energia",
		"scene": "res://scenes/world/collectible.tscn",
		"anchor": &"center",
		"feature": "F20",
		"kind": &"cell",
	},
	"k": {
		"name": "kit de solda",
		"scene": "res://scenes/world/collectible.tscn",
		"anchor": &"center",
		"feature": "F20",
		"kind": &"repair_kit",
	},
	"C": {
		"name": "núcleo de capacitor",
		"scene": "res://scenes/world/collectible.tscn",
		"anchor": &"center",
		"feature": "F20",
		"kind": &"capacitor",
	},
	"|": {
		"name": "porta de energia",
		"scene": "res://scenes/world/door.tscn",
		"anchor": &"feet",
		"feature": "F17",
	},
	"E": {
		"name": "saída de fase",
		"scene": "res://scenes/world/level_exit.tscn",
		"anchor": &"feet",
		"feature": "F28",
	},
	"S": {
		"name": "SR-3",
		"scene": "res://scenes/enemies/sr3.tscn",
		"anchor": &"feet",
		"feature": "F22",
	},
	"~": {
		"name": "enxame de esporos",
		"scene": "res://scenes/enemies/spore_swarm.tscn",
		"anchor": &"center",
		"feature": "F23",
	},
	"M": {
		"name": "parede magnética",
		"scene": "res://scenes/world/magnetic_wall.tscn",
		"anchor": &"center",
		"feature": "F24",
	},
	"m": {
		"name": "plataforma móvel",
		"scene": "res://scenes/world/moving_platform.tscn",
		"anchor": &"center",
		"feature": "F25",
	},
	"g": {
		"name": "planta que cresce",
		"scene": "res://scenes/world/grow_plant.tscn",
		"anchor": &"feet",
		"feature": "F25",
	},
	"x": {
		"name": "parede falsa",
		"scene": "res://scenes/world/secret_wall.tscn",
		"anchor": &"center",
		"feature": "F27",
	},
	"@": {
		"name": "lâmpada",
		"scene": "res://scenes/world/powered_lamp.tscn",
		"anchor": &"center",
		"feature": "F18",
		"aliases": {"color": "lamp_color"},
	},
	"o": {
		"name": "prop de cenário",
		"scene": "res://scenes/world/log_object.tscn",
		"anchor": &"feet",
		"feature": "F19",
		"aliases": {"log": "log_id", "frame": "prop_column"},
		"defaults": {"style": &"prop"},
		"prop_sheet": true,
	},
	"b": {
		"name": "drone BOTÂNICO 04",
		"scene": "res://scenes/npc/botanico.tscn",
		"anchor": &"center",
		"feature": "F34",
	},
	"v": {
		"name": "jato de vapor",
		"scene": "res://scenes/world/steam_vent.tscn",
		"anchor": &"feet",
		"feature": "F32",
	},
	"z": {
		"name": "piso eletrificado",
		"scene": "res://scenes/world/electric_floor.tscn",
		"anchor": &"feet",
		"feature": "F32",
	},
}
const COLLECTIBLE_KINDS: Array[StringName] = [
	&"log", &"research", &"cell", &"repair_kit", &"capacitor"
]
const PROPS_SHEET: String = "res://assets/sprites/props/props_sheet.png"
const PROP_FRAME: Vector2i = Vector2i(32, 32)
const TRIGGER_SCRIPT: String = "res://scenes/world/dialogue_trigger.gd"
const BACKGROUND_TILE: Vector2i = Vector2i(1, 2)
const WINDOW_TILE: Vector2i = Vector2i(2, 2)
const ONE_WAY_TILE: Vector2i = Vector2i(0, 2)
const SOURCE_ID: int = 0
const DEATH_ZONE_MARGIN_TILES: int = 8
const DEATH_ZONE_DEPTH_TILES: int = 4
const DEATH_ZONE_OFFSET_TILES: int = 2
const RESERVED_PARAMS: Array[String] = ["id", "group"]


static func entity_chars() -> String:
	var chars: String = ""
	for symbol: Variant in LEGEND:
		chars += String(symbol)
	return chars


static func build_tiles(parsed: Dictionary, solid: TileMapLayer, background: TileMapLayer) -> void:
	var width: int = int(parsed.get("width", 0))
	var height: int = int(parsed.get("height", 0))
	var solids: Dictionary = parsed.get("solids", {})
	if background != null:
		background.clear()
		for row: int in range(height):
			for column: int in range(width):
				background.set_cell(Vector2i(column, row), SOURCE_ID, BACKGROUND_TILE)
		for cell: Vector2i in parsed.get("windows", []) as Array:
			background.set_cell(cell, SOURCE_ID, WINDOW_TILE)
	if solid == null:
		return
	solid.clear()
	for key: Variant in solids:
		var cell: Vector2i = key
		var mask: int = LevelParser.neighbor_mask(solids, cell, width, height)
		solid.set_cell(cell, SOURCE_ID, LevelParser.atlas_coords_for_mask(mask))
	for cell: Vector2i in parsed.get("one_ways", []) as Array:
		solid.set_cell(cell, SOURCE_ID, ONE_WAY_TILE)


static func build_entities(
	parsed: Dictionary, meta: Dictionary, parent: Node2D, level_id: String
) -> void:
	if parent == null:
		return
	var entities_meta: Dictionary = meta.get("entities", {})
	for entry: Dictionary in parsed.get("entities", []) as Array:
		var symbol: String = String(entry.get("symbol", ""))
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		var definition: Dictionary = LEGEND.get(symbol, {})
		if definition.is_empty():
			continue
		var params: Dictionary = _params_for(entities_meta, cell, definition)
		var kind: StringName = StringName(definition.get("kind", &""))
		if kind != &"":
			params["kind"] = kind
			if not params.has("item_id"):
				params["item_id"] = default_item_id(level_id, kind, cell, params)
			if _already_collected(StringName(params["item_id"])):
				continue
		_apply_aliases(definition, params)
		var instance: Node2D = _instantiate(symbol, definition, params)
		if instance == null:
			continue
		instance.position = LevelParser.cell_to_position(
			cell, StringName(definition.get("anchor", &"center")), Balance.TILE_SIZE
		)
		_apply_params(instance, params)
		parent.add_child(instance)


static func build_triggers(meta: Dictionary, parent: Node2D) -> void:
	if parent == null:
		return
	if not ResourceLoader.exists(TRIGGER_SCRIPT):
		push_warning("LevelBuilder: script de gatilho ausente (F19)")
		return
	var script: Script = load(TRIGGER_SCRIPT)
	for value: Variant in meta.get("triggers", []) as Array:
		if not (value is Dictionary):
			continue
		var data: Dictionary = value
		var rect: Array = data.get("rect", [])
		if rect.size() != 4:
			push_warning("LevelBuilder: gatilho '%s' sem rect válido" % data.get("id", "?"))
			continue
		var area := Area2D.new()
		area.set_script(script)
		area.name = StringName("Trigger_%s" % data.get("id", "anon"))
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitorable = false
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		var size := Vector2(int(rect[2]) * Balance.TILE_SIZE, int(rect[3]) * Balance.TILE_SIZE)
		rectangle.size = size
		shape.shape = rectangle
		area.add_child(shape)
		area.position = Vector2(
			int(rect[0]) * Balance.TILE_SIZE + size.x * 0.5,
			int(rect[1]) * Balance.TILE_SIZE + size.y * 0.5
		)
		_apply_trigger_params(area, data)
		parent.add_child(area)


static func build_death_zone(parsed: Dictionary, zone: Area2D) -> void:
	if zone == null:
		return
	var width: int = int(parsed.get("width", 0))
	var height: int = int(parsed.get("height", 0))
	var tile: int = Balance.TILE_SIZE
	var size := Vector2(
		float((width + DEATH_ZONE_MARGIN_TILES * 2) * tile),
		float(DEATH_ZONE_DEPTH_TILES * tile)
	)
	var shape: CollisionShape2D = zone.get_node_or_null("CollisionShape2D")
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		zone.add_child(shape)
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	zone.position = Vector2(
		float(width * tile) * 0.5,
		float((height + DEATH_ZONE_OFFSET_TILES) * tile) + size.y * 0.5
	)


static func default_item_id(
	level_id: String, kind: StringName, cell: Vector2i, params: Dictionary
) -> StringName:
	if params.has("id"):
		return StringName(params["id"])
	return StringName("%s_%s_%d_%d" % [level_id, kind, cell.x, cell.y])


static func camera_rect(parsed: Dictionary) -> Rect2i:
	return Rect2i(
		0,
		0,
		int(parsed.get("width", 0)) * Balance.TILE_SIZE,
		int(parsed.get("height", 0)) * Balance.TILE_SIZE
	)


static func _params_for(
	entities_meta: Dictionary, cell: Vector2i, definition: Dictionary
) -> Dictionary:
	var params: Dictionary = {}
	for key: Variant in definition.get("defaults", {}):
		params[String(key)] = definition["defaults"][key]
	var raw: Variant = entities_meta.get(LevelParser.cell_key(cell), {})
	if raw is Dictionary:
		for key: Variant in raw as Dictionary:
			params[String(key)] = (raw as Dictionary)[key]
	return params


static func _already_collected(item_id: StringName) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var state: Node = tree.root.get_node_or_null("GameState")
	if state == null:
		return false
	var collected: Variant = state.get("collected_ids")
	return collected is Array and (collected as Array).has(item_id)


static func _instantiate(symbol: String, definition: Dictionary, params: Dictionary) -> Node2D:
	if bool(definition.get("prop_sheet", false)) and not params.has("log"):
		return _make_prop(params)
	var path: String = String(definition.get("scene", ""))
	if not ResourceLoader.exists(path):
		push_warning(
			"LevelBuilder: entidade '%s' (%s) ainda não implementada (%s)"
			% [symbol, definition.get("name", "?"), definition.get("feature", "?")]
		)
		return null
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var instance: Node = scene.instantiate()
	if instance is Node2D:
		return instance
	instance.free()
	return null


static func _make_prop(params: Dictionary) -> Node2D:
	var column: int = int(params.get("frame", 0))
	var texture: AtlasTexture = AssetResolver.atlas(PROPS_SHEET, PROP_FRAME, column, 0)
	var sprite := Sprite2D.new()
	sprite.name = "Prop"
	if texture == null:
		push_warning("LevelBuilder: folha de props ausente em %s" % PROPS_SHEET)
	else:
		sprite.texture = texture
	sprite.offset = Vector2(0.0, -float(PROP_FRAME.y) * 0.5)
	return sprite


static func _apply_params(instance: Node2D, params: Dictionary) -> void:
	var properties: Dictionary = _property_types(instance)
	for key: Variant in params:
		var name: String = String(key)
		var value: Variant = params[key]
		if name == "id":
			instance.add_to_group(StringName("entity:" + String(value)))
		elif name == "group":
			instance.add_to_group(StringName(String(value)))
		if not properties.has(name):
			continue
		instance.set(name, _coerce(value, int(properties[name])))
	_wire_log(instance)
	if instance.has_method("configure"):
		instance.call("configure", params)


static func _apply_aliases(definition: Dictionary, params: Dictionary) -> void:
	var id_property: String = String(definition.get("id_property", ""))
	if not id_property.is_empty() and params.has("id") and not params.has(id_property):
		params[id_property] = params["id"]
	for key: Variant in definition.get("aliases", {}):
		var source: String = String(key)
		var target: String = String((definition["aliases"] as Dictionary)[key])
		if params.has(source) and not params.has(target):
			params[target] = params[source]


static func _wire_log(instance: Node2D) -> void:
	if not instance.has_signal(&"interacted"):
		return
	var value: Variant = instance.get(&"log_id")
	if value == null:
		return
	var log_id: StringName = StringName(value)
	if log_id == &"":
		return
	instance.connect(
		&"interacted", func(_actor: Variant) -> void: DialogueManager.open_log(log_id)
	)


static func _apply_trigger_params(area: Area2D, data: Dictionary) -> void:
	area.set("trigger_id", StringName(String(data.get("id", ""))))
	area.set("dialogue_id", StringName(String(data.get("dialogue", ""))))
	area.set("objective_id", StringName(String(data.get("objective", ""))))
	area.set("flag_id", StringName(String(data.get("set_flag", ""))))
	area.set("once", bool(data.get("once", true)))


static func _property_types(instance: Node) -> Dictionary:
	var types: Dictionary = {}
	for property: Dictionary in instance.get_property_list():
		var usage: int = int(property.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		types[String(property.get("name", ""))] = int(property.get("type", TYPE_NIL))
	return types


static func _coerce(value: Variant, type: int) -> Variant:
	match type:
		TYPE_STRING_NAME:
			return StringName(String(value))
		TYPE_STRING:
			return String(value)
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return float(value)
		TYPE_BOOL:
			return bool(value)
		TYPE_COLOR:
			return Color(String(value)) if value is String else value
	return value
