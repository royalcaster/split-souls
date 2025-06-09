extends StaticBody2D

func _ready():
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		self.visible = false



func _on_area_2d_body_entered(body):
	if not (body is Player):
		return
		
	var game = get_parent().get_parent()
	if game.has_method("on_crystal_direction_item_collected"):
		game.rpc("on_crystal_direction_item_collected")
#	await get_tree().idle_frame

	queue_free()
	$"../../AudioManager".play_audio_2d("item01")
