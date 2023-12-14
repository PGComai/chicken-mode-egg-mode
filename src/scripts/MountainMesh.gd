@tool
extends MeshInstance3D


@export var mountain_radius := 200.0
@export var mountain_height := 50.0
@export var mesh_subdivision := 50
@export var mesh_size := 500.0
@export var mountain_curve: Curve
@export var mountain_noise: FastNoiseLite
@export var mountain_noise2: FastNoiseLite
@export var mountain_noise3: FastNoiseLite
@export var mountain_noise4: FastNoiseLite
@export var flat_ground_color: Color
@export var cliff_color: Color
@export var flat_cliff_curve: Curve
@export_enum("mountain", "skate") var mesh_mode = 0
@export var generate_mountain := false:
	set(value):
		if value:
			_generate_mountain()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _generate_mountain():
	var vertex_array := PackedVector3Array()
	var normal_array := PackedVector3Array()
	var uv_array := PackedVector2Array()
	var color_array := PackedColorArray()
	
	for x in mesh_subdivision:
		var x_progress = x / float(mesh_subdivision)
		var x_1_progress = (x + 1) / float(mesh_subdivision)
		var x_coord = (mesh_size * x_progress) - (mesh_size / 2.0)
		var x_1_coord = (mesh_size * x_1_progress) - (mesh_size / 2.0)
		for z in mesh_subdivision:
			var z_progress = z / float(mesh_subdivision)
			var z_1_progress = (z + 1) / float(mesh_subdivision)
			var z_coord = (mesh_size * z_progress) - (mesh_size / 2.0)
			var z_1_coord = (mesh_size * z_1_progress) - (mesh_size / 2.0)
			
			var v1 := set_mountain_y(Vector3(x_coord, 0.0, z_coord))
			var v2 := set_mountain_y(Vector3(x_1_coord, 0.0, z_coord))
			var v3 := set_mountain_y(Vector3(x_coord, 0.0, z_1_coord))
			var v4 := set_mountain_y(Vector3(x_1_coord, 0.0, z_1_coord))
			
			vertex_array.append(v1)
			uv_array.append(Vector2(x_progress, z_progress))
			vertex_array.append(v2)
			uv_array.append(Vector2(x_1_progress, z_progress))
			vertex_array.append(v3)
			uv_array.append(Vector2(x_progress, z_1_progress))
			
			var n = Plane(v1, v2, v3).normal
			var flatness = clamp(Vector3.UP.dot(n), 0.0, 1.0)
			if flat_cliff_curve:
				flatness = flat_cliff_curve.sample_baked(flatness)
			
			var fgc = flat_ground_color.lerp(Color("white"), clamp(remap(snapped(v1.y, 5.0), 0.0, 200.0, 0.0, 1.0), 0.0, 1.0))
			var clr = cliff_color.lerp(fgc, flatness)
			
			color_array.append(clr)
			color_array.append(clr)
			color_array.append(clr)
			
			normal_array.append(n)
			normal_array.append(n)
			normal_array.append(n)
			
			vertex_array.append(v3)
			uv_array.append(Vector2(x_progress, z_1_progress))
			vertex_array.append(v2)
			uv_array.append(Vector2(x_1_progress, z_progress))
			vertex_array.append(v4)
			uv_array.append(Vector2(x_1_progress, z_1_progress))
			
			n = Plane(v3, v2, v4).normal
			flatness = clamp(Vector3.UP.dot(n), 0.0, 1.0)
			if flat_cliff_curve:
				flatness = flat_cliff_curve.sample_baked(flatness)
			
			clr = cliff_color.lerp(fgc, flatness)
			
			color_array.append(clr)
			color_array.append(clr)
			color_array.append(clr)
			
			normal_array.append(n)
			normal_array.append(n)
			normal_array.append(n)
	
	var am = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_COLOR] = color_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh = am


func set_mountain_y(vec: Vector3) -> Vector3:
	if mesh_mode == 0:
		var dist_from_center = global_position.distance_to(vec)
		dist_from_center = clamp(dist_from_center, 0.0, mountain_radius)
		var dist_mapped = remap(dist_from_center, 0.0, mountain_radius, 0.0, 1.0)
		var noise_effect = mountain_curve.sample_baked(dist_mapped)#pingpong(dist_mapped, 0.5)
		var nval = (mountain_noise.get_noise_2d(vec.x, vec.z) / 1.0) * noise_effect
		var nval2 = (mountain_noise2.get_noise_2d(vec.x, vec.z) / 1.0) * (dist_mapped) * 1.0
		var nval3 = (mountain_noise3.get_noise_2d(vec.x, vec.z) / 1.0) * (dist_mapped) * 2.0
		var height_val = mountain_curve.sample_baked(dist_mapped) + nval + nval2 + nval3
		height_val = min(height_val, 1.0)
		var y_val = remap(height_val, 0.0, 1.0, 0.0, mountain_height)
		vec.y += lerp(snapped(y_val, 5.0), y_val, 0.4)
	elif mesh_mode == 1:
		var dist_from_center = Vector3.ZERO.distance_to(vec)
		dist_from_center = clamp(dist_from_center, 0.0, mountain_radius)
		var dist_mapped = remap(dist_from_center, 0.0, mountain_radius, 0.0, 1.0)
		var height_val = mountain_curve.sample_baked(dist_mapped)
		var y_val = remap(height_val, 0.0, 1.0, 0.0, mountain_height)
		vec.y += y_val
	return vec
