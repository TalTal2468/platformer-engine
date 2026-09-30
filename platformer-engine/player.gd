class_name Player
extends CharacterBody2D

#PLEADE AKFJ REMOVE

#region OnReady
@onready var jump_particles = $"ParticleEffects/JumpParticles"
@onready var wall_slide_particles = $"ParticleEffects/WallSlideParticles"
@onready var dash_particles = $"ParticleEffects/DashParticles"
@onready var camera = $PlayerCamera
@onready var player_visuals = $PlayerVisuals

var phase_copy: Node2D = null
var default_child_y_positions := {}
var flash_tween: Tween = null
var death_tween: Tween = null

func get_hitbox_height() -> float:
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			var shape = child.shape
			if shape is RectangleShape2D: return shape.size.y
			elif shape is CapsuleShape2D: return shape.height
			elif shape is CircleShape2D: return shape.radius * 2.0
			elif shape is SeparationRayShape2D: return shape.length
	push_warning("CollisionShape2D not found or missing a Shape2D resource!")
	return 50.0

var hitbox_height: float
#endregion
#region Exports
@export_group("Core Settings")
@export var respawn_point: Marker2D
@export var can_move := true
@export var can_die := true
@export var base_zoom := 0.9

@export_group("Basic Movement")
@export var speed := 400
@export var gravity := 1800
@export var acceleration := 2000
@export var max_speedX := 800
@export var max_speedY := 1000

@export_group("Advanced Movement")
@export var starting_gravity_normal := true
@export var flip_camera_with_gravity := false
@export var ice_physics := false
@export var ice_acceleration := 800

@export_group("Jump Settings")
@export var jump_force := 800
@export var max_jumps := 2

@export_group("Wall Settings")
@export var wall_mechanics_enabled := true
@export_subgroup("Wall Slide")
@export var wall_slide_speed := 200
@export var max_wall_slide_time := 1.0
@export var limited_wall_slide := true
@export var no_jumps_slide := true
@export_subgroup("Wall Jump")
@export var wall_pushback := 400
@export var free_first_wall_jump := false
@export var allow_zig_zag := true
@export var inf_wall_jumps := false

@export_group("Dash Settings")
@export var can_dash := true
@export var dash_speed := 1000
@export var dash_duration := 0.1
@export var dash_cooldown := 0.5
@export var gravity_during_dash := false

@export_group("Visual Effects")
@export var particles := true
@export var phase_rotate := false
#endregion
#region Internal Variables
# Movement & Jump
var jumps: int = 0
var dash_direction := Vector2.ZERO
var last_key_pressed := ""

# Dash
var is_dashing := false
var can_dash_internal := true

# Wall Mechanics
var pushing_against_wall := false
var pushing_against_wall_only := false
var just_fell_off_wall := false
var just_wall_jumped := false
var corner_jump := false
var last_wall_normal: float = 0.0
var has_wall_jumped_since_ground := false

# Gravity & Rotation
var normal_gravity := true
var gravity_direction := 1.0
var toggling_gravity := false
var last_direction := 1.0
var target_rotation: float = 0.0
var is_rotating := false
var input_disabled_this_frame := false

# Timers & Buffers
var coyote_timer := 0.0
var max_coyote_time := 0.1
var wall_coyote_timer := 0.0
var max_wall_coyote_time := 0.15
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var wall_slide_timer := 0.0
var tap_timer := 0.0

# Death
var is_dead := false
var just_respawned := true
var has_flashed_red := false
var active_flash_box: ColorRect = null
#endregion
#region Memory Helpers
func cleanup_phase_copy() -> void:
	if is_instance_valid(phase_copy):
		phase_copy.queue_free()
	phase_copy = null

func cleanup_flash_box() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		flash_tween = null
	if is_instance_valid(active_flash_box):
		active_flash_box.queue_free()
	active_flash_box = null
#endregion
#region Engine Callbacks
func _ready() -> void:
	hitbox_height = get_hitbox_height()
	for child in get_children():
		default_child_y_positions[child] = child.position.y
	normal_gravity = starting_gravity_normal
	sync_gravity_state()
	if not starting_gravity_normal:
		global_position.y -= hitbox_height
	player_visuals.rotation = 0.0 if normal_gravity else PI
	camera.zoom = Vector2(base_zoom, base_zoom)

