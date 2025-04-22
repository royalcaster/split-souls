extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer


func _ready():
	# connect multiplayer signals
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	# start server automatically if --server is in command line (not tested)
	if "--server" in OS.get_cmdline_args():
		hostGame()

	
func peer_connected(id): 	# called on the server and clients when someone connects (runs on their own machine)
	print("Player Connected " + str(id))
	
func peer_disconnected(id): 	# called on the server and clients when someone disconnects
	print("Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	
	
func connected_to_server(): 	# called on the clients when they connect to server (use it when we send information from client to server)
	print("Connected to server!")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())
	
func connection_failed(): 	# called on the clients 
	print("Connection Failed!")
	
@rpc("any_peer")
func SendPlayerInformation(name, id): 	# call function whenever user connects
	if !GameManager.Players.has(id):	# check if a player with the id already exists, otherwise create a new one
		GameManager.Players[id] = { 	# created object with information we want to save about the players
			"name": name,
			"id": id, 
			"score": 0
		}
		
	# server sends player information to all clients
	if multiplayer.is_server():
		for i in GameManager.Players: 
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
	
	
func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2) 	# maximum of 2 players
	if error != OK: 
		print("cannot host: " + str(error))
		return 
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 	#get more bandwidth (optional)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Playrs!")
	
@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://testScene.tscn").instantiate() 	#load scene
	get_tree().root.add_child(scene) 	#add to scene tree
	self.hide() 	#hide current scene
	
func _on_host_button_down():
	hostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass # Replace with function body.


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 	#get more bandwidth (optional)
	multiplayer.set_multiplayer_peer(peer)

	pass # Replace with function body.


func _on_start_game_button_down():
	StartGame.rpc()	#rpc as parameter will run this code on all participants, rpc_id(1) will run it on the host only
	pass # Replace with function body.
