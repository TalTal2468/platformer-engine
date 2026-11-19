extends Area2D

@onready var button_visual = $ButtonVisual

func _process(delta: float) -> void:
	var pressed := false
	for body in get_overlapping_bodies():
		if body is Player or body is Pushable:
			pressed = true
			break
	if pressed:
		button_visual.scale.y = 0.5
		button_visual.position.y = -13
	else:
		button_visual.scale.y = 1.0
		button_visual.position.y = -25
