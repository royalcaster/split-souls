extends CharacterBody2D

# Export reference to the controller (set automatically when spawned)
var controller_node: Node = null

func _ready():
	set_multiplayer_authority(1)  # Host always has authority

func _physics_process(delta):
	if controller_node != null:
		velocity = controller_node.get_combined_input() * 400
		move_and_slide()
		
func set_sprite_variant(is_host: bool):
	var sprite_node = $Sprite2D
	if is_host:
		sprite_node.texture = preload("res://assets/img/slime_green.png")
	else:
		sprite_node.texture = preload("res://assets/img/slime_purple.png")
