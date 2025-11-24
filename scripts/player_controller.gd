extends CharacterBody2D
class_name PlayerController

@export var move_speed = 15.0
@export var sprint_increase = 1.5

var direction : Vector2
var sprinting = false
var sprin_multiplier = 1.0

enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing : Facing

func _physics_process(delta):
	#Setting the y value of player input
	if Input.is_action_pressed("move_up"):
		direction.y = -1
		player_facing = Facing.UP
	elif Input.is_action_pressed("move_down"):
		direction.y = 1
		player_facing = Facing.DOWN
	else: 
		direction.y = 0
	
	#Setting the y value of player input
	if Input.is_action_pressed("move_right"):
		direction.x = 1
		player_facing = Facing.RIGHT
	elif Input.is_action_pressed("move_left"):
		direction.x = -1
		player_facing = Facing.LEFT
	else:
		direction.x = 0
		
	if Input.is_action_pressed("sprint"):
		sprin_multiplier = sprint_increase
		sprinting = true
	else :
		sprin_multiplier = 1.0
		sprinting = false
		
#	normalized the vector to maintain player speed
	direction = direction.normalized()
	
	velocity = direction * move_speed * delta * 200 * sprin_multiplier
	move_and_slide()
