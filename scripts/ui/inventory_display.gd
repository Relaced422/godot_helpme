extends VBoxContainer

var player_index: int = 0

@onready var inventory_label: Label = $Label
@onready var items_container: HBoxContainer = $ItemsContainer


func _ready():
	update_inventory()


func set_player(index: int) -> void:
	player_index = index
	update_inventory()


func update_inventory() -> void:
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	var inventory = GameManager.get_player_inventory(player_index)
	inventory_label.text = "Items: " + str(inventory.size())
	
	# Create item icons
	for item in inventory:
		var item_info = GameManager.get_item_data(item)
		
		var button = Button.new()
		button.text = item_info["name"][0]  # First letter
		button.tooltip_text = item_info["name"] + "\n" + item_info["description"]
		button.custom_minimum_size = Vector2(40, 40)
		
		items_container.add_child(button)
