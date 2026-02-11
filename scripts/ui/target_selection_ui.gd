extends Control
class_name TargetSelectionUI

@onready var panel: Panel = $Panel
@onready var info_label: Label = $Panel/MarginContainer/VBoxContainer/InfoLabel
@onready var players_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/PlayersContainer
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/CancelButton

var current_user = null
var selected_item: ItemData.ItemType = -1
var all_players: Array = []

signal target_selected(item_type: ItemData.ItemType, target_player)
signal cancelled


func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()


## Setup player list
func set_players(players: Array) -> void:
	all_players = players


## Show target selection
func show_target_selection(user, item_type: ItemData.ItemType) -> void:
	current_user = user
	selected_item = item_type
	
	var item_info = ItemData.get_item_info(item_type)
	info_label.text = "Using: " + item_info["name"] + "\nSelect target player:"
	
	# Clear previous buttons
	for child in players_container.get_children():
		if child is Button:
			child.queue_free()
	
	# Create button for each player (except user)
	for player in all_players:
		if player != user:
			create_player_button(player)
	
	show()


## Create button for player
func create_player_button(player) -> void:
	var button = Button.new()
	button.text = player.player_name + "\n(Tile: " + str(player.current_tile_index) + ")"
	button.custom_minimum_size = Vector2(200, 60)
	button.pressed.connect(_on_player_selected.bind(player))
	
	players_container.add_child(button)


## When player selected
func _on_player_selected(target_player) -> void:
	target_selected.emit(selected_item, target_player)
	hide()


## When cancel pressed
func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()
	
	# Re-show inventory
	if get_parent().has_node("InventoryUI"):
		var inv_ui = get_parent().get_node("InventoryUI")
		inv_ui.show_inventory(current_user)
