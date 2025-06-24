extends Node

enum ControlMode {
	SHARED,
	INDIVIDUAL
}

enum ItemType {
	DIRECTION,
	SPECIALPOWER
}

var control_mode := ControlMode.INDIVIDUAL
var spawn_position = Vector2(80, 70)
var current_crystal_score = 0
var crystals_collected_handled := false

var player: Node2D = null
var camera: Camera2D = null
var small_gates: Array = []

var playerAlive : bool
var batDamageZone : Area2D
var batDamageAmount : int

var synced_random_type : int = -1
var is_loading := false


func _ready():
	rpc_config("sync_random_item_type", MultiplayerAPI.RPC_MODE_AUTHORITY)


func update_crystal_score():
	current_crystal_score += 1
	update_crystal_score_ui()
	update_crystal_score_ui_remote.rpc()  # Remote-Aufruf auf anderen Clients

	if crystals_collected_handled:
		return

	if current_crystal_score >= 5:
		crystals_collected_handled = true
		all_crystals_collected()


func update_crystal_score_ui():
	if has_node("/root/Game/UI/CrystalCounter"):
		$"/root/Game/UI/CrystalCounter".text = str(int(current_crystal_score))


@rpc("call_remote")
func update_crystal_score_ui_remote():
	update_crystal_score_ui()


func all_crystals_collected():
	var gates = get_tree().get_nodes_in_group("small_gates")

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


func generate_synced_random_item_type():
	if multiplayer.is_server():
		randomize()
		var random_index = randi() % ItemType.size()
		synced_random_type = ItemType[ItemType.keys()[random_index]]
		rpc("sync_random_item_type", synced_random_type)
	return synced_random_type






func show_status_message(text: String, duration: float = 2.0):
	var label = get_node_or_null("/root/Game/HUD/StatusLabel")
	if label:
		label.text = text
		label.show()
		await get_tree().create_timer(duration).timeout
		label.hide()
		
@rpc("call_remote")
func show_status_message_remote(text: String, duration: float = 2.0):
	show_status_message(text, duration)
