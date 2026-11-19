extends Node

@export var connected_objects: Node2D = null
@export var start_objects_faded := false
@export var dont_fade_hitbox := false
@export var duration := 0.5

var fade_out_tween: Tween = null
var fade_in_tween: Tween = null

func _ready() -> void:
	if start_objects_faded: 
		fade_objects_out(connected_objects, 0.0)

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

func fade_objects_out(object: Node2D, custom_duration := -1.0) -> void:
	var acting_duration = duration if custom_duration < 0.0 else custom_duration
	if object is CanvasItem:
		if fade_in_tween: fade_in_tween.kill()
		fade_out_tween = create_tween()
		fade_out_tween.tween_property(object, "modulate:a", 0.0, acting_duration)
		if not dont_fade_hitbox:
			fade_out_tween.tween_callback(turn_off_hitbox.bind(object))

func fade_objects_in(object: Node2D) -> void:
	if object is CanvasItem:
		if fade_out_tween: fade_out_tween.kill()
		if not dont_fade_hitbox: turn_on_hitbox(object)
		fade_in_tween = create_tween()
		fade_in_tween.tween_property(object, "modulate:a", 1.0, duration)

func turn_off_hitbox(object) -> void:
	if object is CollisionShape2D or object is CollisionPolygon2D:
		object.set_deferred("disabled", true)
	else: for object_child in object.get_children():
		turn_off_hitbox(object_child)

func turn_on_hitbox(object) -> void:
	if object is CollisionShape2D or object is CollisionPolygon2D:
		object.set_deferred("disabled", false)
	else: for object_child in object.get_children():
		turn_on_hitbox(object_child)
