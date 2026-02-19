extends MeshInstance3D

var health := 6
@onready var collision_sound: = $AudioStreamPlayer3D

func _ready() -> void:
	get_tree().call_group("ui", "set_health", health)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if health > 0:
		health -= 1
		get_tree().call_group("ui", "set_health", health)
	elif health <= 0:
		Global.is_game_over = true
	
	if body is RigidBody3D:
		body.linear_velocity = Vector3.ZERO
		body.global_position = body.global_position - body.transform.basis.x * 5
		if not collision_sound.playing:
			collision_sound.play()
		else:
			collision_sound.stop()
