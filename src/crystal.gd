extends Area2D

signal collected

@export var value: int = 1
@export var y_jump_height: float = -5.0 # Wie hoch gesprungen wird
@export var y_cycle_time: float = 0.3 # Dauer eines Sprungs (hoch und runter)
@export var y_pause_time: float = 1 # Wie lange unten pausiert wird
var start_position: Vector2
var time_passed: float = 0.0
var base_position 

func _ready():
	base_position = global_position
	## start_position = global_position
	#self.visible = true    # will be set visible in Game.gd after host/client clicks join game
	add_to_group("crystals")

func _process(delta):
	time_passed += delta

	var y_time = fmod(time_passed, y_cycle_time + y_pause_time)
	var y_offset: float

	if y_time < y_cycle_time:
		var t_norm = y_time / y_cycle_time
		y_offset = -4 * y_jump_height * pow(t_norm - 0.5, 2) + y_jump_height
	else:
		y_offset = 0.0
	global_position.y = base_position.y + y_offset

func _on_body_entered(body: Node2D):
	if body.has_method("is_player"):
		Globals.update_crystal_score()
		$AudioStreamPlayer.play()
		$".".visible = false
		$CollisionShape2D.queue_free()
		await get_tree().create_timer(2.0).timeout
		collected.emit(value)
		queue_free()
	
