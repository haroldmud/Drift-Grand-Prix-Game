extends RigidBody3D

@export var engine_force := 40.0
@export var steering_speed := 1.5
@export var max_speed := 50.0
@export var friction := 0.01  # ← ADD THIS (higher = slower deceleration, takes longer to stop)
@onready var plane :MeshInstance3D = $"../Plane"
@onready var car_mesh :MeshInstance3D = $PlayerMesh

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().physics_frame
	global_position.y = plane.global_position.y + 0.2

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if Global.is_game_won:
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		return

	var plane_mesh := plane.mesh as PlaneMesh
	if plane_mesh == null:
		return

# Inputs
	var forward_backward_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")

# Smooth tilt for nicer effect
	var max_tilt := deg_to_rad(2)
	var tilt_angle := -steer_input * max_tilt
	car_mesh.rotation.y = lerp(car_mesh.rotation.y, tilt_angle, 0.1)
	car_mesh.rotation.x = lerp(car_mesh.rotation.x, tilt_angle, 0.1)

# --- Steering (allow while coasting; reverse at backward speed; pivot when stopped)
	var forward_dir := state.transform.basis.x
	var speed_along_forward := state.linear_velocity.dot(forward_dir)
	var turn_amount := 0.0

	if abs(steer_input) > 0.0001:
		if abs(speed_along_forward) > 0.1:
		# Reverse steering when moving backward, like a real car
			var dir_sign := -1.0  if (speed_along_forward >= 0.0) else 1.0
			turn_amount = steer_input * steering_speed * dir_sign * state.step
		else:
		# Pivot in place when nearly stopped (tank-like, adjust factor to taste)
			var pivot_factor := 0.5
			turn_amount = steer_input * steering_speed * pivot_factor * state.step

	state.transform.basis = state.transform.basis.rotated(Vector3.UP, turn_amount)

# --- Engine force with max speed check
	if abs(speed_along_forward) < max_speed:
		apply_central_force(forward_dir * forward_backward_input * engine_force)

# --- Drag/friction so it coasts and slows down progressively
# Higher friction = faster deceleration (stops sooner)
	var friction_force := -state.linear_velocity * friction
	apply_central_force(friction_force)

# --- Bounds, clamping and edge velocity kill (unchanged)
	var plane_center: Vector3 = plane.global_transform.origin
	var scale: Vector3 = plane.global_transform.basis.get_scale()
	var plane_half_width: float = plane_mesh.size.x * 0.5 * scale.x
	var plane_half_depth: float = plane_mesh.size.y * 0.5 * scale.z

	var pos: Vector3 = state.transform.origin
	var min_x := plane_center.x - plane_half_width + 1
	var max_x := plane_center.x + plane_half_width - 1
	var min_z := plane_center.z - plane_half_depth + 1
	var max_z := plane_center.z + plane_half_depth - 1

	var hit_x := pos.x < min_x or pos.x > max_x
	var hit_z := pos.z < min_z or pos.z > max_z

	pos.x = clamp(pos.x, min_x, max_x)
	pos.z = clamp(pos.z, min_z, max_z)
	state.transform.origin = pos

	if hit_x:
		state.linear_velocity.x = 0.0
	if hit_z:
		state.linear_velocity.z = 0.0

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
