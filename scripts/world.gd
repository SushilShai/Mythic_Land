extends Node2D

@export var noise_texture: NoiseTexture2D
var noise: Noise
const CHUNK_SIZE = 48
@export var RENDER_DISTANCE = 1
var loaded_chunks = {} # stores loaded chunk coords → true
var world_data = {} # stores world tile data (noise values)

@onready var world_grid: TileMapLayer = $WorldGrid
@onready var display_grid: TileMapLayer = $DisplayGrid
@onready var trees: TileMapLayer = $Trees
@onready var player: Node2D = $player  # Moved here for proper initialization


#enemy
var EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_area: Rect2 = Rect2(Vector2(0,0), Vector2(1024,768)) # adjust to your map size
@export var max_enemies_per_chunk: int = 5

const MAX_ENEMIES = 10
var spawned_enemies: Array = []

var terrain_grid: Array = []
var object_grid: Array = []


var world_source_id: int = 0

var nav_map = NavigationServer2D.map_create()
var chunk_nav_regions = {}

# Atlas coordinates for world tiles (base terrain)
var grass_atlas = Vector2i(0, 0)
var sand_atlas = Vector2i(0, 1)
var water_atlas = Vector2i(1, 1)
var cliff_atlas = Vector2i(1, 0)

# Atlas coordinates for trees - two variations
var tree1_atlas: Vector2i = Vector2i(0, 0)  # tree1
var tree2_atlas: Vector2i = Vector2i(2, 0)  # tree2
var tree_source_id = 0  # Usually 0, change if using multiple sources

@export var world_seed: int = 0
var tile_size: int = 16

# Tree positions storage for Z-index updates
var tree_positions = []

# Custom display tile mapping (unchanged – your autotile logic)
var sw = 0
var gs = 1
var g3 = 2
var s3 = 6
var gw = 3
var w3 = 4
var clf = 5

