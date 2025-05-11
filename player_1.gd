class_name Player
extends CharacterBody2D

@export var speed: int = 70
@onready var animatedSprite2D = $AnimatedSprite2D
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
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
		handleInput()
		move_and_slide()
		updateAnimation()
