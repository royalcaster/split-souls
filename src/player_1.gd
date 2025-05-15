class_name Player
extends BasePlayer

@export var player_1_frames: SpriteFrames
@export var player_2_frames: SpriteFrames
func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	var mp := get_tree().get_multiplayer()

	print("My Peer ID: ", mp.get_unique_id())
	print("Am I Host? ", mp.is_server())
	
	if is_multiplayer_authority():
		$Camera2D.make_current()
	# Spritesheet je nach Peer-ID zuweisen
	if get_multiplayer_authority() == 1:
		animatedSprite2D.sprite_frames = player_1_frames
		
	else:
		animatedSprite2D.sprite_frames = player_2_frames

	if mp.get_unique_id() == 1 and mp.is_server():
		print("Ich bin der Host.")
		print(get_multiplayer_authority())
	else:
		print("Ich bin ein Client.")
		print(get_multiplayer_authority())
