
extends Node2D

signal tree_felled(wood_count: int)
signal tutorial_prompt_changed(message: String, visible: bool)

@export var show_tutorial_prompt := true
@export var fall_duration := 0.85
@export var fade_duration := 0.8

@onready var fall_pivot: Node2D = $FallPivot
@onready var interaction_area: Area2D = $Interaction_Area

var player_in_range: CharacterBody2D = null
var is_falling := false
var is_felled := false
var wood_count := 0


func _ready() -> void:
	wood_count = fall_pivot.get_child_count()

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range == null:
		return

	if is_falling or is_felled:
		return

	if Input.is_action_just_pressed("interact"):
		fell_tree()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if is_felled:
		return

	player_in_range = body as CharacterBody2D

	if player_in_range == null:
		return

	if show_tutorial_prompt:
		tutorial_prompt_changed.emit(
			"Press F to fell the tree",
			true
		)


func _on_body_exited(body: Node2D) -> void:
	if body != player_in_range:
		return

	player_in_range = null

	if show_tutorial_prompt and not is_felled:
		tutorial_prompt_changed.emit("", false)


func fell_tree() -> void:
	if is_falling or is_felled:
		return

	if not is_instance_valid(player_in_range):
		return

	is_falling = true

	if show_tutorial_prompt:
		tutorial_prompt_changed.emit("", false)

	# Determine which direction the tree should fall.
	var direction := 1.0

	if player_in_range.global_position.x > global_position.x:
		direction = -1.0

	var final_rotation := direction * PI / 2.0

	# --------------------------------------------------
	# 1. ANTICIPATION
	# The tree leans backwards before beginning to fall.
	# --------------------------------------------------

	var fall_tween := create_tween()

	fall_tween.tween_property(
		fall_pivot,
		"rotation",
		-direction * 0.035,
		0.09
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Small forward movement before the main fall.
	fall_tween.tween_property(
		fall_pivot,
		"rotation",
		direction * 0.025,
		0.08
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# --------------------------------------------------
	# 2. WEIGHTED FALL
	# Accelerates as the tree falls.
	# --------------------------------------------------

	fall_tween.tween_property(
		fall_pivot,
		"rotation",
		final_rotation + direction * 0.07,
		fall_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# --------------------------------------------------
	# 3. IMPACT AND SETTLING
	# Slightly overshoots, then settles into position.
	# --------------------------------------------------

	fall_tween.tween_property(
		fall_pivot,
		"rotation",
		final_rotation,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await fall_tween.finished

	is_falling = false
	is_felled = true

	# Disable interaction after the tree has fallen.
	interaction_area.set_deferred("monitoring", false)

	# Disable all physical collisions belonging to the tree blocks.
	for block in fall_pivot.get_children():
		var shapes := block.find_children(
			"*",
			"CollisionShape2D",
			true,
			false
		)

		for shape in shapes:
			shape.set_deferred("disabled", true)

	# --------------------------------------------------
	# 4. IMPACT PAUSE AND DISAPPEARANCE
	# --------------------------------------------------

	await get_tree().create_timer(0.2).timeout

	var fade_tween := create_tween()

	fade_tween.tween_property(
		fall_pivot,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await fade_tween.finished

	# Award wood after the complete animation.
	tree_felled.emit(wood_count)
