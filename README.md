
# RetractableRopeGodotJolt
This is an addon for Godot 4.3 using the Jolt physics engine. This project implements a physically based rope made out of several segments, that can be retracted and extended from an origin point.

![Rope origin attached to a CharacterBody3D. The end of the rope is attached to a RigidBody3D](https://github.com/user-attachments/assets/1e7bc995-53c3-47df-bc4a-ba0db987cce8)

The rope starts from a simulated hole and may have another *PhysicsBody3D* at the end. The controller has a custom gizmo that represents the hole where the the rope originates. 

Internally, the rope is comprised of a chain of segments joined by *JoltConeTwistJoint3D* joints. The first segment is attached to the hole by a *JoltGeneric6DOFJoint3D*, which constrains its rotation as it enters the hole. Finally, the visuals of the rope are made by rendering a cylindrical mesh through the positions of each segment, interpolating them to provide a more rounded appearance.

![Rope with the segment colliders being visible](https://github.com/user-attachments/assets/7cf281a5-9285-44e9-b07d-a0b490fccf79) 
![Gizmo of the hole](https://github.com/user-attachments/assets/61d22246-a8ab-4af9-9af2-27e22b016202)

## Setting up
The first thing is to configure Jolt's physics parameters. By default, the physics engine makes too few physics interpolations which causes the string to stretch too much when moving the ends. For best results, it is recommended to adjust the physics engine parameters as in the image (You will need to activate the advanced options to display the Jolt settings).

![Godot Jolt parameters](https://github.com/user-attachments/assets/c48e3713-124b-4459-b023-57ece67379b2)

## Using the rope controller
To create a rope place the *rope_origin* scene or add the *rope_origin* script to a *node3D* (The script will simply replace the node with the rope scene).
The rope controller has several parameters to configure the behaviour of the rope:

![RopeController parameters](https://github.com/user-attachments/assets/3094d051-c4bf-437e-ab76-6a11c8bac2fb)

### Parameters
**Rope start:** The PhysicsBody3D attached to the hole of the rope.

**Rope end:** The PhysicsBody3D attached to the end of the rope. If provided, the attached node will be placed at the end of the generated rope.

 - **Rope Parameters**

**Weight:** Total weight of the rope. The weight will remain the same regardless of the length and will be distributed equally between the segments.

**Segment length:** The length of each segment. Shorter lengths will make the rope look more natural, but will require more segments, impacting performance. 

**Hole radius:** The radius of the hole from where the rope originates. It should be more than the radius of the rope.

**Rope radius:** The radius of the rope.

**Initial length:** Initial length of the rope.

**Segment collisions:** Physics layer and mask of the rope segments. 

 - **Visuals**

**Stiffness:** This will affect the amount of interpolation of the rope mesh, making the rope appear more rounded. A stiffness of 1 will result in no interpolation, making the visuals match exactly with the segments.

**Segment resolution:** Amount of subdivisions between each segment of the rope. Increasing this reduces performance.

**Section resolution:** Amount of subdivisions the section of the rope will have. Incrementing this too much can greatly lower the performance. Increasing this too much can greatly tank performance.

**Material:** Material of the rope mesh.

### Signals
The controller will output the signal *rope_extended* when the rope reaches a maximum length (specified when extending the rope), or *rope_retracted* when the rope is fully retracted.

### Retracting and extending the rope
The controller has methods to extend or retract the rope a given length. These will add or remove segments as needed, smoothly from the hole, as if the rope were coming out of the wall. The methods are: *add_rope* and *remove_rope* respectively. 

In the case of *add_rope*, a maximum length can be specified so that the rope stops extending. The *extended_rope* signal is emitted when that length is reached. 

## Future features and work in progress

This addon can still be extended with more features and improvements.
 
Currently, the rope is generated along a straight line in front of the hole, moving the attached endpoint node, to the end of the rope. In the future it would be desirable to be able to generate the rope between the hole and the attached endpoint with the specified length. This way, the rope will not start fully extended and can be placed in tighter spaces.

Another problem is the performance of the rope visuals. Currently the string mesh is remeshed at each frame using the *SurfaceTool* interface. This is a Godot interface that provides a simple but powerful way to build geometry, but is not as well suited for real-time rendering updates. The result is that mesh rendering takes up the vast majority of the string processing time in each frame.
![Frame time of the rendering method of the rope](https://github.com/user-attachments/assets/707b6fa9-6ce9-4015-9480-34706dcd3488)

In the future, other Godot APIs could be used to create the mesh or even create it on the GPU. 
