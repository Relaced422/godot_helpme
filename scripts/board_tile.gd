extends Node3D
class_name BoardTile

enum TileType {
	NORMAL,
	BAD,
	BLACK_HOLE,
	SKIP,
	REVERSE
}

@export var tile_type: TileType = TileType.NORMAL
@export var tile_index: int = 0

# Sprite indicator (icon above tile)
var icon_sprite: Sprite3D = null
var icon_height: float = 0.8
var icon_size: float = 0.6

# Visual indicator (glowing cylinder in center)
var glow_indicator: MeshInstance3D = null
var glow_height: float = 0.3
var glow_size: float = 5.0

# Pulsing animation
var pulse_speed: float = 2.5
var time_passed: float = 0.0

var tile_colors = {
	TileType.NORMAL: Color(0.8, 0.8, 0.8, 0.0),
	TileType.BAD: Color(1.0, 0.118, 0.0, 1.0),
	TileType.BLACK_HOLE: Color(0.392, 0.002, 0.72, 1.0),
	TileType.SKIP: Color(0.2, 1.0, 0.2, 1.0),
	TileType.REVERSE: Color(0.0, 0.339, 0.888, 1.0)
}

var emission_strengths = {
	TileType.NORMAL: 1.0,
	TileType.BAD: 3.0,
	TileType.BLACK_HOLE: 5.0,
	TileType.SKIP: 4.0,
	TileType.REVERSE: 4.5
}

signal tile_landed(player, tile_type)


func _process(delta: float) -> void:
	if glow_indicator and glow_indicator.visible and glow_indicator.material_override:
		time_passed += delta * pulse_speed
		var pulse = (sin(time_passed) + 1.0) / 2.0
		var base_energy = emission_strengths.get(tile_type, 1.0)
		glow_indicator.material_override.emission_energy = base_energy * (0.6 + pulse * 0.4)
		glow_indicator.scale = Vector3(1.0 + pulse * 0.15, 1.0, 1.0 + pulse * 0.15)


func create_glow_indicator() -> void:
	glow_indicator = MeshInstance3D.new()
	add_child(glow_indicator)

	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = glow_size / 2.0
	cylinder_mesh.bottom_radius = glow_size / 2.0
	cylinder_mesh.height = 0.1
	glow_indicator.mesh = cylinder_mesh
	glow_indicator.position = Vector3(0, glow_height, 0)

	create_tile_icon()


func set_tile_type(type: TileType) -> void:
	tile_type = type

	if glow_indicator == null:
		create_glow_indicator()

	update_visual()
	update_tile_icon()


func create_tile_icon() -> void:
	icon_sprite = Sprite3D.new()
	add_child(icon_sprite)

	icon_sprite.position = Vector3(0, icon_height, 0)
	icon_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	icon_sprite.pixel_size = 0.005 / icon_size
	icon_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	update_tile_icon()


func update_tile_icon() -> void:
	if not icon_sprite:
		return

	match tile_type:
		TileType.NORMAL:
			icon_sprite.texture = null
		TileType.BAD:
			icon_sprite.texture = preload("res://assets/sprites/tile_bad.png")
		TileType.BLACK_HOLE:
			icon_sprite.texture = preload("res://assets/sprites/tile_blackhole.png")
		TileType.SKIP:
			icon_sprite.texture = preload("res://assets/sprites/tile_skip.png")
		TileType.REVERSE:
			icon_sprite.texture = preload("res://assets/sprites/tile_reverse.png")

	icon_sprite.visible = icon_sprite.texture != null


func update_visual() -> void:
	if not glow_indicator:
		return

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


func on_player_landed(player) -> void:
	tile_landed.emit(player, tile_type)

	match tile_type:
		TileType.BAD:
			trigger_minigame(player)
		TileType.BLACK_HOLE:
			send_to_start(player)
		TileType.SKIP:
			pass  # Handled by TurnManager via tile_effect_triggered


func trigger_minigame(player) -> void:
	# Simulate minigame (replace with actual minigame later)
	await get_tree().create_timer(1.0).timeout

	var random_item = ItemData.get_random_item()
	if player.inventory.add_item(random_item):
		var item_info = ItemData.get_item_info(random_item)
		if get_tree().root.has_node("Main/UI/GameUI"):
			var game_ui = get_tree().root.get_node("Main/UI/GameUI")
			game_ui.show_message(player.player_name + " won " + item_info["name"] + "!")


func send_to_start(player) -> void:
	player.teleport_to_tile(0)
