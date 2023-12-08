extends CharacterBody3D

signal sprinting(value)

const SPEED = 10.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const EGG_RUN_SPEED_SCALE = 2.0
const SPRINT_MULTIPLIER = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var global: Node
var rot_h := 0.0
var rot_v := 0.0:
	set(value):
		rot_v = clamp(value, -PI/3.0, PI/3.0)
var stopped := true

@onready var cam_hinge_h = $CamHingeH
@onready var cam_hinge_v = $CamHingeH/CamHingeV
@onready var cam_x_form = $CamHingeH/CamHingeV/SpringArm3D/CamXForm
@onready var animation_player = $AnimationPlayer


func _ready():
	global = get_node("/root/Global")
	global.player_node = self
	global.cam_x_form_node = cam_x_form
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rot_h -= event.relative.x * SENSITIVITY
		rot_v -= event.relative.y * SENSITIVITY


func _process(delta):
	cam_hinge_h.global_position = global_position


func _physics_process(delta):
	var sprint := 1.0
	
	if Input.is_action_pressed("sprint"):
		sprint = SPRINT_MULTIPLIER
	
	cam_hinge_h.rotation.y = rot_h
	cam_hinge_v.rotation.x = rot_v
	
	if not is_on_floor():
		velocity.y -= gravity * delta

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
	
	if Input.is_action_just_pressed("sprint") and not stopped:
		emit_signal("sprinting", true)
	elif Input.is_action_just_released("sprint"):
		emit_signal("sprinting", false)
	
	var direction : Vector3 = (cam_hinge_h.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var body_face_angle = direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
	if direction:
		velocity.x = direction.x * SPEED * sprint
		velocity.z = direction.z * SPEED * sprint
		animation_player.current_animation = "eggrun"
		rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * sprint)
		velocity.z = move_toward(velocity.z, 0, SPEED * sprint)
		animation_player.current_animation = "RESET"
	animation_player.speed_scale = EGG_RUN_SPEED_SCALE * sprint

	move_and_slide()
