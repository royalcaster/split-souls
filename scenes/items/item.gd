extends StaticBody2D

@export var is_dark: bool = true  # Manuell im Editor setzen je nach Team

var collected_already: bool = false

func _ready():
	if not multiplayer.is_server():
		self.visible = false

	# Automatische Gruppenzuweisung
	if is_dark:
		add_to_group("team_items_dark")
	else:
		add_to_group("team_items_light")

func _on_area_2d_body_entered(body):
	if not (body is Player):
		return

	if Globals.is_loading:
		return

	if collected_already:
		return

	collected_already = true

	var game = get_parent().get_parent()
	if game.has_method("on_item_collected"):
		game.on_item_collected.rpc(Globals.generate_synced_random_item_type())

	queue_free()
	$"../../AudioManager".play_audio_2d("item01")

func restore_after_load(collected: bool) -> void:
	collected_already = collected
	visible = not collected
