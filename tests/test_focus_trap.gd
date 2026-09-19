extends TestCase


func test_capture_disables_background_focus_and_restores() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var root := Control.new()
	var background := Button.new()
	var allowed_a := Button.new()
	var allowed_b := Button.new()
	root.add_child(background)
	root.add_child(allowed_a)
	root.add_child(allowed_b)
	tree.root.add_child(root)
	var trap := FocusTrap.new()
	trap.capture([allowed_a, allowed_b] as Array[Control])
	assert_eq(background.focus_mode, Control.FOCUS_NONE, "fundo perde o foco enquanto o modal está aberto")
	assert_eq(allowed_a.focus_mode, Control.FOCUS_ALL, "botão do modal mantém o foco")
	trap.release()
	assert_eq(background.focus_mode, Control.FOCUS_ALL, "fundo recupera o foco ao fechar")
	root.free()


func test_capture_links_neighbours_in_a_cycle() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var root := Control.new()
	var first := Button.new()
	var second := Button.new()
	root.add_child(first)
	root.add_child(second)
	tree.root.add_child(root)
	var trap := FocusTrap.new()
	trap.capture([first, second] as Array[Control])
	assert_eq(first.focus_neighbor_right, first.get_path_to(second), "direita vai para o próximo do ciclo")
	assert_eq(first.focus_neighbor_bottom, first.get_path_to(second), "baixo vai para o próximo do ciclo")
	assert_eq(second.focus_neighbor_right, second.get_path_to(first), "o ciclo volta ao primeiro")
	assert_eq(second.focus_neighbor_left, second.get_path_to(first), "esquerda volta ao primeiro")
	trap.release()
	root.free()
