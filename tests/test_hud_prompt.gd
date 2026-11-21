extends TestCase

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const MAIN_MENU_SCRIPT: String = "res://scenes/ui/main_menu.gd"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const DOCK_SCENE: String = "res://scenes/world/backup_dock.tscn"
const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const SCREEN: Vector2 = Vector2(384.0, 216.0)
const MU7_HEIGHT: float = 32.0

var _spawned: Array[Node] = []


func after_each() -> void:
	for node: Node in _spawned:
		if not is_instance_valid(node):
			continue
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()
	_spawned.clear()


func test_prompt_floats_over_the_mu7_and_stays_on_screen() -> void:
	var hud: CanvasLayer = _spawn(load(HUD_SCENE).instantiate()) as CanvasLayer
	var player := Node2D.new()
	player.add_to_group(&"player")
	_spawn(player)
	for foot: Vector2 in [
		Vector2(192.0, 150.0), Vector2(370.0, 200.0), Vector2(12.0, 120.0), Vector2(192.0, 64.0)
	]:
		player.global_position = foot
		EventBus.interaction_available.emit("[E] SEGURAR PARA ACOPLAR")
		assert_true(bool(hud.call(&"prompt_visible")), "prompt visível")
		var rect: Rect2 = hud.call(&"prompt_rect")
		assert_true(rect.size.x > 0.0, "prompt com largura")
		assert_true(
			rect.position.x >= 0.0 and rect.end.x <= SCREEN.x, "dentro da tela em x (%s)" % foot
		)
		assert_true(
			rect.position.y >= InteractionRules.PROMPT_TOP_LIMIT and rect.end.y <= SCREEN.y,
			"dentro da tela, abaixo da faixa da HUD (%s)" % foot
		)
		var body := Rect2(foot - Vector2(8.0, MU7_HEIGHT), Vector2(16.0, MU7_HEIGHT))
		assert_false(rect.intersects(body), "o prompt não cobre o MU-7 (%s)" % foot)
	player.global_position = Vector2(192.0, 150.0)
	EventBus.interaction_available.emit("[E] ACESSAR TERMINAL")
	var above: Rect2 = hud.call(&"prompt_rect")
	assert_true(above.end.y <= 150.0 - MU7_HEIGHT, "acima da cabeça")
	assert_true(absf(above.get_center().x - 192.0) <= 1.0, "centrado no MU-7")
	EventBus.interaction_cleared.emit()
	assert_false(bool(hud.call(&"prompt_visible")), "some sem alvo")


func test_main_menu_shows_the_final_version_from_data() -> void:
	var version: String = load(MAIN_MENU_SCRIPT).call(&"game_version")
	assert_eq(version, "v1.0", "versão do jogo completo")
	assert_false(version.contains("DEMO"), "sem DEMO no menu")
	var text: String = FileAccess.get_file_as_string(MAIN_MENU_SCENE)
	assert_false(text.contains("DEMO v0.1"), "cena sem a versão antiga")


func test_dock_draws_behind_the_mu7() -> void:
	var dock: Node2D = load(DOCK_SCENE).instantiate()
	var mu7: Node2D = load(PLAYER_SCENE).instantiate()
	var dock_sprite: CanvasItem = dock.get_node("AnimatedSprite2D")
	var mu7_sprite: CanvasItem = mu7.get_node("AnimatedSprite2D")
	var dock_z: int = dock.z_index + dock_sprite.z_index
	var mu7_z: int = mu7.z_index + mu7_sprite.z_index
	assert_true(dock_z < mu7_z, "a doca fica atrás do MU-7 que renasce nela")
	dock.free()
	mu7.free()


func _spawn(node: Node) -> Node:
	Engine.get_main_loop().root.add_child(node)
	_spawned.append(node)
	return node
