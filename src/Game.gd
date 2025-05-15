extends Node2D

@onready var oid_lbl = $Multiplayer/VBoxContainer/OID
@onready var oid_input = $Multiplayer/Panel/VBoxContainer/OIDInput
@onready var multiplayer_ui = $Multiplayer
@onready var tilemap = $MapContainer/TileMap
const PLAYER = preload("res://scenes/player/player_1.tscn")
const CRYSTAL = preload("res://scenes/game/Crystal.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []

var tilemap_length = 35
var tilemap_height = 19

var rng = RandomNumberGenerator.new()

var crystal_position: Vector2 = Vector2(3*16, 6*16)

func _ready():
	spawn_crystal()
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
	var base_spawn_position = Vector2(400, 250)
	var spawn_position = base_spawn_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	player.position = spawn_position
	return player

func spawn_crystal():
	var crystal_instance = CRYSTAL.instantiate()
	add_child(crystal_instance)
	print(crystal_position)
	crystal_instance.position = crystal_position
