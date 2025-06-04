extends CharacterBody2D
class_name Player

var controller: Node
@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames

var _health: int = 100

signal crystal_directions_item_consumed(player_id)

var health: int:
	set(value):
		_health = clamp(value, 0, health_max)
		print("Health set to:", _health)

		if $HealthBar:
			$HealthBar.visible = true  # <–– HealthBar jetzt sichtbar
			$HealthBar.update_health(_health, health_max)

		if multiplayer.is_server():
			rpc("update_healthbar_clients", _health, health_max)

		if _health <= 0 and not dead:
			dead = true
			Globals.playerAlive = false
			if multiplayer.is_server():
				rpc("on_player_dead")
				SceneManager.goto_scene("res://scenes/ui/GameOverMenu.tscn")
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

func update_visibility():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		self.visible = is_multiplayer_authority()
	else:
		self.visible = true

func _physics_process(delta):
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
				listen_for_crystal_direction_consume()
				
		check_hitbox()
	
	move_and_slide()
	updateAnimation()

func listen_for_crystal_direction_consume():
	if Input.is_action_just_pressed("consume_crystal_direction_item"):
		rpc_id(1, "request_consume_crystal_item", multiplayer.get_unique_id())
		# crystal_directions_item_consumed.emit()
		print("requested crystal_directions_item consume")
		
@rpc("any_peer")	
func request_consume_crystal_item():
	if not multiplayer.is_server():
		return
		
	var requesting_peer_id = multiplayer.get_rpc_sender_id()
	print("Server received consume request from client: %d" % requesting_peer_id)
	
@rpc("reliable")
func client_consume_item_visuals(p_player_id: int):
	print("Client received visual update for player: ", p_player_id)
	
	if multiplayer.get_unique_id() == p_player_id:
		print("My item consumed!")
	else:
		print("Another player's item consumed!")

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
func update_healthbar_clients(current: int, max: int):
	if $HealthBar:
		$HealthBar.update_health(current, max)

@rpc("any_peer", "reliable")
func on_player_dead():
	Globals.playerAlive = false
	SceneManager.goto_scene("res://scenes/ui/GameOverMenu.tscn")