var display_tile_map = {
	# Full tiles
	["Grass","Grass","Grass","Grass"]: [gs, Vector2i(2,1)],
	["Sand","Sand","Sand","Sand"]: [sw, Vector2i(2,1)],
	["Water","Water","Water","Water"]: [gw, Vector2i(0,3)],
	
	# Sand on Water
	["Water","Water","Sand","Water"]: [sw, Vector2i(0,0)],
	["Water","Sand","Water","Sand"]: [sw, Vector2i(1,0)],
	["Sand","Water","Sand","Sand"]: [sw, Vector2i(2,0)],
	["Water","Water","Sand","Sand"]: [sw, Vector2i(3,0)],
	["Sand","Water","Water","Sand"]: [sw, Vector2i(0,1)],
	["Water","Sand","Sand","Sand"]: [sw, Vector2i(1,1)],
	["Sand","Sand","Sand","Water"]: [sw, Vector2i(3,1)],
	["Water","Sand","Water","Water"]: [sw, Vector2i(0,2)],
	["Sand","Sand","Water","Water"]: [sw, Vector2i(1,2)],
	["Sand","Sand","Water","Sand"]: [sw, Vector2i(2,2)],
	["Sand","Water","Sand","Water"]: [sw, Vector2i(3,2)],
	["Water","Water","Water","Sand"]: [sw, Vector2i(1,3)],
	["Water","Sand","Sand","Water"]: [sw, Vector2i(2,3)],
	["Sand","Water","Water","Water"]: [sw, Vector2i(3,3)],
	
	# Grass on Water
	["Water","Water","Grass","Water"]: [gw, Vector2i(0,0)],
	["Water","Grass","Water","Grass"]: [gw, Vector2i(1,0)],
	["Grass","Water","Grass","Grass"]: [gw, Vector2i(2,0)],
	["Water","Water","Grass","Grass"]: [gw, Vector2i(3,0)],
	["Grass","Water","Water","Grass"]: [gw, Vector2i(0,1)],
	["Water","Grass","Grass","Grass"]: [gw, Vector2i(1,1)],
	["Grass","Grass","Grass","Water"]: [gw, Vector2i(3,1)],
	["Water","Grass","Water","Water"]: [gw, Vector2i(0,2)],
	["Grass","Grass","Water","Water"]: [gw, Vector2i(1,2)],
	["Grass","Grass","Water","Grass"]: [gw, Vector2i(2,2)],
	["Grass","Water","Grass","Water"]: [gw, Vector2i(3,2)],
	["Water","Water","Water","Grass"]: [gw, Vector2i(1,3)],
	["Water","Grass","Grass","Water"]: [gw, Vector2i(2,3)],
	["Grass","Water","Water","Water"]: [gw, Vector2i(3,3)],
	
	# Grass on Sand
	["Sand","Sand","Grass","Sand"]: [gs, Vector2i(0,0)],
	["Sand","Grass","Sand","Grass"]: [gs, Vector2i(1,0)],
	["Grass","Sand","Grass","Grass"]: [gs, Vector2i(2,0)],
	["Sand","Sand","Grass","Grass"]: [gs, Vector2i(3,0)],
	["Grass","Sand","Sand","Grass"]: [gs, Vector2i(0,1)],
	["Sand","Grass","Grass","Grass"]: [gs, Vector2i(1,1)],
	["Grass","Grass","Grass","Sand"]: [gs, Vector2i(3,1)],
	["Sand","Grass","Sand","Sand"]: [gs, Vector2i(0,2)],
	["Grass","Grass","Sand","Sand"]: [gs, Vector2i(1,2)],
	["Grass","Grass","Sand","Grass"]: [gs, Vector2i(2,2)],
	["Grass","Sand","Grass","Sand"]: [gs, Vector2i(3,2)],
	["Sand","Sand","Sand","Grass"]: [gs, Vector2i(1,3)],
	["Sand","Grass","Grass","Sand"]: [gs, Vector2i(2,3)],
	["Grass","Sand","Sand","Sand"]: [gs, Vector2i(3,3)],
	
	# 3-tile combos (Grass/Sand/Water transitions)
	["Grass","Grass","Sand","Water"]: [g3, Vector2i(0,0)],
	["Grass","Grass","Water","Sand"]: [g3, Vector2i(1,0)],
	["Grass","Water","Sand","Grass"]: [g3, Vector2i(2,0)],
	["Water","Grass","Grass","Sand"]: [g3, Vector2i(3,0)],
	["Sand","Water","Grass","Grass"]: [g3, Vector2i(0,1)],
	["Water","Sand","Grass","Grass"]: [g3, Vector2i(1,1)],
	["Sand","Grass","Grass","Water"]: [g3, Vector2i(2,1)],
	["Grass","Sand","Water","Grass"]: [g3, Vector2i(3,1)],
	["Grass","Sand","Grass","Water"]: [g3, Vector2i(0,2)],
	["Sand","Grass","Water","Grass"]: [g3, Vector2i(1,2)],
	["Grass","Water","Grass","Sand"]: [g3, Vector2i(2,2)],
	["Water","Grass","Sand","Grass"]: [g3, Vector2i(3,2)],
	
	["Sand","Sand","Grass","Water"]: [s3, Vector2i(0,0)],
	["Sand","Sand","Water","Grass"]: [s3, Vector2i(1,0)],
	["Sand","Water","Grass","Sand"]: [s3, Vector2i(2,0)],
	["Water","Sand","Sand","Grass"]: [s3, Vector2i(3,0)],
	["Grass","Water","Sand","Sand"]: [s3, Vector2i(0,1)],
	["Water","Grass","Sand","Sand"]: [s3, Vector2i(1,1)],
	["Grass","Sand","Sand","Water"]: [s3, Vector2i(2,1)],
	["Sand","Grass","Water","Sand"]: [s3, Vector2i(3,1)],
	["Sand","Grass","Sand","Water"]: [s3, Vector2i(0,2)],
	["Grass","Sand","Water","Sand"]: [s3, Vector2i(1,2)],
	["Sand","Water","Sand","Grass"]: [s3, Vector2i(2,2)],
	["Water","Sand","Grass","Sand"]: [s3, Vector2i(3,2)],
	
	["Water","Water","Sand","Grass"]: [w3, Vector2i(0,0)],
	["Water","Water","Grass","Sand"]: [w3, Vector2i(1,0)],
	["Water","Grass","Sand","Water"]: [w3, Vector2i(2,0)],
	["Grass","Water","Water","Sand"]: [w3, Vector2i(3,0)],
	["Sand","Grass","Water","Water"]: [w3, Vector2i(0,1)],
	["Grass","Sand","Water","Water"]: [w3, Vector2i(1,1)],
	["Sand","Water","Water","Grass"]: [w3, Vector2i(2,1)],
	["Water","Sand","Grass","Water"]: [w3, Vector2i(3,1)],
	["Water","Sand","Water","Grass"]: [w3, Vector2i(0,2)],
	["Sand","Water","Grass","Water"]: [w3, Vector2i(1,2)],
	["Water","Grass","Water","Sand"]: [w3, Vector2i(2,2)],
	["Grass","Water","Sand","Water"]: [w3, Vector2i(3,2)],
	
	# Cliffs (some use multi-tile placement)
	["Grass","Grass","Cliff","Grass"]: [clf, Vector2i(0,0)],
	["Grass","Cliff","Grass","Cliff"]: [clf, Vector2i(1,0)],
	["Cliff","Grass","Cliff","Cliff"]: [clf, Vector2i(2,0)],
	["Grass","Grass","Cliff","Cliff"]: [clf, Vector2i(3,0)],
	["Cliff","Grass","Grass","Cliff"]: [[clf, Vector2i(0,1)], [clf, Vector2i(0,2)]],
	["Grass","Cliff","Cliff","Cliff"]: [clf, Vector2i(1,1)],
	["Cliff","Cliff","Cliff","Cliff"]: [clf, Vector2i(2,1)],
	["Grass","Cliff","Grass","Grass"]: [[clf, Vector2i(0,3)], [clf, Vector2i(0,4)]],
	["Cliff","Cliff","Grass","Grass"]: [[clf, Vector2i(1,3)], [clf, Vector2i(1,4)]],
	["Cliff","Cliff","Grass","Cliff"]: [[clf, Vector2i(2,3)], [clf, Vector2i(2,4)]],
	["Cliff","Cliff","Cliff","Grass"]: [[clf, Vector2i(3,3)], [clf, Vector2i(3,4)]],
	["Grass","Grass","Grass","Cliff"]: [clf, Vector2i(1,5)],
	["Grass","Cliff","Cliff","Grass"]: [[clf, Vector2i(2,5)], [clf, Vector2i(2,6)]],
	["Cliff","Grass","Grass","Grass"]: [[clf, Vector2i(3,5)], [clf, Vector2i(3,6)]],
	["Cliff","Grass","Cliff","Grass"]: [clf, Vector2i(0,6)],
}

