extends ProgressBar

var parent
var max_value_amount
var min_value_amount

func _ready():

	parent = get_parent()
	max_value_amount = parent.health_max
	min_value_amount = 0  # Normaldssddsdderweise ist 0 das Minimum für Health

	visible = false
	value = parent.health
	max_value = max_value_amount
	min_value = min_value_amount

func _process(_delta):
	self.value = parent.health # Health-Wert aktualisieren
	
	# Sichtbarkeit: Nur anzeigen, wenn Health nicht voll oder leer
	if parent.health < max_value_amount and parent.health > min_value_amount:
		visible = true
	else:
		visible = false
