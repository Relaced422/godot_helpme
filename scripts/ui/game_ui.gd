extends Control

# Existing UI Elements
@onready var turn_label: Label = $TopPanel/MarginContainer/HBoxContainer/TurnLabel
@onready var score_label: Label = $TopPanel/MarginContainer/HBoxContainer/ScoreLabel
@onready var dice_button: Button = $CenterContainer/DiceButton
@onready var message_label: Label = $BottomPanel/MarginContainer/MessageLabel

# Inventory UI references
@onready var inventory_ui: InventoryUI = $InventoryUI if has_node("InventoryUI") else null
@onready var target_ui: TargetSelectionUI = $TargetSelectionUI if has_node("TargetSelectionUI") else null

# DEBUG: Debug panel
@onready var debug_panel: DebugPanel = $DebugPanel if has_node("DebugPanel") else null

# References
var turn_manager: Node = null

# Scores
var player_scores: Dictionary = {}

var message_timer: float = 0.0
var message_display_time: float = 3.0  # How long to show messages

func _ready():
	# Connect button
	dice_button.pressed.connect(_on_dice_button_pressed)
	
	# Connect inventory UI
	if inventory_ui:
		inventory_ui.item_used.connect(_on_item_used)
		inventory_ui.item_phase_skipped.connect(_on_item_phase_skipped)
	
	# Connect target UI
	if target_ui:
		target_ui.target_selected.connect(_on_target_selected)
		target_ui.cancelled.connect(_on_target_cancelled)

func _process(delta: float) -> void:
	# Count down message timer
	if message_timer > 0:
		message_timer -= delta

## Setup references
func setup(tm: Node) -> void:
	turn_manager = tm
	
	# Set players for target selection
	if target_ui and turn_manager:
		target_ui.set_players(turn_manager.players)
	
	# DEBUG: Setup debug panel
	if debug_panel:
		debug_panel.setup(turn_manager)
	
	# Connect to turn manager signals
	if turn_manager:
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.turn_ended.connect(_on_turn_ended)
		turn_manager.dice_rolled.connect(_on_dice_rolled)
		turn_manager.item_phase_started.connect(_on_item_phase_started)
		turn_manager.item_phase_ended.connect(_on_item_phase_ended)

## Update turn display
func _on_turn_started(player) -> void:
	turn_label.text = player.player_name + "'s Turn"
	dice_button.disabled = true  # Disabled until item phase ends
	message_label.text = "Checking inventory..."


## NEW: When item phase starts
func _on_item_phase_started(player) -> void:
	message_label.text = "Use an item or skip to roll dice"
	
	# Show inventory UI
	if inventory_ui:
		inventory_ui.show_inventory(player)


## NEW: When item phase ends
func _on_item_phase_ended() -> void:
	dice_button.disabled = false
	message_label.text = "Roll the dice!"


## NEW: When item is used
func _on_item_used(item_type: ItemData.ItemType, target_player) -> void:
	if turn_manager:
		turn_manager.use_item(item_type, target_player)


## NEW: When item phase is skipped
func _on_item_phase_skipped() -> void:
	if turn_manager:
		turn_manager.skip_item_phase()


## NEW: When target is selected
func _on_target_selected(item_type: ItemData.ItemType, target_player) -> void:
	if turn_manager:
		turn_manager.use_item(item_type, target_player)


## NEW: When target selection cancelled
func _on_target_cancelled() -> void:
	# Re-show inventory
	var current_player = turn_manager.get_current_player()
	if inventory_ui and current_player:
		inventory_ui.show_inventory(current_player)


## Update after turn ends
func _on_turn_ended(_player) -> void:
	dice_button.disabled = true
	message_label.text = "Turn ended. Next player..."


func _on_dice_rolled(value: int) -> void:
	dice_button.disabled = true
	
	# Only show simple message if not already showing a longer one
	if message_timer <= 0:
		show_message("Rolled: " + str(value) + "!", 2.0)


## Handle button press
func _on_dice_button_pressed() -> void:
	if turn_manager and turn_manager.has_method("roll_dice"):
		turn_manager.roll_dice()


## Update score
func update_score(player_name: String, score: int) -> void:
	player_scores[player_name] = score
	var total = 0
	for s in player_scores.values():
		total += s
	score_label.text = "Total Score: " + str(total)


## Show message (with optional duration)
func show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_timer = duration
	message_display_time = duration
