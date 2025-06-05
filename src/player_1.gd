# Player.gd

extends CharacterBody2D
class_name Player

var controller: Node
@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames
@onready var direction_pointer_arrow: Node2D = get_node_or_null("Arrow")

var _health: int = 100

# signal crystal_directions_item_consumed(player_id) # This signal is not used for network

# Get a reference to your main game scene's root node.
# IMPORTANT: Replace "Game" with the actual name of your main game scene's root node
# if it's different (e.g., if your game.tscn's root node is named "MainGameScene").
@onready var game_node_ref = get_tree().get_root().get_node_or_null("Game")

var health: int:
	set(value):
		_health = clamp(value, 0, health_max)
		print("Health set to:", _health)

		if $HealthBar:
			$HealthBar.visible = true  # <–– HealthBar jetzt sichtbar
			$HealthBar.update_health(_health, health_max)

		if multiplayer.is_server():
			rpc("update_healthbar_clients", _health, health_max)
			
		await get_tree().create_timer(0.1).timeout # wait shortly so that both players call change the scene
		if _health <= 0 and not dead:
			dead = true
			Globals.playerAlive = false
			if multiplayer.is_server():
				rpc("on_player_dead") # call function for client
				on_player_dead() # call function for host

	get:
		return _health


var health_max: int = 100
var health_min: int = 0
var can_take_damage: bool
var dead: bool

func _enter_tree():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		set_multiplayer_authority(name.to_int())

		var updated_spawn_position = Globals.spawn_position
		if not multiplayer.is_server():
			updated_spawn_position.x += 50
		self.position = updated_spawn_position

func _ready():
	# HealthBar zu Beginn ausblenden
	if $HealthBar:
		$HealthBar.visible = false
	
	if is_multiplayer_authority():
		$Camera2D.make_current()

	var mp := get_tree().get_multiplayer()
	if mp.is_server():
		animatedSprite2D.sprite_frames = player_1_frames
	else:
		animatedSprite2D.sprite_frames = player_2_frames

	update_visibility()

	dead = false
	can_take_damage = true
	Globals.playerAlive = true

	if not game_node_ref:
		var main_scene_root_name = get_tree().get_current_scene().name
		game_node_ref = get_tree().get_root().get_node_or_null(main_scene_root_name)
		if not game_node_ref:
			printerr("Player.gd: Could not find the main game node. RPCs to Game.gd might fail.")

func update_visibility():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		self.visible = is_multiplayer_authority()
	else:
		self.visible = true

func _physics_process(_delta):
	if not dead:
		if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
			if is_multiplayer_authority():
				velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
				listen_for_crystal_direction_consume()
		else:
			if not is_multiplayer_authority():
				return
			if controller:
				velocity = controller.get_combined_input() * speed
			if get_tree().get_multiplayer().get_unique_id() != 0:
				listen_for_crystal_direction_consume()

		check_hitbox()
	
	move_and_slide()
	updateAnimation()

func listen_for_crystal_direction_consume():
	if Input.is_action_just_pressed("consume_crystal_direction_item"):
		if game_node_ref:
			# Call the RPC on the specific Game.gd node instance.
			# The RPC will be sent to the authority of game_node_ref (which is the server).
			game_node_ref.rpc("request_consume_crystal_item", multiplayer.get_unique_id())
			print("Player %s: Requested crystal_directions_item consume via Game.gd" % multiplayer.get_unique_id())
		else:
			printerr("Player %s: Cannot request consume, game_node_ref is null." % multiplayer.get_unique_id())
	
@rpc("reliable")
func client_consume_item_visuals(p_player_id_who_consumed: int):
	print("Client %s: Received visual update for player %s consuming an item." % [multiplayer.get_unique_id(), p_player_id_who_consumed])
	
	if multiplayer.get_unique_id() == p_player_id_who_consumed:
		print("My item was consumed!")
		# Add actual visual/audio feedback here for this client
	else:
		print("Another player's (%s) item was consumed!" % p_player_id_who_consumed)
		# Add visual/audio feedback for another player consuming, if needed

func is_player():
	return true

