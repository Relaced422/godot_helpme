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
	give_all_items_button.pressed.connect(_on_give_all_items)
	clear_items_button.pressed.connect(_on_clear_items)
	test_minigame_button.pressed.connect(_on_test_minigame)
	toggle_button.pressed.connect(_on_toggle_panel)
	panel.visible = false


func setup(tm: Node) -> void:
	turn_manager = tm


func _on_toggle_panel() -> void:
	is_panel_visible = !is_panel_visible
	panel.visible = is_panel_visible


func _get_current_player():
	if not turn_manager:
		return null
	return turn_manager.get_current_player()


func _on_give_all_items() -> void:
	var current_player = _get_current_player()
	if not current_player:
		return

	current_player.inventory.clear()

	var all_items = ItemData.ItemType.values()
	for i in range(min(Inventory.MAX_INVENTORY_SIZE, all_items.size())):
		current_player.inventory.add_item(all_items[i])


func _on_clear_items() -> void:
	var current_player = _get_current_player()
	if current_player:
		current_player.inventory.clear()


func _on_test_minigame() -> void:
	var current_player = _get_current_player()
	if not current_player:
		return

	var random_item = ItemData.get_random_item()
	current_player.inventory.add_item(random_item)
