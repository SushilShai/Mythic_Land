extends Control

@export var show_joystick: bool = true

@onready var base: TextureRect = $Base
@onready var konb: TextureRect = $Konb
@export var radius: float = 80.0   # How far the knob can move

var dragging: bool = false
var output_vector: Vector2 = Vector2.ZERO

func _ready():
	# Hide joystick on PC, show on mobile
	var has_touchscreen := Input.get_connected_joypads().is_empty() and DisplayServer.is_touchscreen_available()
	visible = has_touchscreen
	_reset_knob()

func _gui_input(event):
	# Touch input
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
		else:
			dragging = false
			output_vector = Vector2.ZERO
			_reset_knob()
	elif event is InputEventScreenDrag and dragging:
		_process_drag(event.position)
	
	# Mouse input for PC testing
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
				output_vector = Vector2.ZERO
				_reset_knob()
	elif event is InputEventMouseMotion and dragging:
		_process_drag(event.position)

@warning_ignore("unused_parameter")
func _process_drag(pos: Vector2):
	# Convert input to local coordinates relative to the base
	var local_pos = base.get_local_mouse_position()
	var offset = local_pos - base.size / 2

	# Clamp distance
	if offset.length() > radius:
		offset = offset.normalized() * radius

	# Move knob
	konb.position = base.position + base.size / 2 - konb.size / 2 + offset

	# Normalize output direction (vector between -1 and 1)
	output_vector = offset / radius

func _reset_knob():
	konb.position = base.position + base.size / 2 - konb.size / 2

func get_vector() -> Vector2:
	return output_vector
