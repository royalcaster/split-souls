extends Node

enum ControlMode {
	SHARED,
	INDIVIDUAL
}

var control_mode := ControlMode.INDIVIDUAL

var spawn_position = Vector2(30, 60)

#Variablen für Battle
var playerAlive : bool
var batDamageZone : Area2D
var batDamageAmount : int
