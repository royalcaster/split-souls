extends Node2D

@export var player_scene: PackedScene
@export var mini_game: PackedScene
@onready var tilemap = $TileMap
@onready var hud = $HUD

const CRYSTAL = preload("res://scenes/items/crystal.tscn")

var peer = ENetMultiplayerPeer.new()
var players = []
var current_crystal_score = 0

var player_inputs = {} # Dictionary of {peer_id: input_vector}
var shared_player: CharacterBody2D
var active_minigame = null

@export var crystal_positions: Array[Vector2] = [
	Vector2(12, 6),
	Vector2(16, 10),
	Vector2(17, 18),
	Vector2(3, 19)
]

func _ready():
	spawn_crystals()
	if Globals.control_mode == Globals.ControlMode.SHARED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_host_pressed():
	peer.create_server(4455)
	multiplayer.multiplayer_peer = peer
	hide_ui()

# connect either one player instance per player (individual steering) or one player instance for both (shared)
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
			shared_player.position = Globals.spawn_position # set spawn position
			shared_player.name = "SharedPlayer"
			add_child(shared_player)
			shared_player.controller = self
			shared_player.set_multiplayer_authority(1) # Host is the authority

func _on_peer_disconnected(peer_id: int):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		player_inputs.erase(peer_id)

func _process(_delta):
	measure_input(_delta) # used for visual steering cues (arrows)

	# calculates shared input
	if Globals.control_mode == Globals.ControlMode.SHARED:
		if multiplayer.has_multiplayer_peer():
			var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			update_input.rpc(local_input)
			
	# Update HUD
	hud.update_crystal_score(current_crystal_score)

var last_input = [false, false, false, false]  # necessary because otherwise if e.g. player1 does not press any key, player2 will see player1's last input permanently
# methods watches the inputs and sends them via rpc
func measure_input(delta):
	var input = [
		Input.is_action_pressed("move_left"),
		Input.is_action_pressed("move_up"),
		Input.is_action_pressed("move_down"),
		Input.is_action_pressed("move_right")
	]

	if input != last_input:
		update_arrows.rpc(input)
		last_input = input

# call_remote makes ONLY other player receive packages and updates their arrows opacity
@rpc("any_peer", "call_remote", "reliable")
func update_arrows(input: Array):
	$HUD/ArrowLeft.self_modulate.a  = 1.0 if input[0] else 0.5
	$HUD/ArrowUp.self_modulate.a    = 1.0 if input[1] else 0.5
	$HUD/ArrowDown.self_modulate.a  = 1.0 if input[2] else 0.5
	$HUD/ArrowRight.self_modulate.a = 1.0 if input[3] else 0.5

func _on_join_pressed():
	peer.create_client( "127.0.0.1",4455)
	multiplayer.multiplayer_peer = peer
	hide_ui()

# used to update shared input 
@rpc("any_peer", "call_local", "reliable")
func update_input(input_vector: Vector2):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		var sender_id = multiplayer.get_remote_sender_id()
		player_inputs[sender_id] = input_vector

# calculate shared input
func get_combined_input() -> Vector2:
		var combined = Vector2.ZERO
		for input in player_inputs.values():
			combined += input
		return combined.normalized() if combined.length() > 1.0 else combined

# called when both players walk in the gate to switch the control mode
@rpc("authority", "call_local", "reliable")
func switch_control_mode(mode):
	# open gate & spawn players behind it 
	$Gate/CollisionShape2D.set_deferred("disabled", true) # deactivate gate after walking through
	$Gate/Wall/Door.set_deferred("disabled", true) # deactivate wall in gate, so that players can walk out
	$Gate/Sprite2D.texture = load('res://assets/img/gate_opened.png') # open gate
	Globals.spawn_position = $Gate.global_position # set new spawn point behind gate

	# switch control mode 
	if Globals.control_mode == Globals.ControlMode.SHARED:
		Globals.control_mode = Globals.ControlMode.INDIVIDUAL
	else:
		Globals.control_mode = Globals.ControlMode.SHARED

	print("--- Switched mode to: ", Globals.control_mode)

	# Cleanup old player instances
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
		
# hides ui after clicking host button/join button
func hide_ui():
	$Multiplayer.visible = false

func spawn_crystals():
	for pos in crystal_positions:
		var crystal_instance = CRYSTAL.instantiate()
		add_child(crystal_instance)
		crystal_instance.collected.connect(on_crystal_collected)
		crystal_instance.start_position = tile_to_world_position(pos)
		print("Spawned crystal at tile ", tile_to_world_position(pos))
	
func on_crystal_collected(value):
	current_crystal_score += 1
	
func tile_to_world_position(input_pos: Vector2):
	return Vector2((input_pos.x * 32) + 16, (input_pos.y * 32) + 16)


@rpc("any_peer", "call_local", "reliable")
func open_minigame():
	active_minigame = mini_game.instantiate()
	add_child(active_minigame)

	# deactivate player movement outside the minigame
	if shared_player:
		shared_player.set_physics_process(false)
		
@rpc("any_peer", "call_local", "reliable")
func close_minigame(won_game):
	print("before close")
	remove_child(active_minigame)
	print("close")
	
	# reactivate player movement outside the minigame
	if shared_player:
		shared_player.set_physics_process(true)
	
	if won_game: 
		var tree = $Barriers.get_node("TreeBarrier1")
		$Barriers.remove_child(tree)
