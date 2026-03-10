extends Area3D

@export var item_name : String
@export var description : String
@export var item_scene : PackedScene

@onready var mesh_holder: Node3D = $MeshHolder

func _ready():
	if item_scene:
		var model = item_scene.instantiate()
		mesh_holder.add_child(model)
