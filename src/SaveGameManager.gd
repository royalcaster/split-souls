extends Node

const SAVE_FILE := "user://savegame.json"

func save_game(player):
	var data = {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		},
		"health": player.health,
		"enemies": [],
		"crystals": [],
		"barriers": [],
		"team_items": [],
		"crystal_score": Globals.current_crystal_score
	}

	var item_script := preload("res://scenes/items/item.gd")

	# Nur Items speichern, die zum eigenen Team gehören
	var item_group = ""
	if multiplayer.is_server():
		item_group = "team_items_dark"
	else:
		item_group = "team_items_light"


	for item in get_tree().get_nodes_in_group(item_group):
		if item.get_script() != item_script:
			continue

		var item_data = {
			"path": item.get_path(),
			"position": {
				"x": item.global_position.x,
				"y": item.global_position.y
			},
			"visible": item.visible,
			"collected": item.collected_already
		}
		data["team_items"].append(item_data)
		










	for barrier in get_tree().get_nodes_in_group("barriers"):
		var barrier_data = {
			"path": barrier.get_path(),
			"visible": barrier.visible,
			"interactable": barrier.interactable
		}
		data["barriers"].append(barrier_data)

	for crystal in get_tree().get_nodes_in_group("crystals"):
		var crystal_data = {
			"path": crystal.get_path(),
			"position": {
				"x": crystal.global_position.x,
				"y": crystal.global_position.y
			},
			"collected": crystal.collected_already,
			"visible": crystal.visible
		}
		data["crystals"].append(crystal_data)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_data = {
			"name": enemy.get_path(),
			"position": {
				"x": enemy.global_position.x,
				"y": enemy.global_position.y
			},
			"health": enemy.health if "health" in enemy else 0,
			"is_dead": enemy.is_dead if "is_dead" in enemy else false
		}
		data["enemies"].append(enemy_data)

	for e in data["enemies"]:
		print("📦 SAVE: ", e["name"], " → is_dead: ", e["is_dead"])

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("📦 GESPEICHERTES SAVE:")
	print(JSON.stringify(data, "\t"))
	file.close()

	print("📎 Spiel + Gegner gespeichert!")


	Globals.show_status_message("💾 Speichere Spiel...")


func load_game(player):
	Globals.is_loading = true

	if not FileAccess.file_exists(SAVE_FILE):
		print("❌ Kein Savegame gefunden!")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data.has("position"):
		var pos = data["position"]
		player.global_position = Vector2(pos["x"], pos["y"])

	if data.has("health"):
		player.health = data["health"]

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.visible = true
		enemy.set_physics_process(true)
		enemy.dead = false
		enemy.health = enemy.health_max
		if enemy.has_method("sync_health"):
			enemy.sync_health(enemy.health)

	if data.has("enemies"):
		for enemy_data in data["enemies"]:
			var name = enemy_data.get("name", "")
			var enemy = get_node_or_null(name)
			if enemy:
				if enemy_data.has("position"):
					var pos = enemy_data["position"]
					enemy.global_position = Vector2(pos["x"], pos["y"])
				if enemy_data.has("health"):
					enemy.health = enemy_data["health"]
					if enemy.has_method("sync_health"):
						enemy.sync_health(enemy.health)
				if enemy_data.get("is_dead", false):
					enemy.dead = true
					enemy.visible = false
					enemy.set_physics_process(false)

	if data.has("crystals"):
		for crystal_data in data["crystals"]:
			var crystal = get_node_or_null(crystal_data.get("path", ""))
			if crystal:
				if crystal_data.has("position"):
					var pos = crystal_data["position"]
					crystal.global_position = Vector2(pos["x"], pos["y"])
				if crystal_data.has("visible"):
					crystal.visible = crystal_data["visible"]
				if crystal_data.has("collected"):
					crystal.restore_after_load(crystal_data["collected"])

	if data.has("barriers"):
		for barrier_data in data["barriers"]:
			var barrier = get_node_or_null(barrier_data.get("path", ""))
			if barrier:
				if barrier_data.has("visible"):
					barrier.visible = barrier_data["visible"]
				if barrier_data.has("interactable"):
					barrier.interactable = barrier_data["interactable"]

	if data.has("team_items"):
		var item_group = ""
		if multiplayer.is_server():
			item_group = "team_items_dark"
		else:
			item_group = "team_items_light"


		for item_data in data["team_items"]:
			var path = item_data.get("path", "")
			var item = get_node_or_null(path)

			if item and item.is_in_group(item_group):
				if item_data.has("position"):
					var pos = item_data["position"]
					item.global_position = Vector2(pos["x"], pos["y"])

				if item_data.has("visible"):
					item.visible = item_data["visible"]

				if item_data.has("collected"):
					item.restore_after_load(item_data["collected"])
			else:
				print("❌ Item nicht gefunden oder falsches Team:", path)








	if data.has("crystal_score"):
		Globals.current_crystal_score = int(data["crystal_score"])
		Globals.update_crystal_score_ui()
		Globals.update_crystal_score_ui_remote.rpc()  # <-- damit auch der 2. Spieler updatet


	Globals.is_loading = false
	print("📂 Spiel + Gegner + Crystals geladen!")
	Globals.show_status_message("📂 Lade Spiel...")
