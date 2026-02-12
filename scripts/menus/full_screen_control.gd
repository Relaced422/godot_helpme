extends CheckButton

func _ready():
	button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("Fullscreen script ready. Current mode: ", DisplayServer.window_get_mode())

func _on_toggled(toggled_on: bool) -> void:
	print("=== FULLSCREEN TOGGLE ===")
	print("Toggled to: ", toggled_on)
	print("Current mode before change: ", DisplayServer.window_get_mode())
	
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		print("Set to EXCLUSIVE_FULLSCREEN")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Set to WINDOWED")
	
	await get_tree().process_frame
	print("Current mode after change: ", DisplayServer.window_get_mode())
	print("=========================")
