extends Node2D

const bullet_scene = preload("res://scenes/game/bullet.tscn")
const IS_PLAYER = true

@onready var RotationOffset: Node2D = $RotationOffSet
@onready var ShootPos: Marker2D = $RotationOffSet/shoot_pos
@onready var ShootTimer: Timer = $ShootTimer

var rotation_from_client: float = 0.0

var time_between_shot: float = 0.25
var can_shoot: bool = true

func _ready() -> void:

	# Mauszeiger verstecken (vllt noch ändern?)
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	

	# Timer zur Schussverzögerung initialisieren
	ShootTimer.wait_time = time_between_shot
	#ShootTimer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	
	# Positionierungswarnung (einmalig prüfen beim Start)
	if abs(ShootPos.position.angle()) > 0.1:
		push_warning("ShootPos ist nicht exakt auf der X-Achse! Bitte in Szene anpassen.")

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		# Client rotiert lokal
		var target_rotation = (get_global_mouse_position() - global_position).angle()
		RotationOffset.rotation = lerp_angle(
			RotationOffset.rotation, 
			target_rotation, 
			6.5 * delta
		)
	
		# Rotation an den Host schicken
		rpc_id(1, "_update_rotation", target_rotation)
	
	if multiplayer.is_server():
		# Host zeigt die Rotation des Clients an
		RotationOffset.rotation = rotation_from_client
		
		# nur Host kann Schießen
		if Input.is_action_just_pressed("shoot") and can_shoot:
			can_shoot = false
			_shoot()
			ShootTimer.start()

# Host bekommt Rotation von client
@rpc("any_peer")
func _update_rotation(rot: float) -> void:
	if multiplayer.is_server():
		rotation_from_client = rot
		
func _shoot():
	var new_bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(new_bullet)
	new_bullet.global_position = ShootPos.global_position
	new_bullet.rotation = ShootPos.global_rotation

	
	# Debug-Ausgaben zur Position
	print("ShootPos global:", ShootPos.global_position)
	print("Wand global:", global_position)
	play_random_sound()
	
func play_random_sound():
	var rand = randi() % 2
	if rand == 0:
		$"../AudioManager".play_audio_2d("shot1")
	else:
		$"../AudioManager".play_audio_2d("shot2")
func _on_shoot_timer_timeout() -> void:
	can_shoot = true
