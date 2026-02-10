extends Node3D
class_name Board

# Load BoardTile script
const BoardTileScript = preload("res://scripts/board_tile.gd")

# References
@onready var tiles_container: Node3D = $Tiles

var tiles: Array = []

# Tile type counts
@export var bad_tile_percentage: float = 0.20
@export var num_black_holes: int = 1
@export var num_skip_tiles: int = 2
@export var num_reverse_tiles: int = 3

signal tile_effect_triggered(player, tile_type)


func _ready():
	collect_tiles()
	randomize_tiles()


func collect_tiles() -> void:
	tiles.clear()
	
	if tiles_container == null:
		push_error("Tiles container not found!")
		return
	
	for tile_slot in tiles_container.get_children():
		var board_tile = null
		
		if tile_slot.get_child_count() > 0:
			board_tile = tile_slot.get_child(0)
		else:
			board_tile = tile_slot
		
		# Make sure it has the BoardTile script
		if not board_tile.has_method("set_tile_type"):
			board_tile.set_script(BoardTileScript)
		
		# Set tile index
		if board_tile.has_method("set"):
			board_tile.tile_index = tiles.size()
		
		tiles.append(board_tile)
	
	print("Collected ", tiles.size(), " tiles")


func randomize_tiles() -> void:
	if tiles.is_empty():
		return
	
	# Reset all tiles to normal
	for tile in tiles:
		if tile.has_method("set_tile_type"):
			tile.set_tile_type(BoardTileScript.TileType.NORMAL)
	
	var num_tiles = tiles.size()
	var available_indices = range(1, num_tiles)
	available_indices.shuffle()
	
	var index = 0
	
	# Place black hole tiles
	for i in range(num_black_holes):
		if index >= available_indices.size():
			break
		var tile_index = available_indices[index]
		tiles[tile_index].set_tile_type(BoardTileScript.TileType.BLACK_HOLE)
		index += 1
	
	# Place skip tiles
	for i in range(num_skip_tiles):
		if index >= available_indices.size():
			break
		var tile_index = available_indices[index]
		tiles[tile_index].set_tile_type(BoardTileScript.TileType.SKIP)
		index += 1
	
	# Place reverse tiles
	var placed_reverse = 0
	var consecutive_count = 0
	
	while placed_reverse < num_reverse_tiles and index < available_indices.size():
		if consecutive_count < 3:
			var tile_index = available_indices[index]
			tiles[tile_index].set_tile_type(BoardTileScript.TileType.REVERSE)
			placed_reverse += 1
			consecutive_count += 1
		else:
			consecutive_count = 0
		
		index += 1
	
	# Place bad tiles
	var num_bad_tiles = int(num_tiles * bad_tile_percentage)
	var placed_bad = 0
	
	while placed_bad < num_bad_tiles and index < available_indices.size():
		var tile_index = available_indices[index]
		
		if tiles[tile_index].tile_type == BoardTileScript.TileType.NORMAL:
			tiles[tile_index].set_tile_type(BoardTileScript.TileType.BAD)
			placed_bad += 1
		
		index += 1
	
	print("Tiles randomized:")
	print("  - Bad tiles: ", count_tile_type(BoardTileScript.TileType.BAD))
	print("  - Black holes: ", count_tile_type(BoardTileScript.TileType.BLACK_HOLE))
	print("  - Skip tiles: ", count_tile_type(BoardTileScript.TileType.SKIP))
	print("  - Reverse tiles: ", count_tile_type(BoardTileScript.TileType.REVERSE))


func count_tile_type(type) -> int:
	var count = 0
	for tile in tiles:
		if tile.tile_type == type:
			count += 1
	return count


func get_tiles() -> Array:
	return tiles


func get_tile(index: int):
	if index >= 0 and index < tiles.size():
		return tiles[index]
	return null


func player_landed_on_tile(player, tile_index: int) -> void:
	var tile = get_tile(tile_index)
	if tile and tile.has_method("on_player_landed"):
		tile.on_player_landed(player)
		tile_effect_triggered.emit(player, tile.tile_type)
