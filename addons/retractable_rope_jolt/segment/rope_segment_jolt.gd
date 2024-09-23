extends RigidBody3D
## This is a segment of a rope composed of multiple segmentes joined by Jolt pin joints
class_name RopeSegmentJolt

const DEBUG = false

@export var _rope_radius = .1
@export var _segment_length = .5

var _next_segment : PhysicsBody3D ## Next segment on the chain. Can be null
var _prev_segment : PhysicsBody3D ## Previous segment on the chain. Can be null

@onready var _collider : CollisionShape3D = $CollisionShape3D
@onready var _debug_mesh : MeshInstance3D= $MeshInstance3D
@onready var joint : JoltConeTwistJoint3D = $JoltConeTwistJoint3D

func _get_segment_position() -> Vector3:
	return Vector3(0,-_segment_length/2,0)

func _get_end_position() -> Vector3:
	return Vector3(0,-_segment_length,0)

## Sets up the rope segment.
func initialize(radius: float, length: float, coll_layer: int ,coll_mask: int, prev_link: PhysicsBody3D = null ):
	
	_rope_radius = radius
	_segment_length = length
	if prev_link:
		_prev_segment = prev_link
	
	collision_mask = coll_mask
	collision_layer = coll_layer

func set_weight(weight:float):
	mass = weight

## Adds a new link at the end of the rope
func attach_next_segment(segment : PhysicsBody3D, keep_pos : bool = false):
	
	var old_basis = segment.global_basis
		
	segment.global_position = joint.global_position
	segment.global_rotation = global_rotation
	joint.node_b = segment.get_path()
	joint.enabled = true
	
	if keep_pos:
		segment.global_basis = old_basis
	
	_next_segment = segment
	
func set_prev_segment(segment : PhysicsBody3D):
	_prev_segment = segment

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var shape := _collider.shape
	shape.radius = _rope_radius
	shape.height = _segment_length + _rope_radius * 2

	var mesh_shape = _debug_mesh.mesh
	mesh_shape.radius = _rope_radius
	mesh_shape.height = _segment_length + _rope_radius * 2

	_collider.position = _get_segment_position()
	_debug_mesh.position = _get_segment_position()
	joint.position = _get_end_position()
	
	_debug_mesh.visible = DEBUG
