class_name SaveData
extends Resource

var player_position: Vector2
var player_health: int
var world_state: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"player_position": { "x": player_position.x, "y": player_position.y },
		"player_health": player_health,
		"world_state": world_state,
	}

func from_dict(data: Dictionary):
	var pos = data.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(pos.x, pos.y)
	player_health = data.get("player_health", 100)
	world_state = data.get("world_state", {})
