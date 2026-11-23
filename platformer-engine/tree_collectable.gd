
extends Node2D

signal tree_felled(wood_count: int)
signal tutorial_prompt_changed(message: String, visible: bool)

@export var show_tutorial_prompt := true
@export var fall_duration := 1.0
@export var fade_duration := 1.0

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

	print("TREE READY: ", name)
	print("Interaction Area monitoring: ", interaction_area.monitoring)


func _process(_delta: float) -> void:
	if player_in_range == null:
		return

	if is_falling or is_felled:
		return

	if Input.is_action_just_pressed("interact"):
		fell_tree()


func _on_body_entered(body: Node2D) -> void:
	print("BODY ENTERED: ", body.name)
	print("Is player group: ", body.is_in_group("player"))

	if not body.is_in_group("player"):
		return

	if is_felled:
		return

	player_in_range = body as CharacterBody2D

	if player_in_range == null:
		print("ERROR: Player is not a CharacterBody2D")
		return

	print("PLAYER DETECTED")

	if show_tutorial_prompt:
		print("EMITTING PROMPT SIGNAL")
		tutorial_prompt_changed.emit("Press F to fell the tree", true)


func _on_body_exited(body: Node2D) -> void:
	if body != player_in_range:
		return

	player_in_range = null
	print("PLAYER LEFT TREE")

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

	var direction := 1.0

	if player_in_range.global_position.x > global_position.x:
		direction = -1.0

	var fall_tween := create_tween()
	fall_tween.set_trans(Tween.TRANS_CUBIC)
	fall_tween.set_ease(Tween.EASE_IN)

	fall_tween.tween_property(
		fall_pivot,
		"rotation",
		direction * PI / 2.0,
		fall_duration
	)

	await fall_tween.finished

	is_falling = false
	is_felled = true

	interaction_area.set_deferred("monitoring", false)

	for block in fall_pivot.get_children():
		var shapes := block.find_children("*", "CollisionShape2D", true, false)

		for shape in shapes:
			shape.set_deferred("disabled", true)

	var fade_tween := create_tween()
	fade_tween.tween_property(
		fall_pivot,
		"modulate:a",
		0.0,
		fade_duration
	)

	await fade_tween.finished

	tree_felled.emit(wood_count)