# Load the trees.gd script
var tree_manager = preload("res://scripts/trees.gd").new()

func _ready() -> void:
	if noise_texture == null:
		noise_texture = NoiseTexture2D.new()
		noise_texture.noise = FastNoiseLite.new()

	if world_seed == 0:
		world_seed = generate_signed_16_digit_seed()
	print("Using seed: ", world_seed)

	if RENDER_DISTANCE == null:
		RENDER_DISTANCE = 1

	noise_texture.noise.seed = world_seed
	noise = noise_texture.noise

	setup_z_index()
	load_initial_chunks()
	
	var respawn_timer = Timer.new()
	respawn_timer.wait_time = 5.0   # spawn every 5 seconds
	respawn_timer.autostart = true
	respawn_timer.one_shot = false
	add_child(respawn_timer)
	respawn_timer.timeout.connect(_on_respawn_timer)


func _on_respawn_timer():
	# Pick the chunk around the player
	var cx = int(floor(player.global_position.x / CHUNK_SIZE))
	var cy = int(floor(player.global_position.y / CHUNK_SIZE))
	
	# Spawn enemies dynamically in nearby chunks
	for x in range(cx - 1, cx + 2):
		for y in range(cy - 1, cy + 2):
			place_enemies_dynamically(x, y)

func setup_z_index() -> void:
	world_grid.z_index = -10
	display_grid.z_index = -5
	player.z_index = 0
	#trees.z_index = 10
	# player.y_sort_enabled = true  # Uncomment if needed


func load_initial_chunks() -> void:
	for cx in range(-1, 2):
		for cy in range(-1, 2):
			var key = Vector2i(cx, cy)
			if loaded_chunks.has(key):
				continue
			loaded_chunks[key] = true
			generate_world_chunk(cx, cy)
			generate_display_chunk(cx, cy)


