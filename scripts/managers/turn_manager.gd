extends Node
class_name TurnManager

# Load BoardTile script
const BoardTileScript = preload("res://scripts/board_tile.gd")

# Player management
var players: Array = []
var current_player_index: int = 0
var is_turn_active: bool = false
var waiting_for_item_use: bool = false

# Dice settings
@export var min_dice_value: int = 1
@export var max_dice_value: int = 6

# Dice reference
var dice: Node3D = null

# Item effects handler
var item_effects: ItemEffects = null

# Turn effects
var skip_next_turn: Dictionary = {}  # player -> bool

signal turn_started(player)
signal turn_ended(player)
signal dice_rolled(value: int)
signal all_players_ready
signal item_phase_started(player)
signal item_phase_ended


func _ready():
	# Create item effects handler
	item_effects = ItemEffects.new()
	add_child(item_effects)


## Set dice reference
func set_dice(dice_node: Node3D) -> void:
	dice = dice_node


## Set game references for item effects
func set_game_references(board: Node3D) -> void:
	if item_effects:
		item_effects.set_game_references(board, players)
		item_effects.turn_manager = self


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
	
	# Start item usage phase
	start_item_phase()


## Start item usage phase
func start_item_phase() -> void:
	var current_player = get_current_player()
	
	# Check if player has any items
	if current_player.inventory.get_item_count() > 0:
		waiting_for_item_use = true
		item_phase_started.emit(current_player)
		print("  📦 Item phase - ", current_player.player_name, " has ", current_player.inventory.get_item_count(), " item(s)")
	else:
		# No items, skip to dice roll
		end_item_phase()


## End item usage phase
func end_item_phase() -> void:
	waiting_for_item_use = false
	item_phase_ended.emit()


## Use item from inventory
func use_item(item_type: ItemData.ItemType, target_player = null) -> void:
	var current_player = get_current_player()
	
	if not current_player.inventory.has_item(item_type):
		print("Player doesn't have this item!")
		return
	
	# Remove item from inventory
	current_player.inventory.remove_item(item_type)
	
	# Apply effect
	if item_effects:
		item_effects.apply_item_effect(item_type, current_player, target_player)
	
	# End item phase after use
	end_item_phase()


## Skip item usage
func skip_item_phase() -> void:
	print("  ⏭️ Skipped item usage")
	end_item_phase()


## Roll the dice for current player
## Roll the dice for current player
func roll_dice() -> void:
	if not is_turn_active:
		return
	
	if waiting_for_item_use:
		print("Still in item phase! Can't roll yet.")
		return
	
	var current_player = get_current_player()
	
	# Check if player should roll twice and take lower
	if current_player.roll_twice_take_lower:
		print("🌋 Solar Flare active - rolling twice!")
		var roll1 = randi_range(min_dice_value, max_dice_value)
		var roll2 = randi_range(min_dice_value, max_dice_value)
		var dice_value = min(roll1, roll2)
		current_player.roll_twice_take_lower = false
		
		# Show popup with both rolls
		show_solar_flare_message(roll1, roll2, dice_value)
		await get_tree().create_timer(3.0).timeout  # Wait for popup to be read
		
		dice_rolled.emit(dice_value)
		execute_movement(dice_value)
	else:
		# Normal roll
		var dice_value = randi_range(min_dice_value, max_dice_value)
		dice_rolled.emit(dice_value)
		execute_movement(dice_value)


## Show solar flare popup
func show_solar_flare_message(roll1: int, roll2: int, final_roll: int) -> void:
	# Create popup
	var popup = AcceptDialog.new()
	popup.title = "🌋 Solar Flare Shock!"
	popup.dialog_text = "Rolled twice:\n\n🎲 First roll: " + str(roll1) + "\n🎲 Second roll: " + str(roll2) + "\n\n⚡ Taking lower roll: " + str(final_roll)
	popup.ok_button_text = "Continue"
	
	# Make it bigger
	popup.min_size = Vector2(300, 200)
	
	# Add to scene
	get_tree().root.add_child(popup)
	popup.popup_centered()
	
	# Auto-close after 3 seconds
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(popup):
		popup.hide()
		popup.queue_free()

## Execute player movement with dice animation
func execute_movement(dice_value: int) -> void:
	var current_player = get_current_player()
	
	print("Rolled: ", dice_value)
	
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
		await get_tree().create_timer(0.5).timeout
		end_turn()


## Handle tile effects
func _on_tile_effect(player, tile_type) -> void:
	match tile_type:
		BoardTileScript.TileType.SKIP:
			skip_next_turn[player] = true
			print("⏭️ ", player.player_name, " will skip their next turn!")
		
		BoardTileScript.TileType.REVERSE:
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


## DEBUG ONLY: Force give item to current player
func debug_give_item(item_type: ItemData.ItemType) -> void:
	var current_player = get_current_player()
	if current_player and current_player.inventory:
		current_player.inventory.add_item(item_type)
