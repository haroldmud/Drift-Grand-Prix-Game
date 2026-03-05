extends MeshInstance3D

var angular_speed: float = 0.0
var local_center: Vector3
var player: RigidBody3D

func _ready() -> void:
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("TireMesh (%s): Could not find player in group 'player'!" % name)
		return
	
	var aabb: AABB = get_aabb()
	local_center = aabb.position + aabb.size * 0.5

func _physics_process(delta: float) -> void:
	if not player:
		return
		
	angular_speed = player.linear_velocity.length()
	var angle: float = angular_speed * delta
	var axis: Vector3 = global_transform.basis.x.normalized()
	var pivot_global: Vector3 = global_transform * local_center
	var rot: Basis = Basis(axis, angle)
	var gt: Transform3D = global_transform
	gt.basis = rot * gt.basis
	gt.origin = pivot_global + rot * (gt.origin - pivot_global)
	global_transform = gt
