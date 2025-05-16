extends Area2D

signal collected

@export var value: int = 1

func _on_body_entered(body: Node2D):
	if body.has_method("is_player"):
		collected.emit(value)
	queue_free()
