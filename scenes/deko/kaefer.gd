extends CharacterBody2D

@export var speed: float = 30.0
@export var map_bounds: Rect2
@onready var sprite = $Sprite2D

var direction: Vector2
var target_position: Vector2

func _ready():
	if multiplayer.is_server():
		sprite.texture = preload("res://scenes/deko/bug2.png")
	else:
		sprite.texture = preload("res://scenes/deko/bug.png")
	randomize()
	position = get_random_point()
	pick_new_direction()

func _process(delta):
	move_in_direction(delta)

func get_random_point() -> Vector2:
	return Vector2(
		randf_range(map_bounds.position.x, map_bounds.end.x),
		randf_range(map_bounds.position.y, map_bounds.end.y)
	)

func pick_new_direction():
	var angle = randf_range(0, TAU)
	direction = Vector2.RIGHT.rotated(angle).normalized()
	rotation = direction.angle()

func move_in_direction(delta):
	var movement = direction * speed * delta
	var next_pos = position + movement

	if map_bounds.has_point(next_pos):
		move_and_collide(movement)
	else:
		pick_new_direction()
