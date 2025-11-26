extends CharacterBody2D
class_name PlayerController

@export var move_speed = 150.0
@export var sprint_increase = 2.0

@onready var joystick: Control = $joystick

var direction: Vector2
var sprinting = false
var sprint_multiplier = 1.0

enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing: Facing = Facing.DOWN


@warning_ignore("unused_parameter")
func _physics_process(delta):
	direction = Vector2.ZERO

	# ---------- KEYBOARD INPUT ----------
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
		player_facing = Facing.UP
	elif Input.is_action_pressed("move_down"):
		direction.y += 1
		player_facing = Facing.DOWN

	if Input.is_action_pressed("move_right"):
		direction.x += 1
		player_facing = Facing.RIGHT
	elif Input.is_action_pressed("move_left"):
		direction.x -= 1
		player_facing = Facing.LEFT

	# ---------- JOYSTICK INPUT ----------
	var joy_vector = joystick.get_vector()
	if joy_vector.length() > 0.1:
		direction = joy_vector
		# auto-update facing
		if abs(joy_vector.x) > abs(joy_vector.y):
			player_facing = Facing.RIGHT if joy_vector.x > 0 else Facing.LEFT
		else:
			player_facing = Facing.DOWN if joy_vector.y > 0 else Facing.UP

	# ---------- SPRINT ----------
	if Input.is_action_pressed("sprint"):
		sprint_multiplier = sprint_increase
		sprinting = true
	else:
		sprint_multiplier = 1.0
		sprinting = false

	# normalize
	direction = direction.normalized()

	# movement
	velocity = direction * move_speed * sprint_multiplier
	move_and_slide()
