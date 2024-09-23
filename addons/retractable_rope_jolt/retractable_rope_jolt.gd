@tool
extends EditorPlugin

const HOLE_GIZMO_PLUGIN = preload("rope_controller_gizmo_plugin.gd")

var gizmo_plugin = HOLE_GIZMO_PLUGIN.new()

func _enter_tree():
	add_custom_type("RopeOrigin","Node3D", preload("rope_origin.gd"),null)
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	remove_custom_type("RopeOrigin")
	
