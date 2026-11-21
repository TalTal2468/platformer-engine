extends Node

@export var connected_objects: Node2D = null

func on_press():
	if connected_objects: toggle_movement(connected_objects)

func on_release():
	if connected_objects: toggle_movement(connected_objects)

func toggle_movement(object: Node) -> void:
	if object is Platform or object is Spike:
		object.moving = not object.moving
	else: for object_child in object.get_children():
		toggle_movement(object_child)
