@tool
extends MeshInstance3D

## This class makes a rope mesh following a Path3D. It will try to interpolate the rope  mesh 
## using the path provided adding subdivisions.
##
## @experimental
class_name RopeMesher

@export var view_in_editor = false

@onready var path: Path3D = $Path
@export var _ring_resolution := 6 ##Ammount of subdivisions of the section of rope
@export var _radius := 0.1 ##Radius of the rope
@export var _segment_resolution := 3 ##Ammount of subdivisions bewteen each segment of the rope
@export var _rope_material: Material

## Setting up the rope parameters.
func initiatize(ring_resolution, segment_resolution, radius, material):
	self._ring_resolution = ring_resolution
	self._segment_resolution = segment_resolution
	self._radius = radius
	self._rope_material = material

## Calculate points for vertex on a circle using a center point, the normal vector, and the tilt of the circle.
func _create_circle_at(transf: Transform3D) -> PackedVector3Array:
	var circle_array := PackedVector3Array()
	# TODO Ajustar los puntos a la dirección de la normal y giro.
	var new_basis = transf.basis
	for i in _ring_resolution:
		var angle = 2.0 * PI * (float(i)/ float(_ring_resolution))
		var local_point = Vector3(_radius * cos(angle), _radius * sin(angle),0)
		var global_point = transf.origin  \
			+ local_point.x * new_basis.x \
			+ local_point.y * new_basis.y
		circle_array.push_back(global_point)
		
	return circle_array

## Draws a cilinder between two rings of vertices and makes UVs for them
func _draw_segment(st:SurfaceTool, v_start:float, v_end:float, start_ring: PackedVector3Array, end_ring: PackedVector3Array) -> PackedVector3Array:
	
	for i in _ring_resolution:
		var j = (i+1) % _ring_resolution
		var u_start = float(i)/float(_ring_resolution)
		var u_end =  float(i+1)/float(_ring_resolution)
		#First tri
		st.set_uv(Vector2(u_start,v_start))
		st.add_vertex(start_ring[i])
		
		st.set_uv(Vector2(u_end,v_start))
		st.add_vertex(start_ring[j])
		
		st.set_uv(Vector2(u_start,v_end))
		st.add_vertex(end_ring[i])
		
		#Second tri
		st.set_uv(Vector2(u_end,v_start))
		st.add_vertex(start_ring[j])
		
		st.set_uv(Vector2(u_end,v_end))
		st.add_vertex(end_ring[j])
		
		st.set_uv(Vector2(u_start,v_end))
		st.add_vertex(end_ring[i])
		
	return end_ring

## Renders a new mesh using the points on the path.
func render():
	# sample_baked_with_rotation para obtener una transform con el punto, normal y up_vector
	# el offset de esa función se puede obtener combinando sample y get_closest_offset
	if not (path and path.curve):
		return
		
	var curve := path.curve
	
	var st = SurfaceTool.new()
	
	if curve.point_count < 2:
		mesh = st.commit()
		return
	

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#First circle
	var start_offset = 0.0
	var start_transf = curve.sample_baked_with_rotation(start_offset,false,true)
	var start_circle = _create_circle_at(start_transf)
	
	#Iterate through each point on the curve, and subdivide segments.
	for i in curve.point_count - 1:
		for j in _segment_resolution:
			var t = float(j+1)/float(_segment_resolution)
			var end_offset = curve.get_closest_offset(curve.sample(i,t))
			var end_transf = curve.sample_baked_with_rotation(end_offset, false, true)
			var end_circle = _create_circle_at(end_transf)
			#Draw the ring and update with the new circle.
			start_circle = _draw_segment(st,start_offset,end_offset,start_circle,end_circle)
			start_offset = end_offset
	
	#Optimize indices
	st.index()
	
	#Generate normals and tangent data
	st.generate_normals()
	st.generate_tangents()
	
	mesh = st.commit()
	mesh.surface_set_material(0, _rope_material)

func _ready():
	global_position = Vector3.ZERO
	global_rotation_degrees = Vector3.ZERO
	
func _process(delta):
	if Engine.is_editor_hint():
		if view_in_editor:
			call_deferred_thread_group("render")
		
		
