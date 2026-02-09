extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	for slot in tile_slots:
		var tile = slot.get_child(0) as BoardTile
		tiles.append(tile)
	spawn_player()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var tile_slots = $Tiles.get_children()
var tiles: Array[BoardTile] = []

@export var player_scene: PackedScene

func spawn_player():
	var player = player_scene.instantiate()
	$Characters.add_child(player)
	player.transform = tile_slots[0].get_child(0).transform
	return
