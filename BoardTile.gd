extends Node3D
class_name BoardTile

enum TileState {
	NORMAL,
	DANGER,
	BLOCKED
}

@export var tile_id: int
@export var state: TileState = TileState.NORMAL

var default_next_tiles: Array[BoardTile] = []
var current_next_tiles: Array[BoardTile] = []

func set_state(new_state: TileState):
	state = new_state
	update_visual()
	update_connections()

func update_visual():
	var mat := StandardMaterial3D.new()
	match state:
		TileState.NORMAL:
			mat.albedo_color = Color.WHITE
		TileState.DANGER:
			mat.albedo_color = Color.RED
		TileState.BLOCKED:
			mat.albedo_color = Color.DARK_GRAY
	$Mesh.material_override = mat

func update_connections():
	if state == TileState.BLOCKED:
		current_next_tiles.clear()
	else:
		current_next_tiles = default_next_tiles.duplicate()
