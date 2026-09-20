extends TestCase

const BLOCKING_SEQUENCE: StringName = &"core_wake"


func after_each() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	DialogueManager.clear()
	tree.paused = false


func test_blocking_dialogue_freezes_the_world() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_false(tree.paused, "a árvore começa despausada")
	DialogueManager.play(BLOCKING_SEQUENCE)
	assert_true(DialogueManager.is_active(), "a sequência começou")
	assert_true(tree.paused, "diálogo travante congela o mundo para o jogador ler")
	DialogueManager.clear()
	assert_false(tree.paused, "ao terminar, o mundo volta a andar")


func test_ambient_line_does_not_freeze_the_world() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var ambient: StringName = _first_ambient_sequence()
	if ambient == &"":
		return
	DialogueManager.play(ambient)
	assert_false(tree.paused, "fala ambiente não congela o mundo")
	DialogueManager.clear()


func _first_ambient_sequence() -> StringName:
	for id: Variant in DialogueManager.sequences().keys():
		var data: Dictionary = DialogueManager.sequences()[id]
		if String(data.get("mode", "blocking")) == "ambient":
			return StringName(String(id))
	return &""
