

extends WorldEnvironment

@export var rotation_speed := 0.01

#func _process(delta):    
	#if environment and environment.sky:
		#environment.sky.rotation.y += rotation_speed * delta