func generate_world_chunk(cx: int, cy: int) -> void:
	var start_x = cx * CHUNK_SIZE
	var start_y = cy * CHUNK_SIZE
	
	for x in range(start_x, start_x + CHUNK_SIZE + 3):
		for y in range(start_y, start_y + CHUNK_SIZE + 3):
			var noise_val = noise.get_noise_2d(x, y)
			world_data[Vector2i(x, y)] = noise_val
			
			if noise_val < -0.1:
				world_grid.set_cell(Vector2i(x, y), world_source_id, water_atlas)
			elif noise_val < -0.045:
				world_grid.set_cell(Vector2i(x, y), world_source_id, sand_atlas)
			elif noise_val < 0.25:
				world_grid.set_cell(Vector2i(x, y), world_source_id, grass_atlas)
			else:
				world_grid.set_cell(Vector2i(x, y), world_source_id, cliff_atlas)


func generate_display_chunk(cx: int, cy: int) -> void:
	print("Generating display chunk for: (", cx, ", ", cy, ")")
	var start_x = cx * CHUNK_SIZE
	var start_y = cy * CHUNK_SIZE
	
	for dx in range(start_x, start_x + CHUNK_SIZE):
		for dy in range(start_y, start_y + CHUNK_SIZE):
			var world_tiles = get_world_tiles_under_display(dx, dy)
			var tile_data = pick_custom_display_tile(world_tiles)
			
			if tile_data[0] == clf and tile_data.size() == 3:
				display_grid.set_cell(Vector2i(dx, dy - 1), clf, tile_data[1])
				display_grid.set_cell(Vector2i(dx, dy), clf, tile_data[2])
			else:
				display_grid.set_cell(Vector2i(dx, dy), tile_data[0], tile_data[1])
	
	tree_manager.place_trees_dynamically(cx, cy)
	place_enemies_dynamically(cx, cy)


func place_enemies_dynamically(cx: int, cy: int) -> void:
	if EnemyScene == null or player == null:
		return
	
	# ✅ Stop if we already have 10 enemies
	if spawned_enemies.size() >= MAX_ENEMIES:
		return

	var start_x = cx * CHUNK_SIZE
	var start_y = cy * CHUNK_SIZE
	
	var min_distance = 20 * tile_size

	# Try to spawn until we hit the global cap
	while spawned_enemies.size() < MAX_ENEMIES:
		var enemy_instance = EnemyScene.instantiate()
		var spawn_pos: Vector2
		var tries = 0
		var valid = false

		while tries < 50:
			var random_x = randf_range(start_x - 512, start_x + CHUNK_SIZE + 512) # random in all directions
			var random_y = randf_range(start_y - 512, start_y + CHUNK_SIZE + 512)
			spawn_pos = Vector2(random_x, random_y)

			if spawn_pos.distance_to(player.global_position) < min_distance:
				tries += 1
				continue

			# Optional: only spawn on grass
			var noise_val = world_data.get(Vector2i(int(random_x), int(random_y)), 0.0)
			if noise_val < -0.045 or noise_val >= 0.25:
				tries += 1
				continue

			valid = true
			break

		if valid:
			enemy_instance.global_position = spawn_pos
			add_child(enemy_instance)
			spawned_enemies.append(enemy_instance)
			enemy_instance.tree_exited.connect(_on_enemy_dead.bind(enemy_instance))
			print("Spawned enemy at: ", spawn_pos)

func _on_enemy_dead(enemy_instance: Node) -> void:
	# Remove from tracking
	if spawned_enemies.has(enemy_instance):
		spawned_enemies.erase(enemy_instance)

	# Respawn a new one at least 20 tiles away
	var new_enemy = EnemyScene.instantiate()
	var spawn_pos: Vector2
	var tries = 0
	var valid = false
	var min_distance = 20 * tile_size

	while tries < 50:
		var random_x = randf_range(player.global_position.x - 512, player.global_position.x + 512)
		var random_y = randf_range(player.global_position.y - 512, player.global_position.y + 512)
		spawn_pos = Vector2(random_x, random_y)

		if spawn_pos.distance_to(player.global_position) < min_distance:
			tries += 1
			continue

		valid = true
		break

	if valid:
		new_enemy.global_position = spawn_pos
		add_child(new_enemy)
		spawned_enemies.append(new_enemy)
		new_enemy.tree_exited.connect(_on_enemy_dead.bind(new_enemy))
		print("Respawned enemy at: ", spawn_pos)


func get_world_tiles_under_display(dx: int, dy: int) -> Array[Vector2i]:
	return [
		Vector2i(dx, dy),
		Vector2i(dx + 1, dy),
		Vector2i(dx, dy + 1),
		Vector2i(dx + 1, dy + 1)
	]


