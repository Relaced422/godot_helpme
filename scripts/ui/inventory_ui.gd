extends Control
class_name InventoryUI

# UI References
@onready var inventory_panel: Panel = $InventoryPanel
@onready var item_list: ItemList = $InventoryPanel/MarginContainer/VBoxContainer/ItemList if has_node("InventoryPanel/MarginContainer/VBoxContainer/ItemList") else null
@onready var items_container: GridContainer = $InventoryPanel/MarginContainer/VBoxContainer/ItemsContainer if has_node("InventoryPanel/MarginContainer/VBoxContainer/ItemsContainer") else null
@onready var item_info_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/ItemInfoLabel
@onready var use_button: Button = $InventoryPanel/MarginContainer/VBoxContainer/ButtonsContainer/UseButton
@onready var skip_button: Button = $InventoryPanel/MarginContainer/VBoxContainer/ButtonsContainer/SkipButton

# Item selection
var selected_item: ItemData.ItemType = -1
var selected_item_index: int = -1
var current_player = null
var turn_manager = null

# Store items list
var items_list: Array = []

signal item_used(item_type: ItemData.ItemType, target_player)
signal item_phase_skipped


func _ready():
	# Connect buttons
	use_button.pressed.connect(_on_use_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Connect ItemList if it exists
	if item_list:
		item_list.item_selected.connect(_on_itemlist_selected)
	
	# Center the panel
	center_panel()
	
	# Start hidden
	hide()


func center_panel() -> void:
	if inventory_panel:
		inventory_panel.anchor_left = 0.5
		inventory_panel.anchor_top = 0.5
		inventory_panel.anchor_right = 0.5
		inventory_panel.anchor_bottom = 0.5
		inventory_panel.offset_left = -300
		inventory_panel.offset_top = -250
		inventory_panel.offset_right = 300
		inventory_panel.offset_bottom = 250


## Show inventory for player
func show_inventory(player) -> void:
	current_player = player
	selected_item = -1
	selected_item_index = -1
	
	# Hide debug panel if it exists
	if get_parent().has_node("DebugPanel"):
		var debug = get_parent().get_node("DebugPanel")
		debug.panel.visible = false
		debug.is_panel_visible = false
	
	# Get items
	items_list = player.inventory.get_items()
	
	if items_list.is_empty():
		item_info_label.text = "No items available. Click Skip to continue."
		use_button.disabled = true
		
		if item_list:
			item_list.clear()
		
		show()
		return
	
	# Populate ItemList
	if item_list:
		populate_item_list()
	
	item_info_label.text = "Select an item to use or skip to roll dice\n(" + str(items_list.size()) + " items)"
	use_button.disabled = true
	
	show()


## Populate ItemList widget
func populate_item_list() -> void:
	if not item_list:
		return
	
	item_list.clear()
	
	for item_type in items_list:
		var item_info = ItemData.get_item_info(item_type)
		var rarity_emoji = get_rarity_emoji(item_info["rarity"])
		var display_text = rarity_emoji + " " + item_info["name"]
		
		item_list.add_item(display_text)
		
		# Color by rarity
		var index = item_list.item_count - 1
		var color = get_rarity_color(item_info["rarity"])
		item_list.set_item_custom_bg_color(index, color)


## When item is selected in ItemList
func _on_itemlist_selected(index: int) -> void:
	if index < 0 or index >= items_list.size():
		return
	
	selected_item_index = index
	selected_item = items_list[index]
	
	var item_info = ItemData.get_item_info(selected_item)
	item_info_label.text = item_info["name"] + "\n\n" + item_info["description"]
	use_button.disabled = false


## Get rarity emoji
func get_rarity_emoji(rarity: ItemData.Rarity) -> String:
	match rarity:
		ItemData.Rarity.COMMON:
			return "🟢"
		ItemData.Rarity.RARE:
			return "🔵"
		ItemData.Rarity.EPIC:
			return "🟣"
		ItemData.Rarity.LEGENDARY:
			return "🟡"
	return "⚪"


## Get rarity color
func get_rarity_color(rarity: ItemData.Rarity) -> Color:
	match rarity:
		ItemData.Rarity.COMMON:
			return Color(0.4, 0.4, 0.4, 0.5)
		ItemData.Rarity.RARE:
			return Color(0.2, 0.3, 0.6, 0.5)
		ItemData.Rarity.EPIC:
			return Color(0.4, 0.2, 0.6, 0.5)
		ItemData.Rarity.LEGENDARY:
			return Color(0.6, 0.5, 0.1, 0.5)
	return Color(0.5, 0.5, 0.5, 0.5)


## When use button pressed
func _on_use_pressed() -> void:
	if selected_item == -1:
		return
	
	var item_info = ItemData.get_item_info(selected_item)
	
	# Check if item requires target
	if item_info.get("requires_target", false):
		# Show target selection
		hide()
		show_target_selection()
	else:
		# Use item without target
		item_used.emit(selected_item, null)
		hide()


## When skip button pressed
func _on_skip_pressed() -> void:
	item_phase_skipped.emit()
	hide()


## Show target selection UI
func show_target_selection() -> void:
	if get_parent().has_node("TargetSelectionUI"):
		var target_ui = get_parent().get_node("TargetSelectionUI")
		target_ui.show_target_selection(current_player, selected_item)
