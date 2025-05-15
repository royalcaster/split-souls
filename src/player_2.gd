extends CharacterBody2D

@export var speed: int = 70
@onready var animatedSprite2D = $AnimatedSprite2D
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	animatedSprite2D.play("move_down")
