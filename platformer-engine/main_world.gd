
extends Node2D

@onready var tree_collectable: Node2D = $TreeCollectable
@onready var player: Node2D = $Player
@onready var tutorial_ui: CanvasLayer = $TutorialUI
@onready var tree_prompt: Label = $TutorialUI/TreePrompt


func _ready() -> void:
	tutorial_ui.layer = 10

	tree_prompt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tree_prompt.size = Vector2(220, 36)

	tree_prompt.add_theme_font_size_override("font_size", 16)
	tree_prompt.add_theme_color_override("font_color", Color.WHITE)
	tree_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	tree_prompt.add_theme_constant_override("outline_size", 4)

	tree_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	tree_prompt.hide()

	tree_collectable.tutorial_prompt_changed.connect(
		_on_tutorial_prompt_changed
	)


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
