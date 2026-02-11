extends Node3D
class_name Board

const BoardTileScript = preload("res://scripts/board_tile.gd")

@onready var tiles_container: Node3D = $Tiles

var tiles: Array = []

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
		var board_tile = tile_slot.get_child(0) if tile_slot.get_child_count() > 0 else tile_slot

		if not board_tile.has_method("set_tile_type"):
			board_tile.set_script(BoardTileScript)

		board_tile.tile_index = tiles.size()
		tiles.append(board_tile)


func randomize_tiles() -> void:
	if tiles.is_empty():
		push_error("No tiles to randomize!")
		return

	# Reset all tiles to normal
	for tile in tiles:
		tile.set_tile_type(BoardTileScript.TileType.NORMAL)

	var available_indices = range(1, tiles.size())
	available_indices.shuffle()

	var index = 0

	# Place special tiles in order of rarity
	index = place_tiles(available_indices, index, num_black_holes, BoardTileScript.TileType.BLACK_HOLE)
	index = place_tiles(available_indices, index, num_skip_tiles, BoardTileScript.TileType.SKIP)
	index = place_tiles(available_indices, index, num_reverse_tiles, BoardTileScript.TileType.REVERSE)

	# Place bad tiles on remaining normal slots
	var num_bad_tiles = int(tiles.size() * bad_tile_percentage)
	var placed_bad = 0
	while placed_bad < num_bad_tiles and index < available_indices.size():
		var tile_index = available_indices[index]
		if tiles[tile_index].tile_type == BoardTileScript.TileType.NORMAL:
			tiles[tile_index].set_tile_type(BoardTileScript.TileType.BAD)
			placed_bad += 1
		index += 1


func place_tiles(available: Array, start_index: int, count: int, type) -> int:
	var idx = start_index
	for i in range(count):
		if idx >= available.size():
			break
		tiles[available[idx]].set_tile_type(type)
		idx += 1
	return idx


func get_tiles() -> Array:
	return tiles


func get_tile(index: int):
	if index >= 0 and index < tiles.size():
		return tiles[index]
	return null


func player_landed_on_tile(player, tile_index: int) -> void:
	var tile = get_tile(tile_index)
	if tile:
		tile.on_player_landed(player)
		tile_effect_triggered.emit(player, tile.tile_type)
