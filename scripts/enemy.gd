extends CharacterBody2D

@export var speed: float = 100.0
@export var health: int = 100
@export var knockback_force: float = 200.0
@export var wander_radius: float = 300.0
@export var attack_damage: int = 10
@export var attack_interval: float = 1.0   # seconds between attacks

var player: Node2D = null
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking: bool = false
var attack_timer: Timer
var wander_timer: Timer

func _ready():
	# Connect signals
	$DetectionArea.body_entered.connect(_on_detection_entered)
	$DetectionArea.body_exited.connect(_on_detection_exited)
	$AttackingArea.body_entered.connect(_on_attack_entered)
	$AttackingArea.body_exited.connect(_on_attack_exited)

	# Attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_do_attack)

	# Wander timer
	wander_timer = Timer.new()
	wander_timer.wait_time = 2.0
	wander_timer.one_shot = false
	add_child(wander_timer)
	wander_timer.timeout.connect(_on_wander_timer)
	wander_timer.start()

	# Initial wander target
	wander_randomly()

@warning_ignore("unused_parameter")
func _physics_process(delta):
	if player and not is_attacking:
		# Chase player
		navigation.target_position = player.global_position
		if navigation.is_target_reachable() and not navigation.is_navigation_finished():
			var next_point = navigation.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			_play_walk_animation(direction)
		else:
			velocity = Vector2.ZERO
			_play_idle_animation(Vector2.ZERO)
	elif not player and not is_attacking:
		# Wander
		if navigation.is_target_reachable() and not navigation.is_navigation_finished():
			var next_point = navigation.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			velocity = direction * speed * 0.5
			move_and_slide()
			_play_walk_animation(direction)
		else:
			velocity = Vector2.ZERO
			_play_idle_animation(Vector2.ZERO)

func wander_randomly():
	var random_offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	var target = global_position + random_offset
	navigation.target_position = target

func _on_wander_timer():
	if not player and not is_attacking:
		wander_randomly()

func _on_detection_entered(body):
	if body.is_in_group("Player"):
		player = body
		navigation.target_position = player.global_position

func _on_detection_exited(body):
	if body == player:
		player = null
		wander_randomly()

func _on_attack_entered(body):
	if body.is_in_group("Player"):
		is_attacking = true
		velocity = Vector2.ZERO
		sprite.play("attack_down")   # adjust direction if needed
		attack_timer.start()

func _on_attack_exited(body):
	if body == player:
		is_attacking = false
		attack_timer.stop()
		wander_randomly()

func _do_attack():
	if player and is_attacking:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
		sprite.play("attack_down")

func take_damage(amount: int, from: Vector2):
	health -= amount
	if health > 0:
		velocity = (global_position - from).normalized() * knockback_force
		sprite.play("hurt")
	else:
		die()

func die():
	sprite.play("death_down")
	queue_free()

# --- Helper functions for directional animations ---
func _play_walk_animation(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if direction.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func _play_idle_animation(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play("idle_right")
		else:
			sprite.play("idle_left")
	else:
		if direction.y > 0:
			sprite.play("idle_down")
		else:
			sprite.play("idle_up")
