extends StaticBody2D

@onready var sprite = $Sprite2D
var interactable = false
@export var mini_game_version = 0

func _on_area_2d_body_entered(body):
	if not (body is Player):
		return
	$"../../AudioManager".play_audio_2d("barrier")
	interactable = true

func _on_area_2d_body_exited(_body):
	interactable = false


func _on_clickable_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseMotion and interactable:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	elif event is InputEventMouseButton and interactable:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			var game = get_parent().get_parent()
			if game.has_method("open_minigame"):
				game.open_minigame.rpc(get_path(), mini_game_version)

func _on_clickable_area_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
