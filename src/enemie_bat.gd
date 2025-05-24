#Bat
extends CharacterBody2D

# Sinusbewegung
@export var amplitude: float = 50.0
@export var frequency: float = 1.0

# Spieler-Verfolgung
@export var aggro_distance: float = 150.0
@export var speed: float = 75.0

var player: Node2D = null
var start_position: Vector2
var time_passed: float = 0.0

func _ready():
	start_position = global_position

	if $AnimatedSprite2D.sprite_frames.has_animation("bat_movement"):
		$AnimatedSprite2D.play("bat_movement")

func _process(delta):
	# Falls Spieler noch nicht gefunden wurde, regelmäßig neu prüfen
	if player == null:
		player = get_tree().get_first_node_in_group("players")
		if player != null:
			print("✅ Spieler gefunden: ", player.name)

func _physics_process(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= aggro_distance:
		# Spieler verfolgen
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		# Sinusbewegung nur in X-Richtung, vertikal stabil bleiben
		time_passed += delta
		var offset_x = sin(time_passed * frequency * TAU) * amplitude
		var target_pos = Vector2(start_position.x + offset_x, start_position.y)
		var direction = (target_pos - global_position).normalized()

		# Geschwindigkeit proportional zum Abstand -> gleichmäßigeres Schwingen
		velocity = direction * (global_position.distance_to(target_pos) * 1.5)

	move_and_slide()
