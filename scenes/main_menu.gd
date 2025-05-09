extends Node2D

func _on_shared_control_button_pressed():
	get_tree().change_scene_to_file("res://scenes/shared_mode/shared_mode.tscn")


func _on_separate_control_button_pressed():
	print("sep")
	get_tree().change_scene_to_file("res://scenes/separate_mode/separate_mode.tscn") 
