class_name Pushable
extends CharacterBody2D

@export var reset_on_player_death := true
@export var scale_weight := 0.75
# Controls how hard box is to push when comparing its scale to Player scale
	# 0.0 -> box moves at player speed; 1.0 -> double the box scale, half the push speed

@onready var gravity := 1800
@onready var max_speedX := 800 / get_effective_scale()
@onready var max_speedY := 1000
@onready var acceleration := 2000 / get_effective_scale()
@onready var player = get_tree().get_first_node_in_group("player")

var player_dying := false
var pushed_this_frame := false

func _ready() -> void:
	$BoxSpawnPoint.global_position = global_position
	update_stats()
	if reset_on_player_death:
		player.player_death.connect(on_player_death)
		player.player_respawned.connect(turn_on_movement)

func _physics_process(delta: float) -> void:
	if player_dying: return
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

func get_effective_scale() -> float:
	return sqrt(abs(scale.x * scale.y))

func on_player_death() -> void:
	player_dying = true
	reset_box()

func reset_box() -> void:
	velocity = Vector2.ZERO
	global_position = $BoxSpawnPoint.global_position
	pushed_this_frame = false

func turn_on_movement() -> void:
	player_dying = false

func push(velocity_x: float, delta: float) -> float:
	var start_x := global_position.x
	velocity.x = velocity_x
	move_and_collide(Vector2(velocity.x * delta, 0.0))
	pushed_this_frame = true
	return global_position.x - start_x

func update_stats() -> void:
	gravity = player.gravity
	max_speedX = player.base_max_speedX / get_effective_scale()
	max_speedY = player.base_max_speedY
	acceleration = player.base_acceleration / get_effective_scale()
