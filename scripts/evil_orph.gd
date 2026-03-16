extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay

@export var patrol_points: Array[Node3D] = []
@export var speed_walk := 1.0
@export var speed_run := 1.5
@export var attack_range := 2.0
@export var investigate_wait_time := 4.0
@export var patrol_wait_time := 3.0

enum State { IDLE, PATROL, INVESTIGATE, CHASE, RETURN }
var state: State = State.IDLE

var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0

var investigate_position: Vector3
var return_position: Vector3

var target: Node3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --------------------
# READY
# --------------------

func _ready():
	target = get_tree().get_first_node_in_group("player")

	if patrol_points.size() > 0:
		agent.set_target_position(patrol_points[0].global_position)

	_enter_state(State.IDLE if patrol_points.is_empty() else State.PATROL)

# --------------------
# MAIN LOOP
# --------------------

func _physics_process(delta):

	match state:

		State.IDLE:
			if _can_see_player():
				_enter_state(State.CHASE)

		State.PATROL:
			_state_patrol(delta)

		State.INVESTIGATE:
			_state_investigate(delta)

		State.CHASE:
			_state_chase()

		State.RETURN:
			_state_return()

	_apply_gravity(delta)
	move_and_slide()

# --------------------
# PATROL
# --------------------

func _state_patrol(delta):

	if anim.current_animation != "crawl":
		anim.play("crawl")

	if agent.is_navigation_finished():

		patrol_timer -= delta

		if patrol_timer <= 0:
			patrol_timer = patrol_wait_time
			_go_to_next_patrol()

	else:
		var next_pos = agent.get_next_path_position()
		_move_to(next_pos, speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

# --------------------
# INVESTIGATE
# --------------------

func _state_investigate(delta):

	if anim.current_animation != "crawl":
		anim.play("crawl")

	if agent.is_navigation_finished():

		investigate_timer -= delta

		if investigate_timer <= 0:
			_enter_state(State.RETURN)

	else:
		_move_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

# --------------------
# CHASE
# --------------------

func _state_chase():

	if not target:
		_enter_state(State.RETURN)
		return

	if anim.current_animation != "run":
		anim.play("run")

	agent.set_target_position(target.global_position)

	_move_to(agent.get_next_path_position(), speed_run)

	if global_position.distance_to(target.global_position) < attack_range:
		_trigger_jumpscare()

	if not _can_see_player():
		investigate_position = target.global_position
		_enter_state(State.INVESTIGATE)

# --------------------
# RETURN
# --------------------

func _state_return():

	if anim.current_animation != "crawl":
		anim.play("crawl")

	if agent.is_navigation_finished():
		_enter_state(State.PATROL)

	else:
		_move_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

# --------------------
# STATE SWITCH
# --------------------

func _enter_state(new_state: State):

	state = new_state

	match state:

		State.IDLE:
			anim.play("scream")

		State.PATROL:
			patrol_timer = patrol_wait_time

		State.INVESTIGATE:
			investigate_timer = investigate_wait_time
			agent.set_target_position(investigate_position)

		State.RETURN:
			agent.set_target_position(return_position)

		State.CHASE:
			return_position = global_position

# --------------------
# MOVEMENT
# --------------------

func _move_to(pos: Vector3, speed: float):

	var dir = pos - global_position
	dir.y = 0

	if dir.length() < 0.2:
		velocity.x = 0
		velocity.z = 0
		return

	dir = dir.normalized()

	look_at(global_position + dir, Vector3.UP)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

# --------------------
# PATROL POINTS
# --------------------

func _go_to_next_patrol():

	if patrol_points.is_empty():
		return

	patrol_index += 1

	if patrol_index >= patrol_points.size():
		patrol_index = 0

	var point = patrol_points[patrol_index]

	agent.set_target_position(point.global_position)

# --------------------
# GRAVITY
# --------------------

func _apply_gravity(delta):

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

# --------------------
# VISION
# --------------------

func _can_see_player():

	if not target:
		return false

	if not vision_ray.is_colliding():
		return false

	var collider = vision_ray.get_collider()

	if collider == target:
		return true

	if collider.get_parent() == target:
		return true

	if collider.is_in_group("player"):
		return true

	return false

# --------------------
# JUMPSCARE
# --------------------

func _trigger_jumpscare():

	velocity = Vector3.ZERO
	set_physics_process(false)

	get_tree().get_first_node_in_group("player").trigger_jumpscare()

# --------------------
# SOUND
# --------------------

func hear_noise(pos: Vector3):

	if state != State.CHASE:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)

# --------------------
# CUTSCENE HELPER
# --------------------

func play_scream():
	anim.play("scream")
	await anim.animation_finished
