# enemy_bat.gd
extends CharacterBody2D

class_name BatEnemy

# Sinusbewegung
@export var amplitude: float = 50.0
@export var frequency: float = 1.0

# Spieler-Verfolgung
@export var aggro_distance: float = 150.0
@export var speed: float = 75.0

var health = 50
var health_max = 50
var health_min = 0
var dead = false
var taking_damage = false
var is_roaming
var damage_to_deal = 10
var points_for_kill = 100

var player: Node2D = null
var start_position: Vector2
var time_passed: float = 0.0

func _ready():
	start_position = global_position

	if $AnimatedSprite2D.sprite_frames.has_animation("bat_movement"):
		$AnimatedSprite2D.play("bat_movement")

func _process(delta):
	Globals.batDamageAmount = damage_to_deal
	Globals.batDamageZone = $BatDealDamageArea

func _physics_process(delta):
	# Spieler regelmäßig neu suchen, falls verloren gegangen
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("players")
		if player != null:
			print("✅ Spieler gefunden: ", player.name)

	# Kein Spieler vorhanden? Bewegung abbrechen
	if player == null:
		move_sinusoidal(delta)
		return

	# Abstand zum Spieler berechnen
	var distance = global_position.distance_to(player.global_position)

	if distance <= aggro_distance:
		# Spieler verfolgen
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		# Sinusbewegung (Idle-Verhalten)
		move_sinusoidal(delta)

	move_and_slide()

func move_sinusoidal(delta):
	time_passed += delta
	var offset_x = sin(time_passed * frequency * TAU) * amplitude
	var target_pos = Vector2(start_position.x + offset_x, start_position.y)
	var direction = (target_pos - global_position).normalized()

	# Geschwindigkeit proportional zum Abstand
	velocity = direction * (global_position.distance_to(target_pos) * 1.5)
