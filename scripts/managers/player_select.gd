extends Control

signal player_count_selected(count: int)

@onready var button_2_players = $VBoxContainer/Button2Players
@onready var button_3_players = $VBoxContainer/Button3Players
@onready var button_4_players = $VBoxContainer/Button4Players


func _ready():
	button_2_players.pressed.connect(_on_player_count_selected.bind(2))
	button_3_players.pressed.connect(_on_player_count_selected.bind(3))
	button_4_players.pressed.connect(_on_player_count_selected.bind(4))


func _on_player_count_selected(count: int) -> void:
	player_count_selected.emit(count)
	hide()  # Hide menu after selection
