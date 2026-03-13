extends Node3D

var open = false
var openable = true

@export var anim_player: AnimationPlayer
@export var key_req: bool
@export var req_key_name: String

func _ready() -> void:
	$Label.visible = false

func work(inventory):

	if not openable:
		return

	if key_req:
		var key_index := -1
		
		for i in range(inventory.size()):
			if inventory[i]["name"] == req_key_name:
				key_index = i
				break
		
		if key_index == -1:
			$Label.text = "You need the " + req_key_name + "."
			$Label.visible = true
			await get_tree().create_timer(1.0).timeout
			$Label.visible = false
			return
		
		inventory.remove_at(key_index)
		key_req = false

	openable = false
	open = !open

	if open:
		anim_player.play("door_open")
	else:
		anim_player.play("door_close")

	await get_tree().create_timer(0.7).timeout
	openable = true
