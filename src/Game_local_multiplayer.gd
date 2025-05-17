extends Node2D
@export var player_scene: PackedScene
var peer = ENetMultiplayerPeer.new()
var players = []

var player_inputs = {} # Dictionary of {peer_id: input_vector}
var shared_player: CharacterBody2D


func _ready():
	if Globals.control_mode == Globals.ControlMode.SHARED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_host_pressed():
	peer.create_server(4455)
	multiplayer.multiplayer_peer = peer

	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		multiplayer.peer_connected.connect(_add_player)
		_add_player()
	else:
		_on_peer_connected(multiplayer.get_unique_id())

# instanciate players for individual mode
func _add_player(id=1):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	call_deferred("add_child", player)
	players.append(player)

# instanciate shared player for shared mode
func _on_peer_connected(peer_id: int):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		player_inputs[peer_id] = Vector2.ZERO
		if multiplayer.is_server() and shared_player == null:
			shared_player = player_scene.instantiate()
			shared_player.position = Vector2(400, 250) # set spawn position
			shared_player.name = "SharedPlayer"
			add_child(shared_player)
			shared_player.controller = self
			shared_player.set_multiplayer_authority(1) # Host is the authority

func _on_peer_disconnected(peer_id: int):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		player_inputs.erase(peer_id)

func _process(_delta):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		if multiplayer.has_multiplayer_peer():
			var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			update_input.rpc(local_input)

func _on_join_pressed():
	peer.create_client( "127.0.0.1",4455)
	multiplayer.multiplayer_peer = peer
	

@rpc("any_peer", "call_local", "reliable")
func update_input(input_vector: Vector2):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		var sender_id = multiplayer.get_remote_sender_id()
		player_inputs[sender_id] = input_vector

func get_combined_input() -> Vector2:
		var combined = Vector2.ZERO
		for input in player_inputs.values():
			combined += input
		return combined.normalized() if combined.length() > 1.0 else combined

@rpc("authority", "call_local", "reliable")
func switch_control_mode():
	if Globals.control_mode == Globals.ControlMode.SHARED:
		Globals.control_mode = Globals.ControlMode.INDIVIDUAL
	else:
		Globals.control_mode = Globals.ControlMode.SHARED

	print("--- Switched mode to: ", Globals.control_mode)

	# Cleanup old players
	for p in players:
		if p:
			p.queue_free()
	players.clear()

	if shared_player:
		shared_player.queue_free()
		shared_player = null

	# Reinitialize players depending on the mode
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		for id in multiplayer.get_peers():
			_add_player(id)
		_add_player(multiplayer.get_unique_id()) # Ensure local player is added too
	else:
		for id in multiplayer.get_peers():
			_on_peer_connected(id)
		_on_peer_connected(multiplayer.get_unique_id())