func updateAnimation():
	if velocity.length() == 0:
		animatedSprite2D.stop()
	else:
		var direction = "_down"
		if velocity.y > 0 and velocity.x < 0:
			direction = "_hdown"
			animatedSprite2D.flip_h = false
		elif velocity.y > 0 and velocity.x > 0:
			direction = "_hdown"
			animatedSprite2D.flip_h = true
		elif velocity.y < 0 and velocity.x < 0:
			direction = "_hup"
			animatedSprite2D.flip_h = false
		elif velocity.y < 0 and velocity.x > 0:
			direction = "_hup"
			animatedSprite2D.flip_h = true
		elif velocity.x < 0:
			direction = "_horizontal"
			animatedSprite2D.flip_h = false
		elif velocity.x > 0:
			direction = "_horizontal"
			animatedSprite2D.flip_h = true
		elif velocity.y < 0:
			direction = "_up"
		animatedSprite2D.play("move" + direction)

func check_hitbox():
	var hitbox_areas = $PlayerHitbox.get_overlapping_areas()
	var damage: int

	if hitbox_areas:
		var hit_box = hitbox_areas.front()
		var parent = hit_box.get_parent()

		if parent is BatEnemy:
			damage = Globals.batDamageAmount
		if can_take_damage:
			take_damage(damage)

@rpc("authority", "reliable")
func take_damage(damage: int):
	if damage == 0 or dead:
		return

	health -= damage  # Automatisch über Setter synchronisiert
	take_damage_cooldown(1.0)

func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

@rpc("any_peer", "reliable")
func update_healthbar_clients(_current: int, _max: int):
	if $HealthBar:
		$HealthBar.update_health(_current, _max)

	if _current <= 0:
		on_player_dead()

@rpc("any_peer", "reliable")
func on_player_dead():
	Globals.playerAlive = false
	multiplayer.multiplayer_peer = null # todo check if working
	SceneManager.goto_scene("res://scenes/ui/GameOverMenu.tscn")

@rpc("reliable")
func show_consumption_indicator():
	var current_peer_id = -1
	if multiplayer.has_multiplayer_peer():
		current_peer_id = multiplayer.get_unique_id()

	var is_host = (current_peer_id == 1)
	var context_string = "Host" if is_host else "Client"

	print("Player '%s' (%s - Peer %s): show_consumption_indicator CALLED. Arrow node valid: %s" % [name, context_string, current_peer_id, is_instance_valid(direction_pointer_arrow)])

	if not is_instance_valid(direction_pointer_arrow):
		printerr("Player '%s' (%s - Peer %s): DirectionPointerArrow node is NOT VALID. Cannot proceed." % [name, context_string, current_peer_id])
		return
	
	if is_host: 
		direction_pointer_arrow.visible = false
		print("Player '%s' (Host - Peer %s): Hiding arrow as per host-specific rule." % [name, current_peer_id])
		return
	
	var crystal_nodes = get_tree().get_nodes_in_group("crystals")
	print("Player '%s' (Client - Peer %s): Found %s crystal(s) in group 'crystals'." % [name, current_peer_id, crystal_nodes.size()])
	
	if crystal_nodes.is_empty():
		direction_pointer_arrow.visible = false 
		print("Player '%s' (Client - Peer %s): No crystals found, hiding arrow." % [name, current_peer_id])
		return

	var nearest_crystal_node = null
	var min_distance_squared_to_player = INF
	
	var player_global_position = self.global_position 

	for crystal in crystal_nodes:
		if not is_instance_valid(crystal):
			continue
		var distance_sq = player_global_position.distance_squared_to(crystal.global_position)
		
		if distance_sq < min_distance_squared_to_player:
			min_distance_squared_to_player = distance_sq
			nearest_crystal_node = crystal

	if is_instance_valid(nearest_crystal_node):
		var arrow_current_global_position = direction_pointer_arrow.global_position
		var crystal_pos = nearest_crystal_node.global_position 
		
		var direction_vector_from_arrow = crystal_pos - arrow_current_global_position
		
		var target_angle_rad = direction_vector_from_arrow.angle()
		direction_pointer_arrow.rotation = target_angle_rad

		direction_pointer_arrow.visible = true

		var timer = get_tree().create_timer(3.0)
		await timer.timeout
		
		if is_instance_valid(direction_pointer_arrow):
			direction_pointer_arrow.visible = false
	else:
		direction_pointer_arrow.visible = false
		print("Player '%s' (Client - Peer %s): No valid nearest crystal (to player) found after search, hiding arrow." % [name, current_peer_id])
