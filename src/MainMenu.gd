extends Control

func _on_play_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/game/Game.tscn")

func _on_settings_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/ui/SettingsMenu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
