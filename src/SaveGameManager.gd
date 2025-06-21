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
		"team_items": []




	}
	
	for item in get_tree().get_nodes_in_group("team_items"):
		var parent_name = item.get_parent().name  # z. B. "ItemsLight" oder "ItemsDark"
		var item_data = {
		"path": item.get_path(),
		"position": {
			"x": item.global_position.x,
			"y": item.global_position.y
		},
		"visible": item.visible,
		"team": parent_name
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

	# 👉 Hier: Ausgabe aller gespeicherten Gegner
	for e in data["enemies"]:
		print("📦 SAVE: ", e["name"], " → is_dead: ", e["is_dead"])

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("💾 Spiel + Gegner gespeichert!")


func load_game(player):
	if not FileAccess.file_exists(SAVE_FILE):
		print("❌ Kein Savegame gefunden!")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	# Spielerposition laden
	if data.has("position"):
		var pos = data["position"]
		player.global_position = Vector2(pos["x"], pos["y"])

	# Spielerleben laden
	if data.has("health"):
		player.health = data["health"]

	# Alle Gegner zuerst vollständig reaktivieren
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.visible = true
		enemy.set_physics_process(true)
		enemy.dead = false
		enemy.health = enemy.health_max
		if enemy.has_method("sync_health"):
			enemy.sync_health(enemy.health)

	# Jetzt die Daten aus dem Savegame anwenden
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

	# Crystals laden
	if data.has("crystals"):
		for crystal_data in data["crystals"]:
			var crystal = get_node_or_null(crystal_data.get("path", ""))
			if crystal:
				if crystal_data.has("position"):
					var pos = crystal_data["position"]
					crystal.global_position = Vector2(pos["x"], pos["y"])
				if crystal_data.has("visible"):
					crystal.visible = crystal_data["visible"]
					
	if data.has("barriers"):
		for barrier_data in data["barriers"]:
			var barrier = get_node_or_null(barrier_data.get("path", ""))
			if barrier:
				if barrier_data.has("visible"):
					barrier.visible = barrier_data["visible"]
				if barrier_data.has("interactable"):
					barrier.interactable = barrier_data["interactable"]
					
	if data.has("team_items"):
		for item_data in data["team_items"]:
			var item = get_node_or_null(item_data.get("path", ""))
			if item:
				if item_data.has("position"):
					var pos = item_data["position"]
					item.global_position = Vector2(pos["x"], pos["y"])
				if item_data.has("visible"):
					item.visible = item_data["visible"]



	print("📂 Spiel + Gegner + Crystals geladen!")
