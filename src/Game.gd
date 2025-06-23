extends Node2D

@export var player_scene: PackedScene
@export var mini_game: PackedScene
@export var bug_scene: PackedScene
@export var map_size: Vector2 = Vector2(1024, 768)
@export var bug_count: int = 50
#@onready var tilemap = $TileMap
@onready var hud = $HUD
@onready var scoreText = $HUD/CrystalScore 

var ipaddress

const CRYSTAL = preload("res://scenes/items/crystal.tscn")

var peer = ENetMultiplayerPeer.new()
var players = []
#var current_crystal_score = 0
var current_crystal_direction_items = 0
var current_special_power_items = 0

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
	# reset game state after game over
	Globals.control_mode = Globals.ControlMode.INDIVIDUAL
	Globals.spawn_position = Vector2(80, 70)

	#spawn_crystals()
	
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
	spawn_bugs()
	$AudioManager.play_audio_omni("darkmusic")

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
			call_deferred("add_child", shared_player)
			shared_player.controller = self
			shared_player.set_multiplayer_authority(1) # Host is the authority

func _on_peer_disconnected(peer_id: int):
	if Globals.control_mode == Globals.ControlMode.SHARED:
		player_inputs.erase(peer_id)

func _process(_delta):
	measure_input(_delta) # used for visual steering cues (arrows)

	# calculates shared input
	if Globals.control_mode == Globals.ControlMode.SHARED:
		if multiplayer.has_multiplayer_peer() and multiplayer.get_multiplayer_peer().get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			update_input.rpc(local_input)

			
	# Update HUD
	scoreText.text = str(Globals.current_crystal_score)
	hud.update_crystal_direction_items(current_crystal_direction_items)
	hud.update_special_power_score(current_special_power_items)

var last_input = [false, false, false, false]  # necessary because otherwise if e.g. player1 does not press any key, player2 will see player1's last input permanently
# methods watches the inputs and sends them via rpc
func measure_input(_delta):
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
	$HUD/ArrowLeft.self_modulate.a  = 1.0 if input[0] else 0.1
	$HUD/ArrowUp.self_modulate.a    = 1.0 if input[1] else 0.1
	$HUD/ArrowDown.self_modulate.a  = 1.0 if input[2] else 0.1
	$HUD/ArrowRight.self_modulate.a = 1.0 if input[3] else 0.1

func _on_join_pressed():
	if ipaddress == null:
		ipaddress = "127.0.0.1"
	peer.create_client(ipaddress, 4455)
	multiplayer.multiplayer_peer = peer
	start_game()
	spawn_bugs()
	hide_enemies_for_lightplayer()
	$AudioManager.play_audio_omni("lightmusic")

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
func switch_control_mode(_mode):
	# open gate & spawn players behind it 
	$Gates/Gate/CollisionShape2D.set_deferred("disabled", true) # deactivate gate after walking through
	$Gates/Gate/Wall/Door.set_deferred("disabled", true) # deactivate wall in gate, so that players can walk out
	
	# open gate
	if multiplayer.is_server():
		$Gates/Gate/Sprite2D.texture = load('res://assets/dark_assets/gate_opened.png')
	else:
		$Gates/Gate/Sprite2D.texture = load('res://assets/light_assets/gate_opened.png') 
		
	Globals.spawn_position = $Gates/Gate.global_position # set new spawn point behind gate

	# switch control mode 
	if Globals.control_mode == Globals.ControlMode.SHARED:
		Globals.control_mode = Globals.ControlMode.INDIVIDUAL
	else:
		Globals.control_mode = Globals.ControlMode.SHARED


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
	$Gates/Gate.visible = true
	# replace tileset for host
	if multiplayer.is_server():
		var ground_tileset = preload("res://assets/tiles/dark_set.tres")
		$ground.tile_set = ground_tileset
#
		var objects_tileset = preload("res://assets/tiles/dark_set.tres")
		$objects.tile_set = objects_tileset

		var trees_tileset = preload("res://assets/tiles/dark_set_border_trees.tres")
		$border_trees.tile_set = trees_tileset
		
		$Gates/Gate/Sprite2D.texture = preload("res://assets/dark_assets/gate_closed_dark.png")
		
		$ItemsLight.visible = false
		
		var small_gates = get_tree().get_nodes_in_group("small_gates")
		for node in small_gates:
			node.get_node("Sprite2D").texture = preload("res://assets/dark_assets/Tor.png")
	else: 
		$ItemsDark.visible = false

	hide_enemies_for_lightplayer()
	

#func spawn_crystals():
	#for pos in crystal_positions:
		#var crystal_instance = CRYSTAL.instantiate()
		#add_child(crystal_instance)
		#crystal_instance.collected.connect(on_crystal_collected)
		#crystal_instance.start_position = tile_to_world_position(pos)
		#crystal_instance.add_to_group("map_content")
		#print("Spawned crystal at tile ", tile_to_world_position(pos))

func spawn_bugs():
	for i in bug_count:
		var bug = bug_scene.instantiate()
		bug.position = Vector2(
			randf_range(0, map_size.x),
			randf_range(0, map_size.y)
		)
		add_child(bug)


#func on_crystal_collected(value):
	#current_crystal_score += 1
	
func tile_to_world_position(input_pos: Vector2):
	return Vector2((input_pos.x * 32) + 16, (input_pos.y * 32) + 16)

