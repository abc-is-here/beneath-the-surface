extends StaticBody3D

@export var req_item_name : String = "Wire"

@export var shake_strength = 0.03
@export var shake_speed = 25.0

var shaking = false
var original_position : Vector3
var shake_time = 0.0


func _ready():
	$wire.visible = false
	$wire2.visible = true
	original_position = position


func use_item(item):

	if item["name"] == req_item_name:
		work()
		return true
	else:
		$Label.visible = true
		await get_tree().create_timer(1.0).timeout
		$Label.visible = false
		return false


func work():
	$wire.visible = true
	$wire2.visible = false
	$start_particles.emitting = true
	Global.generator_on = true
	start_generator()

func start_generator():
	shaking = true


func _process(delta):

	if shaking:
		shake_time += delta * shake_speed

		var offset = Vector3(sin(shake_time) * shake_strength,cos(shake_time * 1.2) * shake_strength,sin(shake_time * 0.7) * shake_strength)


		position = original_position + offset
