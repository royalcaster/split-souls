extends CharacterBody2D
class_name Player

var controller: Node
@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@onready var direction_pointer_arrow: Node2D = get_node_or_null("Arrow")
@onready var minigame_node = get_tree().get_root().get_node_or_null("res://scenes/minigame/MiniGame.tscn")

var _health: int = 100
var _isplayingSound = false
var is_dead = false


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
	if not mp.is_server():
		animatedSprite2D.sprite_frames = load("res://scenes/player/light.tres")

	update_visibility()

	dead = false
	can_take_damage = true
	Globals.playerAlive = true

func update_visibility():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		self.visible = is_multiplayer_authority()
	else:
		self.visible = true

func _physics_process(_delta):
	if dead or is_dead:
		return

	
	if not dead:
		listen_for_crystal_direction_consume()
		if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
			if is_multiplayer_authority():
				velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
		else:
			if not is_multiplayer_authority():
				return
			if controller:
				velocity = controller.get_combined_input() * speed

		check_hitbox()

	move_and_slide()
	updateAnimation()

func listen_for_crystal_direction_consume():
	if Input.is_action_just_pressed("consume_crystal_direction_item"):
		if game_node_ref:
			# Call the RPC on the specific Game.gd node instance.
			# The RPC will be sent to the authority of game_node_ref (which is the server).
			game_node_ref.rpc("request_consume_crystal_item", multiplayer.is_server()) # give if host pressed to identify who can see the hint in the end

func is_player():
	return true

func updateAnimation():
	if velocity.length() == 0:
		animatedSprite2D.stop()
		if _isplayingSound:
			$AudioManager.stop_audio_2d("footstep01")
			_isplayingSound = false
	else:
		# Wenn Minigame offen, keine Fußschritte abspielen
		if is_minigame_open():
			if _isplayingSound:
				$AudioManager.stop_audio_2d("footstep01")
				_isplayingSound = false

			# Animation weiterhin abspielen, nur kein Sound
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

			return # fertig, kein Sound spielen

		# Normaler Footstep-Sound wenn Minigame nicht offen
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
		if !_isplayingSound:
			$AudioManager.play_audio_2d("footstep01")
			_isplayingSound = true


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
		
	# Nur der Server darf Health verändern und synchronisieren!
	if not multiplayer.is_server():
		return

	health -= damage  # Automatisch über Setter synchronisiert
	take_damage_cooldown(1.0)

# Leben auf Max setzen
@rpc("authority", "reliable") #prüfen ob nötig
func healMax():

	if not multiplayer.is_server():
		return

	health = health_max

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
	is_dead = true
	print("playing animation")
	$AudioManager.stop_audio_2d("footstep01")
	$AudioManager.stop_audio_2d("footstep02")

	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("death")
	await get_tree().process_frame
	$AudioManager.play_audio_2d("death")
	await get_tree().create_timer(4.5).timeout
	Globals.playerAlive = false
	multiplayer.multiplayer_peer = null
	SceneManager.goto_scene("res://scenes/ui/GameOverMenu.tscn")



@rpc("any_peer", "reliable")
func set_arrow_visibility(isVisible, radius):
	direction_pointer_arrow.rotation = radius
	direction_pointer_arrow.visible = isVisible

@rpc("reliable")
func show_consumption_indicator(host_pressed, item_type):
	if item_type == Globals.ItemType.DIRECTION:

		if not is_instance_valid(direction_pointer_arrow):
			return

		var crystal_nodes = get_tree().get_nodes_in_group("crystals")

		if crystal_nodes.is_empty():
			direction_pointer_arrow.visible = false
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

			if not host_pressed: # only person who did not press the button sees the arrow
				rpc("set_arrow_visibility", true, target_angle_rad) # for host
			else:
				direction_pointer_arrow.rotation = target_angle_rad  # for client
				direction_pointer_arrow.visible = true

			var timer = get_tree().create_timer(3.0)
			await timer.timeout

			if is_instance_valid(direction_pointer_arrow):
				if not host_pressed: # only person who did not press the button sees the arrow
					rpc("set_arrow_visibility", false, 0) # for host
				else:
					direction_pointer_arrow.visible = false # for client

		else:
			if not host_pressed: # only person who did not press the button sees the arrow
				rpc("set_arrow_visibility", false, 0) # for host
			else:
				direction_pointer_arrow.visible = false # for client

func is_minigame_open() -> bool:
	if minigame_node and minigame_node.is_open:
		return true
	return false
