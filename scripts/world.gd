extends Node2D

@export var noise_texture: NoiseTexture2D
var noise: Noise
const CHUNK_SIZE = 48
@export var RENDER_DISTANCE = 1
var loaded_chunks = {} # stores loaded chunk coords → true
var world_data = {} # stores world tile data (noise values)

@onready var world_grid: TileMapLayer = $WorldGrid
@onready var display_grid: TileMapLayer = $DisplayGrid
@onready var trees: TileMapLayer = $trees
@onready var player: Node2D = $player  # Moved here for proper initialization

var world_source_id: int = 0

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

func _ready() -> void:
	if noise_texture == null:
		noise_texture = NoiseTexture2D.new()
		noise_texture.noise = FastNoiseLite.new()
	
	if world_seed == 0:
		world_seed = generate_signed_16_digit_seed()
	print("Using seed: ", world_seed)
	
	noise_texture.noise.seed = world_seed
	noise = noise_texture.noise
	
	# Setup Z-index layers
	setup_z_index()
	
	load_initial_chunks()

func setup_z_index() -> void:
	# Set up Z-index for proper depth sorting
	# Lower numbers = behind, higher numbers = in front
	world_grid.z_index = -10  # Background terrain
	display_grid.z_index = -5  # Display layer
	player.z_index = 0         # Player at default level
	trees.z_index = 5          # Trees initially behind player
	
	# Enable Y-sorting if you want proper depth based on Y position
	# player.y_sort_enabled = true  # Uncomment if your player is a Sprite2D

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
	
	# Generate slightly larger area to avoid edge gaps
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
	
	# Place trees after terrain is set
	place_trees_in_chunk(cx, cy)

func generate_display_chunk(cx: int, cy: int) -> void:
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
		update_z_index()

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
	
	# Unload distant chunks
	for old_key in loaded_chunks.keys():
		if not new_loaded_chunks.has(old_key):
			remove_chunk(old_key)
			loaded_chunks.erase(old_key)

func remove_chunk(chunk_coord: Vector2i) -> void:
	var start_x = chunk_coord.x * CHUNK_SIZE
	var start_y = chunk_coord.y * CHUNK_SIZE
	
	for x in range(start_x, start_x + CHUNK_SIZE):
		for y in range(start_y, start_y + CHUNK_SIZE):
			world_grid.set_cell(Vector2i(x, y), -1)
			display_grid.set_cell(Vector2i(x, y), -1)
			trees.set_cell(Vector2i(x, y), -1)  # Clear trees too
	
	# Remove tree positions from storage
	for x in range(start_x, start_x + CHUNK_SIZE):
		for y in range(start_y, start_y + CHUNK_SIZE):
			var pos = Vector2i(x, y)
			if tree_positions.has(pos):
				tree_positions.erase(pos)

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
	
	return [gs, Vector2i(2,1)]  # Fallback to basic grass

# Simple tree placement (single tile trees)
func place_trees_in_chunk(cx: int, cy: int) -> void:
	var start_x = cx * CHUNK_SIZE
	var start_y = cy * CHUNK_SIZE
	
	for x in range(start_x, start_x + CHUNK_SIZE):
		for y in range(start_y, start_y + CHUNK_SIZE):
			var noise_val = world_data.get(Vector2i(x, y), 0.0)
			
			# Only place trees on grass tiles
			if noise_val >= -0.045 and noise_val < 0.25:
				# Deterministic random chance for tree placement
				var tree_chance = noise.get_noise_2d(x + 5000, y + 5000)
				
				if tree_chance > 0.6:
					# Choose which tree variation to place
					var tree_variant_noise = noise.get_noise_2d(x + 10000, y + 10000)
					var tree_atlas_coord: Vector2i
					
					if tree_variant_noise > 0:
						tree_atlas_coord = tree1_atlas  # tree1
					else:
						tree_atlas_coord = tree2_atlas  # tree2
					
					# Place the tree
					trees.set_cell(Vector2i(x, y), tree_source_id, tree_atlas_coord)
					
					# Store tree position for Z-index updates
					tree_positions.append(Vector2i(x, y))

# Update Z-index based on player position relative to trees
func update_z_index() -> void:
	if player == null:
		return
	
	# Get player's tile position (center of player)
	@warning_ignore("unused_variable")
	var player_tile_pos = Vector2i(player.position / tile_size)
	
	# Check all tree positions
	var player_behind_tree = false
	
	for tree_pos in tree_positions:
		# Convert tree position to world pixel position (center of tile)
		var tree_world_pos = Vector2(
			tree_pos.x * tile_size + tile_size / 2.0,
			tree_pos.y * tile_size + tile_size / 2.0
		)
		
		# If player is below (higher Y value) and horizontally aligned with tree
		# Player is "behind" the tree if their Y position is greater than tree's Y position
		if player.position.y > tree_world_pos.y and \
		   abs(player.position.x - tree_world_pos.x) < tile_size * 1.5:  # Within reasonable X distance
			player_behind_tree = true
			break
	
	# Update tree Z-index based on player position
	if player_behind_tree:
		# Player is behind tree - tree should be in front
		trees.z_index = 10  # Higher than player
	else:
		# Player is in front of tree - tree should be behind
		trees.z_index = 5   # Lower than player

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
