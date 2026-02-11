extends Node
class_name ItemEffects

const BoardTileScript = preload("res://scripts/board_tile.gd")

var board: Node3D = null
var players: Array = []
var turn_manager = null


func set_game_references(board_ref: Node3D, players_ref: Array) -> void:
	board = board_ref
	players = players_ref


func apply_item_effect(item_type: ItemData.ItemType, user: Node3D, target: Node3D = null) -> void:
	var item_info = ItemData.get_item_info(item_type)
	var effect = item_info.get("effect", "")

	match effect:
		"force_roll_1":
			target.force_next_roll_to_1 = true
		"move_back_3":
			move_player_back(target, 3)
		"roll_twice_lower":
			target.roll_twice_take_lower = true
		"random_back_4":
			move_player_back(target, randi_range(1, 4))
		"knockback_danger":
			knockback_to_danger(target)
		"skip_turn":
			if turn_manager:
				turn_manager.skip_next_turn[target] = true
		"place_trap":
			pass  # TODO: Implement trap placement
		"swap_positions":
			swap_player_positions(user, target)
		"halve_rolls_2":
			target.halve_next_rolls = 2
		"rewind_last_turn":
			target.teleport_to_tile(target.last_turn_position)
		"corrupt_tiles_3":
			corrupt_tiles_ahead(target, 3)
		"random_teleport":
			random_teleport_player(target)
		"all_move_back_3":
			move_all_others_back(user, 3)
		"send_to_start":
			target.teleport_to_tile(0)
		"shuffle_positions":
			shuffle_all_positions()


func move_player_back(player: Node3D, tiles: int) -> void:
	var new_index = max(0, player.current_tile_index - tiles)
	player.teleport_to_tile(new_index)


func knockback_to_danger(player: Node3D) -> void:
	if not board:
		return

	var tiles = board.get_tiles()

	# Find nearest danger tile behind
	for i in range(player.current_tile_index - 1, -1, -1):
		if tiles[i].tile_type == BoardTileScript.TileType.BAD:
			player.teleport_to_tile(i)
			return

	# No danger tile found, move back 5
	move_player_back(player, 5)


func swap_player_positions(player1: Node3D, player2: Node3D) -> void:
	var temp_index = player1.current_tile_index
	player1.teleport_to_tile(player2.current_tile_index)
	player2.teleport_to_tile(temp_index)


func corrupt_tiles_ahead(player: Node3D, count: int) -> void:
	if not board:
		return

	var tiles = board.get_tiles()
	var start_index = player.current_tile_index + 1

	for i in range(count):
		var tile_index = start_index + i
		if tile_index < tiles.size():
			tiles[tile_index].set_tile_type(BoardTile.TileType.BAD)


func random_teleport_player(player: Node3D) -> void:
	if not board:
		return
	var tiles = board.get_tiles()
	player.teleport_to_tile(randi() % tiles.size())


func move_all_others_back(user: Node3D, tiles_back: int) -> void:
	for player in players:
		if player != user:
			move_player_back(player, tiles_back)


func shuffle_all_positions() -> void:
	var positions = []
	for player in players:
		positions.append(player.current_tile_index)

	positions.shuffle()

	for i in range(players.size()):
		players[i].teleport_to_tile(positions[i])
