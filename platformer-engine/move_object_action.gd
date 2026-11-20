extends Node

@export var connected_objects: Node2D = null
@export var offset: Vector2 = Vector2.ZERO
@export var move_duration := 1.0
@export var change_global_position := false
@export var easing := true

var movement_tween: Tween = null
var original_position: Vector2
var property: String

func _ready() -> void:
	property = "global_position" if change_global_position else "position"
	if connected_objects:
		original_position = connected_objects.get(property)

func on_press() -> void: move_to(original_position + offset)

func on_release() -> void: move_to(original_position)

func move_to(target_position):
	if connected_objects:
		if movement_tween: movement_tween.kill()
		movement_tween = create_tween()
		movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		if easing: movement_tween.set_trans(Tween.TRANS_CUBIC)
		movement_tween.tween_property(connected_objects, property, target_position, move_duration)
