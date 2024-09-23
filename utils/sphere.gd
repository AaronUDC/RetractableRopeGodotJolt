extends RigidBody3D

const isContinuous = true

@export var distance = 10.0
@export var targetDistance = 10.0
@export var zoomIncrement = .05
@export var zoomSpeed = 10
@onready var camera = $"../Camera3D"



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	distance = lerp(distance, targetDistance, delta*zoomSpeed)
	
	var mousePos = get_viewport().get_mouse_position()
	var cursorPos = get_viewport().get_camera_3d().project_position(mousePos,distance)
	
	if(Input.is_action_pressed("ui_accept") or isContinuous):
		global_position = cursorPos

func _input(event):
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			targetDistance += zoomIncrement
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			targetDistance -= zoomIncrement
