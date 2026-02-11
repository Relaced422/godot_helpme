extends Node
class_name TurnManager

const BoardTileScript = preload("res://scripts/board_tile.gd")

var players: Array = []
var current_player_index: int = 0
var is_turn_active: bool = false
var waiting_for_item_use: bool = false

@export var min_dice_value: int = 1
@export var max_dice_value: int = 6

var dice: Node3D = null
var item_effects: ItemEffects = null
var skip_next_turn: Dictionary = {}  # player -> bool

signal turn_started(player)
signal turn_ended(player)
signal dice_rolled(value: int)
signal all_players_ready
signal item_phase_started(player)
signal item_phase_ended


func _ready():
	item_effects = ItemEffects.new()
	add_child(item_effects)


func set_dice(dice_node: Node3D) -> void:
	dice = dice_node


func set_game_references(board: Node3D) -> void:
	if item_effects:
		item_effects.set_game_references(board, players)
		item_effects.turn_manager = self


func add_player(player) -> void:
	players.append(player)
	skip_next_turn[player] = false
	player.movement_finished.connect(_on_player_movement_finished.bind(player))

	if player.board:
		player.board.tile_effect_triggered.connect(_on_tile_effect)


func start_game() -> void:
	if players.is_empty():
		push_error("No players added!")
		return

	current_player_index = 0
	all_players_ready.emit()
	start_turn()


func start_turn() -> void:
	if is_turn_active:
		return

	var current_player = get_current_player()

	if skip_next_turn.get(current_player, false):
		skip_next_turn[current_player] = false
		end_turn()
		return

	is_turn_active = true
	turn_started.emit(current_player)
	start_item_phase()


func start_item_phase() -> void:
	var current_player = get_current_player()

	if current_player.inventory.get_item_count() > 0:
		waiting_for_item_use = true
		item_phase_started.emit(current_player)
	else:
		end_item_phase()


func end_item_phase() -> void:
	waiting_for_item_use = false
	item_phase_ended.emit()


func use_item(item_type: ItemData.ItemType, target_player = null) -> void:
	var current_player = get_current_player()

	if not current_player.inventory.has_item(item_type):
		return

	current_player.inventory.remove_item(item_type)

	if item_effects:
		item_effects.apply_item_effect(item_type, current_player, target_player)

	end_item_phase()


func skip_item_phase() -> void:
	end_item_phase()


## Roll the dice for current player
func roll_dice() -> void:
	if not is_turn_active or waiting_for_item_use:
		return

	var current_player = get_current_player()

	if current_player.roll_twice_take_lower:
		var roll1 = randi_range(min_dice_value, max_dice_value)
		var roll2 = randi_range(min_dice_value, max_dice_value)
		var dice_value = min(roll1, roll2)
		current_player.roll_twice_take_lower = false

		show_solar_flare_message(roll1, roll2, dice_value)
		await get_tree().create_timer(3.0).timeout

		dice_rolled.emit(dice_value)
		execute_movement(dice_value)
	else:
		var dice_value = randi_range(min_dice_value, max_dice_value)
		dice_rolled.emit(dice_value)
		execute_movement(dice_value)


func show_solar_flare_message(roll1: int, roll2: int, final_roll: int) -> void:
	var popup = AcceptDialog.new()
	popup.title = "Solar Flare Shock!"
	popup.dialog_text = "Rolled twice:\n\nFirst roll: " + str(roll1) + "\nSecond roll: " + str(roll2) + "\n\nTaking lower roll: " + str(final_roll)
	popup.ok_button_text = "Continue"
	popup.min_size = Vector2(300, 200)

	get_tree().root.add_child(popup)
	popup.popup_centered()

	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(popup):
		popup.hide()
		popup.queue_free()


func execute_movement(dice_value: int) -> void:
	var current_player = get_current_player()

	if dice:
		dice.global_position = current_player.global_position + Vector3(0, 3, 0)
		dice.roll_dice(dice_value)
		await dice.roll_finished

	current_player.move_forward(dice_value)


func _on_player_movement_finished(player) -> void:
	if player == get_current_player():
		await get_tree().create_timer(0.5).timeout
		end_turn()


func _on_tile_effect(player, tile_type) -> void:
	if tile_type == BoardTileScript.TileType.SKIP:
		skip_next_turn[player] = true


func end_turn() -> void:
	var current_player = get_current_player()
	is_turn_active = false
	turn_ended.emit(current_player)

	current_player_index = (current_player_index + 1) % players.size()

	await get_tree().create_timer(1.0).timeout
	start_turn()


func get_current_player():
	if players.is_empty():
		return null
	return players[current_player_index]


func debug_give_item(item_type: ItemData.ItemType) -> void:
	var current_player = get_current_player()
	if current_player and current_player.inventory:
		current_player.inventory.add_item(item_type)
