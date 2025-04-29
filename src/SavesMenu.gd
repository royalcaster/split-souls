extends Control

func _on_play_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/game/Game.tscn")

func _on_back_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/ui/MainMenu.tscn")
