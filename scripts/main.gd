extends Node3D

@onready var board: Node3D = $Board
@onready var turn_manager: Node = $TurnManager
@onready var camera: Camera3D = $Camera3D if has_node("Camera3D") else null
@onready var game_ui: Control = $UI/GameUI if has_node("UI/GameUI") else null
@onready var dice: Node3D = $Dice if has_node("Dice") else null

# Camera settings
@export var camera_offset: Vector3 = Vector3(0, 10, 10)
@export var camera_follow_speed: float = 5.0
@export var camera_rotation_speed: float = 8.0

# Players
var players: Array = []
var player_scene = preload("res://scenes/player/player.tscn")
var active_player: Node3D = null


func _ready():
	spawn_players()
	setup_game()
	
	# Show tutorial if requested
	if GameManager.show_tutorial:
		show_tutorial()


func _process(delta: float) -> void:
	if camera and active_player:
		smooth_follow_player(delta)


func spawn_players() -> void:
	var num_players = GameManager.num_players
	var selected_chars = GameManager.selected_characters
	
	for i in range(num_players):
		var player = player_scene.instantiate()
		add_child(player)
		
		# Make sure player has the Player script
		if not player.has_method("set_character"):
			push_error("Player scene doesn't have Player script attached!")
			continue
		
		# Configure player
		var char_type = selected_chars[i]
		var char_data = GameManager.get_character_data(char_type)
		
		# Set properties safely
		player.player_name = "Player " + str(i + 1)
		player.player_color = char_data.get("color", Color.WHITE)
		player.character_type = char_type
		
		# This must be called AFTER setting character_type
		if player.has_method("set_character"):
			player.set_character(char_type)
		
		players.append(player)
		
		print("Spawned ", player.player_name, " as ", char_data["name"])

func setup_game() -> void:
	if not board:
		push_error("Missing board!")
		return
	
	# Setup all players
	for player in players:
		if player.has_method("set_board"):
			player.set_board(board)
		if player.has_method("teleport_to_tile"):
			player.teleport_to_tile(0)
		if turn_manager.has_method("add_player"):
			turn_manager.add_player(player)
	
	# Setup dice
	if dice and turn_manager.has_method("set_dice"):
		turn_manager.set_dice(dice)
	
	# Setup UI
	if game_ui and game_ui.has_method("setup"):
		game_ui.setup(turn_manager)
	
	# Connect signals
	if turn_manager.has_signal("turn_started"):
		turn_manager.turn_started.connect(_on_turn_started)
	if turn_manager.has_signal("dice_rolled"):
		turn_manager.dice_rolled.connect(_on_dice_rolled)
	
	# Start game
	if turn_manager.has_method("start_game"):
		turn_manager.start_game()


func _on_turn_started(player) -> void:
	print("=== ", player.player_name, "'s Turn ===")
	active_player = player


func _on_dice_rolled(value: int) -> void:
	print("Dice rolled: ", value)


func smooth_follow_player(delta: float) -> void:
	if not camera or not active_player:
		return
	
	var target_pos = active_player.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target_pos, camera_follow_speed * delta)
	
	var look_target = active_player.global_position
	var current_transform = camera.global_transform
	var target_transform = current_transform.looking_at(look_target, Vector3.UP)
	camera.global_transform = current_transform.interpolate_with(target_transform, camera_rotation_speed * delta)


func show_tutorial() -> void:
	# Create tutorial dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Tutorial"
	dialog.dialog_text = """Welcome to Space Board Game!

HOW TO PLAY:
1. Press SPACE or click 'Roll Dice' to roll
2. Your character will move forward
3. Land on special tiles for events
4. Take turns until someone wins!

Good luck!"""
	dialog.ok_button_text = "Got it!"
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Wait for player to close
	await dialog.confirmed
	dialog.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if turn_manager and turn_manager.has_method("roll_dice"):
			turn_manager.roll_dice()
