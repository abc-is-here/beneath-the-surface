extends WorldEnvironment

@onready var thunder_player = $"../AudioStreamPlayer"
var flash_timer = 0.0

func _process(delta):
	if randf() < 0.005: # Small chance to strike every frame
		trigger_lightning()

func trigger_lightning():
	# 1. Visual Flash
	var tween = create_tween()
	var mat = environment.sky.sky_material
	# Flash on instantly, then fade out
	mat.set_shader_parameter("lightning_flash", 1.0)
	tween.tween_property(mat, "shader_parameter/lightning_flash", 0.0, 0.4)
	
	# 2. Sound Effect
	# Optional: Add a small delay for distant thunder (light travels faster than sound!)
	await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
	thunder_player.pitch_scale = randf_range(0.8, 1.2) # Vary pitch for realism
	thunder_player.play()
