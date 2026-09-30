extends Path2D
@export var line_color := Color.DIM_GRAY
var line_width: float = 6.0
var circle_radius: float = 8.0
var scaleX : float
var scaleY : float
var loop : bool
var one_shot : bool

func _ready() -> void:
	# Force the node to redraw if the curve changes at runtime
	z_index = RenderingServer.CANVAS_ITEM_Z_MIN
	if curve:
		curve.changed.connect(queue_redraw)

func _draw() -> void:
	var points = curve.get_baked_points()
	if points.size() < 2 or one_shot: return
	
	var scaled_points : PackedVector2Array
	for point in points:
		scaled_points.append(point * Vector2(scaleX, scaleY))
	
	var start_point = points[0]
	var end_point = points[-1]
	var scaled_end_point = end_point * Vector2(1.0 / scaleX - 1, 1.0 / scaleY - 1)
	var inverse_scale = Vector2(1.0 / scaleX, 1.0 / scaleY)
	
	draw_set_transform(Vector2.ZERO, 0.0, inverse_scale)
	draw_polyline(scaled_points, line_color, line_width, true)
	if loop:
		var inner_circle_radius = circle_radius
		draw_circle(start_point, inner_circle_radius, line_color)
		draw_set_transform(Vector2.ZERO - scaled_end_point, 0.0, inverse_scale)
		draw_circle(end_point, inner_circle_radius, line_color)
