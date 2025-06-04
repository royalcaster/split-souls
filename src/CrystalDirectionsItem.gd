extends Area2D

signal collected

func _ready() -> void:
	add_to_group("crystal_direction_items")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_player"):
		collected.emit()
		queue_free()
