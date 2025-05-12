class_name Player
extends CharacterBody2D

@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames
func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	var mp := get_tree().get_multiplayer()

	print("My Peer ID: ", mp.get_unique_id())
	print("Am I Host? ", mp.is_server())
	
	if is_multiplayer_authority():
		$Camera2D.make_current()
	# Spritesheet je nach Peer-ID zuweisen
	if get_multiplayer_authority() == 1:
		animatedSprite2D.sprite_frames = player_1_frames
	else:
		animatedSprite2D.sprite_frames = player_2_frames

	if mp.get_unique_id() == 1 and mp.is_server():
		print("Ich bin der Host.")
		print(get_multiplayer_authority())
	else:
		print("Ich bin ein Client.")
		print(get_multiplayer_authority())



func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = moveDirection*speed

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
	
func _physics_process(delta):
		if not is_multiplayer_authority():
			return
		handleInput()
		move_and_slide()
		updateAnimation()
