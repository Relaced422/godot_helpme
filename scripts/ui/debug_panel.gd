extends Control
class_name DebugPanel

@onready var panel: Panel = $Panel
@onready var give_all_items_button: Button = $Panel/MarginContainer/VBoxContainer/GiveAllItemsButton
@onready var clear_items_button: Button = $Panel/MarginContainer/VBoxContainer/ClearItemsButton
@onready var test_minigame_button: Button = $Panel/MarginContainer/VBoxContainer/TestMinigameButton
@onready var toggle_button: Button = $ToggleButton

var turn_manager = null
var is_panel_visible: bool = false


func _ready():
	# Connect buttons
	give_all_items_button.pressed.connect(_on_give_all_items)
	clear_items_button.pressed.connect(_on_clear_items)
	test_minigame_button.pressed.connect(_on_test_minigame)
	toggle_button.pressed.connect(_on_toggle_panel)
	
	# Start with panel hidden
	panel.visible = false


func setup(tm: Node) -> void:
	turn_manager = tm


func _on_toggle_panel() -> void:
	is_panel_visible = !is_panel_visible
	panel.visible = is_panel_visible


func _on_give_all_items() -> void:
	if not turn_manager:
		print("No turn manager!")
		return
	
	var current_player = turn_manager.get_current_player()
	if not current_player:
		print("No current player!")
		return
	
	print("🎁 DEBUG: Giving items to ", current_player.player_name)
	
	# Clear inventory first
	current_player.inventory.clear()
	
	# Get all item types
	var all_items = []
	for item_type in ItemData.ItemType.values():
		all_items.append(item_type)
	
	# Give only up to 8 items (max inventory size)
	var max_items = 8
	for i in range(min(max_items, all_items.size())):
		var item_type = all_items[i]
		if current_player.inventory.add_item(item_type):
			var item_info = ItemData.get_item_info(item_type)
			print("  + Added: ", item_info["name"])
	
	print("  Total items: ", current_player.inventory.get_item_count())

func _on_clear_items() -> void:
	if not turn_manager:
		return
	
	var current_player = turn_manager.get_current_player()
	if not current_player:
		return
	
	print("🗑️ DEBUG: Clearing inventory of ", current_player.player_name)
	current_player.inventory.clear()
	print("  Inventory cleared. Total items: ", current_player.inventory.get_item_count())


func _on_test_minigame() -> void:
	if not turn_manager:
		return
	
	var current_player = turn_manager.get_current_player()
	if not current_player:
		return
	
	print("🎮 DEBUG: Simulating minigame win")
	var random_item = ItemData.get_random_item()
	if current_player.inventory.add_item(random_item):
		var item_info = ItemData.get_item_info(random_item)
		print("  🎁 Won: ", item_info["name"])
	else:
		print("  ! Inventory is full!")
