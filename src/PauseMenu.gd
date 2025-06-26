extends Control

var is_overlay: bool = true

func _ready():
	pass

func _on_continue_button_pressed() -> void:
	if is_overlay:
		close_pause_overlay_rpc.rpc()
		
@rpc("any_peer", "call_local", "reliable")
func close_pause_overlay_rpc():
	SceneManager.close_pause_overlay()

func _on_texture_button_pressed():
	get_tree().quit()
