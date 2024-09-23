extends EditorNode3DGizmoPlugin


enum  HANDLES {hole_depth, hole_radius}

const CIRCLE_RESOLUTION = 24

func _has_gizmo(for_node_3d):
	return for_node_3d is RopeController

func _get_gizmo_name():
	return "Rope hole"


func _init():
	
	create_material("main", Color(Color.CHARTREUSE))

func _create_circle_at(radius: float) -> PackedVector3Array:
	var circle_array := PackedVector3Array()
	# TODO Ajustar los puntos a la dirección de la normal y giro.
	for i in CIRCLE_RESOLUTION:
		var angle = 2.0 * PI * (float(i)/ float(CIRCLE_RESOLUTION))
		var local_point = Vector3(radius * cos(angle), 0, radius * sin(angle))
		circle_array.push_back(local_point)
		
	return circle_array



func _redraw(gizmo):
	
	gizmo.clear()
	

	var hole: RopeController= gizmo.get_node_3d()
	var depth : float = hole.rope_segment_length
	var radius : float = hole.rope_hole_radius
	
	var lines = PackedVector3Array()
	
	var circle_points = _create_circle_at(radius)
		
	for i in CIRCLE_RESOLUTION:
		var j = (i+1) % CIRCLE_RESOLUTION
		lines.push_back(circle_points[i])
		lines.push_back(circle_points[j])
				
		lines.push_back(circle_points[i] + Vector3(0,depth,0))
		lines.push_back(circle_points[j] + Vector3(0,depth,0))
		
	for i in ceili(CIRCLE_RESOLUTION/2):
		lines.push_back(circle_points[i*2] + Vector3(0,depth,0))
		lines.push_back(circle_points[i*2])

	gizmo.add_lines(lines, get_material("main", gizmo), false)






