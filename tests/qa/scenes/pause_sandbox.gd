extends Node2D

@onready var counter_label: Label = %Counter
@onready var reactor_label: Label = %Reactor
@onready var marker: ColorRect = %Marker

var _ticks: int = 0


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	_ticks += 1
	marker.position = Vector2(32.0 + fmod(float(_ticks) * 2.0, 320.0), 166.0)
	_refresh()


func _refresh() -> void:
	counter_label.text = "CONTADOR: %d" % _ticks
	reactor_label.text = "Estabilidade do Reator: %d%%" % roundi(GameState.reactor_percent)