func _physics_process(delta: float) -> void:
	if is_dead or not can_move: return
	
	input_disabled_this_frame = false
	handle_rotation(delta)
	handle_timers(delta)
	
	if is_dashing:
		dash(delta)
		return
		
	var input_direction := 0.0
	if not input_disabled_this_frame:
		input_direction = Input.get_axis("left", "right")
		
	if flip_camera_with_gravity and not normal_gravity:
		input_direction *= -1
		
	var is_moving_into_wall: bool = sign(input_direction) == -sign(get_wall_normal().x) and input_direction != 0
	pushing_against_wall = is_on_wall() and is_moving_into_wall
	pushing_against_wall_only = is_on_wall_only() and is_moving_into_wall
	
	handle_ground_air_state(delta)
	handle_wall_logic(delta)
	handle_jump_input()
	handle_horizontal_movement(delta, input_direction)
	move_and_slide()
	
	if test_move(global_transform, Vector2.ZERO): 
		die()
	resize_camera()
	
	if Input.is_action_just_pressed("restart"): 
		die()

func handle_timers(delta: float) -> void:
	dash_cooldown_timer -= delta
	tap_timer -= delta
	wall_coyote_timer -= delta
	
	if not is_dashing and dash_cooldown_timer <= 0 and can_dash and not input_disabled_this_frame:
		if Input.is_action_just_pressed("right"): handle_tap("right")
		elif Input.is_action_just_pressed("left"): handle_tap("left")
#endregion
#region Core Movement
func handle_ground_air_state(delta: float) -> void:
	if just_respawned and not is_on_floor(): jumps = 0
	if is_on_floor() and pushing_against_wall and Input.is_action_pressed("jump"):
		corner_jump = true
	if (velocity.y * gravity_direction) > 0:
		corner_jump = false
		just_wall_jumped = false
		
	if is_on_floor():
		coyote_timer = max_coyote_time
		jumps = max_jumps - 1
		has_wall_jumped_since_ground = false
		just_fell_off_wall = false
		can_dash_internal = true
		wall_slide_timer = 0.0
		wall_coyote_timer = 0.0
		last_wall_normal = 0.0
	else:
		coyote_timer -= delta
		if (not pushing_against_wall_only or not wall_mechanics_enabled) or corner_jump:
			apply_gravity(delta)
		just_respawned = false

func handle_wall_logic(delta: float) -> void:
	var currently_sliding = false
	if not is_on_floor() and pushing_against_wall_only:
		wall_coyote_timer = max_wall_coyote_time
		
	if not is_on_floor() and (pushing_against_wall_only or wall_coyote_timer > 0) and wall_mechanics_enabled and not corner_jump:
		var is_falling = (velocity.y * gravity_direction) > 0
		if is_falling and (no_jumps_slide or jumps > 0) and (wall_slide_timer < max_wall_slide_time or not limited_wall_slide) and pushing_against_wall_only:
			currently_sliding = true
			wall_slide_timer += delta
			var slide_target = wall_slide_speed * gravity_direction
			velocity.y = move_toward(velocity.y, slide_target, 5000 * delta)
			wall_slide_particles.position.x = 15 if get_wall_normal().x < 0 else -15
		else:
			apply_gravity(delta)
			
		if Input.is_action_pressed("jump") and not just_wall_jumped and max_jumps > 1:
			var jump_direction = get_wall_normal().x 
			var is_zig_zag = jump_direction != last_wall_normal and last_wall_normal != 0 and allow_zig_zag
			var is_free_wall_jump = free_first_wall_jump and not has_wall_jumped_since_ground
			
			if (inf_wall_jumps or is_zig_zag or jumps > 0 or is_free_wall_jump) and (not limited_wall_slide or wall_slide_timer < max_wall_slide_time):
				velocity.x = jump_direction * wall_pushback
				velocity.y = -jump_force * gravity_direction
				just_wall_jumped = true
				has_wall_jumped_since_ground = true
				can_dash_internal = true
				last_wall_normal = jump_direction
				wall_coyote_timer = 0
				if particles:
					jump_particles.restart()
					jump_particles.emitting = true
				if not inf_wall_jumps and not is_zig_zag:
					jumps -= 1
					
	wall_slide_particles.emitting = currently_sliding and particles
	if not is_on_wall():
		wall_slide_timer = 0.0
	if is_on_floor():
		last_wall_normal = 0.0

func handle_jump_input() -> void:
	if Input.is_action_just_released("jump"):
		just_wall_jumped = false
		corner_jump = false
	if not is_on_floor() and pushing_against_wall and (velocity.y * gravity_direction) > 0:
		corner_jump = false
		
	if not just_respawned:
		if coyote_timer > 0 and Input.is_action_pressed("jump"):
			velocity.y = -jump_force * gravity_direction
			coyote_timer = 0
			can_dash_internal = true
		elif not is_on_floor() and ((not is_on_wall() or (not pushing_against_wall or (wall_slide_timer > max_wall_slide_time))) or not wall_mechanics_enabled) and Input.is_action_just_pressed("jump") and jumps > 0 and not just_wall_jumped and not corner_jump:
			velocity.y = -jump_force * gravity_direction 
			jumps -= 1
			can_dash_internal = true
			if particles:
				jump_particles.restart()
				jump_particles.emitting = true

