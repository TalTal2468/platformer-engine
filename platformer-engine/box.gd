class_name Pushable
extends CharacterBody2D

@export var gravity := 1800
@export var max_speedX := 800 / scale[0]
@export var max_speedY := 1000
@export var acceleration := 2000 / scale[0]

func _physics_process(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_speedY)
	var collided_with_player = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Player and collision.get_normal().y == 0.0:
			collided_with_player = true
	if not collided_with_player:
		velocity.x = clamp(move_toward(velocity.x, 0.0, acceleration * delta), -max_speedX, max_speedX)
	move_and_slide()
