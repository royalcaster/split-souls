extends CanvasLayer
var current_crystal_score = 1

func update_crystal_score():
	current_crystal_score +=1
	$CrystalScore.text = str(current_crystal_score)

func update_crystal_direction_items(value):
	$CrystalDirectionItems.text = str(value)
