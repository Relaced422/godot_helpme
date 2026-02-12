extends Node3D
class_name BoardTile

enum TileType {
	NORMAL,
	BAD,
	BLACK_HOLE,
	SKIP,
	REVERSE,
	FINISH
}

@export var tile_type: TileType = TileType.NORMAL
@export var tile_index: int = 0

# Visual indicators
var glow_indicator: MeshInstance3D = null
var tile_sprite: Sprite3D = null
var glow_height: float = 0.3
var sprite_height: float = 5.0  # MUCH HIGHER - easier to see
var glow_size: float = 5.0

# Animation
var pulse_speed: float = 2.5
var time_passed: float = 0.0

# Colors for glow
var tile_colors = {
	TileType.NORMAL: Color(0.8, 0.8, 0.8, 0.0),
	TileType.BAD: Color(1.0, 0.2, 0.2, 0.8),
	TileType.BLACK_HOLE: Color(0.302, 0.0, 0.502, 1.0),
	TileType.SKIP: Color(0.2, 1.0, 0.2, 0.9),
	TileType.REVERSE: Color(1.0, 0.3, 0.8, 0.9),
	TileType.FINISH: Color(1.0, 0.84, 0.0, 1.0)
}

# Emission intensity
var emission_strengths = {
	TileType.NORMAL: 1.0,
	TileType.BAD: 5.0,
	TileType.BLACK_HOLE: 5.0,
	TileType.SKIP: 5.0,
	TileType.REVERSE: 5.0,
	TileType.FINISH: 6.0
}

signal tile_landed(player, tile_type)


func _process(delta: float) -> void:
	time_passed += delta * pulse_speed
	var pulse = (sin(time_passed) + 1.0) / 2.0
	
	# Pulse glow
	if glow_indicator and glow_indicator.visible and glow_indicator.material_override:
		var base_energy = emission_strengths.get(tile_type, 1.0)
		glow_indicator.material_override.emission_energy = base_energy * (0.6 + pulse * 0.4)
		
		var scale_pulse = 1.0 + (pulse * 0.15)
		glow_indicator.scale = Vector3(scale_pulse, 1.0, scale_pulse)
	
	# Pulse sprite
	if tile_sprite and tile_sprite.visible:
		var sprite_pulse = (sin(time_passed * 0.8) + 1.0) / 2.0
		var sprite_scale = 1.0 + (sprite_pulse * 0.1)
		tile_sprite.scale = Vector3(sprite_scale, sprite_scale, sprite_scale)


func create_glow_indicator() -> void:
	glow_indicator = MeshInstance3D.new()
	get_tree().get_root().add_child(glow_indicator)
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = glow_size / 2.0
	cylinder_mesh.bottom_radius = glow_size / 2.0
	cylinder_mesh.height = 0.1
	glow_indicator.mesh = cylinder_mesh
	
	glow_indicator.global_position = global_position + Vector3(0, glow_height, 0)


func create_tile_sprite() -> void:
	tile_sprite = Sprite3D.new()
	add_child(tile_sprite)
	
	tile_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tile_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	tile_sprite.pixel_size = 0.2  # BIGGER - easier to see
	tile_sprite.position = Vector3(0, sprite_height, 0)
	tile_sprite.modulate = Color(1, 1, 1, 1)


func set_tile_type(type: TileType) -> void:
	tile_type = type
	
	if not glow_indicator:
		create_glow_indicator()
	
	if not tile_sprite:
		create_tile_sprite()
	
	update_visual()


func update_visual() -> void:
	# Update glow
	if glow_indicator:
		glow_indicator.visible = true
		
		var color = tile_colors.get(tile_type, Color.WHITE)
		
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
	
	# Update sprite
	if tile_sprite:
		var texture = load_sprite_for_type(tile_type)
		
		if texture:
			tile_sprite.texture = texture
			tile_sprite.visible = true
		else:
			tile_sprite.visible = false


func load_sprite_for_type(type: TileType) -> Texture2D:
	var path = ""
	
	match type:
		TileType.NORMAL:
			path = "res://assets/tiles/tile_normal.png"
		TileType.BAD:
			path = "res://assets/tiles/tile_bad.png"
		TileType.BLACK_HOLE:
			path = "res://assets/tiles/tile_black_hole.png"
		TileType.SKIP:
			path = "res://assets/tiles/tile_skip.png"
		TileType.REVERSE:
			path = "res://assets/tiles/tile_reverse.png"
		TileType.FINISH:
			path = "res://assets/tiles/tile_finish.png"
	
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	
	return null


func on_player_landed(player) -> void:
	tile_landed.emit(player, tile_type)
	
	match tile_type:
		TileType.BAD:
			var outcome = MinigameManager.play_minigame(player)
			if outcome == MinigameManager.Outcome.WIN:
				MinigameManager.give_reward(player)
		
		TileType.BLACK_HOLE:
			if player.has_method("teleport_to_tile"):
				player.teleport_to_tile(0)
		
		TileType.SKIP, TileType.REVERSE, TileType.FINISH:
			pass  # Handled by TurnManager
