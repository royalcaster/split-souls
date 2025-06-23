extends StaticBody2D

@export var game_node_path: NodePath
var game_node: Node
var bodies_in_gate := []
@onready var sprite = $Sprite2D


@export var number = 0

func _ready():
	game_node = get_node_or_null(game_node_path)

func open_gate():
	if multiplayer.is_server():
		sprite.texture = preload("res://assets/dark_assets/Tor_offen.png")
	else: 
		sprite.texture = preload("res://assets/light_assets/Tor_offen.png")
	$CollisionShape2D.disabled = true
