extends Node3D
class_name RopeController

## This signal is emmited when the rope is completely retracted.
signal retracted_rope
## This signal is emmited when the rope has reached a target length provided in the 
## [method add_rope] method. 
signal extended_rope

const _SEGMENT = preload("segment/rope_segment_jolt.tscn")

# Part references
@onready var _hole :  = $Hole
@onready var _mesh : RopeMesher = $Mesh
@onready var _segment_container = $Segments
 
#region Inspector parameters
# Parameters that control the physical properties of the rope.
@export_group("Rope parameters", "rope") 
## Total weight of the rope outside the hole. The total weight is divided between the segments,
## making the total weight the same regardless of the lenght.
@export_range(0.01, 10, 0.01, "or_greater","suffix:kg") var rope_weight : float = 1
## Length of each segment that forms the rope
@onready @export_range(0.01, 1, 0.01, "or_greater","suffix:m") var rope_segment_length : float = .5 : 
	get: return rope_segment_length
	set(value):
		rope_segment_length = value
		$Hole.hole_depth = value

## Radius of the hole the rope is comming from.
@onready @export_range(0.01, 1,0.01, "or_greater","suffix:m") var rope_hole_radius : float = .1: 
	get: return rope_hole_radius
	set(value):
		rope_hole_radius = value
		$Hole.hole_radius = value

## Radius of the rope
@export_range(0.01, .5, 0.01, "or_greater","suffix:m") var rope_radius : float = .1

## Total initial length of the rope
@export_range(0.01, 20, 0.01, "or_greater","suffix:m") var rope_initial_length : float = 10

@export_subgroup("Segment collisions")
@export_flags_3d_physics var layer : int ##Physics layer for the rope collisions
@export_flags_3d_physics var mask : int ##Physics mask for the rope collisions

#Parameters that control the visuals of the rope. 
#They won't have an effect on the behaviour of the rope
@export_group("Visuals", "rope")
## How rounded the rope mesh will be interpolated between segments. 
## A stiffness of 1 means that there is no interpolation.
@export_range(0, 1, 0.01) var rope_stiffness : float = 0
## Ammount of subdivisions the rope mesh will have between segments.
## Incrementing this will lower the performance.
@export_range(1, 10, 1, "or_greater") var rope_segment_resolution : int = 3
## Ammount of subdivisions a section of the rope will have.
## Incrementing this will greatly lower the performance.
@export_range(2, 12, 1, "or_greater") var rope_section_resolution : int = 6
## The material assigned to the rope mesh
@export var rope_material : Material

## [PhysicsBody3D] attached to the origin of the rope.
@export var _rope_start : PhysicsBody3D :
	get: return _rope_start
	set(value): 
		_rope_start = value

## [PhysicsBody3D] attached to the end of the rope. [br]
## - If set, the starting line of rope will be
## placed between the starting and ending points, whith the lenght of [member rope_initial_length]. [br]
## - If not set, the rope will be placed stretched in the direction of the hole.
@onready @export var _rope_end : PhysicsBody3D

#endregion

## Current length of the rope
var _rope_length : float

## Stack that stores the segments of the rope, the top of the stack is the segment closer to the hole.
var _segment_stack : Array[RopeSegmentJolt] = []

## First segment of the rope that is attached to the hole.
var _first_segment : RopeSegmentJolt : 
	get: return _segment_stack.back() if not _segment_stack.is_empty() else null

## Number of segments of the rope. (Helper getter)
var _segment_count : int :
	get: return _segment_stack.size()
	
## This flag will be set to true when the rope finishes it's creation.
var rope_ready = false

## Retracts some rope equal to the [param distance]. 
## When the rope is spent, the signal [signal finished_rope] is emmited.
func remove_rope(distance:float):

	if _rope_length <= 0: 
		return
	
	var first_segment_offset = _get_first_segment_offset(_rope_length)
	var new_length = _rope_length - distance 
	
	
	
	if first_segment_offset + distance < rope_segment_length:
		#Update the distance inside the hole.
		
		_hole.set_distance(_get_first_segment_offset(new_length))
		_rope_length = new_length
		#print(first_segment_offset + distance)
		#print(new_length)
	else:
		#First segment needs to be removed. And changed with the next one
		var new_target_segments = floori(new_length/rope_segment_length)+1
		var old_segment_count := _segment_count
		# Update the new starting segment.

		for i in old_segment_count-new_target_segments:
			#Delete segments and points in curve necesary for achieving the new lenght.
			if _segment_count == 1:
				#Stop retracting rope  if is the last segment and emit a signal.
				retracted_rope.emit()
				print("Finished rope")
				_rope_length = 0.0
				return
			
			var segment : RopeSegmentJolt = _segment_stack.pop_back()
			_mesh.path.curve.remove_point(_mesh.path.curve.point_count-1)
			_segment_container.remove_child(segment)
			segment.queue_free()
		
		var new_offset = _get_first_segment_offset(new_length)
		_hole.attach_segment(_segment_stack[-1],new_offset)
		
		_rope_length = new_length
		_update_weights()
		
		

