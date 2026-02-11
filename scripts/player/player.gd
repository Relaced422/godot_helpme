extends Node3D
class_name Player

# Player properties
@export var player_name: String = "Player"
@export var player_color: Color = Color.WHITE
@export var movement_speed: float = 10.0
@export var character_type: GameManager.Character = GameManager.Character.LAIKA

# Current state
var current_tile_index: int = 0
var is_moving: bool = false
var current_direction: Vector3 = Vector3.FORWARD

# References
var board: Node3D = null
var visual: Node3D = null
var name_label: Label3D = null
var sprite: Sprite3D = null

# Directional sprites
var sprite_front: Texture2D
var sprite_back: Texture2D
var sprite_left: Texture2D
var sprite_right: Texture2D

# Inventory
var inventory: Inventory = null

# Item effects state
var force_next_roll_to_1: bool = false
var roll_twice_take_lower: bool = false
var halve_next_rolls: int = 0  # Number of rolls to halve
var last_turn_position: int = 0  # For time rewind

signal movement_started
signal movement_finished
signal landed_on_tile(tile_index: int)


func _ready():
	# Create inventory
	inventory = Inventory.new()
	add_child(inventory)
	
	# Find visual
	if has_node("Visual"):
		visual = $Visual
		
		# Setup sprite if it exists
		if visual.has_node("Sprite3D"):
			sprite = visual.get_node("Sprite3D")
			load_character_sprites()
			setup_sprite()
		
		# Find name label
		if visual.has_node("NameLabel"):
			name_label = visual.get_node("NameLabel")
			update_name_label()


func load_character_sprites() -> void:
	var char_data = GameManager.get_character_data(character_type)
	
	if char_data.is_empty():
		return
	
	# Load textures
	sprite_front = load(char_data["front"])
	sprite_back = load(char_data["back"])
	sprite_left = load(char_data["left"])
	sprite_right = load(char_data["right"])
	
	# Set player color from character
	player_color = char_data.get("color", Color.WHITE)


func setup_sprite() -> void:
	if not sprite:
		return
	
	# Load character sprites
	load_character_sprites()
	
	# Set initial texture
	if sprite_front:
		sprite.texture = sprite_front
	
	# Configure sprite
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = Color.WHITE
	sprite.pixel_size = 0.005
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector3(0.5, 0.5, 0.5)
	sprite.position.y = 1.0


func update_name_label() -> void:
	if name_label:
		name_label.text = player_name


func update_sprite_direction(move_direction: Vector3) -> void:
	if not sprite:
		return
	
	var dir = move_direction.normalized()
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var cam_forward = -camera.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var cam_right = camera.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var forward_dot = dir.dot(cam_forward)
	var right_dot = dir.dot(cam_right)
	
	if abs(forward_dot) > abs(right_dot):
		if forward_dot > 0:
			sprite.texture = sprite_back
		else:
			sprite.texture = sprite_front
	else:
		if right_dot > 0:
			sprite.texture = sprite_right
		else:
			sprite.texture = sprite_left


## Main movement function
func move_forward(steps: int) -> void:
	if is_moving:
		return
	
	if board == null:
		push_error("Player has no board reference!")
		return
	
	var tiles = board.get_tiles()
	if tiles.is_empty():
		return
	
	# Save position for time rewind
	last_turn_position = current_tile_index
	
	# Apply item effects to dice roll
	var modified_steps = steps
	
	# Force roll to 1
	if force_next_roll_to_1:
		modified_steps = 1
		force_next_roll_to_1 = false
		print("🛰 Roll forced to 1!")
	
	# Halve roll
	elif halve_next_rolls > 0:
		modified_steps = int(steps / 2.0)
		halve_next_rolls -= 1
		print("🌑 Roll halved! ", steps, " → ", modified_steps)
	
	# Check if we're on a reverse tile BEFORE moving
	var current_tile = tiles[current_tile_index]
	var is_reverse = false
	
	if current_tile.has_method("get") and current_tile.get("tile_type") == BoardTile.TileType.REVERSE:
		is_reverse = true
		modified_steps = -modified_steps
		print("🔄 Reversing movement! Going back ", abs(modified_steps), " spaces")
	
	is_moving = true
	movement_started.emit()
	
	await move_step_by_step(modified_steps, tiles)
	
	is_moving = false
	movement_finished.emit()
	landed_on_tile.emit(current_tile_index)

## Move step by step with hop
func move_step_by_step(total_steps: int, tiles: Array) -> void:
	var direction = 1 if total_steps > 0 else -1
	var abs_steps = abs(total_steps)
	
	for step in range(abs_steps):
		var previous_index = current_tile_index
		current_tile_index = (current_tile_index + direction) % tiles.size()
		
		# Handle negative wrapping
		if current_tile_index < 0:
			current_tile_index = tiles.size() + current_tile_index
		
		var target_tile = tiles[current_tile_index]
		var target_position = target_tile.global_position
		
		# Calculate movement direction for sprite
		var move_direction = target_position - global_position
		update_sprite_direction(move_direction)
		
		await move_with_hop(target_position)
		await get_tree().create_timer(0.05).timeout
	
	# Notify board about landing
	if board and board.has_method("player_landed_on_tile"):
		board.player_landed_on_tile(self, current_tile_index)


## Move with hopping animation
func move_with_hop(target_pos: Vector3) -> void:
	var start_pos = global_position
	var distance = start_pos.distance_to(target_pos)
	var duration = distance / movement_speed
	
	var elapsed = 0.0
	var hop_height = 1.0
	
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t = clampf(elapsed / duration, 0.0, 1.0)
		var eased_t = ease(t, -2.0)
		
		var current_pos = start_pos.lerp(target_pos, eased_t)
		var hop = sin(t * PI) * hop_height
		current_pos.y += hop
		
		global_position = current_pos
		await get_tree().process_frame
	
	global_position = target_pos


## Teleport to tile
func teleport_to_tile(tile_index: int) -> void:
	if board == null:
		return
	
	var tiles = board.get_tiles()
	if tile_index < 0 or tile_index >= tiles.size():
		return
	
	current_tile_index = tile_index
	global_position = tiles[tile_index].global_position


## Set board reference
func set_board(board_node: Node3D) -> void:
	board = board_node


## Set character from GameManager
func set_character(character: GameManager.Character) -> void:
	character_type = character
	if sprite:
		load_character_sprites()
		setup_sprite()
