extends StaticBody3D

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

var open = false
var openable = true

func work():

	if not openable:
		return

	openable = false
	open = !open

	if open:
		anim_player.play("open_cabinet")
	else:
		anim_player.play("close_cabinet")

	await get_tree().create_timer(0.7).timeout
	openable = true
