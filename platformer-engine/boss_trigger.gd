extends Area2D
## Put this on an Area2D (with a CollisionShape2D) in a level.
## Touching it starts the Wits Duel. Disappears once the duel is won.

@export_file("*.tscn") var duel_scene := "res://wits_duel.tscn"
@export var duel_id := "guardian_1"

func _ready() -> void:
	if GameState.solved.get(duel_id, false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		get_tree().change_scene_to_file.call_deferred(duel_scene)
