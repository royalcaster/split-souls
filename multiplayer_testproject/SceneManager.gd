extends Node2D

@export var PlayerScene : PackedScene

var player_spawn_map := {}  # Map: player_id -> spawn_position

func _ready():
	var index = 0
	for i in GameManager.Players:
		# instantiate player
		var currentPlayer = PlayerScene.instantiate()
		var player_id = str(GameManager.Players[i].id)
		currentPlayer.name = player_id
		add_child(currentPlayer)
		
		# place player in spawn position
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index): 
				currentPlayer.global_position = spawn.global_position
				player_spawn_map[player_id] = spawn.global_position  # Speichern!

		index += 1


func _on_button_button_down():
	print("switch mode and set player position")
	switch_to_combined_steering.rpc()
	

@rpc("any_peer", "call_local") 
func switch_to_combined_steering():
	var index = 0
	var new_spawns = get_tree().get_nodes_in_group("CombinedSteeringPlayerSpawnPoint") # replace players and change steering
	# replacing them because if they were on random locations before, they have to be in the same place to be steered together

	for player in get_children():
		if player is CharacterBody2D and index < new_spawns.size():
			player.global_position = new_spawns[index].global_position
			index += 1
	
	Globals.control_mode_separated = false
