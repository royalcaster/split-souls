extends CharacterBody2D

# Parameter für die Bewegung
@export var amplitude: float = 50.0     # Wie weit die Fledermaus nach links/rechts fliegt
@export var frequency: float = 0.2      # Wie schnell sie schwingt
var start_position: Vector2             # Startpunkt merken
var time_passed: float = 0.0            # Zeit für den Sinus

func _ready():
	start_position = global_position
	$AnimatedSprite2D.play("bat_movement")

func _process(delta):
	time_passed += delta
	global_position.x = start_position.x + sin(time_passed * frequency * TAU) * amplitude
