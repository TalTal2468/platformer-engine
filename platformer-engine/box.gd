class_name Pushable
extends CharacterBody2D

@export_group("Basic Movement")
@export var gravity := 1800
@export var max_speedY := 1000

func _physics_process(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_speedY)
	move_and_slide()
	var collided_with_player = false
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() is Player:
			collided_with_player = true
	if not collided_with_player: velocity.x = 0.0
