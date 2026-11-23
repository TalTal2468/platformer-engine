
extends Node2D

@export var block_scene: PackedScene
@export var player_path: NodePath = ^"../Player"
@export var grid_size := 32
@export var building_range := 160.0

var player: CharacterBody2D
var preview: Node2D

var build_mode := false
var placement_position := Vector2.ZERO
var can_place := false

var warning_layer: CanvasLayer
var warning_label: Label
var warning_timer: Timer


func _ready() -> void:
	player = get_node_or_null(player_path) as CharacterBody2D

	if player == null:
		push_error("BridgeBuilder: Could not find Player.")
		return

	if block_scene == null:
		push_error("BridgeBuilder: Assign tree.tscn to Block Scene.")
		return

	setup_warning()

	preview = block_scene.instantiate() as Node2D

	if preview == null:
		push_error("BridgeBuilder: Block scene root must be a Node2D.")
		return

	add_child(preview)

	preview.modulate = Color(0.5, 1.0, 0.5, 0.45)
	disable_collisions(preview)
	preview.visible = false


func setup_warning() -> void:
	warning_layer = CanvasLayer.new()
	warning_layer.name = "BuildingWarnings"
	warning_layer.layer = 20

	# Add to this node rather than the scene root.
	add_child(warning_layer)

	warning_label = Label.new()
	warning_label.name = "NoWoodWarning"
	warning_label.text = "NOT ENOUGH ALIEN WOOD"

	warning_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	warning_label.position = Vector2(-190, -100)
	warning_label.size = Vector2(380, 45)

	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	warning_label.add_theme_font_size_override("font_size", 20)
	warning_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.35, 0.28)
	)
	warning_label.add_theme_color_override(
		"font_outline_color",
		Color(0.08, 0.04, 0.04)
	)
	warning_label.add_theme_constant_override("outline_size", 5)

	warning_layer.add_child(warning_label)
	warning_label.hide()

	warning_timer = Timer.new()
	warning_timer.one_shot = true
	warning_timer.wait_time = 1.8

	add_child(warning_timer)

	warning_timer.timeout.connect(_on_warning_timeout)


func _on_warning_timeout() -> void:
	if is_instance_valid(warning_label):
		warning_label.hide()


func show_no_wood_warning() -> void:
	warning_label.show()
	warning_timer.start()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			set_build_mode(not build_mode)
			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_ESCAPE and build_mode:
			set_build_mode(false)
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and build_mode:
				place_block()
				get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not build_mode:
		return

	if not is_instance_valid(player) or not is_instance_valid(preview):
		return

	update_preview()


func set_build_mode(enabled: bool) -> void:
	if preview == null:
		return

	build_mode = enabled
	preview.visible = enabled

	if enabled:
		print("Building mode enabled")
	else:
		print("Building mode disabled")


func update_preview() -> void:
	var mouse_position := get_global_mouse_position()

	placement_position = Vector2(
		round(mouse_position.x / grid_size) * grid_size,
		round(mouse_position.y / grid_size) * grid_size
	)

	preview.global_position = placement_position

	can_place = is_valid_position(placement_position)

	if can_place:
		preview.modulate = Color(0.5, 1.0, 0.5, 0.45)
	else:
		preview.modulate = Color(1.0, 0.4, 0.4, 0.45)


func is_valid_position(target: Vector2) -> bool:
	if not is_instance_valid(player):
		return false

	if player.global_position.distance_to(target) > building_range:
		return false

	var query := PhysicsPointQueryParameters2D.new()
	query.position = target
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [player.get_rid()]

	var space_state := get_world_2d().direct_space_state
	var results := space_state.intersect_point(query, 32)

	for result in results:
		var collider = result.get("collider")

		if collider == null:
			continue

		if collider is Node and collider.is_in_group("player"):
			continue

		return false

	return true


func place_block() -> void:
	if not can_place:
		return

	if not GameState.spend_wood(1):
		show_no_wood_warning()
		return

	var new_block := block_scene.instantiate() as Node2D

	if new_block == null:
		GameState.add_wood(1)
		push_error("BridgeBuilder: Could not instantiate block.")
		return

	get_tree().current_scene.add_child(new_block)
	new_block.global_position = placement_position

	print("Bridge block placed. Wood remaining: ", GameState.wood_count)


func disable_collisions(node: Node) -> void:
	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0

	if node is Area2D:
		node.monitoring = false
		node.monitorable = false

	for child in node.get_children():
		disable_collisions(child)
