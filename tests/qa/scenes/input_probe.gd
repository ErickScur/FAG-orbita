extends Control

const ACTIONS: PackedStringArray = [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"jump",
	"dash",
	"interact",
	"beam",
	"flashlight",
	"map",
	"log_archive",
	"pause",
]

@onready var frame_label: Label = %FrameLabel
@onready var pressed_label: Label = %PressedLabel

var _frames: int = 0


func _ready() -> void:
	frame_label.text = "FRAME 0"
	pressed_label.text = "NENHUMA"


func _process(_delta: float) -> void:
	_frames += 1
	frame_label.text = "FRAME %d" % _frames
	var active: PackedStringArray = []
	for action: String in ACTIONS:
		if Input.is_action_pressed(action):
			active.append(action)
	if active.is_empty():
		pressed_label.text = "NENHUMA"
	else:
		pressed_label.text = ", ".join(active)
