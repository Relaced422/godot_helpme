extends RigidBody3D

signal die_settled(face_number)

var is_rolling = false
var settle_timer = 0.0
var settle_threshold = 0.1

func _process(delta):
	if is_rolling:
		if linear_velocity.length() < settle_threshold and angular_velocity.length() < settle_threshold:
			settle_timer += delta
			if settle_timer > 0.5:
				is_rolling = false
				settle_timer = 0.0
				detect_top_face()
		else:
			settle_timer = 0.0

func roll_die():
	if is_rolling:
		return
	
	is_rolling = true
	
	global_position = Vector3(randf_range(-0.5, 0.5), randf_range(3, 5), randf_range(-0.5, 0.5))
	rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	var random_force = Vector3(randf_range(-3, 3), randf_range(-1, 1), randf_range(-3, 3))
	var random_torque = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
	
	apply_central_impulse(random_force)
	apply_torque_impulse(random_torque)

func detect_top_face():
	var face_normals = {
		1: Vector3(0, 0, 1),
		6: Vector3(0, 0, -1),
		3: Vector3(0, 1, 0),
		4: Vector3(0, -1, 0),
		2: Vector3(1, 0, 0),
		5: Vector3(-1, 0, 0)
	}
	
	var max_dot = -1.0
	var top_face = 1
	
	for face_number in face_normals:
		var world_normal = global_transform.basis * face_normals[face_number]
		var dot_product = world_normal.dot(Vector3.UP)
		if dot_product > max_dot:
			max_dot = dot_product
			top_face = face_number
	
	print("Die settled! Top face: ", top_face)
	emit_signal("die_settled", top_face)
