extends CharacterBody2D

# Export reference to the controller (set automatically when spawned)
var controller_node: Node = null

func _ready():
	set_multiplayer_authority(1)  # Host always has authority

func _physics_process(delta):
	if controller_node != null:
		velocity = controller_node.get_combined_input() * 400
		move_and_slide()
