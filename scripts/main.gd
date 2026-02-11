extends Node3D

@onready var board: Node3D = $Board
@onready var turn_manager: TurnManager = $TurnManager
@onready var camera: Camera3D = $Camera3D if has_node("Camera3D") else null
@onready var game_ui: Control = $UI/GameUI if has_node("UI/GameUI") else null
@onready var dice: Node3D = $Dice if has_node("Dice") else null

@export var camera_offset: Vector3 = Vector3(0, 10, 10)
@export var camera_follow_speed: float = 5.0
@export var camera_rotation_speed: float = 8.0

var players: Array = []
var player_scene = preload("res://scenes/player/player.tscn")
var active_player: Node3D = null


func _ready():
	spawn_players()
	setup_game()

	if GameManager.show_tutorial:
		show_tutorial()


func _process(delta: float) -> void:
	if camera and active_player:
		smooth_follow_player(delta)


func spawn_players() -> void:
	for i in range(GameManager.num_players):
		var player = player_scene.instantiate()
		add_child(player)

		var char_type = GameManager.selected_characters[i]
		var char_data = GameManager.get_character_data(char_type)

		player.player_name = "Player " + str(i + 1)
		player.player_color = char_data.get("color", Color.WHITE)
		player.set_character(char_type)

		players.append(player)


func setup_game() -> void:
	if not board:
		push_error("Missing board!")
		return

	for player in players:
		player.set_board(board)
		player.teleport_to_tile(0)
		turn_manager.add_player(player)

	if dice:
		turn_manager.set_dice(dice)

	if game_ui:
		game_ui.setup(turn_manager)

	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.start_game()


func _on_turn_started(player) -> void:
	active_player = player


func smooth_follow_player(delta: float) -> void:
	var target_pos = active_player.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target_pos, camera_follow_speed * delta)

	var current_transform = camera.global_transform
	var target_transform = current_transform.looking_at(active_player.global_position, Vector3.UP)
	camera.global_transform = current_transform.interpolate_with(target_transform, camera_rotation_speed * delta)


func show_tutorial() -> void:
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

	await dialog.confirmed
	dialog.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and turn_manager:
		turn_manager.roll_dice()
