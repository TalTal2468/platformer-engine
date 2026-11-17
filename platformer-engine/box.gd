class_name Pushable
extends CharacterBody2D

@export var scale_weight := 0.75
# Controls how hard box is to push when comparing its scale to Player scale
	# 0.0 -> box moves at player speed; 1.0 -> double the box scale, half the push speed

@onready var gravity := 1800
@onready var max_speedX := 800 / scale[0]
@onready var max_speedY := 1000
@onready var acceleration := 2000 / scale[0]
@onready var player = get_tree().get_first_node_in_group("player")

var pushed_this_frame := false

func _ready() -> void:
	update_stats()

func push(velocity_x: float, delta: float) -> float:
	var start_x := global_position.x
	velocity.x = velocity_x
	move_and_collide(Vector2(velocity.x * delta, 0.0))
	pushed_this_frame = true
	return global_position.x - start_x

func update_stats() -> void:
	gravity = player.gravity
	max_speedX = player.base_max_speedX / scale[0]
	max_speedY = player.base_max_speedY
	acceleration = player.base_acceleration / scale[0]

func _physics_process(delta: float) -> void:
	update_stats()
	velocity.y = min(velocity.y + gravity * delta, max_speedY)
	if pushed_this_frame:
		# Don't move horizontally this frame because it was already done in push
		pushed_this_frame = false
		var velocity_x := velocity.x
		velocity.x = 0.0
		move_and_slide()
		velocity.x = velocity_x
	else:
		velocity.x = clamp(move_toward(velocity.x, 0.0, acceleration * delta), -max_speedX, max_speedX)
		move_and_slide()
