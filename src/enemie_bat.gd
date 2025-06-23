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
var can_take_damage = true
var damage_to_deal = 10
var points_for_kill = 100

var player: Node2D = null
var start_position: Vector2
var time_passed: float = 0.0

func _ready():
	start_position = global_position
	add_to_group("enemies")

	if $AnimatedSprite2D.sprite_frames.has_animation("bat_movement"):
		$AnimatedSprite2D.play("bat_movement")

func _process(_delta):
	Globals.batDamageAmount = damage_to_deal
	Globals.batDamageZone = $BatDealDamageArea

func _physics_process(_delta):
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("players")
		if player != null:
			print("✅ Spieler gefunden: ", player.name)

	if player == null:
		move_sinusoidal(_delta)
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= aggro_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		move_sinusoidal(_delta)

	move_and_slide()

func move_sinusoidal(delta):
	time_passed += delta
	var offset_x = sin(time_passed * frequency * TAU) * amplitude
	var target_pos = Vector2(start_position.x + offset_x, start_position.y)
	var direction = (target_pos - global_position).normalized()
	velocity = direction * (global_position.distance_to(target_pos) * 1.5)

# Schaden erhalten
@rpc("any_peer", "call_remote", "reliable")
func take_damage(damage: int) -> void:
	if not is_multiplayer_authority():
		return  # Nur Server darf verarbeiten
		
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == -1:
		return # invalid sender


	if not can_take_damage or dead:
		return

	health = clamp(health - damage, health_min, health_max)
	print("🟥 [SERVER] Gegner-Health reduziert auf: ", health)

	sync_health.rpc(health)  # an alle Clients schicken

	if health <= health_min:
		rpc_die.rpc()  # Enemy bei Client löschen
		rpc_die()        # Enemy bei Host (lokal)
	else:
		take_damage_cooldown(0.2)

# Health auf allen Clients synchronisieren
@rpc("any_peer", "call_remote", "reliable")
func sync_health(current: int):
	health = current
	if has_node("HealthBar"):
		$HealthBar.update_health(health, health_max)

# Enemy dead wird an Client gesendet
@rpc("authority", "call_remote", "reliable")
func rpc_die():
	if dead:
		return
	dead = true
	queue_free()

func take_damage_cooldown(wait_time: float) -> void:
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

func get_health():
	return health

func get_health_max():
	return health_max

func _on_damage_area_body_entered(body):
	if body is Player and not dead:
		if body.can_take_damage:
			body.take_damage(damage_to_deal)


func _on_bat_deal_damage_area_body_entered(body: Node2D) -> void:
	if body is Player and not dead:
		if body.can_take_damage:
			body.take_damage(damage_to_deal)
