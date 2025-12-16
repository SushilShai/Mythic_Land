extends CharacterBody2D
class_name PlayerController

# ---------------- EXPORT VARIABLES ----------------
@export var move_speed: float = 150.0
@export var sprint_increase: float = 2.0

# ---------------- NODE REFERENCES ----------------
@onready var joystick: Control = $joystick
@onready var marker: TileMapLayer = $"../marker"
@onready var display_grid: TileMapLayer = $"../DisplayGrid"

# ---------------- STATE VARIABLES ----------------
var direction: Vector2 = Vector2.ZERO
var sprinting: bool = false
var sprint_multiplier: float = 1.0
var click_position: Vector2 = Vector2.ZERO
var click_cell: Vector2i = Vector2i.ZERO

enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing: Facing = Facing.DOWN

# ---------------- READY ----------------
func _ready() -> void:
	click_position = position

# ---------------- PHYSICS PROCESS ----------------
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	direction = Vector2.ZERO

	# ---------- TILE HIGHLIGHT ----------
	var mouse_pos: Vector2 = get_global_mouse_position()
	var hover_cell: Vector2i = display_grid.local_to_map(mouse_pos)

		# Clear marker layer each frame
	marker.clear()

	# Highlight hovered cell (atlas_coords (0,0) = hover highlight)
	marker.set_cell(hover_cell, 0, Vector2i(0,0), 0)

	# If click target exists, highlight it differently (atlas_coords (1,0) = click target)
	if click_position != position:
		click_cell = display_grid.local_to_map(click_position)
		marker.set_cell(click_cell, 0, Vector2i(1,0), 0)


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

	# Normalize keyboard diagonal movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# ---------- JOYSTICK INPUT ----------
	var joy_vector: Vector2 = joystick.get_vector()
	if joy_vector.length() > 0.1:
		direction = joy_vector.normalized()
		if abs(joy_vector.x) > abs(joy_vector.y):
			player_facing = Facing.RIGHT if joy_vector.x > 0 else Facing.LEFT
		else:
			player_facing = Facing.DOWN if joy_vector.y > 0 else Facing.UP

	# ---------- MOUSE CLICK (only if no key/joystick input) ----------
	if direction == Vector2.ZERO:
		if Input.is_action_just_pressed("left_click"):
			# Snap click position to grid
			var target_cell: Vector2i = display_grid.local_to_map(get_global_mouse_position())
			click_position = display_grid.map_to_local(target_cell)

		if position.distance_to(click_position) > 3:
			direction = (click_position - position).normalized()
			if abs(direction.x) > abs(direction.y):
				player_facing = Facing.RIGHT if direction.x > 0 else Facing.LEFT
			else:
				player_facing = Facing.DOWN if direction.y > 0 else Facing.UP
	else:
		# cancel old click target when keys/joystick are used
		click_position = position

	# ---------- SPRINT ----------
	if Input.is_action_pressed("sprint"):
		sprint_multiplier = sprint_increase
		sprinting = true
	else:
		sprint_multiplier = 1.0
		sprinting = false

	# ---------- MOVEMENT ----------
	velocity = direction * move_speed * sprint_multiplier
	move_and_slide()
