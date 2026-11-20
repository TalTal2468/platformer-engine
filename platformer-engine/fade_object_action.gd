extends Node

@export var connected_objects: Node2D = null
@export var start_objects_faded := false
@export var fade_hitbox := true
@export var fade_duration := 0.2

var fade_tween: Tween = null

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
	var acting_duration = fade_duration if custom_duration < 0.0 else custom_duration
	if object is CanvasItem:
		if fade_tween: fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(object, "modulate:a", 0.0, acting_duration)
		if fade_hitbox:
			fade_tween.tween_callback(set_hitbox.bind(object, false))

func fade_objects_in(object: Node2D) -> void:
	if object is CanvasItem:
		if fade_tween: fade_tween.kill()
		if fade_hitbox: set_hitbox(object, true)
		fade_tween = create_tween()
		fade_tween.tween_property(object, "modulate:a", 1.0, fade_duration)

func set_hitbox(object, state: bool) -> void:
	if object is CollisionShape2D or object is CollisionPolygon2D:
		object.set_deferred("disabled", not state)
	else: for object_child in object.get_children():
		set_hitbox(object_child, state)
