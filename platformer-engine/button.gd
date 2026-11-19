extends Area2D

@onready var button_visual = $ButtonVisual
var height_animation_tween: Tween

func _physics_process(_delta: float) -> void:
	var pressed := false
	for body in get_overlapping_bodies():
		if body is Player or body is Pushable:
			pressed = true
			break
	if pressed: animate_height(15)
	else: animate_height(25)

func animate_height(target_height: float) -> void:
	if height_animation_tween and height_animation_tween.is_valid():
		height_animation_tween.kill()
	height_animation_tween = create_tween()
	height_animation_tween.set_trans(Tween.TRANS_CUBIC)
	height_animation_tween.set_ease(Tween.EASE_OUT)
	height_animation_tween.tween_method(set_height, button_visual.size.y, target_height, 0.1)

func set_height(height: float) -> void:
	button_visual.size.y = height
	button_visual.position.y = -height
