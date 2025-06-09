extends Node

enum ControlMode {
	SHARED,
	INDIVIDUAL
}

var control_mode := ControlMode.INDIVIDUAL

var spawn_position = Vector2(80, 70)

#Variablen für Battle
var playerAlive : bool
var batDamageZone : Area2D
var batDamageAmount : int

var current_crystal_score = 0
func update_crystal_score():
	current_crystal_score+=1
	#print(current_crystal_score)
	#$HUD/CrystalScore.text = str(current_crystal_score)
