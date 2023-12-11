extends CharacterBody3D

signal sprinting(value)

const SPEED = 10.0
const JUMP_VELOCITY = 7.0
const SENSITIVITY = 0.003
const EGG_RUN_SPEED_SCALE = 2.0
const SPRINT_MULTIPLIER = 1.5
const FALL_DAMAGE_VELOCITY = -18.0

@export var left_foot_back := false
@export var damaged := false:
	set(value):
		damaged = value
		_eggshell_effect()
@export var egg_mode := true:
	set(value):
		egg_mode = value
		_mode_switch()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var global: Node
var rot_h := 0.0
var rot_v := 0.0:
	set(value):
		rot_v = clamp(value, -PI/3.0, PI/3.0)
var stopped := true
var steaming := false:
	set(value):
		if value != steaming:
			steaming = value
			_steaming_effect()
var falling_movement_multiplier := 1.0
var falling_direction := Vector3.ZERO
var falling := false:
	set(value):
		falling = value
		if falling:
			falling_movement_multiplier = 0.1
		else:
			falling_movement_multiplier = 1.0
var falling_velocity := 0.0
var fall_damaged := false
var slipping_animation_multiplier := 1.0
var slipping := false:
	set(value):
		if value != slipping:
			print("slipping: %s" % value)
			slipping = value
			if slipping:
				slipping_animation_multiplier = 2.0
			else:
				slipping_animation_multiplier = 1.0
var running_animation := "eggrun"
var mode_speed_multiplier := 1.0
var mode_fall_multiplier := 1.0
var attacking := false

@onready var cam_hinge_h = $CamHingeH
@onready var cam_hinge_v = $CamHingeH/CamHingeV
@onready var cam_x_form = $CamHingeH/CamHingeV/SpringArm3D/CamXForm
@onready var animation_player = $AnimationPlayer
@onready var foot_step_l = $Skeleton3D/FootL/MeshInstance3D/FootStepL
@onready var foot_step_r = $Skeleton3D/FootR/MeshInstance3D/FootStepR
@onready var egg_mesh = $Skeleton3D/Egg/EggMesh
@onready var bounce_timer = $BounceTimer
@onready var steam = $Skeleton3D/Egg/EggMesh/Steam
@onready var hot_cast = $HotCast
@onready var slippery_cast = $SlipperyCast
@onready var neck_mesh = $Skeleton3D/Neck/NeckMesh
@onready var head_mesh = $Skeleton3D/Head/HeadMesh
@onready var beak_mesh = $Skeleton3D/Head/BeakMesh
@onready var wing_1_l = $Skeleton3D/BicepL/Wing1
@onready var wing_2_l = $Skeleton3D/ForeArmL/Wing2
@onready var wing_1_r = $Skeleton3D/BicepR/Wing1
@onready var wing_2_r = $Skeleton3D/ForeArmR/Wing2


func _ready():
	global = get_node("/root/Global")
	global.player_node = self
	global.cam_x_form_node = cam_x_form
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if egg_mode:
		neck_mesh.visible = false
		head_mesh.visible = false
		beak_mesh.visible = false
		wing_1_l.visible = false
		wing_1_r.visible = false
		wing_2_l.visible = false
		wing_2_r.visible = false


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rot_h -= event.relative.x * SENSITIVITY
		rot_v -= event.relative.y * SENSITIVITY


func _process(delta):
	cam_hinge_h.global_position = global_position
	foot_step_l.pitch_scale = randfn(1.0, 0.02)
	foot_step_r.pitch_scale = randfn(1.0, 0.02)


