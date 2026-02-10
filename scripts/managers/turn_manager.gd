extends Node
class_name TurnManager

# Load BoardTile script
const BoardTileScript = preload("res://scripts/board_tile.gd")

# Player management
var players: Array = []
var current_player_index: int = 0
var is_turn_active: bool = false

# Dice settings
@export var min_dice_value: int = 1
@export var max_dice_value: int = 6

# Dice reference
var dice: Node3D = null

# Turn effects
var skip_next_turn: Dictionary = {}  # player -> bool

signal turn_started(player)
signal turn_ended(player)
signal dice_rolled(value: int)
signal all_players_ready


func _ready():
	pass


## Set dice reference
func set_dice(dice_node: Node3D) -> void:
	dice = dice_node


## Add a player to the game
func add_player(player) -> void:
	players.append(player)
	skip_next_turn[player] = false
	
	# Connect to player signals
	player.movement_finished.connect(_on_player_movement_finished.bind(player))
	
	# Connect to tile landing
	if player.board and player.board.has_signal("tile_effect_triggered"):
		player.board.tile_effect_triggered.connect(_on_tile_effect)


## Start the game
func start_game() -> void:
	if players.is_empty():
		push_error("No players added!")
		return
	
	current_player_index = 0
	all_players_ready.emit()
	start_turn()


## Start current player's turn
func start_turn() -> void:
	if is_turn_active:
		return
	
	var current_player = get_current_player()
	
	# Check if turn should be skipped
	if skip_next_turn.get(current_player, false):
		print(current_player.player_name, "'s turn is SKIPPED!")
		skip_next_turn[current_player] = false
		end_turn()
		return
	
	is_turn_active = true
	turn_started.emit(current_player)
	
	print(current_player.player_name, "'s turn!")


## Roll the dice for current player
func roll_dice() -> void:
	if not is_turn_active:
		return
	
	var dice_value = randi_range(min_dice_value, max_dice_value)
	dice_rolled.emit(dice_value)
	
	print("Rolled: ", dice_value)
	
	var current_player = get_current_player()
	
	# Position dice above player
	if dice:
		dice.global_position = current_player.global_position + Vector3(0, 3, 0)
		
		# Wait for dice animation
		dice.roll_dice(dice_value)
		await dice.roll_finished
	
	# Move player
	current_player.move_forward(dice_value)


## Called when player finishes moving
func _on_player_movement_finished(player) -> void:
	if player == get_current_player():
		# Small delay before ending turn (to show tile effect)
		await get_tree().create_timer(0.5).timeout
		end_turn()


## Handle tile effects
func _on_tile_effect(player, tile_type) -> void:
	match tile_type:
		BoardTileScript.TileType.SKIP:
			# Mark next turn to be skipped
			skip_next_turn[player] = true
			print("⏭️ ", player.player_name, " will skip their next turn!")
		
		BoardTileScript.TileType.REVERSE:
			# This was already handled during movement in a reversed way
			# But we can add a visual effect here
			print("🔄 ", player.player_name, " hit a reverse tile!")
		
		BoardTileScript.TileType.BLACK_HOLE:
			print("🕳️ ", player.player_name, " fell into a black hole!")
		
		BoardTileScript.TileType.BAD:
			print("😈 ", player.player_name, " landed on a bad tile! Minigame time!")


## End current player's turn
func end_turn() -> void:
	var current_player = get_current_player()
	is_turn_active = false
	turn_ended.emit(current_player)
	
	# Move to next player
	current_player_index = (current_player_index + 1) % players.size()
	
	# Small delay before next turn
	await get_tree().create_timer(1.0).timeout
	start_turn()


## Get the current active player
func get_current_player():
	if players.is_empty():
		return null
	return players[current_player_index]
