extends Control

@onready var new_game: Button = $NewGame
@onready var load_game: Button = $LoadGame
@onready var option: Button = $Option

func _ready():
	new_game.pressed.connect(_on_newgame)
	load_game.pressed.connect(_on_loadgame)
	option.pressed.connect(_on_option)
	
func _on_newgame():
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_loadgame():
	pass
	
func _on_option():
	pass
