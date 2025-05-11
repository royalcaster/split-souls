class_name Player
extends CharacterBody2D

@export var speed: int = 70
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if is_multiplayer_authority():
		# Ask the server to tell everyone which skin to use
		if MultiplayerServer.is_host:
			rpc("set_sprite_frames", 1)
		else:
			rpc("set_sprite_frames", 2)

@rpc("any_peer")
func set_sprite_frames(type: int):
	match type:
		1:
			animatedSprite2D.frames = player_1_frames
		2:
			animatedSprite2D.frames = player_2_frames
	animatedSprite2D.play("move_down")

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