func _physics_process(delta):
	if Input.is_action_just_pressed("modeswitch"):
		egg_mode = not egg_mode
	var sprint := 1.0
	
	#if Input.is_action_pressed("sprint"):
		#sprint = SPRINT_MULTIPLIER
	
	cam_hinge_h.rotation.y = rot_h
	cam_hinge_v.rotation.x = rot_v
	
	if not is_on_floor():
		steaming = false
		falling = true
		falling_velocity = velocity.y
		velocity.y -= gravity * delta * mode_fall_multiplier
	else:
		if hot_cast.is_colliding():
			steaming = true
		else:
			steaming = false
		if slippery_cast.is_colliding():
			slipping = true
			#velocity.y -= gravity * delta * 10.0
		else:
			slipping = false
		if falling:
			falling = false
			if falling_velocity <= FALL_DAMAGE_VELOCITY:
				fall_damaged = true
				animation_player.current_animation = "splits"
				animation_player.speed_scale = 2.0
	
	if not fall_damaged:
		if Input.is_action_just_pressed("attack") and not attacking and not egg_mode:
			attacking = true
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var input_strength := input_dir.length()
		
		if input_dir.is_equal_approx(Vector2.ZERO) and not stopped:
			stopped = true
			emit_signal("sprinting", false)
		elif not input_dir.is_equal_approx(Vector2.ZERO) and stopped:
			stopped = false
			if is_equal_approx(sprint, SPRINT_MULTIPLIER):
				emit_signal("sprinting", true)
		
		#if Input.is_action_just_pressed("sprint") and not stopped:
			#emit_signal("sprinting", true)
		#elif Input.is_action_just_released("sprint"):
			#emit_signal("sprinting", false)
		
		var direction : Vector3 = (cam_hinge_h.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var body_face_angle = direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
		if direction and not falling and not attacking:
			velocity.x = lerp(velocity.x, direction.x * SPEED * sprint * mode_speed_multiplier, 0.1)
			velocity.z = lerp(velocity.z, direction.z * SPEED * sprint * mode_speed_multiplier, 0.1)
			animation_player.current_animation = running_animation
			rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
			animation_player.speed_scale = EGG_RUN_SPEED_SCALE * sprint * slipping_animation_multiplier * mode_speed_multiplier
		elif falling:
			velocity.x = lerp(velocity.x, direction.x * SPEED * sprint * mode_speed_multiplier, 0.01)
			velocity.z = lerp(velocity.z, direction.z * SPEED * sprint * mode_speed_multiplier, 0.01)
			if egg_mode:
				if left_foot_back:
					animation_player.current_animation = "eggmidairL"
				else:
					animation_player.current_animation = "eggmidairR"
			else:
				animation_player.current_animation = "chickenjump"
			if not stopped:
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.01)
			animation_player.speed_scale = 4.0
		elif attacking:
			body_face_angle = cam_hinge_h.transform.basis.z.signed_angle_to(Vector3.BACK, Vector3.UP)
			rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.2)
			velocity.x = lerp(velocity.x, 0.0, 0.3)
			velocity.z = lerp(velocity.z, 0.0, 0.3)
			animation_player.current_animation = "chickengust"
			animation_player.speed_scale = 3.0
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.3)
			velocity.z = lerp(velocity.z, 0.0, 0.3)
			animation_player.current_animation = "RESET"
		
		move_and_slide()


func _mode_switch():
	if egg_mode:
		neck_mesh.visible = false
		head_mesh.visible = false
		beak_mesh.visible = false
		wing_1_l.visible = false
		wing_1_r.visible = false
		wing_2_l.visible = false
		wing_2_r.visible = false
		running_animation = "eggrun"
		mode_speed_multiplier = 1.0
		mode_fall_multiplier = 1.0
	else:
		neck_mesh.visible = true
		head_mesh.visible = true
		beak_mesh.visible = true
		wing_1_l.visible = true
		wing_1_r.visible = true
		wing_2_l.visible = true
		wing_2_r.visible = true
		running_animation = "chickenrun"
		mode_speed_multiplier = 1.8
		mode_fall_multiplier = 0.5


func _steaming_effect():
	if steaming:
		steam.emitting = true
	else:
		steam.emitting = false


func _eggshell_effect():
	var material: StandardMaterial3D
	if egg_mesh:
		material = egg_mesh.get_surface_override_material(0)
		if damaged:
			material.detail_enabled = true
		else:
			material.detail_enabled = false


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "splits":
		fall_damaged = false
	elif anim_name == "chickengust":
		attacking = false
