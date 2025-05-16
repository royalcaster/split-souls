extends CharacterBody2D
class_name Player

var controller: Node
@export var speed: int = 100
@onready var animatedSprite2D = $AnimatedSprite2D
@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames


func _enter_tree():
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		set_multiplayer_authority(name.to_int())
		self.position  = Vector2(400, 250)

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

	# sets other player figure invisible 
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		if not is_multiplayer_authority():
			animatedSprite2D.sprite_frames = null

func _physics_process(delta):
	if Globals.control_mode == Globals.ControlMode.INDIVIDUAL:
		if is_multiplayer_authority():
			velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	else:
		if not is_multiplayer_authority():
			return
		if controller:
			velocity = controller.get_combined_input() * speed
	move_and_slide()
	updateAnimation()

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