func handle_horizontal_movement(delta: float, input_direction: float) -> void:
	var directionX = input_direction
	var local_acceleration = acceleration
	var target_speed = speed * directionX
	if ice_physics:
		local_acceleration = ice_acceleration
		target_speed += velocity.x
	velocity.x = clamp(move_toward(velocity.x, target_speed, local_acceleration * delta), -max_speedX, max_speedX)
#endregion
#region Gravity
func apply_gravity(delta: float) -> void:
	var gravity_step = gravity * delta * gravity_direction
	var max_fall = max_speedY * gravity_direction
	if normal_gravity:
		velocity.y = min(velocity.y + gravity_step, max_fall)
	else:
		velocity.y = max(velocity.y + gravity_step, max_fall)

func handle_rotation(delta: float) -> void:
	var directionX = Input.get_axis("left", "right")
	if directionX != 0:
		last_direction = sign(directionX)
		
	if Input.is_action_just_pressed("toggle gravity"):
		toggle_gravity()
		
	if toggling_gravity and not is_rotating:
		toggling_gravity = false
		normal_gravity = !normal_gravity
		sync_gravity_state()
		is_rotating = true
		input_disabled_this_frame = true
		tap_timer = 0
		last_key_pressed = ""
		
		cleanup_phase_copy()
		if phase_rotate:
			phase_copy = player_visuals.duplicate()
			add_child(phase_copy)
			phase_copy.position.y = player_visuals.position.y
			
		if Input.is_action_pressed("left"):
			Input.action_release("left")
			Input.action_press("left")
		if Input.is_action_pressed("right"):
			Input.action_release("right")
			Input.action_press("right")
			
		if not normal_gravity:
			target_rotation = player_visuals.rotation + (PI if last_direction < 0 else -PI)
		else:
			target_rotation = player_visuals.rotation + (-PI if last_direction < 0 else PI)

	if is_rotating:
		player_visuals.rotation = lerp(player_visuals.rotation, target_rotation, 15.0 * delta)
		if phase_rotate and phase_copy:
			var flicker = Engine.get_frames_drawn() % 2 == 0
			player_visuals.visible = flicker
			phase_copy.visible = !flicker
			phase_copy.scale = player_visuals.scale
			phase_copy.rotation = target_rotation + angle_difference(player_visuals.rotation, target_rotation)
			
		if abs(player_visuals.rotation - target_rotation) < 0.01:
			player_visuals.rotation = wrapf(target_rotation, -PI, PI)
			is_rotating = false
			player_visuals.visible = true
			cleanup_phase_copy()

	var facing_direction = last_direction
	if not flip_camera_with_gravity and not normal_gravity:
		facing_direction *= -1
	player_visuals.scale.x = facing_direction

func toggle_gravity(type: String = "") -> void:
	if not ((type == "normal" and normal_gravity) or (type == "inverted" and not normal_gravity)):
		toggling_gravity = true

func sync_gravity_state() -> void:
	gravity_direction = 1.0 if normal_gravity else -1.0
	up_direction = Vector2.UP if normal_gravity else Vector2.DOWN
	jump_particles.gravity.y = abs(jump_particles.gravity.y) * gravity_direction
	if not just_respawned and not is_dead:
		if normal_gravity: global_position.y += hitbox_height
		else: global_position.y -= hitbox_height
	if normal_gravity: set_children_y_offset(1)
	else: set_children_y_offset(-1)

func set_children_y_offset(direction: int) -> void:
	for child in get_children():
		if child == $TestRect or child == active_flash_box:
			continue
		if default_child_y_positions.has(child):
			var default_y: float = default_child_y_positions[child]
			child.position.y = default_y if direction == 1 else default_y + hitbox_height
		elif child == phase_copy and is_instance_valid(phase_copy):
			phase_copy.position.y = player_visuals.position.y
#endregion
#region Dash Mechanics
func dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = dash_direction.x * dash_speed
	
	if gravity_during_dash:
		apply_gravity(delta)
	else:
		if normal_gravity:
			if velocity.y > 0: velocity.y = 0
		else:
			if velocity.y < 0: velocity.y = 0
			
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer > 0 or jumps > 0:
			velocity.y = -jump_force * gravity_direction
			if not is_on_floor() and coyote_timer <= 0:
				jumps -= 1
			coyote_timer = 0
			just_wall_jumped = true
			is_dashing = false
			can_dash_internal = true
			stop_dash_effect(0.2)
			if particles:
				jump_particles.restart()
				jump_particles.emitting = true
				
	if dash_timer <= 0:
		is_dashing = false
		velocity.x = clamp(velocity.x, -max_speedX, max_speedX)
		stop_dash_effect(0.2)
		
	move_and_slide()

