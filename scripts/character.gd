extends CharacterBody3D

# --- Movement ---
@export var speed = 1.5
@export var acceleration = 6.0
@export var air_acceleration = 2.0
@export var friction = 10.0
@export var air_friction = 0.5

# --- Sprint ---
@export var sprint_multiplier = 1.8
@export var sprint_bob_multiplier = 1.6
@export var sprint_fov = 80.0
@export var normal_fov = 75.0

# --- Stamina ---
@export var max_stamina = 5.0
@export var stamina_drain_rate = 1.2
@export var stamina_regen_rate = 0.8
@export var stamina_regen_delay = 1.0

var stamina = max_stamina
var stamina_regen_timer = 0.0
var breath_intensity = 0.0

# --- Head Bob ---
@export var head_bob_amount = 0.06
@export var head_bob_speed = 8.0
var head_bob_time = 0.0
var head_origin_position: Vector3

# --- Head Breathing ---
@export var head_breath_amount = 0.02
@export var head_breath_speed = 1.2
var head_breath_time = 0.0

# --- Hand Sway ---
@export var hand_sway_amount = 0.02
@export var hand_tilt_amount = 2.0
var hands_origin_position: Vector3
var hands_origin_rotation: Vector3

# --- Hand Idle Breathing ---
@export var breath_amount = 0.008
@export var breath_speed = 1.5
var breath_time = 0.0

# --- Mouse ---
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Node Refs ---
@export var head: Node3D
@export var camera: Camera3D
@export var hands_pivot: Node3D
@export var hands_mesh: Node3D

@onready var flashlight_anim: AnimationPlayer = $head/flashlight_anim
@onready var wall_check: RayCast3D = $head/WallCheck
@onready var stamina_bar = $StaminaBar

var hands_default_z: float
var flashlight_on = true

# --- Inventory stuff ---
var inventory = []
var selected_item = 0
@onready var interaction_check: RayCast3D = $head/Camera3D/InteractionCheck
@onready var inventory_ui: Control = $InventoryUI


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flashlight_anim.stop()

	head_origin_position = head.position
	hands_origin_position = hands_pivot.position
	hands_origin_rotation = hands_pivot.rotation
	hands_default_z = hands_pivot.position.z

	stamina_bar.value = 100


func _process(_delta):
	stamina_bar.value = (stamina / max_stamina) * 100.0


func _unhandled_input(event):

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))

	if Input.is_action_just_pressed("cursor_toggle"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	# --- Inventory ---
	if event.is_action_pressed("inventory") and event.is_pressed():
		if inventory_ui.visible:
			inventory_ui.visible = false
		else:
			inventory_ui.open_inventory(inventory)

func _physics_process(delta):
	# --- Inventory ---
	if inventory_ui.visible:
		return
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
	
	if Input.is_action_just_pressed("interact"):
		if interaction_check.is_colliding():
			var collider = interaction_check.get_collider()
				
			if collider and collider.is_in_group("pickup_item"):
				pickup_item(collider)
			if collider.is_in_group("interact_items"):
				collider.get_parent().get_parent().work(inventory)
	
	
	# --- Input ---
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# --- Sprint & Stamina ---
	var wants_to_sprint = Input.is_action_pressed("sprint") and is_on_floor() and direction.length() > 0
	var is_sprinting = false

	var current_speed = speed
	var current_bob_speed = head_bob_speed
	var current_bob_amount = head_bob_amount

	if wants_to_sprint and stamina > 0.0:
		is_sprinting = true
		current_speed *= sprint_multiplier
		current_bob_speed *= sprint_bob_multiplier
		current_bob_amount *= 1.2
		
		camera.fov = lerp(camera.fov, sprint_fov, 6.0 * delta)

		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0.0)
		stamina_regen_timer = 0.0
	else:
		camera.fov = lerp(camera.fov, normal_fov, 6.0 * delta)

		stamina_regen_timer += delta
		if stamina_regen_timer >= stamina_regen_delay:
			stamina += stamina_regen_rate * delta
			stamina = min(stamina, max_stamina)

	# --- Breathing Intensity ---
	var exhaustion = 1.0 - (stamina / max_stamina)
	if is_sprinting:
		breath_intensity = 1.0
	else:
		breath_intensity = move_toward(breath_intensity, exhaustion, delta * 1.5)

	# --- Movement ---
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if is_on_floor():
		if direction.length() > 0:
			horizontal_velocity = horizontal_velocity.move_toward(direction * current_speed, acceleration * delta)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(direction * current_speed, air_acceleration * delta)

	horizontal_velocity = horizontal_velocity.limit_length(current_speed)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	var horizontal_speed = horizontal_velocity.length()

	# --- Head Bob, Breathing ---
	if is_on_floor() and horizontal_speed > 0.1:
		head_bob_time += delta * current_bob_speed
		var bob_offset = sin(head_bob_time) * current_bob_amount
		head.position.y = head_origin_position.y + bob_offset
		head.rotation.z = lerp(head.rotation.z, 0.0, 8.0 * delta)
		head_breath_time = 0.0
	else:
		head.position.y = lerp(head.position.y, head_origin_position.y, 6.0 * delta)

		var dynamic_speed = head_breath_speed * (1.0 + breath_intensity * 2.5)
		var dynamic_amount = head_breath_amount * (1.0 + breath_intensity * 3.0)

		head_breath_time += delta * dynamic_speed

		var breath_offset = sin(head_breath_time) * dynamic_amount
		head.position.y = head_origin_position.y + breath_offset

		head.position.z = head_origin_position.z + sin(head_breath_time) * 0.03 * breath_intensity

		var exhale_drop = abs(sin(head_breath_time)) * 0.02 * breath_intensity
		head.position.y -= exhale_drop

		head.rotation.z = deg_to_rad(sin(head_breath_time * 0.5) * 2.0 * breath_intensity)

	# --- Hand Movement ---
	var target_position = hands_origin_position
	var target_rotation = hands_origin_rotation

	if is_on_floor() and horizontal_speed > 0.1:
		var sway_x = cos(head_bob_time) * hand_sway_amount
		var sway_y = sin(head_bob_time) * (hand_sway_amount * 0.5)

		target_position.x += sway_x
		target_position.y += sway_y
		target_rotation.z = deg_to_rad(cos(head_bob_time) * hand_tilt_amount)
	else:
		breath_time += delta * breath_speed
		target_position.y += sin(breath_time) * breath_amount

	# --- Wall Push ---
	if wall_check.is_colliding():
		var distance = wall_check.get_collision_point().distance_to(wall_check.global_position)
		var max_distance = wall_check.target_position.length()
		var push_amount = clamp((max_distance - distance) / max_distance, 0.0, 1.0)
		target_position.z += push_amount * 0.9

	hands_pivot.position = hands_pivot.position.lerp(target_position, 10.0 * delta)
	hands_pivot.rotation = hands_pivot.rotation.lerp(target_rotation, 10.0 * delta)

	move_and_slide()

# --- Pick Up and add stuff to inventory ---
func pickup_item(item):

	inventory.append({
		"name": item.item_name,
		"description": item.description,
		"scene": item.item_scene
	})

	item.queue_free()
