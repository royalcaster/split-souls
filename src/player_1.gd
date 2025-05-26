extends CharacterBody2D
class_name Player

var controller: Node
@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames

var health = 100
var health_max = 100
var health_min = 0
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
		animatedSprite2D.visible = is_multiplayer_authority()
	else:
		animatedSprite2D.visible = true

func _physics_process(delta):
	if !dead:
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

			if parent.has_method("take_damage"):
				if multiplayer.is_server():
					parent.take_damage(25)
				else:
					parent.take_damage.rpc_id(parent.get_multiplayer_authority(), 25)


func take_damage(damage):
	if damage != 0:
		if health > 0:
			health -= damage
			print("player_health: ", health)
			if health <= 0:
				health = 0
				dead = true
				Globals.playerAlive = false
				#handle_death_animation()
				SceneManager.goto_scene("res://scenes/ui/GameOverMenu.tscn")
			take_damage_cooldown(1.0)

# ToDo:
#func handle_death_animation():
#	animated_sprite.play("death") --> Sprite noch nicht vorhanden
#	await get_tree().create_timer(3.5).timeout --> Zeit, um Animation abspielen zu lassen
#	self.queue_free() --> Spielernode wird entfernt

func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

func get_health():
	return health

func get_health_max():
	return health_max
