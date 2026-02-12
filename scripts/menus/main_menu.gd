extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $options
@onready var player_count_panel: Panel = $PlayerCountPanel
@onready var btn_2_players: Button = $PlayerCountPanel/VBoxContainer/PlayerButton2
@onready var btn_3_players: Button = $PlayerCountPanel/VBoxContainer/PlayerButton3
@onready var btn_back_player_count: Button = $PlayerCountPanel/VBoxContainer/BackButton  # Or just BackButton if not in VBoxContainer

var selected_player_count: int = 2

func _ready():
	print("🎬 MAIN MENU LOADED")
	main_buttons.visible = true
	options.visible = false
	player_count_panel.visible = false
	
	# Connect buttons
	btn_2_players.pressed.connect(_on_2_players_pressed)
	btn_3_players.pressed.connect(_on_3_players_pressed)
	btn_back_player_count.pressed.connect(_on_back_player_count_pressed)
	print("✅ All player count buttons connected")

func _exit_tree():
	print("🎬 MAIN MENU EXITING")

func _on_start_pressed():
	print("🎮 START PRESSED! Going to player selection...")
	
	# Show player count selection instead of going straight to character select
	main_buttons.visible = false
	player_count_panel.visible = true

func _on_player_count_confirmed(player_count: int):
	print("👥 Selected %d players" % player_count)
	selected_player_count = player_count
	
	# Store in GameManager
	GameManager.num_players = player_count
	
	# Initialize inventories (make sure this function exists in GameManager)
	if GameManager.has_method("initialize_inventories"):
		GameManager.initialize_inventories()
	
	print("🎯 Transitioning to character select...")
	
	# Force hide everything
	hide()
	cleanup_media()
	
	# Small delay to ensure everything is clean
	await get_tree().create_timer(0.1).timeout
	
	# Change scene
	var result = get_tree().change_scene_to_file("res://scenes/menus/character_select.tscn")
	if result != OK:
		push_error("Failed to load character select scene!")

func cleanup_media() -> void:
	for node in get_tree().get_nodes_in_group("menu_media"):
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
			node.stop()
		if node is VideoStreamPlayer:
			node.stop()

func _on_settings_pressed():  
	print("⚙️ Settings pressed")
	main_buttons.visible = false
	options.visible = true

func _on_back_options_pressed() -> void:
	main_buttons.visible = true
	options.visible = false
	player_count_panel.visible = false

func _on_back_player_count_pressed() -> void:
	player_count_panel.visible = false
	main_buttons.visible = true

func _on_button_3_pressed() -> void:
	print("👋 Quitting game")
	get_tree().quit()

func _on_focus_entered() -> void:
	pass

func _on_2_players_pressed():
	print("🔹 2 Players button pressed")
	_on_player_count_confirmed(2)

func _on_3_players_pressed():
	print("🔹 3 Players button pressed")
	_on_player_count_confirmed(3)
