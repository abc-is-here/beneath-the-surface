extends Control

var items = []
var index = 0

@onready var item_pivot: Node3D = $SubViewportContainer/SubViewport/ItemViewer/ItemPivot

func _ready() -> void:
	visible = false

func _process(delta):

	if visible:
		item_pivot.rotate_y(0.3 * delta)

func show_item():

	if items.size() == 0:
		return

	index = clamp(index, 0, items.size() - 1)

	for child in item_pivot.get_children():
		child.queue_free()

	var item = items[index]

	var model = item["scene"].instantiate()
	item_pivot.add_child(model)

# --- Please spare my life, I am using AI for these functions. I did not know how this worked but now I do! ---
	center_model(model)
	scale_model(model)

# --------------------------------

	$ItemName.text = item["name"]
	$ItemDesc.text = item["description"]
	$empty.visible = false

func _input(event):
	if items.size() == 0:
		return

	if Input.is_action_just_pressed("left"):
		index = (index - 1 + items.size()) % items.size()
		show_item()

	if Input.is_action_just_pressed("right"):
		index = (index + 1) % items.size()
		show_item()

func center_model(model):

	var meshes = model.find_children("*", "MeshInstance3D", true, false)

	if meshes.size() == 0:
		return

	var combined_aabb = meshes[0].get_aabb()

	for mesh in meshes:
		combined_aabb = combined_aabb.merge(mesh.get_aabb())

	var center = combined_aabb.position + combined_aabb.size / 2
	model.position -= center

func scale_model(model):

	var meshes = model.find_children("*", "MeshInstance3D", true, false)

	if meshes.size() == 0:
		return

	var combined_aabb = meshes[0].get_aabb()

	for mesh in meshes:
		combined_aabb = combined_aabb.merge(mesh.get_aabb())

	var max_size = max(combined_aabb.size.x, combined_aabb.size.y, combined_aabb.size.z)

	var target_size = 1.2
	var scale_factor = target_size / max_size

	model.scale = Vector3.ONE * scale_factor

func open_inventory(new_items):

	items = new_items
	index = 0
	show_item()
	visible = true
