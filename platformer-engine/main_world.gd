
extends Node2D

@onready var tree_collectable: Node2D = $TreeCollectable
@onready var player: Node2D = $Player
@onready var tutorial_ui: CanvasLayer = $TutorialUI
@onready var tree_prompt: Label = $TutorialUI/TreePrompt

var wood_panel: PanelContainer
var wood_label: Label

var current_wood_amount: int = 0


func _ready() -> void:
	tutorial_ui.layer = 10

	setup_tutorial_prompt()
	setup_wood_hud()

	tree_collectable.tutorial_prompt_changed.connect(
		_on_tutorial_prompt_changed
	)

	tree_collectable.tree_felled.connect(
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
	wood_panel = PanelContainer.new()
	wood_panel.name = "AlienWoodCounter"
	wood_panel.position = Vector2(24, 24)
	wood_panel.custom_minimum_size = Vector2(160, 46)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.09, 0.075, 0.94)
	panel_style.border_color = Color(0.35, 0.55, 0.40, 0.9)

	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(9)

	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6

	wood_panel.add_theme_stylebox_override("panel", panel_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "ALIEN WOOD"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override(
		"font_color",
		Color(0.65, 0.82, 0.62)
	)

	wood_label = Label.new()
	wood_label.add_theme_font_size_override("font_size", 22)
	wood_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.94, 0.85)
	)

	row.add_child(title)
	row.add_child(wood_label)

	wood_panel.add_child(row)
	tutorial_ui.add_child(wood_panel)

	wood_panel.pivot_offset = Vector2(80, 23)


func _on_tree_felled(amount: int) -> void:
	GameState.add_wood(amount)


func _on_wood_changed(new_amount: int) -> void:
	if not is_instance_valid(wood_label):
		return

	var increased := new_amount > current_wood_amount

	current_wood_amount = new_amount
	wood_label.text = str(new_amount)

	if increased:
		animate_wood_counter()


func animate_wood_counter() -> void:
	var tween := create_tween()

	tween.tween_property(
		wood_panel,
		"scale",
		Vector2(1.12, 1.12),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		wood_panel,
		"scale",
		Vector2.ONE,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
