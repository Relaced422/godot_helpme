extends Node

# Character data
enum Character {
	LAIKA,
	ASTRONAUT,
	ROBOT
}

# Game state
var num_players: int = 2
var selected_characters: Array = []  # Stores Character enum values
var show_tutorial: bool = false

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


func reset_game() -> void:
	selected_characters.clear()
	num_players = 2
	show_tutorial = false


func get_character_data(character: Character) -> Dictionary:
	return character_sprites.get(character, {})
