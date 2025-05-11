extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var player_scene2: PackedScene


func _on_host_btn_pressed():
	MultiplayerServer.host()
	
func _add_player(id :=1):
	var player = player_scene.instantiate() if id == 1 else player_scene2.instantiate()
	player.name =str(id)
	#player.set_multiplayer_authority(id)
	call_deferred("add_child", player)
	

func _on_client_btn_pressed():
	MultiplayerServer.join()
