class_name Pushable
extends CharacterBody2D

@export var gravity := 1800
@export var max_speedX := 800 / scale[0]
@export var max_speedY := 1000
@export var acceleration := 2000 / scale[0]

var pushed_this_frame := false

func push(velocity_x: float, delta: float) -> float:
	var start_x := global_position.x
	velocity.x = clamp(velocity_x, -max_speedX, max_speedX)
	move_and_collide(Vector2(velocity.x * delta, 0.0))
	pushed_this_frame = true
	return global_position.x - start_x

func _physics_process(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_speedY)
	if pushed_this_frame:
		# Don't move horizontally this frame because it was already done in push()
		pushed_this_frame = false
		var velocity_x := velocity.x
		velocity.x = 0.0
		move_and_slide()
		velocity.x = velocity_x
	else:
		velocity.x = clamp(move_toward(velocity.x, 0.0, acceleration * delta), -max_speedX, max_speedX)
		move_and_slide()
