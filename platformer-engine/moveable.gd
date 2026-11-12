extends CharacterBody2D

@export var mass := 1.0
@export var acceleration := 2500.0   # was 900, gets up to speed much faster
@export var push_multiplier := 1.8   # overall speed boost (the old 1.3 was dropped earlier)
@export var start_speed := 80.0      # instant speed when a push begins (divided by chain mass)
@export var friction := 1400.0
var gravity := 1800.0

var push_dir := 0.0
var push_speed := 0.0
var last_driven_frame := -10
var _chain_blocked := false

# called by the player, same signature as before
func push(direction, speed):
	push_dir = sign(direction.x)
	push_speed = speed

func _physics_process(delta):
	var frame := Engine.get_physics_frames()

	# a box behind us is driving this one, so skip our own movement
	if frame - last_driven_frame <= 1:
		push_dir = 0.0
		return

	if push_dir != 0.0:
		var chain := _get_chain(push_dir)
		var total_mass := 0.0
		for b in chain:
			total_mass += b.mass

		var target := 0.0 if _chain_blocked else push_dir * push_speed * push_multiplier / total_mass

		# starting kick: jump straight to a decent speed instead of ramping from zero
		var kick := minf(start_speed / total_mass, absf(target))
		if velocity.x * push_dir < kick:
			velocity.x = push_dir * kick

		velocity.x = move_toward(velocity.x, target, (acceleration / total_mass) * delta)

		# move the front box first so nothing is blocked by the box ahead of it
		for i in range(chain.size() - 1, -1, -1):
			chain[i]._drive(velocity.x, delta, chain[i] != self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		_drive(velocity.x, delta, false)

	push_dir = 0.0

# moves this box at the given speed (used by the head of the chain)
func _drive(vx: float, delta: float, mark_driven: bool):
	if mark_driven:
		last_driven_frame = Engine.get_physics_frames()
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = vx
	move_and_slide()

# walks forward through touching boxes, returns [self, next, next, ...]
func _get_chain(dir: float) -> Array:
	var chain: Array = [self]
	_chain_blocked = false
	var current = self

	while true:
		var hit := KinematicCollision2D.new()
		if not current.test_move(current.global_transform, Vector2(dir * 2.0, 0.0), hit):
			break
		if abs(hit.get_normal().x) < 0.5:
			break  # floor or ceiling, not something in our way
		var other = hit.get_collider()
		if other.has_method("_drive") and not chain.has(other):
			chain.append(other)
			current = other
		else:
			_chain_blocked = true  # wall, player, or anything solid
			break

	return chain
