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

# Visual indicator (glowing circle/plane in center)
var glow_indicator: MeshInstance3D = null
var glow_height: float = 0.3
var glow_size: float = 5.0

# Pulsing animation
var pulse_enabled: bool = true
var pulse_speed: float = 2.5
var time_passed: float = 0.0

# Colors for each tile type
var tile_colors = {
	TileType.NORMAL: Color(0.8, 0.8, 0.8, 0.0),        # Light gray
	TileType.BAD: Color(1.0, 0.2, 0.2, 0.8),           # Red
	TileType.BLACK_HOLE: Color(0.302, 0.0, 0.502, 1.0),   # Dark purple
	TileType.SKIP: Color(0.2, 1.0, 0.2, 0.9),          # Green
	TileType.REVERSE: Color(1.0, 0.3, 0.8, 0.9)        # Pink
}

# Emission intensity for each tile type
var emission_strengths = {
	TileType.NORMAL: 1.0,
	TileType.BAD: 3.0,
	TileType.BLACK_HOLE: 5.0,
	TileType.SKIP: 4.0,
	TileType.REVERSE: 4.5
}

signal tile_landed(player, tile_type)


func _ready():
	print("BoardTile _ready() - Index: ", tile_index, " Type: ", TileType.keys()[tile_type])
	# Don't create or update visual here - wait for set_tile_type to be called
	# This prevents the initial white glow


func _process(delta: float) -> void:
	# Pulse effect for special tiles
	if pulse_enabled and glow_indicator and glow_indicator.visible:
		time_passed += delta * pulse_speed
		var pulse = (sin(time_passed) + 1.0) / 2.0
		
		if glow_indicator.material_override:
			var base_energy = emission_strengths.get(tile_type, 1.0)
			glow_indicator.material_override.emission_energy = base_energy * (0.6 + pulse * 0.4)
			
			var scale_pulse = 1.0 + (pulse * 0.15)
			glow_indicator.scale = Vector3(scale_pulse, 1.0, scale_pulse)


func ensure_glow_exists() -> void:
	# Create glow if it doesn't exist yet
	if glow_indicator == null:
		create_glow_indicator()


func create_glow_indicator() -> void:
	print("  Creating glow indicator for tile ", tile_index)
	glow_indicator = MeshInstance3D.new()
	
	# Add to scene root instead of self, but position relative to this tile
	get_tree().get_root().add_child(glow_indicator)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = glow_size / 2.0
	cylinder_mesh.bottom_radius = glow_size / 2.0
	cylinder_mesh.height = 0.1
	glow_indicator.mesh = cylinder_mesh
	
	# Set global position
	glow_indicator.global_position = global_position + Vector3(0, glow_height, 0)
	
func set_tile_type(type: TileType) -> void:
	print("  set_tile_type() called on tile ", tile_index, " -> ", TileType.keys()[type])
	tile_type = type
	
	# Make sure glow exists before updating visual
	ensure_glow_exists()
	update_visual()


func update_visual() -> void:
	if not glow_indicator:
		print("    WARNING: glow_indicator still null in update_visual!")
		return
	
	# Show all glows (even normal for testing)
	glow_indicator.visible = true
	
	var color = tile_colors.get(tile_type, Color.WHITE)
	
	print("    Applying ", TileType.keys()[tile_type], " color: ", color, " to tile ", tile_index)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy = emission_strengths.get(tile_type, 1.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	glow_indicator.material_override = material
	glow_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	print("    ✓ Material applied successfully!")


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
