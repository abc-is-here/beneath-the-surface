extends Node3D

var count = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.generator_on and count!=1:
		$AnimationPlayer.play("cage_up")
		count+=1


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/win.tscn")
