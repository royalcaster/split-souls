extends Node

#conent here is for each player locally. if you want to change it for all players, you need to use a function with 
#@rpc("any_peer", "call_local") 

var control_mode_separated := true

var player_inputs := {}  # Map: player_id -> Vector2
var combined_direction := Vector2.ZERO  # Die Richtung, in die sich beide bewegen sollen
