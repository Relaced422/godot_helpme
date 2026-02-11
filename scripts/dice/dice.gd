extends Node3D
class_name Dice

var dice_mesh: MeshInstance3D = null
@export var dice_texture: Texture2D = null

var is_rolling: bool = false
var target_value: int = 1
var roll_duration: float = 1.2
var bounce_height: float = 2.0
var spin_speed: float = 1080.0

signal roll_finished


func _ready():
	create_custom_dice()


func create_custom_dice() -> void:
	dice_mesh = MeshInstance3D.new()
	add_child(dice_mesh)
	
	# Create custom mesh with UV mapping
	var mesh = create_dice_mesh_with_uvs()
	dice_mesh.mesh = mesh
	
	# Load texture
	if dice_texture == null:
		dice_texture = load("res://assets/dice/dice_texture.png")
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_texture = dice_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	dice_mesh.material_override = material


func create_dice_mesh_with_uvs() -> ArrayMesh:
	var vertices = PackedVector3Array([
		# Front face (1)
		Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5),
		Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5),
		# Back face (6)
		Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5),
		Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5),
		# Top face (3)
		Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5),
		Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5),
		# Bottom face (4)
		Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5),
		Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5),
		# Right face (2)
		Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5),
		Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5),
		# Left face (5)
		Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5),
		Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5),
	])
	
	# UV coordinates - adjust these based on your texture layout
	# This assumes a cross-shaped dice net
	var uvs = PackedVector2Array([
		# Front (1) - center
		Vector2(0.25, 0.5), Vector2(0.5, 0.5),
		Vector2(0.5, 0.75), Vector2(0.25, 0.75),
		# Back (6) - right
		Vector2(0.75, 0.5), Vector2(1.0, 0.5),
		Vector2(1.0, 0.75), Vector2(0.75, 0.75),
		# Top (3) - top center
		Vector2(0.25, 0.75), Vector2(0.5, 0.75),
		Vector2(0.5, 1.0), Vector2(0.25, 1.0),
		# Bottom (4) - bottom center
		Vector2(0.25, 0.25), Vector2(0.5, 0.25),
		Vector2(0.5, 0.5), Vector2(0.25, 0.5),
		# Right (2) - right of center
		Vector2(0.5, 0.5), Vector2(0.75, 0.5),
		Vector2(0.75, 0.75), Vector2(0.5, 0.75),
		# Left (5) - left of center
		Vector2(0.0, 0.5), Vector2(0.25, 0.5),
		Vector2(0.25, 0.75), Vector2(0.0, 0.75),
	])
	
	# Indices for triangles
	var indices = PackedInt32Array([
		0, 1, 2,  0, 2, 3,   # Front
		4, 5, 6,  4, 6, 7,   # Back
		8, 9, 10, 8, 10, 11, # Top
		12, 13, 14, 12, 14, 15, # Bottom
		16, 17, 18, 16, 18, 19, # Right
		20, 21, 22, 20, 22, 23, # Left
	])
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh


# Rest of the functions (animate_roll, set_dice_rotation) same as Method 1
func roll_dice(value: int) -> void:
	if is_rolling:
		return
	
	target_value = value
	is_rolling = true
	visible = true
	
	await animate_roll()
	
	is_rolling = false
	roll_finished.emit()


func animate_roll() -> void:
	var start_pos = global_position
	var elapsed = 0.0
	
	while elapsed < roll_duration:
		elapsed += get_process_delta_time()
		var t = elapsed / roll_duration
		
		var bounce = sin(t * PI) * bounce_height
		global_position = start_pos + Vector3(0, bounce, 0)
		
		dice_mesh.rotation_degrees += Vector3(
			spin_speed * get_process_delta_time(),
			spin_speed * get_process_delta_time() * 0.7,
			spin_speed * get_process_delta_time() * 0.5
		)
		
		await get_tree().process_frame
	
	set_dice_rotation(target_value)
	global_position = start_pos
	
	await get_tree().create_timer(2.0).timeout
	
	var fade_duration = 0.5
	elapsed = 0.0
	while elapsed < fade_duration:
		elapsed += get_process_delta_time()
		var alpha = 1.0 - (elapsed / fade_duration)
		
		if dice_mesh.material_override:
			dice_mesh.material_override.albedo_color = Color(1, 1, 1, alpha)
		
		await get_tree().process_frame
	
	visible = false
	
	if dice_mesh.material_override:
		dice_mesh.material_override.albedo_color = Color.WHITE


func set_dice_rotation(value: int) -> void:
	match value:
		1:
			dice_mesh.rotation_degrees = Vector3(0, 0, 0)
		2:
			dice_mesh.rotation_degrees = Vector3(0, 90, 0)
		3:
			dice_mesh.rotation_degrees = Vector3(90, 0, 0)
		4:
			dice_mesh.rotation_degrees = Vector3(-90, 0, 0)
		5:
			dice_mesh.rotation_degrees = Vector3(0, -90, 0)
		6:
			dice_mesh.rotation_degrees = Vector3(0, 180, 0)
