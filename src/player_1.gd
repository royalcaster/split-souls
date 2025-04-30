extends CharacterBody2D

@export var speed: int = 70
@onready var animations = $AnimationPlayer

func handleInput():
	var moveDirection = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = moveDirection*speed

func updateAnimation():
	if velocity.length() == 0:
		animations.stop()
	else:
		var direction = "down"
		
		if velocity.y > 0 and velocity.x < 0: direction = "leftdown"
		elif velocity.y > 0 and velocity.x > 0: direction = "rightdown"
		elif velocity.y < 0 and velocity.x < 0: direction = "leftup"
		elif velocity.y < 0 and velocity.x > 0: direction = "rightup"
		elif velocity.x < 0: direction = "left"
		elif velocity.x > 0: direction = "right"
		elif velocity.y < 0: direction = "up"

		
	
		animations.play("Player1_walk" + direction)
	
func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()
