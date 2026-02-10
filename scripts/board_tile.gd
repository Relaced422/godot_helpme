extends Node3D
class_name BoardTile

# Tile types
enum TileType {
	NORMAL,
	BAD,
	BLACK_HOLE,
	SKIP,
	REVERSE
}

@export var tile_type: TileType = TileType.NORMAL
@export var tile_index: int = 0

@onready var mesh_instance: MeshInstance3D = null

var tile_colors = {
	TileType.NORMAL: Color(1.0, 1.0, 1.0, 1.0),
	TileType.BAD: Color(1.0, 0.3, 0.3, 0.4),
	TileType.BLACK_HOLE: Color(0.1, 0.0, 0.2, 1.0),
	TileType.SKIP: Color(0.3, 1.0, 0.3, 1.0),
	TileType.REVERSE: Color(1.0, 0.4, 0.8, 1.0)
}

signal tile_landed(player, tile_type)


func _ready():
	find_mesh()
	update_visual()


func find_mesh() -> void:
	if has_node("MeshInstance3D"):
		mesh_instance = get_node("MeshInstance3D")
	else:
		for child in get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break


func set_tile_type(type: TileType) -> void:
	tile_type = type
	update_visual()


func update_visual() -> void:
	if not mesh_instance:
		return
	
	var color = tile_colors.get(tile_type, Color.WHITE)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	
	if tile_type == TileType.BAD:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	match tile_type:
		TileType.BLACK_HOLE:
			material.emission_enabled = true
			material.emission = Color(0.2, 0.0, 0.4)
			material.emission_energy = 0.5
		TileType.SKIP:
			material.emission_enabled = true
			material.emission = Color(0.0, 0.5, 0.0)
			material.emission_energy = 0.3
		TileType.REVERSE:
			material.emission_enabled = true
			material.emission = Color(0.8, 0.0, 0.4)
			material.emission_energy = 0.3
	
	mesh_instance.material_override = material


func on_player_landed(player) -> void:
	print("Player landed on ", TileType.keys()[tile_type], " tile")
	tile_landed.emit(player, tile_type)
	
	match tile_type:
		TileType.BAD:
			trigger_minigame(player)
		TileType.BLACK_HOLE:
			send_to_start(player)
		TileType.SKIP:
			skip_turn(player)
		TileType.REVERSE:
			pass


func trigger_minigame(player) -> void:
	print("🎮 Minigame triggered for ", player.player_name)


func send_to_start(player) -> void:
	print("🕳️ Black hole! Sending ", player.player_name, " to start")
	if player.has_method("teleport_to_tile"):
		player.teleport_to_tile(0)


func skip_turn(player) -> void:
	print("🟢 Skip tile! ", player.player_name, "'s next turn will be skipped")
