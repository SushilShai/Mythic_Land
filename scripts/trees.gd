extends Node

const CHUNK_SIZE = 48
const TREE_PROBABILITY = 0.2   # chance to place a tree
const TILE_SIZE = 32           # size of each tile

@onready var trees: TileMapLayer = $"."

var terrain_grid = []   # terrain types ("Grass", "Sand", etc.)
var object_grid = []    # objects ("Tree", null)

func _ready():
	randomize()
	trees.z_index = 10

	# Example initialization (replace with world.gd terrain later)
	terrain_grid.resize(32)
	for x in range(32):
		terrain_grid[x] = []
		for y in range(32):
			terrain_grid[x].append("Grass")

	initialize_grids(32, 32)

func initialize_grids(width: int, height: int) -> void:
	object_grid.resize(width)
	for x in range(width):
		object_grid[x] = []
		for y in range(height):
			object_grid[x].append(null)

func set_terrain_grid(grid: Array) -> void:
	terrain_grid = grid
	initialize_grids(terrain_grid.size(), terrain_grid[0].size())

func place_trees_dynamically(cx: int, cy: int) -> void:
	var start_x = cx * CHUNK_SIZE
	var start_y = cy * CHUNK_SIZE

	for i in range(CHUNK_SIZE * CHUNK_SIZE):
		var x = randi_range(start_x, start_x + CHUNK_SIZE - 1)
		var y = randi_range(start_y, start_y + CHUNK_SIZE - 1)

		if x >= 0 and x < terrain_grid.size() and y >= 0 and y < terrain_grid[x].size():
			if terrain_grid[x][y] == "Grass" and object_grid[x][y] == null:
				if randf() < TREE_PROBABILITY:
					place_tree(x, y)


func place_tree(x: int, y: int) -> void:
	print("Placing tree at:", x, y)
	var atlas_positions = [Vector2i(0, 0), Vector2i(2, 0)]
	var atlas_coord = atlas_positions[randi() % atlas_positions.size()]

	trees.set_cell(Vector2i(x, y), 0, atlas_coord)
	object_grid[x][y] = "Tree"
