extends Node3D
class_name Dice

@onready var dice_mesh: MeshInstance3D = $DiceMesh
@onready var faces: Node3D = $Faces if has_node("Faces") else null

# Animation settings
@export var roll_duration: float = 1.0
@export var bounce_height: float = 3.0
@export var spin_speed: float = 720.0  # Degrees per second

var is_rolling: bool = false
var final_value: int = 1

signal roll_finished(value: int)


func _ready():
	# Start hidden
	visible = false


## Roll the dice and show result
func roll_dice(value: int) -> void:
	if is_rolling:
		return
	
	final_value = value
	is_rolling = true
	visible = true
	
	# Perform roll animation
	await animate_roll()
	
	# Show final result
	show_result(final_value)
	
	is_rolling = false
	roll_finished.emit(final_value)
	
	# Hide after delay
	await get_tree().create_timer(1.5).timeout
	visible = false


## Animate the dice roll
func animate_roll() -> void:
	var start_pos = global_position
	var elapsed = 0.0
	
	# Reset rotation
	rotation = Vector3.ZERO
	
	while elapsed < roll_duration:
		elapsed += get_process_delta_time()
		var t = elapsed / roll_duration
		
		# Bounce motion (parabolic)
		var height = sin(t * PI) * bounce_height
		global_position = start_pos + Vector3(0, height, 0)
		
		# Spin rapidly
		rotation.x += deg_to_rad(spin_speed * get_process_delta_time())
		rotation.y += deg_to_rad(spin_speed * 0.7 * get_process_delta_time())
		rotation.z += deg_to_rad(spin_speed * 0.5 * get_process_delta_time())
		
		await get_tree().process_frame
	
	# Land back at start position
	global_position = start_pos


## Show the final dice value
# In dice.gd, replace show_result with:

func show_result(value: int) -> void:
	# Hide all faces first
	if faces:
		for face in faces.get_children():
			face.visible = false
		
		# Show only the rolled face
		var face_name = "Face" + str(value)
		if faces.has_node(face_name):
			var rolled_face = faces.get_node(face_name)
			rolled_face.visible = true
	
	# Rotate to show top face
	rotation = Vector3(deg_to_rad(-90), 0, 0)
	
	# Match final rotation based on value
	match value:
		1: rotation = Vector3.ZERO
		2: rotation = Vector3(0, deg_to_rad(180), 0)
		3: rotation = Vector3(0, deg_to_rad(-90), 0)
		4: rotation = Vector3(0, deg_to_rad(90), 0)
		5: rotation = Vector3(deg_to_rad(-90), 0, 0)
		6: rotation = Vector3(deg_to_rad(90), 0, 0)
	
	# Smooth rotation to final position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
