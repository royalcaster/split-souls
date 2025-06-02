extends StaticBody2D

var interactable = false

func _on_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseMotion and interactable:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	elif event is InputEventMouseButton and interactable:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if multiplayer.is_server():
				$CanvasLayer/SpeechbubbleDark.visible = true
				# speech bubble disappears after 10 seconds
				await get_tree().create_timer(5.0).timeout
				$CanvasLayer/SpeechbubbleDark.visible = false
			else: 
				$CanvasLayer/SpeechbubbleLight.visible = true
				# speech bubble disappears after 10 seconds
				await get_tree().create_timer(5.0).timeout
				$CanvasLayer/SpeechbubbleLight.visible = false
			

func _on_area_2d_body_entered(_body):
	if not (_body is Player):
		return

	interactable = true


func _on_area_2d_body_exited(_body):
	interactable = false
