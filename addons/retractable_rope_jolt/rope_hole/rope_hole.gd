@tool
extends JoltGeneric6DOFJoint3D
## Simulation of a hole from wich a rope, made with a chain of segments, is comming from using a [JoltGeneric6DOFJoint3D]. 
##
## This makes a rope attached to it act like it is pulled inside a hole, by closing the angle
## limits of the joint as the segment is moved inside the hole.
class_name RopeHole

## The PhysicsBody3D attached to the first segment
@onready @export var parent_body: PhysicsBody3D :
	get: return get_node_or_null(node_a)
	set(value):
		node_a = get_path_to(value) if value else ""


@export var attached_body: RigidBody3D ## The segment of rope that is attached to the hole


## Maximun depth at witch a segment can be inside the hole. (Take the lenght of [member attached_body] 
## for best results) It should be greater than 0.
@export_range(0.0, 5,0.01, "or_greater","suffix:m") var hole_depth : float  = .5:
	get: return hole_depth
	set(value):
		hole_depth = value
		set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, value)
		update_gizmos()
		
## The radius of the hole. It will affect how the joint angle of aperture will change in 
## relation to how much is the segment inside
@export_range(0.0, 1,0.01, "or_greater","suffix:m") var hole_radius : float = 0.1:
	get: return hole_radius
	set(value):
		hole_radius = value
		update_gizmos()

#region Old angle based system

# Old parameters
### Maximun angle of aperture (in degrees) of the joint when the [member attached_body] 
### is at the origin of the joint.
#@export_range(0.0,180.0,0.5,"suffix:º") var max_angle : float = 90.0 
### [member max_angle] in radians 
#var max_angle_rad : float :
	#get:
		#return deg_to_rad(max_angle)
	#set(value):
		#max_angle = rad_to_deg(value)
#
### Minimun angle of aperture (in degrees) of the joint when the [member attached_body] is at the
### [member hole_depth]
#@export_range(0.0,180.0,0.5,"suffix:º") var min_angle : float = 5.0
#
### [member min_angle] in radians
#var min_angle_rad : float :
	#get:
		#return deg_to_rad(min_angle)
	#set(value):
		#min_angle = rad_to_deg(value)

#endregion

## If the angle apperture of the hole will update with [method Node._physics_process]
@export var self_updating : bool = true

## If the [member attached_body] is free to move inside the hole (If true, set self_updating to true 
## for best results). When false, the segment can be moved through the hole using [method set_distance].
@export var free_movement : bool = false:
	get: return free_movement
	set(value):
		set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, value)

## Updates the angle limits of the joint according to the distance of the [member attached_body]
func _update_limits():
	var distance_inside:float
	if free_movement:
		#Calculate the distance.
		distance_inside = attached_body.global_position.distance_to(global_position)
	else:
		#Use target distance
		distance_inside = get_param_y(PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT)
	#Makes the hole a bit more closed the more it's inside
	var angle_limit = atan2(hole_radius,distance_inside) - (atan2(hole_radius,hole_depth)/2) 
	
	set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angle_limit)
	set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, -angle_limit)
	
	set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angle_limit)
	set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, -angle_limit)

## Sets the [param distance] of the segment from the origin of the joint.
## The value will be clamped between 0 and [member hole_depth]
func set_distance(distance:float):
	#print(distance)
	distance = clampf(distance,0.0,hole_depth)
	#print(distance)
	set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT,distance)

## Frees the segment from the joint. The segment won't be deleted, just detached.
func detach_segment():
	node_b = ""
	attached_body = null 

## Attaches a [param segment] at a given [param distance] from the joint.
func attach_segment(segment: RigidBody3D, distance:float):
	var path = segment.get_path()
	var old_basis = segment.global_basis
	#Place the segment in the rest position
	segment.global_position = global_position
	segment.global_rotation = global_rotation
	segment.linear_velocity = Vector3.ZERO
	segment.angular_velocity = Vector3.ZERO
	#Attach the segment to the joint
	node_b = path
	attached_body = segment
	
	#Return the segment to its old position.
	segment.global_basis = old_basis
	
	#Update the target distance
	set_distance(distance)

func _physics_process(delta):
	if self_updating and attached_body:
		_update_limits()
		
