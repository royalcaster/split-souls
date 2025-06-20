extends Window
class_name MiniGame

const my_scene: PackedScene = preload("res://scenes/minigame/MiniGame.tscn")


@onready var player = $Map/Player
@onready var start_pos = $Map/StartPosition
@onready var end_zone = $Map/EndZone
@onready var animatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
var can_respawn = true

var player_inputs = {} # Dictionary of {peer_id: input_vector}
var move_speed = 100.0
var won_game = false

signal minigame_completed
signal minigame_failed

var active_map
static var active_map_index
#
func _ready():
	
	# initialize player_inputs for all peers
	if multiplayer.has_multiplayer_peer():
		for peer_id in multiplayer.get_peers():
			player_inputs[peer_id] = Vector2.ZERO
		player_inputs[multiplayer.get_unique_id()] = Vector2.ZERO
		
	if not multiplayer.is_server():
		animatedSprite2D.sprite_frames = load("res://scenes/player/light.tres")
		
func _enter_tree():
	var maps = [$Version1, $Version2, $Version3]
	var active_map = maps[active_map_index]
	active_map.enabled = true
	
static func new_minigame(version_index) -> MiniGame:
	var new_minigame: MiniGame = my_scene.instantiate()
	active_map_index = version_index
	return new_minigame

func _process(delta):
	# collect local inputs
	if multiplayer.has_multiplayer_peer():
		var local_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		update_minigame_input.rpc(local_input)
	
	# move player based on combined input
	move_player(delta)

@rpc("any_peer", "call_local", "reliable")
func update_minigame_input(input_vector: Vector2):
	if not won_game:
		var sender_id = multiplayer.get_remote_sender_id()
		player_inputs[sender_id] = input_vector

func get_combined_minigame_input() -> Vector2:
	# one player moves only x coordinates, other only y coordinates
	var combined = Vector2.ZERO
	var peer_ids = player_inputs.keys()
	
	if peer_ids.size() >= 2:
		# host controls x axis
		var host_id = 1
		if host_id in player_inputs:
			combined.x = player_inputs[host_id].x
		
		# client controls y axis
		for peer_id in peer_ids:
			if peer_id != host_id:
				combined.y = player_inputs[peer_id].y
				break
	else:
		# fallback for solo testing: one player controls both axis (can be removed later)
		for input in player_inputs.values():
			combined += input
			break
	
	return combined

func move_player(delta):
	var input_vector = get_combined_minigame_input()
	player.velocity = input_vector.normalized() * move_speed
	
	updateAnimation()

	if multiplayer.is_server():
		var has_collision = player.move_and_slide()
		if has_collision and can_respawn: # reset character back to starting position if he touched a wall 
			reset_game.rpc()
			respawn_cooldown.rpc(0.5)
	else: 
		player.move_and_slide() # for clients local display
		
func updateAnimation():
	if player.velocity.length() == 0:
		animatedSprite2D.stop()
	else:
		var direction = "_down"
		if player.velocity.y > 0 and player.velocity.x < 0:
			direction = "_hdown"
			animatedSprite2D.flip_h = false
		elif player.velocity.y > 0 and player.velocity.x > 0:
			direction = "_hdown"
			animatedSprite2D.flip_h = true
		elif player.velocity.y < 0 and player.velocity.x < 0:
			direction = "_hup"
			animatedSprite2D.flip_h = false
		elif player.velocity.y < 0 and player.velocity.x > 0:
			direction = "_hup"
			animatedSprite2D.flip_h = true
		elif player.velocity.x < 0:
			direction = "_horizontal"
			animatedSprite2D.flip_h = false
		elif player.velocity.x > 0:
			direction = "_horizontal"
			animatedSprite2D.flip_h = true
		elif player.velocity.y < 0:
			direction = "_up"
		animatedSprite2D.play("move" + direction)

@rpc("authority", "call_local", "reliable")
func reset_game():
	player.global_position = start_pos.global_position

	# Reset inputs
	for peer_id in player_inputs.keys():
		player_inputs[peer_id] = Vector2.ZERO
		
func _on_close_requested():
	var game = get_parent()
	if game.has_method("close_minigame"):
		game.close_minigame.rpc(won_game)
		self.remove_from_group("activeTree")
	queue_free()

func _on_end_zone_body_entered(body):
	if body == player: 
		$Map.visible = false
		$WinScreen.visible = true
		won_game = true
		$AudioStreamPlayer.play()

@rpc("authority", "call_local", "reliable")
func respawn_cooldown(wait_time):
	can_respawn = false
	await get_tree().create_timer(wait_time).timeout
	can_respawn = true
