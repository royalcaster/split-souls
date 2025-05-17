extends Area2D

@export var game_node_path: NodePath
var game_node: Node

func _ready():
	game_node = get_node(game_node_path)

func _on_body_entered(body):
	if body is Player and multiplayer.is_server():
		game_node.rpc("switch_control_mode")
