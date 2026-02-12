extends Control

# UI Elements
@onready var turn_label: Label = $TopPanel/MarginContainer/HBoxContainer/TurnLabel
@onready var score_label: Label = $TopPanel/MarginContainer/HBoxContainer/ScoreLabel
@onready var dice_button: Button = $CenterContainer/DiceButton
@onready var message_label: Label = $BottomPanel/MarginContainer/MessageLabel
@onready var inventory_display: VBoxContainer = $InventoryDisplay  # NEW

# References
var turn_manager: Node = null
var current_player: Player = null  # NEW

# Scores
var player_scores: Dictionary = {}


func _ready():
	dice_button.pressed.connect(_on_dice_button_pressed)


func setup(tm: Node) -> void:
	turn_manager = tm
	
	if turn_manager:
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.turn_ended.connect(_on_turn_ended)
		turn_manager.dice_rolled.connect(_on_dice_rolled)


func _on_turn_started(player) -> void:
	current_player = player  # NEW
	turn_label.text = player.player_name + "'s Turn"
	dice_button.disabled = false
	message_label.text = "Roll the dice! (space)"
	
	# Update inventory display
	if inventory_display and inventory_display.has_method("set_player"):
		inventory_display.set_player(player.player_index)


func _on_turn_ended(_player) -> void:
	dice_button.disabled = true
	message_label.text = "Turn ended. Next player..."


func _on_dice_rolled(value: int) -> void:
	dice_button.disabled = true
	message_label.text = "Rolled: " + str(value) + "!"


func _on_dice_button_pressed() -> void:
	if turn_manager and turn_manager.has_method("roll_dice"):
		turn_manager.roll_dice()


func update_score(player_name: String, score: int) -> void:
	player_scores[player_name] = score
	var total = 0
	for s in player_scores.values():
		total += s
	score_label.text = "Total Score: " + str(total)


func show_message(text: String) -> void:
	message_label.text = text
