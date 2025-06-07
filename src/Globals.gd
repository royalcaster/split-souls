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
