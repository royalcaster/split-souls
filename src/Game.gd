extends Node2D

@export var player_scene: PackedScene

@onready var oid_lbl = $Multiplayer/VBoxContainer/OID
@onready var oid_input = $Multiplayer/VBoxContainer/OIDInput
@onready var multiplayer_ui = $Multiplayer

var peer = ENetMultiplayerPeer.new()
var player_inputs: Dictionary = {} # {peer_id: input_vector}
var shared_player: CharacterBody2D

func _ready():
	MultiplayerServer.noray_connected.connect(_on_noray_connected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	$MultiplayerSpawner.spawn_function = spawn_shared_player

func _process(_delta):
	if multiplayer.has_multiplayer_peer():
		var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		update_input.rpc(local_input)

func _on_noray_connected():
	oid_lbl.text = Noray.oid

func _on_host_pressed():
	MultiplayerServer.host()
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined!")
	)
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed():
	MultiplayerServer.join(oid_input.text)
	multiplayer_ui.hide()

func _on_copy_oid_pressed():
	DisplayServer.clipboard_set(Noray.oid)

func _on_peer_connected(peer_id: int):
	player_inputs[peer_id] = Vector2.ZERO
	if multiplayer.is_server() and shared_player == null:
#		shared_player = spawn_shared_player(peer_id)
		$MultiplayerSpawner.spawn(peer_id)

func _on_peer_disconnected(peer_id: int):
	player_inputs.erase(peer_id)

@rpc("any_peer", "call_local", "reliable")
func update_input(input_vector: Vector2):
	var sender_id = multiplayer.get_remote_sender_id()
	player_inputs[sender_id] = input_vector

func get_combined_input() -> Vector2:
	var combined = Vector2.ZERO
	for input in player_inputs.values():
		combined += input
	return combined.normalized() if combined.length() > 1.0 else combined

func spawn_shared_player(_pid):
	var player = player_scene.instantiate()
	player.name = "SharedPlayer"
	player.position = Globals.spawn_position
	player.set_multiplayer_authority(1)
	add_child(player)
	player.controller = self
	shared_player = player
	return player
