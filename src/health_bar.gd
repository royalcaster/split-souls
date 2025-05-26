extends ProgressBar

var parent
var max_value_amount
var min_value_amount = 0

func _ready():
	parent = get_parent()

	# Prüfe, ob der Parent gültige Health-Methoden hat (Multiplayer-sicher)
	if parent and parent.has_method("get_health") and parent.has_method("get_health_max"):
		max_value_amount = parent.get_health_max()
		value = parent.get_health()
		max_value = max_value_amount
		min_value = min_value_amount
		visible = false
	else:
		push_error("❌ Parent hat keine gültigen Health-Methoden!")

func _process(_delta):
	if not parent: return
	if not parent.has_method("get_health"): return
	
	# Health-Wert synchronisiert vom Parent lesen
	value = parent.get_health()

	# Sichtbarkeit steuern
	visible = value < max_value_amount and value > min_value_amount

# 🔁 Diese Funktion ist optional, wenn du sie direkt aufrufst (z. B. aus einem globalen Sync)
func update_health(current: int, max: int):
	value = current
	max_value = max
