extends AnimatableBody2D

@export var open_offset := Vector2(0, -300)   # how far it slides when open
@export var open_time := 0.4
@export var plates: Array[NodePath] = []     # drag plates in via the Inspector

var _closed_pos: Vector2
var _tween: Tween
var _pressed_count := 0

func _ready():
	_closed_pos = position
	for p in plates:
		var plate = get_node(p)
		plate.pressed.connect(_on_pressed)
		plate.released.connect(_on_released)

func _on_pressed():
	_pressed_count += 1
	_update()

func _on_released():
	_pressed_count -= 1
	_update()

func _update():
	# door opens only when ALL linked plates are active
	var open := _pressed_count >= plates.size()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", _closed_pos + (open_offset if open else Vector2.ZERO), open_time)
