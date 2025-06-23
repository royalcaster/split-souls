extends CharacterBody2D

@export var map_bounds: Rect2

@export var center: Vector2
@export var radius: float = 100.0
@export var speed: float = 1.0
var angle: float = 0.0

func _ready():
	var anim = $AnimatedSprite2D
	anim.play("Fliegen")

	# Zufälligen Frame innerhalb der Animation wählen
	var frame_count = anim.sprite_frames.get_frame_count("Fliegen")
	anim.frame = randi() % frame_count

func _process(delta):
	angle += speed * delta
	position = center + Vector2(cos(angle), sin(angle)) * radius
	rotation = angle + PI / 2
