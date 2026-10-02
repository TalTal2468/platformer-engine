extends Node2D

@onready var pathFollow: PathFollow2D = $PlatformPath/PlatformPathFollow
@export var speed = 1.0
@export var loop := true
@export var one_shot := false
@export var show_path := true
var time_passed: float = 0.0

func _ready():
	$PlatformPath.loop = loop
	$PlatformPath.one_shot = one_shot
	$PlatformPath.scaleX = scale.x
	$PlatformPath.scaleY = scale.y
	$PlatformPath.show_path = show_path
	if pathFollow:
		pathFollow.loop = not one_shot

func _physics_process(delta: float) -> void:
	if (not pathFollow) or (pathFollow.get_parent() is Path2D and pathFollow.get_parent().curve.get_baked_length() == 0):
		return
	pathFollow.global_rotation = 0
	if loop and not one_shot:
		time_passed += delta
		pathFollow.progress_ratio = (sin(speed * time_passed) + 1) / 2
	else:
		if not one_shot or pathFollow.progress_ratio < 1.0:
			pathFollow.progress_ratio += speed * delta
		if one_shot:
			pathFollow.progress_ratio = clamp(pathFollow.progress_ratio, 0, 1)
