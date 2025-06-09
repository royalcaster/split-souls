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
	#else:
	#	push_error("❌ Parent hat keine gültigen Health-Methoden!")

func _process(_delta):
	if not parent: return
	if not parent.has_method("get_health"): return
	
	# Health-Wert synchronisiert vom Parent lesen
	value = parent.get_health()

	visible = value < max_value_amount and value > min_value_amount

func update_health(_current: int, _max: int):
	max_value = _max
	# Wert deferred setzen, um UI-Update zu erzwingen
	call_deferred("_set_value", _current)

func _set_value(val):
	value = val
	visible = value < max_value and value > min_value_amount
