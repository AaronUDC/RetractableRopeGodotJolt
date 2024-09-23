@tool
extends RigidBody3D
class_name Agujero

@export  var joint: JoltGeneric6DOFJoint3D
@export var target_body: RigidBody3D

@export var max_angle : float = 90.0
@export var min_angle : float = 5.0
@export var max_distance : float = 1.0

var max_angle_rad : float :
	get:
		return deg_to_rad(max_angle)
	set(value):
		max_angle = rad_to_deg(value)

var min_angle_rad : float :
	get:
		return deg_to_rad(min_angle)
	set(value):
		min_angle = rad_to_deg(value)

@export var current_angle : float

func _update_limits():
	
	var percent_out = clampf(target_body.global_position.distance_to(joint.global_position)/max_distance,0.0,1.0)
	current_angle = lerp(min_angle_rad,max_angle_rad, percent_out)
	
	joint.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, current_angle)
	joint.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, -current_angle)
	
	joint.set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, current_angle)
	joint.set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, -current_angle)

func set_distance(distance:float):
	joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT,distance)

func detach_segment():
	joint.node_b = ""
	target_body = null 

func attach_segment(segment: RigidBody3D, distance:float):
	var path = segment.get_path()
	var old_rotation = segment.global_rotation
	segment.global_position = joint.global_position
	segment.global_rotation = -joint.global_rotation
	joint.node_b = path
	
	segment.global_position = joint.position + distance * joint.global_basis.y
	segment.global_rotation = old_rotation
	set_distance(distance)
	target_body = segment
	
func _ready():
	if joint.node_b:
		target_body = joint.get_node(joint.node_b)

func _physics_process(delta):
	
	if target_body:
		_update_limits()
	
