extends CanvasLayer

signal finished

enum Phase { IDLE, FADE, TYPE, HOLD, DONE }

const MAIN_TEXT: String = "SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP"
const HINT_TEXT: String = "[E] CONTINUAR"
const FADE_TIME: float = 0.4
const TYPE_INTERVAL: float = 0.03
const HOLD_TIME: float = 1.5

@onready var fade: ColorRect = %Fade
@onready var panel: PanelContainer = %Panel
@onready var main_line: Label = %MainLine
@onready var cost_line: Label = %CostLine
@onready var bar: ProgressBar = %Bar
@onready var hint_line: Label = %HintLine

var _phase: int = Phase.IDLE
var _elapsed: float = 0.0
var _typed: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	fade.modulate.a = 0.0
	panel.modulate.a = 0.0
	main_line.text = ""
	cost_line.text = "CUSTO: -%d%% DE ESTABILIDADE" % roundi(Balance.REACTOR_DEATH_PENALTY)
	cost_line.modulate.a = 0.0
	hint_line.text = HINT_TEXT
	hint_line.modulate.a = 0.0
	bar.value = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")):
		return
	if _phase == Phase.IDLE or _phase == Phase.DONE:
		return
	get_viewport().set_input_as_handled()
	if _phase == Phase.HOLD:
		_close()
		return
	_reveal_all()


func play() -> void:
	if _phase != Phase.IDLE:
		return
	AudioManager.play_sfx(&"chassis_lost")
	AudioManager.play_one_shot(&"chassis_lost")
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.gui_release_focus()
	_phase = Phase.FADE
	_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	match _phase:
		Phase.FADE:
			_run_fade()
		Phase.TYPE:
			_run_typing()
		Phase.HOLD:
			_run_hold()


func _run_fade() -> void:
	var ratio: float = minf(_elapsed / FADE_TIME, 1.0)
	fade.modulate.a = ratio
	panel.modulate.a = ratio
	if ratio >= 1.0:
		_phase = Phase.TYPE
		_elapsed = 0.0


func _run_typing() -> void:
	var target: int = mini(int(_elapsed / TYPE_INTERVAL), MAIN_TEXT.length())
	if target != _typed:
		_typed = target
		main_line.text = MAIN_TEXT.substr(0, _typed)
	if _typed >= MAIN_TEXT.length():
		_start_hold()


func _run_hold() -> void:
	bar.value = minf(_elapsed / HOLD_TIME, 1.0) * 100.0
	if _elapsed >= HOLD_TIME:
		_close()


func _reveal_all() -> void:
	_typed = MAIN_TEXT.length()
	main_line.text = MAIN_TEXT
	fade.modulate.a = 1.0
	panel.modulate.a = 1.0
	_start_hold()


func _start_hold() -> void:
	_phase = Phase.HOLD
	_elapsed = 0.0
	cost_line.modulate.a = 1.0
	hint_line.modulate.a = 1.0


func _close() -> void:
	if _phase == Phase.DONE:
		return
	_phase = Phase.DONE
	set_process(false)
	bar.value = 100.0
	AudioManager.play_sfx(&"respawn")
	finished.emit()
	queue_free()
