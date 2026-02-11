extends Control

@onready var player_info_label: Label = $VBoxContainer/TopPanel/PlayerInfoLabel
@onready var laika_button: Button = $VBoxContainer/CenterContainer/CharacterButtons/LaikaButton
@onready var astronaut_button: Button = $VBoxContainer/CenterContainer/CharacterButtons/AstronautButton
@onready var robot_button: Button = $VBoxContainer/CenterContainer/CharacterButtons/RobotButton
@onready var selected_label: Label = $VBoxContainer/BottomPanel/SelectedLabel

var current_player_index: int = 0
var already_selected_characters: Array = []


func _ready():
	setup_button_images()

	laika_button.pressed.connect(_on_character_selected.bind(GameManager.Character.LAIKA))
	astronaut_button.pressed.connect(_on_character_selected.bind(GameManager.Character.ASTRONAUT))
	robot_button.pressed.connect(_on_character_selected.bind(GameManager.Character.ROBOT))

	update_ui()


func setup_button_images() -> void:
	setup_character_image(laika_button, "LaikaImage", GameManager.Character.LAIKA)
	setup_character_image(astronaut_button, "AstronautImage", GameManager.Character.ASTRONAUT)
	setup_character_image(robot_button, "RobotImage", GameManager.Character.ROBOT)


func setup_character_image(button: Button, image_node_name: String, character: GameManager.Character) -> void:
	if not button.has_node(image_node_name):
		return

	var texture_rect = button.get_node(image_node_name) as TextureRect
	var char_data = GameManager.get_character_data(character)

	var sprite_path = char_data.get("front", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		texture_rect.texture = load(sprite_path)


func update_ui() -> void:
	player_info_label.text = "Player " + str(current_player_index + 1) + ": Select Your Character"

	laika_button.disabled = GameManager.Character.LAIKA in already_selected_characters
	astronaut_button.disabled = GameManager.Character.ASTRONAUT in already_selected_characters
	robot_button.disabled = GameManager.Character.ROBOT in already_selected_characters

	update_button_text(laika_button, "Laika", GameManager.Character.LAIKA in already_selected_characters)
	update_button_text(astronaut_button, "Astronaut", GameManager.Character.ASTRONAUT in already_selected_characters)
	update_button_text(robot_button, "Robot", GameManager.Character.ROBOT in already_selected_characters)


func update_button_text(button: Button, char_name: String, is_taken: bool) -> void:
	button.text = "\n\n\n" + char_name + ("\n(Taken)" if is_taken else "")


func _on_character_selected(character: GameManager.Character) -> void:
	GameManager.selected_characters.append(character)
	already_selected_characters.append(character)

	var char_name = GameManager.get_character_data(character)["name"]
	selected_label.text = "Player " + str(current_player_index + 1) + " selected: " + char_name

	current_player_index += 1

	if current_player_index >= GameManager.num_players:
		await get_tree().create_timer(1.0).timeout
		show_tutorial_prompt()
	else:
		await get_tree().create_timer(0.5).timeout
		update_ui()


func show_tutorial_prompt() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Tutorial"
	dialog.dialog_text = "Would you like to see the tutorial?"
	dialog.ok_button_text = "Yes"
	dialog.add_button("No", false, "no")

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(_on_tutorial_yes)
	dialog.custom_action.connect(_on_tutorial_no)
	dialog.close_requested.connect(_on_tutorial_no)


func _on_tutorial_yes() -> void:
	GameManager.show_tutorial = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_tutorial_no(_action: String = "") -> void:
	GameManager.show_tutorial = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
