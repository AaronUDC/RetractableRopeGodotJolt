extends CharacterBody3D
class_name Actor

@export_group("Movement stats")
@export var SPEED = 5.0
@export var RUN_SPEED = 10.0
@export var JUMP_VELOCITY = 4.5

@export_group("Cord")
@export var CORD_MOVEMENT_COST = 1.0
@export var CORD_JUMP_COST = 0.5
@export var rope_controller : RopeController

@export_group("Camera")
@export var camera : Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouseFocus = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		toggleMouseMode()

func _physics_process(delta):

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		rope_controller.remove_rope(CORD_JUMP_COST)
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("movement_right", "movement_left", "movement_back", "movement_forward")
	var direction =  Vector3(input_dir.x, 0, input_dir.y).normalized()
	var front_dir = get_front_direction()
	var angle = atan2(front_dir.x,front_dir.z)
	if direction:
		var movement = direction.rotated(up_direction, angle)
		velocity.x = SPEED * movement.x
		velocity.z = SPEED * movement.z
		
		global_rotation.y = rotate_toward(global_rotation.y, atan2(movement.x,movement.z), delta * 10)
		#look_at(global_position - movement)
		
		rope_controller.remove_rope(CORD_MOVEMENT_COST * delta)
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	
	
	move_and_slide()

func toggleMouseMode():
	mouseFocus = not mouseFocus
	if mouseFocus:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#camera.mouse_follow = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#camera.mouse_follow = true
		
func get_front_direction() :
	var dir : Vector3 = -camera.transform.basis.z
	dir.y = 0
	dir = dir.normalized()
	return dir
