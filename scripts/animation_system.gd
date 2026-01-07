extends Node2D

@export var player_controller : PlayerController
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var default_animation_speed

func _ready():
	default_animation_speed = animated_sprite_2d.speed_scale

@warning_ignore("unused_parameter")
func _process(delta):
	if player_controller.velocity.length() > 0.0:
		#play movement animations
		if player_controller.player_facing == player_controller.Facing.DOWN:
			animated_sprite_2d.play("walk_down")
		elif player_controller.player_facing == player_controller.Facing.UP:
			animated_sprite_2d.play("walk_up")
		elif player_controller.player_facing == player_controller.Facing.RIGHT:
			animated_sprite_2d.play("walk_right")
		elif player_controller.player_facing == player_controller.Facing.LEFT:
			animated_sprite_2d.play("walk_left")
			
		if player_controller.sprinting:
			animated_sprite_2d.speed_scale = default_animation_speed + player_controller.sprint_increase * 0.5
		else:
			animated_sprite_2d.speed_scale = default_animation_speed
	else:
		#play idle animations
		if player_controller.player_facing == player_controller.Facing.DOWN:
			animated_sprite_2d.play("idle_down")
		elif player_controller.player_facing == player_controller.Facing.UP:
			animated_sprite_2d.play("idle_up")
		elif player_controller.player_facing == player_controller.Facing.RIGHT:
			animated_sprite_2d.play("idle_right")
		elif player_controller.player_facing == player_controller.Facing.LEFT:
			animated_sprite_2d.play("idle_left")
		animated_sprite_2d.speed_scale = default_animation_speed
