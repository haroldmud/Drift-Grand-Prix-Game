extends RigidBody3D

@export var engine_force := 40.0
@export var steering_speed := 1.5
@export var max_speed := 50.0

@export var min_volume_db := -20.0  #  Idle volume (quieter)
@export var max_volume_db := -10.0
@export var volume_transition_speed := 5.0  # ← How fast volume changes

@export var friction := 0.01  # (higher = slower deceleration, takes longer to stop)
@export var max_steer_angle := 20.0
@onready var plane :MeshInstance3D = $"../Plane"
@onready var car_mesh :MeshInstance3D = $PlayerMesh
@onready var cam1: Camera3D = $TwistPivot/PitchPivot/Camera1
@onready var cam2: Camera3D = $TwistPivot/PitchPivot/Camera2
@onready var front_tire_left_pivot = $PlayerMesh/FrontTireLeftPivot
@onready var front_tire_right_pivot = $PlayerMesh/FrontTireRightPivot
@onready var engine_audio := $EngineAudio

var steer_angle := 0.0
var current_volume := -20.0
#@onready var tire := $TireMesh1
#var tire_speed := 10.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().physics_frame
	global_position.y = plane.global_position.y + 0.2
	engine_audio.stream.loop = true
	engine_audio.volume_db = min_volume_db
	current_volume = min_volume_db
	engine_audio.play()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		if cam1.is_current():
			cam2.make_current()
		else :
			cam1.make_current()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if Global.is_game_won:
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		return
		
	#front_tire_right_pivot.rotation.y = -steer_angle * 0.2
	#front_tire_left_pivot.rotation.y = -steer_angle * 0.2
	#print(steer_angle)

	var plane_mesh := plane.mesh as PlaneMesh
	if plane_mesh == null:
		return

# Inputs
	var forward_backward_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")

			# --- TIRE STEERING ---
	var target_steer := steer_input * deg_to_rad(max_steer_angle)
	steer_angle = lerp(steer_angle, target_steer, state.step * 10.0)
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


	var target_volume := min_volume_db
	if Input.is_action_pressed("move_forward"):
		target_volume = max_volume_db
	
	current_volume = lerp(current_volume, target_volume, state.step * volume_transition_speed)
	engine_audio.volume_db = current_volume

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
