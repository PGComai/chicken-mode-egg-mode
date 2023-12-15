extends RayCast3D


@export var slope_color: Color
@export var flat_color: Color



@onready var node_3d = $Node3D
@onready var mesh_instance_3d = $Node3D/MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_colliding():
		var pos = get_collision_point()
		var nor = get_collision_normal()
		var ang = nor.angle_to(Vector3.UP)
		if ang > PI/4.0:
			mesh_instance_3d.mesh.material.albedo_color = slope_color
		else:
			mesh_instance_3d.mesh.material.albedo_color = flat_color
		if is_equal_approx(nor.angle_to(Vector3.UP), 0.0):
			node_3d.rotation = Vector3(PI/2.0, 0.0, 0.0)
			node_3d.global_position = pos
		else:
			node_3d.look_at_from_position(pos, pos + nor, Vector3.UP, true)
		node_3d.global_position = pos
		node_3d.visible = true
	else:
		node_3d.visible = false
