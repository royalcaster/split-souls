extends Node

enum ControlMode {
	SHARED,
	INDIVIDUAL
}

enum ItemType {
	DIRECTION,
	SPECIALPOWER,
	#Heart_Container
}

var control_mode := ControlMode.INDIVIDUAL

var spawn_position = Vector2(80, 70)

var current_crystal_score = 0
var crystals_collected_handled := false

var player: Node2D = null
var camera: Camera2D = null
var small_gates: Array = []

#Variablen für Battle
var playerAlive : bool
var batDamageZone : Area2D
var batDamageAmount : int

var synced_random_type : int = -1

func _ready():
	# Das registriert die sync_random_item_type-Funktion für Authority-RPCs.
	rpc_config("sync_random_item_type", MultiplayerAPI.RPC_MODE_AUTHORITY)

func generate_synced_random_item_type():
	if multiplayer.is_server():
		randomize()
		var random_index = randi() % ItemType.size()
		synced_random_type = ItemType[ItemType.keys()[random_index]]
		# An alle Clients senden:
		rpc("sync_random_item_type", synced_random_type)
	return synced_random_type

@rpc("call_remote")
func sync_random_item_type(random_type : int):
	synced_random_type = random_type

func update_crystal_score():
	current_crystal_score+=1
	if crystals_collected_handled:
		return
	if current_crystal_score == 5:
		crystals_collected_handled = true
		all_crystals_collected()
	
func all_crystals_collected(): 
	var gates = get_tree().get_nodes_in_group("small_gates")

	# go with camera to gate to show its open
	player = get_tree().get_current_scene().find_child("SharedPlayer", true, false)
	camera = player.find_child("Camera2D", true, false)

	for gate in gates:
		await fly_camera_to_position(gate.global_position)
		gate.open_gate()
		await get_tree().create_timer(0.4).timeout 

	await fly_camera_to_position(player.global_position)

func fly_camera_to_position(target_global_position: Vector2, duration: float = 1.5):
	var target_local_position = player.to_local(target_global_position)
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "position", target_local_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	return tween.finished
