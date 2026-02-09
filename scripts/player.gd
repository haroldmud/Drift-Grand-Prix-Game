extends RigidBody3D

@export var engine_force := 40.0
@export var steering_speed := 1.5
@export var max_speed := 25.0
@onready var plane :MeshInstance3D = $"../Plane"
@onready var car_mesh :MeshInstance3D = $PlayerMesh
var max_tilt := deg_to_rad(30) # max 30 degrees


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().physics_frame # makes sure the physics to fully update first before firing anything else like the position, etc.
	global_position.y = plane.global_position.y + 0.2 # 0.2 Godot unit or meters

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var plane_mesh := plane.mesh as PlaneMesh
	if plane_mesh == null:
		return

	# --- Plane bounds (WITH scale)
	var plane_center: Vector3 = plane.global_transform.origin
	var scale: Vector3 = plane.global_transform.basis.get_scale()
	var plane_half_width: float = plane_mesh.size.x * 0.5 * scale.x
	var plane_half_depth: float = plane_mesh.size.y * 0.5 * scale.z
	
		# --- Steering (physics-safe rotation)
	var turn_amount := 0.0
	var forward_backward_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var tilt_angle = -steer_input * max_tilt  # negative for left/right tilt

# Smooth tilt for nicer effect
	car_mesh.rotation.x = lerp(car_mesh.rotation.y, tilt_angle, 0.1)

	if forward_backward_input > 0.0:
		turn_amount = -steer_input * steering_speed * state.step
	elif forward_backward_input < 0.0:
		turn_amount = steer_input * steering_speed * state.step

	state.transform.basis = state.transform.basis.rotated(Vector3.UP, turn_amount) # increases the rotation angle the more the speed increases

	# --- Engine force with max speed check
	var forward_direction := state.transform.basis.x
	var current_speed := state.linear_velocity.dot(forward_direction) # speed along forward

	# Apply force only if below max speed
	if abs(current_speed) < max_speed:
		apply_central_force(forward_direction * forward_backward_input * engine_force)

	# --- Clamp AFTER forces
	var pos: Vector3 = state.transform.origin

	var min_x := plane_center.x - plane_half_width + 1 # This 1(can be anything depending on your result) represents the remaining half size of the car that's overlapping
	var max_x := plane_center.x + plane_half_width - 1
	var min_z := plane_center.z - plane_half_depth + 1
	var max_z := plane_center.z + plane_half_depth - 1

	var hit_x := pos.x < min_x or pos.x > max_x
	var hit_z := pos.z < min_z or pos.z > max_z

	pos.x = clamp(pos.x, min_x, max_x)
	pos.z = clamp(pos.z, min_z, max_z)
	state.transform.origin = pos

	# --- Kill velocity at edges
	if hit_x:
		state.linear_velocity.x = 0.0
	if hit_z:
		state.linear_velocity.z = 0.0

# MAKE THE HIDDEN MOUSE VISIBLE
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
