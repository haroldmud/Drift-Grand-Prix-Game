extends MeshInstance3D

var health := 6
@onready var collision_sound := $BumpSound

func _ready() -> void:
	get_tree().call_group("ui", "set_health", health)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if health > 0:
		health -= 1
		get_tree().call_group("ui", "set_health", health)
	elif health <= 0:
		Global.is_game_over = true

	if body is RigidBody3D:
		# Get the car's current velocity direction
		var car_velocity = body.linear_velocity
		var car_forward = -body.transform.basis.x  # Car's forward direction
		
		# Check if car is moving forward or backward
		var is_moving_forward = car_velocity.dot(car_forward) > 0
		
		# Calculate bounce force
		var bounce_strength = 25.0
		var bounce_direction: Vector3
		
		if is_moving_forward:
			# Hit from front - bounce backward
			bounce_direction = -car_forward
		else:
			# Hit from back - bounce forward
			bounce_direction = car_forward
		
		# Apply bounce
		body.linear_velocity = bounce_direction * bounce_strength
		
		# Disable player control temporarily
		if body.has_method("disable_controls"):
			body.disable_controls(1)  # Disable for 0.5 seconds
		
		# Play sound
		if not collision_sound.playing:
			collision_sound.play()
		else:
			collision_sound.stop()
			collision_sound.play()
