extends Node

@export var connected_boxes: Node2D = null

func on_press() -> void:
	if connected_boxes: reset_boxes(connected_boxes)

func reset_boxes(object: Node) -> void:
	if object is Pushable:
		object.reset_box()
	else: for object_child in object.get_children():
		reset_boxes(object_child)
