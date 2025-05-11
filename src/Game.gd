extends Node2D

@onready var oid_lbl = $Multiplayer/VBoxContainer/OID
@onready var oid_input = $Multiplayer/VBoxContainer/OIDInput
@onready var multiplayer_ui = $Multiplayer
const PLAYER = preload("res://scenes/player/player_1.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []
func _ready():
	$MultiplayerSpawner.spawn_function = add_player
	await MultiplayerServer.noray_connected
	oid_lbl.text = Noray.oid

func _process(delta):
	if get_node_or_null("SettingsMenu") == null:
		if Input.is_action_just_pressed("ui_cancel"):
			SceneManager.open_pause_overlay()

func _on_settings_button_pressed():
	if get_node_or_null("SettingsMenu") == null:
		SceneManager.open_pause_overlay()

func return_to_main_menu():
	if get_tree().paused:
		get_tree().paused = false
	SceneManager.goto_scene("res://scenes/ui/MainMenu.tscn")


func _on_host_pressed():
	MultiplayerServer.host()
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined the game!")
			$MultiplayerSpawner.spawn(pid)
	)
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed():
	MultiplayerServer.join(oid_input.text)
	multiplayer_ui.hide()


func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	players.append(player)
	
	return player
