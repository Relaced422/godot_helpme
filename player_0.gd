extends Node3D

var current_tile_index: int = 0
var currentDiceThrow: int = 4

func moveToTile(tile : BoardTile):
	var nexTile = current_tile_index + currentDiceThrow
	transform = tile.transform
	BoardTile

	
	
