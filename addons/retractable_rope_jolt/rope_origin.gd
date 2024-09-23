@tool
extends Node3D
class_name RopeOrigin

const GENERATOR_SCENE = preload("rope_origin.tscn")

# Instantiate the rope generator scene
func _ready():
	if(GENERATOR_SCENE.can_instantiate()):
		var generator_instance= GENERATOR_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		get_parent().add_child(generator_instance)
		var self_name = name
		name = "del"
		generator_instance.name = self_name
		
		generator_instance.owner = get_tree().edited_scene_root
		queue_free()
