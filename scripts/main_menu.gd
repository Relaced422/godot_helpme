extends Control

@onready var player2_button: Button = $CenterContainer/VBoxContainer/PlayerCountButtons/Player2Button
@onready var player3_button: Button = $CenterContainer/VBoxContainer/PlayerCountButtons/Player3Button
@onready var player4_button: Button = $CenterContainer/VBoxContainer/PlayerCountButtons/Player4Button
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton

var selected_player_count: int = 0


func _ready():
	# Connect buttons
	player2_button.pressed.connect(_on_player_count_selected.bind(2))
	player3_button.pressed.connect(_on_player_count_selected.bind(3))
	player4_button.pressed.connect(_on_player_count_selected.bind(4))
	start_button.pressed.connect(_on_start_pressed)


func _on_player_count_selected(count: int) -> void:
	selected_player_count = count
	GameManager.num_players = count
	
	# Visual feedback - highlight selected button
	player2_button.button_pressed = (count == 2)
	player3_button.button_pressed = (count == 3)
	player4_button.button_pressed = (count == 4)
	
	# Enable start button
	start_button.disabled = false
	
	print("Selected ", count, " players")


func _on_start_pressed() -> void:
	if selected_player_count > 0:
		# Go to character selection
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")
