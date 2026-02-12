extends Node

# Character data
enum Character {
	LAIKA,
	ASTRONAUT,
	ROBOT
}

# Item types for inventory
enum ItemType {
	SHIELD,           # Protects from bad tiles
	DOUBLE_DICE,      # Roll 2 dice, pick highest
	TELEPORT,         # Jump to any tile
	REVERSE_CARD,     # Force reverse on someone
	SKIP_IMMUNITY     # Can't be skipped
}

# Game state
var num_players: int = 2
var selected_characters: Array = []  # Stores Character enum values
var show_tutorial: bool = false

# Player inventories (player_index -> Array of ItemType)
var player_inventories: Dictionary = {}

# Item data
var item_data = {
	ItemType.SHIELD: {
		"name": "Shield",
		"description": "Protects from next bad tile",
		"icon": "res://assets/items/shield.png"
	},
	ItemType.DOUBLE_DICE: {
		"name": "Double Dice",
		"description": "Roll twice, pick best",
		"icon": "res://assets/items/double_dice.png"
	},
	ItemType.TELEPORT: {
		"name": "Teleport",
		"description": "Jump to any tile",
		"icon": "res://assets/items/teleport.png"
	},
	ItemType.REVERSE_CARD: {
		"name": "Reverse Card",
		"description": "Force another player to reverse",
		"icon": "res://assets/items/reverse_card.png"
	},
	ItemType.SKIP_IMMUNITY: {
		"name": "Skip Immunity",
		"description": "Ignore skip tiles",
		"icon": "res://assets/items/skip_immunity.png"
	}
}

# Character sprite data
var character_sprites = {
	Character.LAIKA: {
		"name": "Laika",
		"front": "res://assets/sprites/laika_front.png",
		"back": "res://assets/sprites/laika_back.png",
		"left": "res://assets/sprites/laika_left.png",
		"right": "res://assets/sprites/laika_right.png",
		"color": Color(0.8, 0.6, 0.4)  # Brown
	},
	Character.ASTRONAUT: {
		"name": "Astronaut",
		"front": "res://assets/sprites/astronaut_front.png",
		"back": "res://assets/sprites/astronaut_back.png",
		"left": "res://assets/sprites/astronaut_left.png",
		"right": "res://assets/sprites/astronaut_right.png",
		"color": Color(0.9, 0.9, 0.9)  # White
	},
	Character.ROBOT: {
		"name": "Robot",
		"front": "res://assets/sprites/robot_front.png",
		"back": "res://assets/sprites/robot_back.png",
		"left": "res://assets/sprites/robot_left.png",
		"right": "res://assets/sprites/robot_right.png",
		"color": Color(0.5, 0.7, 0.9)  # Blue
	}
}


func _ready():
	print("🎮 GameManager ready")
	initialize_inventories()


func reset_game() -> void:
	selected_characters.clear()
	num_players = 2
	show_tutorial = false
	initialize_inventories()


func initialize_inventories() -> void:
	print("📦 Initializing inventories for ", num_players, " players")
	player_inventories.clear()
	for i in range(num_players):
		player_inventories[i] = []
	print("✅ Inventories initialized: ", player_inventories)


func get_character_data(character: Character) -> Dictionary:
	return character_sprites.get(character, {})


func get_item_data(item_type: ItemType) -> Dictionary:
	return item_data.get(item_type, {})


# === INVENTORY FUNCTIONS ===

func add_item_to_player(player_index: int, item: ItemType) -> void:
	if player_index not in player_inventories:
		player_inventories[player_index] = []
	
	player_inventories[player_index].append(item)
	print("✨ Player ", player_index + 1, " received: ", item_data[item]["name"])


func remove_item_from_player(player_index: int, item: ItemType) -> bool:
	if player_index not in player_inventories:
		return false
	
	var inventory = player_inventories[player_index]
	var item_index = inventory.find(item)
	
	if item_index >= 0:
		inventory.remove_at(item_index)
		return true
	
	return false


func get_player_inventory(player_index: int) -> Array:
	return player_inventories.get(player_index, [])


func has_item(player_index: int, item: ItemType) -> bool:
	var inventory = get_player_inventory(player_index)
	return item in inventory


func get_inventory_count(player_index: int) -> int:
	return get_player_inventory(player_index).size()
