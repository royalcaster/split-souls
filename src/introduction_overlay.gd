extends TextureButton

func _ready():
	if multiplayer.is_server():
		texture_normal = load("res://assets/Scroll_dark.png")
	else:
		texture_normal = load("res://assets/Scroll.png")
