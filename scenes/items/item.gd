extends StaticBody2D

func _ready():
	if not multiplayer.is_server():
		self.visible = false



func _on_area_2d_body_entered(body):
	if not (body is Player):
		return

	var game = get_parent().get_parent()
	if game.has_method("on_item_collected"):
		game.on_item_collected.rpc(Globals.generate_synced_random_item_type())
	queue_free()
	$"../../AudioManager".play_audio_2d("item01")

