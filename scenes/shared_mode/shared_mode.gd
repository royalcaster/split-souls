extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
var player_inputs = {}  # Stores all players' input vectors
var shared_player = null  # Reference to the single player instance


func _on_host_pressed():
	peer.create_server(445)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player_input)
	_add_player(multiplayer.get_unique_id())  # Add host player


func _add_player(id):
	player_inputs[id] = Vector2.ZERO
	# Only host creates the shared character
	if id == 1 && shared_player == null:
		shared_player = player_scene.instantiate()
		shared_player.name = "SharedPlayer"
		shared_player.controller_node = self  # Pass reference to controller
		add_child(shared_player)


func _remove_player_input(id):
	player_inputs.erase(id)
 
func _on_join_pressed():
	peer.create_client("127.0.0.1", 445)
	multiplayer.multiplayer_peer = peer


func _process(delta):
	if multiplayer.has_multiplayer_peer():
		var local_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		update_input.rpc(local_input)


@rpc("any_peer", "call_local", "reliable")
func update_input(input_vector):
	var sender_id = multiplayer.get_remote_sender_id()
	player_inputs[sender_id] = input_vector


func get_combined_input():
	var combined = Vector2.ZERO
	for input in player_inputs.values():
		combined += input
	# Normalize if combined vector is too large
	return combined.normalized() if combined.length() > 1.0 else combined
