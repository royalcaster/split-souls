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
		
		# make sure both players do not spawn on top of each other 
		var updated_spawn_position = Globals.spawn_position
		if not multiplayer.is_server():
			updated_spawn_position.x = updated_spawn_position.x + 50
			
		self.position = updated_spawn_position

func _ready():
	
	# camera always follows character that is controlled
	if is_multiplayer_authority():
		$Camera2D.make_current()
			
	# host is dark player, client is light player
	var mp := get_tree().get_multiplayer()
	if mp.is_server():
		animatedSprite2D.sprite_frames = player_1_frames
	else:
		animatedSprite2D.sprite_frames = player_2_frames
	update_visibility()
	
	dead = false
	can_take_damage = true
	Globals.playerAlive = true
	
	# Zauberstab
	#var wand = preload("res://scenes/game/shoot.tscn").instantiate()
	#wand.position = Vector2(10, 0)
	#add_child(wand)
	
func update_visibility():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		if not is_multiplayer_authority():
			animatedSprite2D.visible = false
		else:
			animatedSprite2D.visible = true
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
		if hit_box.get_parent() is BatEnemy:
			damage = Globals.batDamageAmount

	if can_take_damage:
		take_damage(damage)

func take_damage(damage):
	if damage !=0:
		if health > 0:
			health -= damage
			print("player_health: ", health)
			if health <= 0:
				health = 0
				dead = true
				Globals.playerAlive = false
				#handle_death_animation()
			take_damage_cooldown(1.0)


#######   TODO   #######
#func handle_death_animation():
#	animated_sprite.play("death") #Sprite noch nicht vorhanden
#	await get_tree().create_timer(3.5).timeout #Timer, damit sich die dead-Animation angesehen werden kann
#	self.queue_free() #Player-Node wird gelöscht, hier vllt Szenewechsel zu Startbildschirm
########################


func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true
