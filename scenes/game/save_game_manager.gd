class_name save_game_manager
extends Node

var save_file_path := "user://savegame.json"

func save_game(save_data: SaveData):
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	var json = JSON.stringify(save_data.to_dict())
	file.store_line(json)
	file.close()

func load_game() -> SaveData:
	if not FileAccess.file_exists(save_file_path):
		return null

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	var json = file.get_line()
	file.close()

	var parsed = JSON.parse_string(json)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Savegame corrupt!")
		return null

	var save_data = SaveData.new()
	save_data.from_dict(parsed)
	return save_data
