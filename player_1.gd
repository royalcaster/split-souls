extends CharacterBody2D

@export var speed: int = 70
@onready var animations = $AnimatedSprite2D
func _ready():
	animations.play("move_down")

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = moveDirection*speed

func updateAnimation():
	
	if velocity.length() == 0:
		animations.stop()
	else:
		var direction = "_down"
		
		if velocity.y > 0 and velocity.x < 0: 
			direction = "_hdown"
			animations.flip_h = false
		elif velocity.y > 0 and velocity.x > 0:
			direction = "_hdown"
			animations.flip_h = true
		elif velocity.y < 0 and velocity.x < 0:
			direction = "_hup"
			animations.flip_h = false
		elif velocity.y < 0 and velocity.x > 0:
			direction = "_hup"
			animations.flip_h = true
		elif velocity.x < 0:
			direction = "_horizontal"
			animations.flip_h = false
		elif velocity.x > 0: 
			direction = "_horizontal"
			animations.flip_h = true
		elif velocity.y < 0:
			direction = "_up"


		
	
		animations.play("move" + direction)
	
func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()
