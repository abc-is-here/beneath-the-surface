extends CharacterBody3D

# --- Movement Variables ---
@export var speed = 1.5
@export var acceleration = 6.0
@export var air_acceleration = 2.0
@export var friction = 10.0
@export var air_friction = 0.5

# --- Head Bob ---
@export var head_bob_amount = 0.06
@export var head_bob_speed = 8.0

var head_bob_time = 0.0
var head_origin_position: Vector3

# --- Head Idle Breathing ---
@export var head_breath_amount = 0.03
@export var head_breath_speed = 1.2

var head_breath_time = 0.0

# --- Hand Sway ---
@export var hand_sway_amount = 0.02
@export var hand_sway_speed = 8.0
@export var hand_tilt_amount = 2.0

var hands_origin_position: Vector3
var hands_origin_rotation: Vector3

# --- Idle Breathing ---
@export var breath_amount = 0.008
@export var breath_speed = 1.5

var breath_time = 0.0

# --- Mouse Look ---
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Node Refs ---
@export var head: Node3D
@export var camera: Camera3D
@export var hands_pivot: Node3D
@export var hands_mesh: Node3D

# --- Animations ---
var flashlight_on = true
@onready var flashlight_anim: AnimationPlayer = $head/flashlight_anim


func _ready():
	flashlight_anim.stop()
	head_origin_position = head.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hands_origin_position = hands_pivot.position
	hands_origin_rotation = hands_pivot.rotation


func _unhandled_input(event):

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))

	if Input.is_action_just_pressed("cursor_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):

	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# --- Flashlight ---
	if Input.is_action_just_pressed("flashlight") and not flashlight_anim.is_playing():
		if flashlight_on:
			flashlight_anim.play("stop_flash")
		else:
			flashlight_anim.play("use_flash")
		flashlight_on = !flashlight_on

	# --- Movement ---
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if is_on_floor():
		if direction.length() > 0:
			horizontal_velocity = horizontal_velocity.move_toward(direction * speed, acceleration * delta)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(direction * speed, air_acceleration * delta)

	horizontal_velocity = horizontal_velocity.limit_length(speed)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	# --- Head Bob, Breathing ---
	var horizontal_speed = horizontal_velocity.length()

	if is_on_floor() and horizontal_speed > 0.1:
		head_bob_time += delta * head_bob_speed
		var bob_offset = sin(head_bob_time) * head_bob_amount
		head.position.y = head_origin_position.y + bob_offset
		head_breath_time = 0.0
	else:
		head.position.y = lerp(head.position.y, head_origin_position.y, 6.0 * delta)
		head_breath_time += delta * head_breath_speed
		var breath_offset = sin(head_breath_time) * head_breath_amount
		head.position.y = head_origin_position.y + breath_offset

	# --- Hand Movement ---
	if is_on_floor() and horizontal_speed > 0.1:
		var sway_x = cos(head_bob_time) * hand_sway_amount
		var sway_y = sin(head_bob_time) * (hand_sway_amount * 0.5)

		hands_pivot.position.x = hands_origin_position.x + sway_x
		hands_pivot.position.y = hands_origin_position.y + sway_y
		hands_pivot.rotation.z = deg_to_rad(cos(head_bob_time) * hand_tilt_amount)

	else:
		breath_time += delta * breath_speed
		var breath_offset = sin(breath_time) * breath_amount

		hands_pivot.position.x = lerp(hands_pivot.position.x, hands_origin_position.x, 6.0 * delta)
		hands_pivot.position.y = hands_origin_position.y + breath_offset
		hands_pivot.rotation = hands_pivot.rotation.lerp(hands_origin_rotation, 6.0 * delta)

	move_and_slide()
