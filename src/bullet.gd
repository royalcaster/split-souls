extends Sprite2D

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var RayCast: RayCast2D = $RayCast2D
@onready var sfx_shot = $sfx_shot

var speed: float = 1000.0
@export var damage: int = 20

func _physics_process(delta: float) -> void:
	global_position += Vector2(1, 0).rotated(rotation) * speed * delta

	if RayCast.is_colliding():
		var collider = RayCast.get_collider()

		if collider != null and is_instance_valid(collider):
			if collider.has_method("take_damage"):
				# Multiplayer: nur Schaden auf dem Server anwenden
				if multiplayer.is_server():
					collider.take_damage(damage)
				else:
					# Falls Client trifft, sagt er dem Server Bescheid --> funktioniert nicht, ist aber auch nicht notwenidg, da der Client nicht schießt
					rpc_id(1, "deal_damage_rpc", collider.get_path())  # 1 = Server-ID
				AnimPlayer.play("remove")
			elif not collider.get("IS_PLAYER"):
				AnimPlayer.play("remove")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "remove":
		queue_free()

func _on_distance_timeout_timeout() -> void:
	AnimPlayer.play("remove")

@rpc("any_peer", "reliable")
func deal_damage_rpc(collider_path: NodePath):
	var enemy = get_node_or_null(collider_path)
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)
