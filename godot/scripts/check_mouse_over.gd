extends Area2D

var over = false

func _mouse_enter() -> void:
	over = true

func _mouse_exit() -> void:
	over = false

func mouse_is_over() -> bool:
	return over