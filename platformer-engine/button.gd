extends Area2D

@onready var button_visual = $ButtonVisual
@onready var player = get_tree().get_first_node_in_group("player")

@export var kill_player := false

var height_animation_tween: Tween
var pressed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	animate_height(15 if valid_presser() else 25)
	if not valid_presser(): pressed = false

func _on_body_entered(body: Node2D) -> void:
	if (body is Player or body is Pushable) and not pressed:
		pressed = true
		for button_child in get_children():
			if button_child.has_method("on_press"):
				button_child.on_press()
		if kill_player: player.die()

func _on_body_exited(body: Node2D) -> void:
	if (body is Player or body is Pushable) and pressed:
		pressed = false
		for button_child in get_children():
			if button_child.has_method("on_release"):
				button_child.on_release()

func valid_presser() -> bool:
	var valid = false
	for body in get_overlapping_bodies():
		if body is Player or body is Pushable:
			valid = true
			break
	return valid

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