func assign_enemy_authority():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_multiplayer_authority(1)  # Server hat Authority

@rpc("any_peer", "call_local", "reliable")
func open_minigame(barrier_path, mini_game_version):
	active_minigame = MiniGame.new_minigame(mini_game_version)
	add_child(active_minigame)
	
	# add barrier to group (this group keeps track of which barrier was clicked)
	var barrier = get_node_or_null(barrier_path)
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
	for barrier in $Barriers.get_children():
		barrier.visible = not multiplayer.is_server()
			
# hide enemies for light player (client)
func hide_enemies_for_lightplayer():
	for enemy in $Enemies.get_children():
		enemy.visible = multiplayer.is_server()
		
# special power
@rpc("any_peer", "reliable")
func make_enemies_and_barriers_visible_for_5s():
	for barrier in $Barriers.get_children():
		barrier.visible = true

	for enemy in $Enemies.get_children():
		enemy.visible = true

	# wait 5 seconds and hide them again 
	await get_tree().create_timer(5.0).timeout
	hide_enemies_for_lightplayer()
	hide_barriers_for_darkplayer()

@rpc("any_peer") # todo check if necessary
func on_item_collected(item_type: Globals.ItemType):

	if item_type == Globals.ItemType.DIRECTION:
		current_crystal_direction_items += 1
		# Notify all clients of the new count
		rpc("update_client_item_count", current_crystal_direction_items, item_type)
	elif item_type == Globals.ItemType.SPECIALPOWER:
		current_special_power_items += 1
		# Notify all clients of the new count
		rpc("update_client_item_count", current_special_power_items, item_type)

@rpc("any_peer", "call_local")
func request_consume_item(host_pressed: bool, item_type: Globals.ItemType):
	if item_type == Globals.ItemType.DIRECTION:
		if current_crystal_direction_items <= 0:
			return

		current_crystal_direction_items -= 1
		rpc("update_client_item_count", current_crystal_direction_items, item_type)
	
		var target_player_nodes_for_indicator = []
		if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
			target_player_nodes_for_indicator = players
		elif Globals.control_mode == Globals.ControlMode.SHARED:
			if is_instance_valid(shared_player):
				target_player_nodes_for_indicator.append(shared_player)

		for player_node_instance in target_player_nodes_for_indicator:
			if is_instance_valid(player_node_instance):
				player_node_instance.rpc("show_consumption_indicator", host_pressed, item_type) # only person who did not press sees the button

	elif item_type == Globals.ItemType.SPECIALPOWER:
		if current_special_power_items <= 0:
			return

		current_special_power_items -= 1

		rpc("update_client_item_count", current_special_power_items, item_type)
		rpc("make_enemies_and_barriers_visible_for_5s")

@rpc("any_peer", "reliable")
func update_client_item_count(new_count: int, item_type: Globals.ItemType):

	if not multiplayer.is_server():
		if item_type == Globals.ItemType.DIRECTION:
			self.current_crystal_direction_items = new_count
		elif item_type == Globals.ItemType.SPECIALPOWER:
			self.current_special_power_items = new_count

func _on_texture_rect_gui_input(event): # crytal item can also be used by clicking on it 
	if event is InputEventMouseMotion and current_crystal_direction_items > 0:
		$HUD/DirectionsClickable.mouse_default_cursor_shape = Input.CURSOR_POINTING_HAND
		
	if event is InputEventMouseButton and event.pressed:
		rpc("request_consume_item", multiplayer.is_server(), Globals.ItemType.DIRECTION)

func _on_texture_rect_mouse_exited():
	$HUD/DirectionsClickable.mouse_default_cursor_shape = Input.CURSOR_ARROW

func _on_special_power_clickable_gui_input(event):
	if current_special_power_items > 0:
		if event is InputEventMouseMotion:
			$HUD/SpecialPowerClickable.mouse_default_cursor_shape = Input.CURSOR_POINTING_HAND
			
		if event is InputEventMouseButton and event.pressed:
			rpc("request_consume_item", multiplayer.is_server(), Globals.ItemType.SPECIALPOWER)

func _on_special_power_clickable_mouse_exited():
	$HUD/SpecialPowerClickable.mouse_default_cursor_shape = Input.CURSOR_ARROW


func _on_line_edit_text_changed(new_text):
	print("_on_line_edit_text_changed", new_text)
	ipaddress = new_text

func _unhandled_input(event):

    if Input.is_action_just_pressed("ui_cancel"):
    		SceneManager.open_pause_overlay()

	if event is InputEventKey and event.pressed:
		var player = null
		if Globals.control_mode == Globals.ControlMode.SHARED:
			player = shared_player
		elif Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
			player = get_tree().get_first_node_in_group("players")

		if player == null:
			print("⚠️ Kein Spieler zum Speichern/Laden gefunden!")
			return

		if event.keycode == KEY_F5:
			SaveGameManager.save_game(player)
		elif event.keycode == KEY_F9:
			SaveGameManager.load_game(player)

func _on_steuerung_pressed() -> void:
	var new_scene = load("res://scenes/ui/Steuerung.tscn")
	get_tree().change_scene_to_packed(new_scene)


func _on_anleitung_pressed() -> void:
	var new_scene = load("res://scenes/ui/AnleitungMenu.tscn")
	get_tree().change_scene_to_packed(new_scene)


func _on_beenden_pressed():
	get_tree().quit()
