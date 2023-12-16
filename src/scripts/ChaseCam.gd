extends Camera3D


const NORMAL_FOV = 75.0
const SPRINT_FOV = 82.0


var global: Node
var x_form_target: Node3D
var x_form_target_queued := true
var player_node: CharacterBody3D:
	set(value):
		player_node = value
var player_node_queued := true
var player_sprinting := false
var fov_changing := false
var lerp_strength := 0.2
var shake_timer := 0.0
var shaking := false:
	set(value):
		shaking = value
		if not shaking:
			shake_timer = 0.0
var default_v_offset := 0.1
var default_h_offset := 0.0
var current_lerp := 0.2


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
	if shaking:
		h_offset = lerp(h_offset, randfn(0.0, 1.0), 0.02)
		v_offset = lerp(v_offset, randfn(0.0, 1.0), 0.02)
		shake_timer -= delta
		if shake_timer <= 0.0:
			shaking = false
	else:
		h_offset = lerp(h_offset, default_h_offset, 0.1)
		v_offset = lerp(v_offset, default_v_offset, 0.1)
	if x_form_target:
		current_lerp = lerp(current_lerp, lerp_strength, 0.1)
		global_transform = global_transform.interpolate_with(x_form_target.global_transform, current_lerp)
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
	player_node = value


func _on_global_camxform_changed(value):
	x_form_target = value


func _on_chicken_egg_newshoes(value):
	if value:
		x_form_target = player_node.shoe_look
		lerp_strength = 0.05
	else:
		x_form_target = global.cam_x_form_node
		lerp_strength = 0.2


func _on_chicken_egg_newhat(value):
	if value:
		x_form_target = player_node.hat_look
		lerp_strength = 0.05
	else:
		x_form_target = global.cam_x_form_node
		lerp_strength = 0.2


func _on_chicken_egg_camera_shake(zero_to_one):
	shaking = true
	shake_timer = zero_to_one


func _on_chicken_egg_newtie(value):
	if value:
		x_form_target = player_node.tie_look
		lerp_strength = 0.05
	else:
		x_form_target = global.cam_x_form_node
		lerp_strength = 0.2


func _on_chicken_egg_newknees(value):
	if value:
		x_form_target = player_node.knee_look
		lerp_strength = 0.05
	else:
		x_form_target = global.cam_x_form_node
		lerp_strength = 0.2


func _on_chicken_egg_newshorts(value):
	if value:
		x_form_target = player_node.short_look
		lerp_strength = 0.05
	else:
		x_form_target = global.cam_x_form_node
		lerp_strength = 0.2
