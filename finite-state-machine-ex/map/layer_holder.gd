extends Node2D
const DEFAULT_TML = preload("res://map/default_tml.tscn")
@onready var solid_tiles: TileMapLayer = $solids

const MAIN_SOURCE_ID = 0
const SOLID = {'brick':Vector2i(1,0), 'grass':Vector2i(2,0)}
var astar = AStarGrid2D.new()
var map_rect = Rect2i()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_rect = Rect2i(0, 0, 16, 12)
	
	astar.region = map_rect
	astar.cell_size = Vector2i(64, 64)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for solidcoord in solid_tiles.get_used_cells():
		astar.set_point_solid(solidcoord, true)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func is_point_traversable(position) -> bool:
	var map_position = solid_tiles.local_to_map(position)
	if map_rect.has_point(map_position) and not astar.is_point_solid(map_position):
		return true
	return false


# useless
func add_border():
	for y in range(12):
		solid_tiles.set_cell(Vector2i(0, y), MAIN_SOURCE_ID, SOLID['brick'])
		solid_tiles.set_cell(Vector2i(15, y), MAIN_SOURCE_ID, SOLID['brick'])
	for y in range(14):
		solid_tiles.set_cell(Vector2i(y+1, 0), MAIN_SOURCE_ID, SOLID['brick'])
		solid_tiles.set_cell(Vector2i(y+1, 11), MAIN_SOURCE_ID, SOLID['brick'])
