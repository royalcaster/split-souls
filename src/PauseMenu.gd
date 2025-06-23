extends Control

var is_overlay: bool = true

func _ready():
	pass
	
func _process(delta):
	if is_overlay:
		if Input.is_action_just_pressed("ui_cancel"):
			SceneManager.close_pause_overlay()

func _on_continue_button_pressed() -> void:
	if is_overlay:
		SceneManager.close_pause_overlay()

func _on_exit_button_pressed() -> void:
	if is_overlay:
		SceneManager.close_pause_overlay()
		SceneManager.goto_scene("res://scenes/ui/MainMenu.tscn")
