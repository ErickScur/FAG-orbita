extends TestCase

const SPORE_SCENE: String = "res://scenes/enemies/spore_swarm.tscn"
const VENT_SCENE: String = "res://scenes/world/steam_vent.tscn"
const SR3_SCENE: String = "res://scenes/enemies/sr3.tscn"
const PLAYER_SCRIPT: String = "res://scenes/player/mu7.gd"

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_spores_let_the_dash_through() -> void:
	var swarm: Node = _mount(SPORE_SCENE)
	assert_true(swarm is DamageArea, "esporo é área de dano")
	assert_true((swarm as DamageArea).dash_passable, "dash atravessa o esporo")


func test_steam_jet_lets_the_dash_through() -> void:
	var vent: Node = _mount(VENT_SCENE)
	var jet: DamageArea = vent.get_node("Jet")
	assert_true(jet.dash_passable, "dash atravessa o jato de vapor")


func test_machine_contact_still_hurts_during_the_dash() -> void:
	var sr3: Node = _mount(SR3_SCENE)
	var hitbox: DamageArea = sr3.get_node("Hitbox")
	assert_false(hitbox.dash_passable, "contato com a SR-3 continua ferindo")
	var fresh := DamageArea.new()
	_nodes.append(fresh)
	assert_false(fresh.dash_passable, "área nova não é atravessável por padrão")


func test_the_player_skips_passable_damage_only_while_dashing() -> void:
	var source: String = (load(PLAYER_SCRIPT) as GDScript).source_code
	assert_true(
		source.contains("if _dashing and source.dash_passable:"), "o filtro mora no MU-7"
	)


func _mount(scene_path: String) -> Node:
	var node: Node = (load(scene_path) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	_nodes.append(node)
	return node
