extends Node2D

@export var player_scene: PackedScene
@export var mini_game: PackedScene
@onready var tilemap = $TileMap
@onready var hud = $HUD

const CRYSTAL = preload("res://scenes/items/crystal.tscn")

var peer = ENetMultiplayerPeer.new()
var players = []
var current_crystal_score = 0
var current_crystal_direction_items = 0

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
	
	### ✅ Gegner-Authority zuweisen, wenn Server
	if multiplayer.is_server():
		assign_enemy_authority()

	if Globals.control_mode == Globals.ControlMode.SHARED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_host_pressed():
	peer.create_server(4455)
	multiplayer.multiplayer_peer = peer
	start_game()
	hide_barriers_for_darkplayer()

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
	hud.update_crystal_direction_items(current_crystal_direction_items)

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
	start_game()
	hide_enemies_for_lightplayer()

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
	
func start_game():
	# makes all gaming contents visible after joining/hosting the game
	var nodes_in_group = get_tree().get_nodes_in_group("map_content")
	for node in nodes_in_group:
		node.visible = true
		
	$Multiplayer.visible= false # hide host/join buttons
	 
	# replace tileset for host
	if multiplayer.is_server():
		var ground_tileset = preload("res://src/dark_tileset_ground.tres")
		$ground.tile_set = ground_tileset
#
		var trees_tileset = preload("res://src/dark_tileset_trees.tres")
		$trees.tile_set = trees_tileset
#
		var objects_tileset = preload("res://src/dark_tileset_objects.tres")
		$objects.tile_set = objects_tileset
	
	find_and_connect_event_triggers()


func spawn_crystals():
	for pos in crystal_positions:
		var crystal_instance = CRYSTAL.instantiate()
		add_child(crystal_instance)
		crystal_instance.collected.connect(on_crystal_collected)
		crystal_instance.start_position = tile_to_world_position(pos)
		crystal_instance.add_to_group("map_content")
		print("Spawned crystal at tile ", tile_to_world_position(pos))
	
func on_crystal_collected(value):
	current_crystal_score += 1
	
func tile_to_world_position(input_pos: Vector2):
	return Vector2((input_pos.x * 32) + 16, (input_pos.y * 32) + 16)


func assign_enemy_authority():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_multiplayer_authority(1)  # Server hat Authority

@rpc("any_peer", "call_local", "reliable")
func open_minigame(barrier_path):
	active_minigame = mini_game.instantiate()
	add_child(active_minigame)
	
	# add barrier to group (this group keeps track of which barrier was clicked)
	var barrier = get_node(barrier_path)
	if not barrier.is_in_group("activeTree"):
		barrier.add_to_group("activeTree")

	# deactivate player movement outside the minigame
	if shared_player:
		shared_player.set_physics_process(false)
		
@rpc("any_peer", "call_local", "reliable")
func close_minigame(won_game):
	remove_child(active_minigame)
	
	# reactivate player movement outside the minigame
	if shared_player:
		shared_player.set_physics_process(true)
	
	if won_game: 
		var barriers = get_tree().get_nodes_in_group("activeTree")
		if barriers.size() > 0: # remove barrier which was added to group when the minigame was opened
			var barrier = barriers[0]
			var parent = barrier.get_parent()
			parent.remove_child(barrier)
			
# only light player should be able to see barriers 
func hide_barriers_for_darkplayer():
	if multiplayer.is_server():
		for barrier in $Barriers.get_children():
			barrier.visible = false
			
# hide enemies for light player (client)
func hide_enemies_for_lightplayer():
	if not multiplayer.is_server():
		$EnemieBat.visible = false
		
# special power TODO: use
func make_enemies_and_barriers_visible_for_5s():
	for barrier in $Barriers.get_children():
		barrier.visible = true
		
	$EnemieBat.visible = true 

	# wait 5 seconds and hide them again 
	await get_tree().create_timer(5.0).timeout
	hide_enemies_for_lightplayer()
	hide_barriers_for_darkplayer()
	
func find_and_connect_event_triggers():
	var crystal_direction_items_nodes = get_tree().get_nodes_in_group("crystal_direction_items") # Renamed variable to avoid conflict
	print("finding triggers")
	for item_node in crystal_direction_items_nodes: # Renamed loop variable
		print("trigger found")
		# Ensure not to connect multiple times if this function is called again
		if not item_node.collected.is_connected(on_crystal_direction_item_collected):
			item_node.collected.connect(on_crystal_direction_item_collected)

func on_crystal_direction_item_collected():
	# This function is called when an item is collected.
	# The server should be the authority for changing the count.
	if multiplayer.is_server():
		current_crystal_direction_items += 1
		print("Game.gd (Server): Crystal direction item collected. New total: %d" % current_crystal_direction_items)
		# Notify all clients of the new count
		rpc("update_client_item_count", current_crystal_direction_items)
	# else: Client does not modify the count directly. It will receive an update.
	
@rpc("any_peer", "call_local")
func request_consume_crystal_item(p_player_id: int):
	print("Game.gd: Received request_consume_crystal_item for player_id: %s" % p_player_id)
	
	if not multiplayer.is_server():
		print("Game.gd: Not the server. Ignoring consume request.")
		return
		
	var actual_sender_peer_id = multiplayer.get_remote_sender_id()
	print("Game.gd (Server): Processing consume request from actual sending peer %s for player %s" % [actual_sender_peer_id, p_player_id])

	if current_crystal_direction_items <= 0:
		print("Game.gd (Server): Validation FAILED for player %s. No items. Global: %d" % [p_player_id, current_crystal_direction_items])
		return
	
	current_crystal_direction_items -= 1 
	print("Game.gd (Server): Item consumed for player %s. Global items remaining: %d" % [p_player_id, current_crystal_direction_items])
	
	rpc("client_consume_item_visuals", p_player_id)
	
	rpc("update_client_item_count", current_crystal_direction_items)

	var target_player_nodes_for_indicator = []
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		target_player_nodes_for_indicator = players 
	elif Globals.control_mode == Globals.ControlMode.SHARED:
		if is_instance_valid(shared_player):
			target_player_nodes_for_indicator.append(shared_player)

	for player_node_instance in target_player_nodes_for_indicator:
		if is_instance_valid(player_node_instance):
			player_node_instance.rpc("show_consumption_indicator")
			print("Game.gd (Server): Requested show_consumption_indicator for player character: %s" % player_node_instance.name)

@rpc("any_peer", "reliable")
func update_client_item_count(new_count: int):
	if not multiplayer.is_server():
		self.current_crystal_direction_items = new_count
