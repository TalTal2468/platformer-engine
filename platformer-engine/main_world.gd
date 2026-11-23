
extends Node2D

@onready var tree_collectable: Node2D = $TreeCollectable
@onready var player: Node2D = $Player
@onready var tutorial_ui: CanvasLayer = $TutorialUI
@onready var tree_prompt: Label = $TutorialUI/TreePrompt

var wood_label: Label


func _ready() -> void:
	tutorial_ui.layer = 10

	setup_tutorial_prompt()
	setup_wood_hud()

	tree_collectable.connect(
		"tutorial_prompt_changed",
		_on_tutorial_prompt_changed
	)

	tree_collectable.connect(
		"tree_felled",
		_on_tree_felled
	)

	GameState.wood_changed.connect(_on_wood_changed)

	_on_wood_changed(GameState.wood_count)


func setup_tutorial_prompt() -> void:
	tree_prompt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tree_prompt.size = Vector2(220, 36)

	tree_prompt.add_theme_font_size_override("font_size", 16)
	tree_prompt.add_theme_color_override("font_color", Color.WHITE)
	tree_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	tree_prompt.add_theme_constant_override("outline_size", 4)

	tree_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	tree_prompt.hide()


func setup_wood_hud() -> void:
	var panel := PanelContainer.new()

	panel.name = "WoodCounter"
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(160, 48)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.09, 0.075, 0.92)
	panel_style.border_color = Color(0.35, 0.55, 0.40, 0.9)

	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)

	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8

	panel.add_theme_stylebox_override("panel", panel_style)

	wood_label = Label.new()
	wood_label.name = "WoodLabel"
	wood_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wood_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	wood_label.add_theme_font_size_override("font_size", 20)
	wood_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.94, 0.85)
	)

	panel.add_child(wood_label)
	tutorial_ui.add_child(panel)


func _on_tree_felled(amount: int) -> void:
	GameState.add_wood(amount)


func _on_wood_changed(new_amount: int) -> void:
	if is_instance_valid(wood_label):
		wood_label.text = "WOOD   " + str(new_amount)


func _on_tutorial_prompt_changed(
	message: String,
	should_be_visible: bool
) -> void:
	tree_prompt.text = message

	if should_be_visible:
		position_tree_prompt()
		tree_prompt.show()
	else:
		tree_prompt.hide()


func position_tree_prompt() -> void:
	var tree_screen_position: Vector2 = (
		get_viewport().get_canvas_transform()
		* tree_collectable.global_position
	)

	var player_is_right: bool = (
		player.global_position.x > tree_collectable.global_position.x
	)

	if player_is_right:
		tree_prompt.position = tree_screen_position + Vector2(-240, -55)
	else:
		tree_prompt.position = tree_screen_position + Vector2(50, -55)
