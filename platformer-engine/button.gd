extends Area2D

@onready var button_visual = $ButtonVisual
@onready var player = get_tree().get_first_node_in_group("player")

@export var kill_player := false
@export var connected_boxes: Node2D = null

var height_animation_tween: Tween
var pressed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	animate_height(15 if valid_presser() else 25)
	if not valid_presser(): pressed = false

func _on_body_entered(body: Node2D) -> void:
	if (body is Player or body is Pushable) and not pressed:
		pressed = true
		if connected_boxes: reset_boxes(connected_boxes)
		if kill_player: player.die()

func reset_boxes(object: Node2D) -> void:
	if object is Pushable:
		object.reset_box()
	else: for box_child in object.get_children():
		reset_boxes(box_child)

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
