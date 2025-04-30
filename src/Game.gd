extends Node2D

func _process(delta):
	if get_node_or_null("SettingsMenu") == null:
		if Input.is_action_just_pressed("ui_cancel"):
			SceneManager.open_pause_overlay()

func _on_settings_button_pressed():
	if get_node_or_null("SettingsMenu") == null:
		SceneManager.open_pause_overlay()

func return_to_main_menu():
	if get_tree().paused:
		get_tree().paused = false
	SceneManager.goto_scene("res://scenes/ui/MainMenu.tscn")
