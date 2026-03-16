extends Node3D

@export var open_distance := 0.7
@export var speed := 4.0

var closed_position : Vector3
var open_position : Vector3
var is_open := false
var moving := false

func _ready():
	closed_position = position
	open_position = position + transform.basis.z * open_distance

func _process(delta):
	var target
	if moving:
		if is_open:
			target = open_position
		else:
			target = closed_position
		position = position.lerp(target, speed * delta)

		if position.distance_to(target) < 0.01:
			position = target
			moving = false

func interact():
	is_open = !is_open
	moving = true
