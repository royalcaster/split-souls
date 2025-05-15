extends Area2D

func _on_body_entered(body):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		Globals.control_mode = Globals.ControlMode.INDIVIDUAL
	else:
		Globals.control_mode = Globals.ControlMode.SHARED
	print("---host? ", multiplayer.is_server())
	print("---mode ", Globals.control_mode)

	
