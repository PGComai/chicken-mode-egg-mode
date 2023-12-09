extends Camera3D


const NORMAL_FOV = 75.0
const SPRINT_FOV = 82.0


var global: Node
var x_form_target: Node3D
var x_form_target_queued := true
var player_node: CharacterBody3D:
	set(value):
		player_node = value
		player_node.sprinting.connect(_on_player_sprinting)
var player_node_queued := true
var player_sprinting := false
var fov_changing := false


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_node_changed.connect(_on_global_player_node_changed)
	global.camxform_changed.connect(_on_global_camxform_changed)
	if global.player_node:
		player_node = global.player_node
		player_node_queued = false
	if global.cam_x_form_node:
		x_form_target = global.cam_x_form_node
		x_form_target_queued = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if x_form_target:
		global_transform = global_transform.interpolate_with(x_form_target.global_transform, 0.2)
	if fov_changing:
		if player_sprinting:
			fov = lerp(fov, SPRINT_FOV, 0.05)
			if is_equal_approx(fov, SPRINT_FOV):
				fov = SPRINT_FOV
				fov_changing = false
		else:
			fov = lerp(fov, NORMAL_FOV, 0.05)
			if is_equal_approx(fov, NORMAL_FOV):
				fov = NORMAL_FOV
				fov_changing = false

func _on_player_sprinting(value):
	player_sprinting = value
	fov_changing = true


func _on_global_player_node_changed(value):
	if player_node_queued:
		player_node_queued = false
		player_node = value


func _on_global_camxform_changed(value):
	if x_form_target_queued:
		x_form_target_queued = false
		x_form_target = value
