extends CharacterBody2D
class_name BasePlayer

@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D

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