func start_dash(direction: float) -> void:
	is_dashing = true
	dash_particles.direction.x = -direction
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = Vector2(direction, 0)
	tap_timer = 0
	can_dash_internal = false
	if particles:
		dash_particles.restart()
		dash_particles.emitting = true

func stop_dash_effect(delay: float) -> void:
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	dash_particles.emitting = false

func handle_tap(key: String) -> void:
	if last_key_pressed == key and tap_timer > 0 and can_dash_internal:
		var direction = 1.0 if key == "right" else -1.0
		if flip_camera_with_gravity and not normal_gravity:
			direction *= -1
		start_dash(direction)
	else:
		last_key_pressed = key
		tap_timer = 0.2
#endregion
#region Camera
func resize_camera() -> void:
	var delta = get_process_delta_time()
	var target_zoom_vector = Vector2(base_zoom, base_zoom)
	camera.zoom = camera.zoom.lerp(target_zoom_vector, 5.0 * delta)
	if flip_camera_with_gravity:
		camera.rotation = lerp_angle(camera.rotation, player_visuals.rotation, 10.0 * delta)
	else:
		camera.rotation = lerp_angle(camera.rotation, 0.0, 10.0 * delta)
#endregion
#region Player Health & Respawn
func die() -> void:
	if is_dead or not can_die: return
	if not has_flashed_red:
		flash_red()
		return
		
	is_dead = true
	
	if death_tween and death_tween.is_valid():
		death_tween.kill()
		
	death_tween = create_tween()
	death_tween.tween_property(self, "modulate:a", 0, 0.4)
	death_tween.chain().tween_callback(func():
		just_respawned = true
		reset_player()
		if is_instance_valid(respawn_point):
			global_position = respawn_point.global_position
			if not starting_gravity_normal:
				global_position.y -= hitbox_height
		else:
			push_warning("Respawn point is missing or invalid")
			global_position = Vector2.ZERO
	)
	death_tween.chain().set_parallel(true)
	death_tween.tween_property(self, "modulate:a", 1, 0.6)
	death_tween.chain().tween_callback(func():
		is_dead = false
		has_flashed_red = false
	)

func flash_red() -> void:
	cleanup_flash_box()
	has_flashed_red = true
	var was_able_to_move = can_move
	freeze_player()
	
	var collision_node: CollisionShape2D = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_node = child
			break
			
	var hitbox_size := Vector2(50, 50)
	if collision_node and collision_node.shape:
		var shape = collision_node.shape
		if shape is RectangleShape2D:
			hitbox_size = shape.size
		elif shape is CapsuleShape2D:
			hitbox_size = Vector2(shape.radius * 2.0, shape.height)
			
	var red_box := ColorRect.new()
	active_flash_box = red_box
	
	var local_offset = collision_node.position if collision_node else Vector2.ZERO
	red_box.color = Color(1.0, 0.0, 0.0, 0.5)
	red_box.size = hitbox_size
	red_box.position = local_offset - red_box.size / 2.0
	red_box.pivot_offset = red_box.size / 2.0
	red_box.rotation = player_visuals.rotation
	add_child(red_box)
	
	flash_tween = create_tween()
	flash_tween.tween_property(red_box, "modulate:a", 1.0, 0.15)
	flash_tween.tween_property(red_box, "modulate:a", 0.0, 0.15)
	flash_tween.tween_callback(func():
		cleanup_flash_box()
		can_move = was_able_to_move
		die()
	)

func freeze_player() -> void:
	can_move = false
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0
	dash_particles.emitting = false
	jump_particles.emitting = false
	wall_slide_particles.emitting = false
	is_rotating = false
	player_visuals.visible = true
	
	cleanup_flash_box()
	cleanup_phase_copy()

func reset_player() -> void:
	jumps = 0
	coyote_timer = 0
	wall_coyote_timer = 0
	just_wall_jumped = false
	has_wall_jumped_since_ground = false
	tap_timer = 0
	last_key_pressed = ""
	dash_cooldown_timer = 0
	normal_gravity = starting_gravity_normal
	target_rotation = 0.0 if normal_gravity else PI
	up_direction = Vector2.UP if normal_gravity else Vector2.DOWN
	cleanup_phase_copy()
	if is_equal_approx(target_rotation, abs(player_visuals.rotation)):
		player_visuals.rotation = abs(player_visuals.rotation)
	else:
		if phase_rotate:
			phase_copy = player_visuals.duplicate()
			add_child(phase_copy)
			phase_copy.position.y = player_visuals.position.y
		is_rotating = true
	sync_gravity_state()
	resize_camera()
#endregion
