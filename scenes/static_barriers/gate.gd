extends Area2D

@export var game_node_path: NodePath
var game_node: Node
var bodies_in_gate := []

func _ready():
	game_node = get_node_or_null(game_node_path)

func _on_body_entered(body):
	if not (body is Player):
		return

	# checks if character is already in gate and if not, add them to list
	if body not in bodies_in_gate:
		bodies_in_gate.append(body)
	
	# Only host triggers mode switch (technical reason)
	if multiplayer.is_server():
		if (Globals.ControlMode.INDIVIDUAL and bodies_in_gate.size() >= 2) or Globals.control_mode == Globals.ControlMode.SHARED:
			game_node.rpc("switch_control_mode", Globals.control_mode)


func _on_body_exited(body):
	if body in bodies_in_gate:
		bodies_in_gate.erase(body)
