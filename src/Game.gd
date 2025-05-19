extends Node2D

@onready var oid_lbl = $Multiplayer/VBoxContainer/OID
@onready var oid_input = $Multiplayer/Panel/VBoxContainer/OIDInput
@onready var multiplayer_ui = $Multiplayer
@onready var tilemap = $MapContainer/TileMap
const PLAYER = preload("res://scenes/player/player_1.tscn")
const CRYSTAL = preload("res://scenes/game/Crystal.tscn")
const ENEMY = preload("res://scenes/enemies/enemie_bat.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Player] = []

# Tile-Koordinaten (werden mit 16 multipliziert)
var crystal_positions: Array[Vector2] = [
	Vector2(3, 6),
	Vector2(5, 8),
	Vector2(10, 4),
	Vector2(2, 8)
]

var enemy_positions: Array[Vector2] = [
	Vector2(10, 25),
	Vector2(15, 22),
	Vector2(20, 18)
]

func _ready():
	spawn_crystal(0, crystal_positions[0])

	if multiplayer.is_server():
		spawn_enemy(0, enemy_positions[0])  # Nur der Server spawnt Gegner
	
	$MultiplayerSpawner.spawn_function = add_player
	await MultiplayerServer.noray_connected

	var oid_node = get_node_or_null("Multiplayer/VBoxContainer/OID")
	if oid_node:
		oid_node.text = Noray.oid
	else:
		print("WARNUNG: Knoten 'OID' nicht gefunden!")

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
			$MultiplayerSpawner.spawn(pid)  # spawn für jeden neuen Peer
	)

	# Spawn den Host-Player explizit nur hier einmal
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

func spawn_enemy(index: int, pos: Vector2):
	if index < enemy_positions.size():
		var enemy_instance = ENEMY.instantiate()
		enemy_instance.global_position = pos * 16
		add_child(enemy_instance)
		print("Spawned enemy at tile ", pos)

# Optional: spawnt alle Gegner direkt (z.B. bei Spielstart oder Wellen)
func spawn_all_enemies():
	for i in enemy_positions.size():
		spawn_enemy(i, enemy_positions[i])
