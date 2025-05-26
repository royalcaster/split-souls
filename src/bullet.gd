extends Sprite2D

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var RayCast: RayCast2D = $RayCast2D

var speed: float = 1000.0

#########Abschnitt func _ready: Anzeige Marker für Bullet (zum Testen)
#func _ready():
	#var marker = ColorRect.new()
	#marker.color = Color.RED
	#marker.size = Vector2(4, 4)
	#marker.position = Vector2(-2, -2)
	#add_child(marker)

func _physics_process(delta: float) -> void:
	global_position += Vector2(1, 0).rotated(rotation) * speed * delta

	if RayCast.is_colliding():
		var collider = RayCast.get_collider()

		if collider != null and is_instance_valid(collider):
			if collider.has_method("take_damage"):
				collider.take_damage(20)
				AnimPlayer.play("remove")
			elif !collider.get("IS_PLAYER"):
				AnimPlayer.play("remove")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "remove":
		queue_free()


func _on_distance_timeout_timeout() -> void:
	AnimPlayer.play("remove")
