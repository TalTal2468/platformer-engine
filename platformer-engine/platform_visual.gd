@tool
extends Node2D

@export var tile_texture: Texture2D
@export var tile_region := Rect2(0, 0, 32, 32)  # the one tile to repeat, in sheet pixels
@export var tile_size := 48.0                    # on-screen size of each tile
@export var base_size := 100.0                   # must match the hitbox size

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()  # keeps the editor preview in sync when you rescale a platform

func _draw() -> void:
	if tile_texture == null:
		return
	var s := global_scale
	var size := Vector2(base_size, base_size) * s.abs()
	# undo the platform's stretch so tiles draw at their true size
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / s.x, 1.0 / s.y))
	var origin := -size / 2.0
	var y := 0.0
	while y < size.y:
		var h := minf(tile_size, size.y - y)
		var x := 0.0
		while x < size.x:
			var w := minf(tile_size, size.x - x)
			var src := Rect2(tile_region.position, Vector2(tile_region.size.x * w / tile_size, tile_region.size.y * h / tile_size))
			draw_texture_rect_region(tile_texture, Rect2(origin + Vector2(x, y), Vector2(w, h)), src)
			x += tile_size
		y += tile_size
