extends Area2D

signal collected

@export var value: int = 1
@export var y_jump_height: float = -5.0
@export var y_cycle_time: float = 0.3
@export var y_pause_time: float = 1

@onready var collider := $CollisionShape2D

var base_position
var time_passed: float = 0.0
var collected_already := false

func _ready():
	base_position = global_position
	add_to_group("crystals")

func _process(delta):
	if collected_already:
		return

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
	if collected_already or Globals.is_loading:
		return

	if body.has_method("is_player"):
		collected_already = true
		Globals.update_crystal_score()
		$AudioStreamPlayer.play()
		visible = false
		collider.disabled = true
		await get_tree().create_timer(2.0).timeout
		collected.emit(value)
		# NICHT löschen – nur verstecken und deaktivieren


func restore_after_load(is_collected: bool):
	
	print("🔁 Restore Crystal → collected:", is_collected)
	collected_already = is_collected
	if is_collected:
		visible = false
		collider.disabled = true
		set_process(false)
		set_physics_process(false)
