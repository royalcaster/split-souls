extends Area2D

signal collected

@export var value: int = 1
@export var y_jump_height: float = -5.0 # Wie hoch gesprungen wird
@export var y_cycle_time: float = 0.3 # Dauer eines Sprungs (hoch und runter)
@export var y_pause_time: float = 1 # Wie lange unten pausiert wird

var start_position: Vector2
var time_passed: float = 0.0

func _ready():
	# start_position = global_position
	self.visible = false    # will be set visible in Game.gd after host/client clicks join game
	add_to_group("crystals")

func _process(delta):
	time_passed += delta

	var y_time = fmod(time_passed, y_cycle_time + y_pause_time)
	var y_offset: float

	if y_time < y_cycle_time:
		# Parabel: Schneller nach oben, langsamer nach unten
		var t_norm = y_time / y_cycle_time
		y_offset = -4 * y_jump_height * pow(t_norm - 0.5, 2) + y_jump_height
	else:
		# Pause unten
		y_offset = 0.0

	global_position.y = start_position.y + y_offset
	global_position.x = start_position.x

func _on_body_entered(body: Node2D):
	if body.has_method("is_player"):
		collected.emit(value)
		queue_free()
