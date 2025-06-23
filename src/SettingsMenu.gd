extends Control

var is_overlay: bool = false

func _ready():
	pass

func _on_pressed() -> void:
	if is_overlay:
		SceneManager.close_settings_overlay()
		queue_free()
	else:
		SceneManager.goto_scene("res://scenes/game/Game.tscn")


func _on_texture_button_pressed():
	get_tree().quit()
