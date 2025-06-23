extends Node


# Load the custom images for the mouse cursor.
var pointer = load("res://assets/img/cursor/1. Pointer.png")
var hand_pointer = load("res://assets/img/cursor/2. Hand Pointer.png")


func _ready():
	Input.set_custom_mouse_cursor(pointer)
	Input.set_custom_mouse_cursor(hand_pointer, Input.CURSOR_POINTING_HAND)
