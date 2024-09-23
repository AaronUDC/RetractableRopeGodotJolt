extends Node3D


@export var agujero: RopeHole
@export var segment: RigidBody3D
@export var segment2: RigidBody3D

@onready var distance = agujero.hole_depth


func _process(delta):
	
	var movement = Input.get_axis("movement_back","movement_forward")
	
	if movement:
		distance += movement * delta
		distance = clampf(distance,-1.0,agujero.hole_depth)
		agujero.set_distance(distance)
		
	if distance < 0:
		if not segment: 
			distance=0
			return
			
		distance = agujero.hole_depth
		segment.queue_free()
		segment = null
		agujero.attach_segment(segment2,distance)
		
		
		
func _input(event):
	
	if event is InputEvent:
		if event.is_action_pressed("ui_accept"):
			agujero.attach_segment(segment, agujero.hole_depth)
		elif event.is_action_pressed("movement_left"):
			agujero.detach_segment()
		
		
