extends Node2D

@onready var oid_lbl = $Multiplayer/VBoxContainer/OID
@onready var oid_input = $Multiplayer/Panel/VBoxContainer/OIDInput
@onready var multiplayer_ui = $Multiplayer
@onready var tilemap = $MapContainer/TileMap
const PLAYER = preload("res://scenes/player/player_1.tscn")
const CRYSTAL = preload("res://scenes/game/Crystal.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []

# tile positions -> are multiplied by 16 later to get pixel positions
var crystal_positions: Array[Vector2] = [
	Vector2(3, 6),
	Vector2(5, 8),
	Vector2(10, 4),
	Vector2(2, 8)
]

func _ready():
	spawn_crystal(0, crystal_positions[0])
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

func spawn_crystal(index: int, pos: Vector2):
	if index < crystal_positions.size():
		var crystal_instance = CRYSTAL.instantiate()
		crystal_instance.value = index
		add_child(crystal_instance)
		crystal_instance.collected.connect(on_crystal_collected)
		crystal_instance.position = pos * 16
		print("Spawned crystal at tile ", pos)
	
func on_crystal_collected(value):
	$Hud.update_crystal_score(value)
	print("collected crystal")
	spawn_crystal(value + 1, crystal_positions[value])
