extends Node

@export var connected_objects: Node2D = null
@export var start_objects_faded := false

func on_press() -> void:
	if connected_objects:
		if start_objects_faded:
			fade_objects_in(connected_objects)
		else: fade_objects_out(connected_objects)

func on_release() -> void:
	if connected_objects:
		if start_objects_faded:
			fade_objects_out(connected_objects)
		else: fade_objects_in(connected_objects)

func fade_objects_out(object: Node2D) -> void:
	# Fade connected objects out with a tween
	pass

func fade_objects_in(object: Node2D) -> void:
	# Fade connected objects in with a tween
	pass
