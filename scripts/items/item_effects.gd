extends Node
class_name ItemEffects

# Load BoardTile for tile type checking
const BoardTileScript = preload("res://scripts/board_tile.gd")

# Reference to game
var board: Node3D = null
var players: Array = []
var turn_manager = null


func set_game_references(board_ref: Node3D, players_ref: Array) -> void:
	board = board_ref
	players = players_ref


# Apply item effect
func apply_item_effect(item_type: ItemData.ItemType, user: Node3D, target: Node3D = null) -> void:
	var item_info = ItemData.get_item_info(item_type)
	var effect = item_info.get("effect", "")
	
	print("🎯 ", user.player_name, " used ", item_info["name"])
	
	match effect:
		"force_roll_1":
			target.force_next_roll_to_1 = true
			print("  → ", target.player_name, "'s next roll will be 1!")
		
		"move_back_3":
			move_player_back(target, 3)
			print("  → ", target.player_name, " moved back 3 tiles!")
		
		"roll_twice_lower":
			target.roll_twice_take_lower = true
			print("  → ", target.player_name, " will roll twice and take lower!")
		
		"random_back_4":
			var back_amount = randi_range(1, 4)
			move_player_back(target, back_amount)
			print("  → ", target.player_name, " moved back ", back_amount, " tiles!")
		
		"knockback_danger":
			knockback_to_danger(target)
			print("  → ", target.player_name, " knocked back!")
		
		"skip_turn":
			if turn_manager:
				turn_manager.skip_next_turn[target] = true
				print("  → ", target.player_name, " will skip next turn!")
			else:
				print("  → ERROR: No turn manager reference!")
		
		"place_trap":
			# TODO: Implement trap placement
			print("  → Trap placed! (Not implemented yet)")
		
		"swap_positions":
			swap_player_positions(user, target)
			print("  → ", user.player_name, " and ", target.player_name, " swapped positions!")
		
		"halve_rolls_2":
			target.halve_next_rolls = 2
			print("  → ", target.player_name, "'s next 2 rolls will be halved!")
		
		"rewind_last_turn":
			rewind_player(target)
			print("  → ", target.player_name, " rewound to previous position!")
		
		"corrupt_tiles_3":
			corrupt_tiles_ahead(target, 3)
			print("  → 3 tiles ahead corrupted!")
		
		"random_teleport":
			random_teleport_player(target)
			print("  → ", target.player_name, " randomly teleported!")
		
		"all_move_back_3":
			move_all_others_back(user, 3)
			print("  → All other players moved back 3!")
		
		"send_to_start":
			send_player_to_start(target)
			print("  → ", target.player_name, " sent to START!")
		
		"shuffle_positions":
			shuffle_all_positions()
			print("  → All positions SHUFFLED!")


# Helper functions
func move_player_back(player: Node3D, tiles: int) -> void:
	if player.has_method("teleport_to_tile"):
		var new_index = max(0, player.current_tile_index - tiles)
		player.teleport_to_tile(new_index)


func knockback_to_danger(player: Node3D) -> void:
	if not board:
		print("  → ERROR: No board reference!")
		return
	
	var tiles = board.get_tiles()
	var current_index = player.current_tile_index
	
	print("  → Searching for danger tile behind position ", current_index)
	
	# Find nearest danger tile behind
	for i in range(current_index - 1, -1, -1):
		var tile = tiles[i]
		# Check tile type using the BoardTile enum
		if tile.tile_type == BoardTileScript.TileType.BAD:
			print("  → Found danger tile at ", i)
			player.teleport_to_tile(i)
			return
	
	# No danger tile found, move back 5
	print("  → No danger tile found, moving back 5 tiles")
	move_player_back(player, 5)

func swap_player_positions(player1: Node3D, player2: Node3D) -> void:
	var temp_index = player1.current_tile_index
	player1.teleport_to_tile(player2.current_tile_index)
	player2.teleport_to_tile(temp_index)


func rewind_player(player: Node3D) -> void:
	if player.has_method("teleport_to_tile"):
		player.teleport_to_tile(player.last_turn_position)


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
	var random_index = randi() % tiles.size()
	player.teleport_to_tile(random_index)


func move_all_others_back(user: Node3D, tiles_back: int) -> void:
	for player in players:
		if player != user:
			move_player_back(player, tiles_back)


func send_player_to_start(player: Node3D) -> void:
	player.teleport_to_tile(0)


func shuffle_all_positions() -> void:
	# Get all current positions
	var positions = []
	for player in players:
		positions.append(player.current_tile_index)
	
	# Shuffle positions array
	positions.shuffle()
	
	# Assign shuffled positions
	for i in range(players.size()):
		players[i].teleport_to_tile(positions[i])
