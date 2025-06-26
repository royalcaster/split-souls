extends StaticBody2D
class_name HeartContainer

#var player: Node2D = null

func _ready():
	add_to_group("map_content")
	
	if not multiplayer.is_server():
		self.visible = false

func HeartHeal(body: Node2D) -> void:
	if body is Player:
		if body.can_take_damage:
			body.healMax()
			queue_free()
