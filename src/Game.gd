extends Node2D

@export var player_scene: PackedScene
var peer = ENetMultiplayerPeer.new()
var player_inputs = {} # Dictionary of {peer_id: input_vector}
var shared_player: CharacterBody2D


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_host_pressed():
	peer.create_server(4455)
	multiplayer.multiplayer_peer = peer
	_on_peer_connected(multiplayer.get_unique_id()) # Add host manually

func _on_join_pressed():
	peer.create_client("127.0.0.1", 4455) # Use actual host IP
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(peer_id: int):
	player_inputs[peer_id] = Vector2.ZERO
	if multiplayer.is_server() and shared_player == null:
		shared_player = player_scene.instantiate()
		shared_player.position = Vector2(400, 250) # set spawn position
		shared_player.name = "SharedPlayer"
		add_child(shared_player)
		shared_player.controller = self
		shared_player.set_multiplayer_authority(1) # Host is the authority

func _on_peer_disconnected(peer_id: int):
	player_inputs.erase(peer_id)

func _process(_delta):
	if multiplayer.has_multiplayer_peer():
		var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		update_input.rpc(local_input)

@rpc("any_peer", "call_local", "reliable")
func update_input(input_vector: Vector2):
	var sender_id = multiplayer.get_remote_sender_id()
	player_inputs[sender_id] = input_vector

func get_combined_input() -> Vector2:
	var combined = Vector2.ZERO
	for input in player_inputs.values():
		combined += input
	return combined.normalized() if combined.length() > 1.0 else combined