func _process(_delta):
	if player != null:
		update_chunks(player.position)


func update_chunks(player_pos: Vector2) -> void:
	var tile_pos = player_pos / tile_size
	var cx = int(floor(tile_pos.x / CHUNK_SIZE))
	var cy = int(floor(tile_pos.y / CHUNK_SIZE))
	
	var new_loaded_chunks = {}
	
	for x in range(cx - RENDER_DISTANCE, cx + RENDER_DISTANCE + 1):
		for y in range(cy - RENDER_DISTANCE, cy + RENDER_DISTANCE + 1):
			var key = Vector2i(x, y)
			new_loaded_chunks[key] = true
			
			if not loaded_chunks.has(key):
				loaded_chunks[key] = true
				generate_world_chunk(x, y)
				generate_display_chunk(x, y)
				generate_nav_chunk(x, y)
				tree_manager.place_trees_dynamically(x, y)
	
	for old_key in loaded_chunks.keys():
		if not new_loaded_chunks.has(old_key):
			remove_chunk(old_key)
			loaded_chunks.erase(old_key)

func generate_nav_chunk(x: int, y: int) -> void:
	var nav_region = NavigationRegion2D.new()

	# Build a rectangle polygon for the chunk
	var start = Vector2(x * CHUNK_SIZE * tile_size, y * CHUNK_SIZE * tile_size)
	var size = Vector2(CHUNK_SIZE * tile_size, CHUNK_SIZE * tile_size)
	var rect_points = PackedVector2Array([
		start,
		start + Vector2(size.x, 0),
		start + size,
		start + Vector2(0, size.y)
	])

	var nav_poly = NavigationPolygon.new()
	nav_poly.add_outline(rect_points)
	nav_poly.make_polygons_from_outlines()

	nav_region.navigation_polygon = nav_poly

	# ✅ Add region under NavigationRoot
	add_child(nav_region)

	# Store reference for cleanup
	chunk_nav_regions[Vector2i(x, y)] = nav_region


func remove_chunk(chunk_coord: Vector2i) -> void:
	var start_x = chunk_coord.x * CHUNK_SIZE
	var start_y = chunk_coord.y * CHUNK_SIZE
	
	for x in range(start_x, start_x + CHUNK_SIZE):
		for y in range(start_y, start_y + CHUNK_SIZE):
			world_grid.set_cell(Vector2i(x, y), -1)
			display_grid.set_cell(Vector2i(x, y), -1)
			trees.set_cell(Vector2i(x, y), -1)
	
	for x in range(start_x, start_x + CHUNK_SIZE):
		for y in range(start_y, start_y + CHUNK_SIZE):
			var pos = Vector2i(x, y)
			if tree_positions.has(pos):
				tree_positions.erase(pos)
	 # Remove nav region
	if chunk_nav_regions.has(chunk_coord):
		var region: NavigationRegion2D = chunk_nav_regions[chunk_coord]
		region.queue_free()   # ✅ free the node directly
		chunk_nav_regions.erase(chunk_coord)



func pick_custom_display_tile(world_tiles: Array[Vector2i]) -> Array:
	var tile_types: Array[String] = []
	
	for wt in world_tiles:
		var noise_val = world_data.get(wt, 0.0)
		@warning_ignore("unused_variable")
		var atlas: Vector2i
		
		if noise_val < -0.1:
			atlas = water_atlas
			tile_types.append("Water")
		elif noise_val < -0.045:
			atlas = sand_atlas
			tile_types.append("Sand")
		elif noise_val < 0.25:
			atlas = grass_atlas
			tile_types.append("Grass")
		else:
			atlas = cliff_atlas
			tile_types.append("Cliff")
	
	if display_tile_map.has(tile_types):
		var data = display_tile_map[tile_types]
		if data is Array and data.size() > 0 and data[0] is Array:
			return [clf, data[0][1], data[1][1]]
		else:
			return data
	
	return [gs, Vector2i(2,1)]


func generate_signed_16_digit_seed() -> int:
	var s = ""
	for i in range(16):
		var digit = randi() % 10
		if i == 0 and digit == 0:
			digit = 1 + randi() % 9
		s += str(digit)
	var number = int(s)
	if randi() % 2 == 0:
		number *= -1
	return number
