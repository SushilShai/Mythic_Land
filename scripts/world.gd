extends Node2D

@export var noise_texture: NoiseTexture2D
var noise: Noise

var width: int = 200
var height: int = 200

@onready var world_grid: TileMapLayer = $WorldGrid
@onready var display_grid: TileMapLayer = $DisplayGrid

var world_source_id: int = 0

# Atlas coordinates for world tiles
var grass_atlas = Vector2i(0, 0)
var sand_atlas = Vector2i(0, 1)
var water_atlas = Vector2i(1, 1)
var cliff_atlas = Vector2i(1,0)

var noise_val_arr = []

@export var world_seed: int = 0
var tile_size: int = 16

# --------------------------
# Custom mapping for display tiles
var sw=0
var gs=1
var g3=2
var s3=6
var gw=3
var w3=4
var clf=5
# Returns [source_id, atlas_coords]
# --------------------------
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

	#Grass on water
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
	
	# Grass on sand
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
	
	#Grass 3 tile combo
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

	# Sand 3 combo
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
	
#	Water 3 combo
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
	
#	cliffs
	["Grass","Grass","Cliff","Grass"]:[clf, Vector2i(0,0)],
	["Grass","Cliff","Grass","Cliff"]:[clf, Vector2i(1,0)],
	["Cliff","Grass","Cliff","Cliff"]:[clf, Vector2i(2,0)],
	["Grass","Grass","Cliff","Cliff"]:[clf, Vector2i(3,0)],
	["Cliff","Grass","Grass","Cliff"]:[
		[clf, Vector2i(0,1)],
		[clf,Vector2i(0,2)],
		],
	["Grass","Cliff","Cliff","Cliff"]:[clf, Vector2i(1,1)],
	["Cliff","Cliff","Cliff","Cliff"]:[clf, Vector2i(2,1)],
	["Grass","Cliff","Grass","Grass"]:[
		[clf, Vector2i(0,3)],
		[clf, Vector2i(0,4)],
		],
	["Cliff","Cliff","Grass","Grass"]:[
		[clf, Vector2i(1,3)],
		[clf, Vector2i(1,4)],
		],
	["Cliff","Cliff","Grass","Cliff"]:[
		[clf, Vector2i(2,3)],
		[clf, Vector2i(2,4)],
		],
	["Cliff","Cliff","Cliff","Grass"]:[
		[clf, Vector2i(3,3)],
		[clf, Vector2i(3,4)],
		],
	["Grass","Grass","Grass","Cliff"]:[clf, Vector2i(1,5)],
	["Grass","Cliff","Cliff","Grass"]:[
		[clf, Vector2i(2,5)],
		[clf, Vector2i(2,6)],
		],
	["Cliff","Grass","Grass","Grass"]:[
		[clf, Vector2i(3,5)],
		[clf, Vector2i(3,6)],
		],
	["Cliff","Grass","Cliff","Grass"]:[clf, Vector2i(0,6)],

}

func _ready() -> void:
	if noise_texture == null:
		noise_texture = NoiseTexture2D.new()
		noise_texture.noise = FastNoiseLite.new()
	
	if world_seed == 0:
		world_seed = generate_signed_16_digit_seed()

	print("Using seed: ", world_seed)

	# Set noise seed
	noise_texture.noise.seed = world_seed
	noise = noise_texture.noise

	# Generate world & display grids
	generate_world()
	generate_display_grid()


# ----------------------
# Generate World Grid
# ----------------------
func generate_world() -> void:
	@warning_ignore("integer_division")
	for x in range(-width/2, width/2):
		@warning_ignore("integer_division")
		for y in range(-height/2, height/2):
			var noise_val = noise.get_noise_2d(x, y)
			noise_val_arr.append(noise_val)

			if noise_val < -0.1:
				world_grid.set_cell(Vector2i(x, y), world_source_id, water_atlas)
			elif noise_val >= -0.1 and noise_val < -0.0450:
				world_grid.set_cell(Vector2i(x, y), world_source_id, sand_atlas)
			elif noise_val >= -0.0450 and noise_val < 0.25:
				world_grid.set_cell(Vector2i(x, y), world_source_id, grass_atlas)
			elif noise_val >= 0.25 and noise_val < 0.3:
				world_grid.set_cell(Vector2i(x, y), world_source_id, cliff_atlas)
			else: 
				world_grid.set_cell(Vector2i(x, y), world_source_id, cliff_atlas)



# ----------------------
# Generate Display Grid
# ----------------------
func generate_display_grid() -> void:
	display_grid.clear()
	@warning_ignore("integer_division")
	display_grid.position = Vector2(tile_size/2, tile_size/2) # offset half tile

	@warning_ignore("integer_division")
	for dx in range(-width/2, width/2 - 1):
		@warning_ignore("integer_division")
		for dy in range(-height/2, height/2 - 1):
			var world_tiles = get_world_tiles_under_display(dx, dy)
			var tile_data = pick_custom_display_tile(world_tiles)
			display_grid.set_cell(Vector2i(dx, dy), tile_data[0], tile_data[1])
				
			# Cliff column placement
			if tile_data[0] == clf and tile_data.size() == 3:
				var top_atlas = tile_data[1]
				var bottom_atlas = tile_data[2]

				# top cliff tile (above)
				display_grid.set_cell(Vector2i(dx, dy - 1), clf, top_atlas)
				# bottom cliff tile
				display_grid.set_cell(Vector2i(dx, dy), clf, bottom_atlas)
			else:
				# Normal placement
				display_grid.set_cell(Vector2i(dx, dy), tile_data[0], tile_data[1])

# ----------------------
# Get 4 world tiles under a display tile
# ----------------------
func get_world_tiles_under_display(dx: int, dy: int) -> Array[Vector2i]:
	return [
		Vector2i(dx, dy),         # top-left
		Vector2i(dx + 1, dy),     # top-right
		Vector2i(dx, dy + 1),     # bottom-left
		Vector2i(dx + 1, dy + 1)  # bottom-right
	]


# ----------------------
# Pick display tile based on custom mapping
# Returns [source_id, atlas_coords]
# ----------------------
func pick_custom_display_tile(world_tiles: Array[Vector2i]) -> Array:
	var tile_types: Array[String] = []

	for wt in world_tiles:
		var atlas = world_grid.get_cell_atlas_coords(wt)
		if atlas == grass_atlas:
			tile_types.append("Grass")
		elif atlas == sand_atlas:
			tile_types.append("Sand")
		elif atlas == water_atlas:
			tile_types.append("Water")
		elif atlas == cliff_atlas:
			tile_types.append("Cliff")
		else:
			tile_types.append("Unknown")

	if display_tile_map.has(tile_types):
		var data = display_tile_map[tile_types]
		# Handle special "column cliff" case
		if typeof(data[0]) == TYPE_ARRAY and data.size() == 2:
			# data looks like [[clf, top_atlas], [clf, bottom_atlas]]
			return [clf, data[0][1], data[1][1]]
		else:
			return data
	else:
		return [gs, grass_atlas]  # default fallback


# ----------------------
# Utility: Generate signed 16-digit seed
# ----------------------
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