## Extends the rope by the [param distance] provided until it reaches the [param maximun].
## When the maximun ammount is reached, the rope will stop extending and the signal
## [signal extended_rope] is emmited.
func add_rope(distance : float, maximun: float = -1):
	
	if maximun>0 and _rope_length >= maximun: 
		return
	
	var new_length = _rope_length + distance
	if maximun > 0 and new_length > maximun: new_length = maximun
	
	# Do stuff if the lenght has not reached the maximun.
	var first_segment_offset = _get_first_segment_offset(_rope_length)
	
	if first_segment_offset - distance > 0:
		_hole.set_distance(_get_first_segment_offset(new_length))
		_rope_length = new_length
	else:
		## Add segments until new_length or maximun is reached.
		var new_target_segments = floori(new_length/rope_segment_length)+1
		var old_segment_count := _segment_count
		var next_segment : RopeSegmentJolt = _segment_stack.back()
		_hole.detach_segment()
		
		for i in range(old_segment_count,new_target_segments):
			
			var segment : RopeSegmentJolt = _create_segment()
			
			_segment_container.add_child(segment)
			segment.global_rotation = _hole.global_rotation
			segment.global_position = next_segment.global_position + segment.global_basis.y * rope_segment_length
			
			next_segment.set_prev_segment(segment)
			segment.attach_next_segment(next_segment, true)
			_segment_stack.push_back(segment)
			
			segment.name = str(i)
			
			_mesh.path.curve.add_point(segment.global_position)
			
			next_segment = segment
			
		
		var new_offset = _get_first_segment_offset(new_length)
		_hole.attach_segment(next_segment,new_offset)
		
		_rope_length = new_length
		_update_weights()

	if maximun > 0 and _rope_length >= maximun:
		extended_rope.emit()
		print("Extended rope")


## Updates the visual aspects of the rope
func _update_visuals():
	_mesh.initiatize(rope_section_resolution,rope_segment_resolution,rope_radius,rope_material)

func _update_weights():
	var target_weight : float = rope_weight/ _segment_count
	for segment: RopeSegmentJolt in _segment_stack:
		segment.set_weight(target_weight)

func _get_first_segment_offset(length:float) -> float:
	return rope_segment_length -  fmod(length,rope_segment_length)
	
func _create_segment(prev_link = null) -> RopeSegmentJolt: 
	var segment_instance : RopeSegmentJolt = _SEGMENT.instantiate()
	segment_instance.initialize(rope_radius,rope_segment_length,layer,mask,prev_link)
	return segment_instance


func _create_rope_line(target_segment_count : int, first_segment_offset : float):

	#Adding starting segments
	var segment = _create_segment(_rope_start)
	_segment_container.add_child(segment)
	_hole.attach_segment(segment,first_segment_offset)
	_segment_stack.push_back(segment)
	
	segment.name = str(target_segment_count)
	segment.global_rotation = _hole.global_rotation
	
	var prev_segment = segment
	
	for i in range(1,target_segment_count):
		
		segment = _create_segment(prev_segment)
		_segment_container.add_child(segment)
		prev_segment.attach_next_segment(segment)
		_segment_stack.push_back(segment)
		
		segment.name = str(target_segment_count-i)
		segment.global_rotation = prev_segment.global_rotation
		
		prev_segment = segment
	
	if _rope_end:
		segment.attach_next_segment(_rope_end)
		
	_segment_stack.reverse()

func _fill_curve():
	
	var curve : Curve3D = _mesh.path.curve
	curve.clear_points()
	
	#First point in the curve is the last segment's joint or the object attached to it.
	if _rope_end:
		curve.add_point(_rope_end.global_position)
	else:
		curve.add_point(_segment_stack.front().joint.global_position)
	
	#Rest of the points are the segments origins:
	for i in range(0,_segment_count):
		curve.add_point(_segment_stack[i].global_position)
	

func _set_point_in_curve(curve: Curve3D, idx: int, point: Node3D, last:Node3D, stiffness: float):
	# Places the segment position in the curve and sets the handles as an average bewteen
	# the up vectors of the segment and his last.
	curve.set_point_position(idx, point.global_position)
	var avg = (point.global_basis.y + last.global_basis.y)/2
	curve.set_point_in(idx, -avg * stiffness)
	curve.set_point_out(idx, avg * stiffness)

func _refresh_mesh():
	
	var curve : Curve3D = _mesh.path.curve
	var stiffness =(1 - rope_stiffness)*(rope_segment_length/2)
	
	#Updating the points on the curve
	if _rope_end:
		# If a rope end object was set, the ending point is it's position.
		_set_point_in_curve(curve,0,_rope_end,_segment_stack[0],stiffness)
	else: 
		# If not, use the last segment's joint instead.
		curve.set_point_position(0,_segment_stack[0].joint.global_position)
		curve.set_point_in(0,Vector3.ZERO)
		curve.set_point_out(0,Vector3.ZERO)
		#_set_point_in_curve(curve,0,_segment_stack[0].joint,_segment_stack[0],stiffness)
	
	# Set points in curve for all the segments up until the second segment using the average
	# up vector between the segment and its previous one
	for i in range(1,_segment_count):
		_set_point_in_curve(curve,i,_segment_stack[i-1], _segment_stack[i], stiffness)
	
	# The first segment doesn't have a previous segment to average the curve handles, 
	# it just uses the segment up vector.
	curve.set_point_position(curve.point_count-1,_segment_stack[-1].global_position)
	var avg = _segment_stack[-1].global_basis.y
	curve.set_point_in(curve.point_count-1, -avg * stiffness)
	curve.set_point_out(curve.point_count-1, avg * stiffness)
	
	# Render the mesh
	_mesh.render()

func _ready():
	_rope_length = rope_initial_length
	_hole.hole_depth = rope_segment_length
	_segment_stack.clear()
	
	_update_visuals()
	
	if _rope_start:
		_hole.parent_body = _rope_start
		
		var target_segment_count = floori(_rope_length/rope_segment_length)+1
		var first_segment_offset = _get_first_segment_offset(_rope_length)
		
		_create_rope_line(target_segment_count,first_segment_offset)
		_fill_curve()
		
		_update_weights()
		
		rope_ready = true
	
func _physics_process(delta):

	if rope_ready:
		_refresh_mesh()

func _get_configuration_warnings():
	var warnings : Array[String] = []
	if not (_rope_start is PhysicsBody3D):
		warnings.push_back("No starting position was set")
	return warnings
