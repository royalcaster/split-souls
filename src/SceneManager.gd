extends Node

var current_scene_path: String = ""
var game_scene_instance = null

func goto_scene(scene_path: String):
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free()

	var next_scene = load(scene_path)
	if next_scene:
		var scene_instance = next_scene.instantiate()
		current_scene_path = scene_path
		get_tree().root.add_child(scene_instance)
		get_tree().current_scene = scene_instance
		print("Changed scene to: ", scene_path)
	else:
		printerr("Failed to load scene: ", scene_path)

func open_pause_overlay():
	if not current_scene_path.begins_with("res://scenes/game/"):
		return

	var current_scene = get_tree().current_scene
	if current_scene and current_scene.find_child("PauseOverlay", false):
		return

	if not get_tree().paused:
		get_tree().paused = true
		var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
		if not pause_scene:
			printerr("Failed to load PauseMenu scene!")
			get_tree().paused = false
			return

		var pause_instance = pause_scene.instantiate()
		if not pause_instance or not pause_instance.has_method("_on_exit_button_pressed"):
			printerr("PauseMenu instance is invalid or missing script.")
			get_tree().paused = false
			return

		pause_instance.is_overlay = true
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "PauseOverlay"

		canvas_layer.add_child(pause_instance)
		get_tree().current_scene.add_child(canvas_layer)

func close_pause_overlay():
	if get_tree().paused:
		get_tree().paused = false
		print("Closing pause overlay")	
		
	var current_scene = get_tree().current_scene
	if current_scene:
		var canvas_layer = current_scene.find_child("PauseOverlay", true, false)
		if canvas_layer:
			canvas_layer.queue_free()
		else:
			printerr("Could not find PauseOverlay to remove.")
	else:
		printerr("Cannot close overlay, current scene is null.")
