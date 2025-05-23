extends Node

enum ControlMode {
	SHARED,
	INDIVIDUAL
}

var control_mode := ControlMode.INDIVIDUAL

var spawn_position = Vector2(30, 60)
