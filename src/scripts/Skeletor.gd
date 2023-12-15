@tool
extends Skeleton3D


@export var head_height := 1.7
@export var shoulder_height := 1.5
@export var waist_height := 0.9
@export var shoulder_length := 0.2
@export var bicep_length := 0.3
@export var forearm_length := 0.3
@export var hip_diameter := 0.2
@export var leg_length := 4.5
@export var generate_bones := false:
	set(value):
		if value:
			_generate_bones()

var bone_names := []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _generate_bones():
	print("generating bones")
	clear_bones()
	var waist_pos := Vector3(0.0, waist_height, 0.0)
	var shoulder_pos := Vector3(0.0, shoulder_height, 0.0)
	var head_pos := Vector3(0.0, head_height, 0.0)
	var forward_basis := Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	
	add_bone("Spine0")
	set_bone_rest(0, Transform3D(forward_basis, waist_pos))
	bone_names.append("Spine0")
	
	add_bone("Spine1")
	set_bone_rest(1, Transform3D(forward_basis, shoulder_pos))
	set_bone_parent(1, 0)
	bone_names.append("Spine1")
	
	add_bone("Spine2")
	set_bone_rest(2, Transform3D(forward_basis, head_pos))
	set_bone_parent(2, 1)
	bone_names.append("Spine2")
	
	add_bone("Head")
	set_bone_rest(3, Transform3D(forward_basis, head_pos))
	set_bone_parent(3, 2)
	bone_names.append("Head")
	
	add_bone("ShoulderL")
	set_bone_rest(4, Transform3D(forward_basis, Vector3(-shoulder_length, 0.0, 0.0)))
	set_bone_parent(4, 1)
	bone_names.append("ShoulderL")
	
	add_bone("BicepL")
	set_bone_rest(5, Transform3D(forward_basis, Vector3(-bicep_length, 0.0, 0.0)))
	set_bone_parent(5, 4)
	bone_names.append("BicepL")
	
	add_bone("ForeArmL")
	set_bone_rest(6, Transform3D(forward_basis, Vector3(-forearm_length, 0.0, 0.0)))
	set_bone_parent(6, 5)
	bone_names.append("ForeArmL")
	
	add_bone("HandL")
	set_bone_rest(7, Transform3D(forward_basis, Vector3(-0.15, 0.0, 0.0)))
	set_bone_parent(7, 6)
	bone_names.append("HandL")
	
	add_bone("ShoulderR")
	set_bone_rest(8, Transform3D(forward_basis, Vector3(shoulder_length, 0.0, 0.0)))
	set_bone_parent(8, 1)
	bone_names.append("ShoulderR")
	
	add_bone("BicepR")
	set_bone_rest(9, Transform3D(forward_basis, Vector3(bicep_length, 0.0, 0.0)))
	set_bone_parent(9, 8)
	bone_names.append("BicepR")
	
	add_bone("ForeArmR")
	set_bone_rest(10, Transform3D(forward_basis, Vector3(forearm_length, 0.0, 0.0)))
	set_bone_parent(10, 9)
	bone_names.append("ForeArmR")
	
	add_bone("HandR")
	set_bone_rest(11, Transform3D(forward_basis, Vector3(0.15, 0.0, 0.0)))
	set_bone_parent(11, 10)
	bone_names.append("HandR")
	
	add_bone("HipL")
	set_bone_rest(12, Transform3D(forward_basis, Vector3(-hip_diameter, 0.0, 0.0)))
	set_bone_parent(12, 0)
	bone_names.append("HipL")
	
	add_bone("ThighL")
	set_bone_rest(13, Transform3D(forward_basis, Vector3(0.0, -(leg_length / 2.0), 0.0)))
	set_bone_parent(13, 12)
	bone_names.append("ThighL")
	
	add_bone("ShinL")
	set_bone_rest(14, Transform3D(forward_basis, Vector3(0.0, -(leg_length / 2.0), 0.0)))
	set_bone_parent(14, 13)
	bone_names.append("ShinL")
	
	add_bone("FootL")
	set_bone_rest(15, Transform3D(forward_basis, Vector3(0.0, 0.0, -0.2)))
	set_bone_parent(15, 14)
	bone_names.append("FootL")
	
	add_bone("HipR")
	set_bone_rest(16, Transform3D(forward_basis, Vector3(hip_diameter, 0.0, 0.0)))
	set_bone_parent(16, 0)
	bone_names.append("HipR")
	
	add_bone("ThighR")
	set_bone_rest(17, Transform3D(forward_basis, Vector3(0.0, -(leg_length / 2.0), 0.0)))
	set_bone_parent(17, 16)
	bone_names.append("ThighR")
	
	add_bone("ShinR")
	set_bone_rest(18, Transform3D(forward_basis, Vector3(0.0, -(leg_length / 2.0), 0.0)))
	set_bone_parent(18, 17)
	bone_names.append("ShinR")
	
	add_bone("FootR")
	set_bone_rest(19, Transform3D(forward_basis, Vector3(0.0, 0.0, -0.2)))
	set_bone_parent(19, 18)
	bone_names.append("FootR")
	
	reset_bone_poses()
