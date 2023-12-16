extends CharacterBody3D


const SPEED = 10.0
const JUMP_VELOCITY = 15.0
const SENSITIVITY = 0.003
const RUN_SPEED = 0.8
const FALL_DAMAGE_VELOCITY = -18.0
const DETECT_RANGE = 18.0
const BEHIND_RANGE = 5.0
const ACTIVE_RANGE = 40.0
const MAX_HEALTH = 70.0
const FORK_DAMAGE = 4.0
const KNOCKBACK_STRENGTH = 10.0
const CHARGE_MULTI = 4.0
const STUCK_THRESH = 1.0
const TARGET_THRESH = 1.5
const PATH_THRESH = 2.0
const ACTIVITY_RANGE = 15000.0


@export var patrol_zone: Node3D
@export var spawn_pos: Vector3
@export var patrol_offset := 0


@onready var animation_player = $AnimationPlayer
@onready var alerted = $Alerted
@onready var navigation_agent_3d = $NavigationAgent3D
@onready var player_cast = $PlayerCast
@onready var foot_step_l = $Skeleton3D/FootL/MeshInstance3D/FootStepL
@onready var foot_step_r = $Skeleton3D/FootR/MeshInstance3D/FootStepR
@onready var search_timer = $SearchTimer
@onready var jump_cast = $JumpCast
@onready var nav_timer = $NavTimer
@onready var knockback_reciever = $KnockbackReciever
@onready var slippery_cast = $SlipperyCast
@onready var cam_hinge_h = $CamHingeH
@onready var cam_hinge_v = $CamHingeH/CamHingeV
@onready var cam_x_form = $CamHingeH/CamHingeV/SpringArm3D/CamXForm
@onready var x_form_pot = $Skeleton3D/Torso/XFormPot
@onready var bounce_timer = $BounceTimer
@onready var question_mark_pot = $Skeleton3D/Torso/QMarkHolder/QuestionMarkPot
@onready var control_timer = $ControlTimer
@onready var in_pot_area = $Skeleton3D/Torso/AnimatableBody3D/InPotArea


var global: Node
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var running_animation := "potrun"
var stopped := true
var falling_movement_multiplier := 1.0
var falling_direction := Vector3.ZERO
var falling := false:
	set(value):
		if falling and not value:
			print("starting bounce timer")
			bounce_timer.start()
		falling = value
		if falling:
			falling_movement_multiplier = 0.1
		else:
			falling_movement_multiplier = 1.0
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
var falling_velocity := 0.0
var fall_damaged := false
var mode_speed_multiplier := 1.0
var nav_target_pos: Vector3
var patrol_idx := 0
var player_node: CharacterBody3D
var player_node_queued := true
var player_direction: Vector3
var stop_and_look := false:
	set(value):
		alerted.visible = value
		stop_and_look = value
var looking_for_player := false
var player_position_known := false:
	set(value):
		if value != player_position_known:
			player_position_known = value
			if value:
				stop_and_look = true
				looking_for_player = true
				print("found player")
			else:
				nav_target_pos = patrol_zone.get_children()[patrol_idx].global_position
				navigation_agent_3d.target_position = nav_target_pos
				print("lost player")
var last_player_position: Vector3
var damaged := false
var death_queued := false
var health := 10.0:
	set(value):
		health = value
		damaged = true
		velocity.y = JUMP_VELOCITY
var unstuck_speed_multiplier := 1.0
var waypoint_stuck_counter := 0.0
var can_nav := false
var knockback := false
var knockback_direction := Vector3.ZERO
var knockback_strength := 1.0
var player_in_control := false:
	set(value):
		player_in_control = value
		question_mark_pot.visible = not player_in_control
		if player_in_control:
			stop_and_look = false
			global.player_node = self
			global.cam_x_form_node = cam_x_form
		else:
			control_timer.start()
			in_pot_area.monitoring = false
var rot_h := 0.0
var rot_v := 0.0:
	set(value):
		rot_v = clamp(value, -PI/3.0, PI/3.0)
var double_jump_ready := false


func _ready():
	spawn_pos = global_position
	patrol_idx = patrol_offset
	global = get_node("/root/Global")
	global.player_node_changed.connect(_on_global_player_node_changed)
	if global.player_node:
		player_node = global.player_node
		player_node_queued = false


#func _input(event):
	#if event is InputEventMouseMotion and player_in_control:
		#rot_h -= event.relative.x * SENSITIVITY
		#rot_v -= event.relative.y * SENSITIVITY


func _process(delta):
	if player_node.global_position.distance_squared_to(global_position) > ACTIVITY_RANGE and not player_position_known:
		pass
	else:
		cam_hinge_h.global_position = global_position
		foot_step_l.pitch_scale = randfn(1.0, 0.02)
		foot_step_r.pitch_scale = randfn(1.0, 0.02)
		
		cam_hinge_h.rotation.y = rot_h
		cam_hinge_v.rotation.x = rot_v
		
		if not nav_target_pos and can_nav:
			nav_target_pos = patrol_zone.get_children()[0].global_position
			navigation_agent_3d.target_position = nav_target_pos
			print("picked target")
		
		if navigation_agent_3d.distance_to_target() < TARGET_THRESH or navigation_agent_3d.get_next_path_position().distance_squared_to(global_position) < PATH_THRESH:
			waypoint_stuck_counter += delta
			if waypoint_stuck_counter > STUCK_THRESH:
				print("stuck")
				waypoint_stuck_counter = 0.0
				patrol_idx += 1
				if patrol_idx >= patrol_zone.get_children().size():
					patrol_idx = 0
				nav_target_pos = patrol_zone.get_children()[patrol_idx].global_position
				navigation_agent_3d.target_position = nav_target_pos


func _physics_process(delta):
	if player_in_control:
		if Input.is_action_just_pressed("modeswitch"):
			player_in_control = false
		if not is_on_floor():
			#steaming = false
			falling = true
			falling_velocity = velocity.y
			velocity.y -= gravity * delta# * mode_fall_multiplier
		else:
			#if hot_cast.is_colliding():
				#steaming = true
			#else:
				#steaming = false
			if slippery_cast.is_colliding():
				slipping = true
				#velocity.y -= gravity * delta * 10.0
			else:
				slipping = false
			if falling:
				falling = false
				#if falling_velocity <= FALL_DAMAGE_VELOCITY:
					#fall_damaged = true
					#animation_player.current_animation = "splits"
					#animation_player.speed_scale = 2.0
					#emit_signal("camera_shake", 0.2)
		
		var just_jumped := false
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if double_jump_ready:
				velocity.y = JUMP_VELOCITY * 1.5
				print("double jump")
				double_jump_ready = false
			else:
				velocity.y = JUMP_VELOCITY
				double_jump_ready = true
			just_jumped = true
		
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var input_strength := input_dir.length()
		
		if input_dir.is_equal_approx(Vector2.ZERO) and not stopped:
			stopped = true
		elif not input_dir.is_equal_approx(Vector2.ZERO) and stopped:
			stopped = false
		
		var direction : Vector3 = (cam_hinge_h.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
		var body_face_angle = direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
		if knockback:
			print("knockback")
			velocity = knockback_direction * knockback_strength
			knockback = false
		if direction and not falling:
			velocity.x = lerp(velocity.x, direction.x * 
												SPEED * 
												mode_speed_multiplier, 0.1)
			velocity.z = lerp(velocity.z, direction.z * 
												SPEED * 
												mode_speed_multiplier, 0.1)
			animation_player.current_animation = running_animation
			rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
			var goofy_run = remap(velocity.length(), 0.0, SPEED * 
															mode_speed_multiplier, 0.0, 1.0)
			goofy_run = clamp(goofy_run, 0.0, 1.0)
			goofy_run = 1.0 - goofy_run
			goofy_run += 1.0
			animation_player.speed_scale = RUN_SPEED * slipping_animation_multiplier
			#animation_player.speed_scale = (goofy_run * 
										#slipping_animation_multiplier * 
										#mode_speed_multiplier)
		elif falling:
			velocity.x = lerp(velocity.x, direction.x * 
												SPEED * 
												mode_speed_multiplier, 0.01)
			velocity.z = lerp(velocity.z, direction.z * 
												SPEED * 
												mode_speed_multiplier, 0.01)
			animation_player.current_animation = "RESET"
			if not stopped:
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.01)
			animation_player.speed_scale = 1.0
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.3)
			velocity.z = lerp(velocity.z, 0.0, 0.3)
			animation_player.current_animation = "RESET"
		
		move_and_slide()
	else:
		if player_node.global_position.distance_squared_to(global_position) > ACTIVITY_RANGE and not player_position_known:
			pass
		else:
		#region player detection
			if player_node and not stop_and_look:
				var cast_target = player_cast.to_local(player_node.global_position).normalized()
				if looking_for_player:
					cast_target = cast_target * ACTIVE_RANGE
				elif cast_target.dot(Vector3.MODEL_REAR) <= 0.0:
					cast_target = cast_target * BEHIND_RANGE
				else:
					cast_target = cast_target * DETECT_RANGE
				player_cast.target_position = cast_target
				
				if player_cast.is_colliding():
					var collider : Object = player_cast.get_collider()
					if collider.has_meta("player"):
						search_timer.start()
						player_position_known = true
						last_player_position = player_node.global_position
						nav_target_pos = last_player_position
						navigation_agent_3d.target_position = last_player_position
						var dist2target = navigation_agent_3d.distance_to_target()
					else:
						if not looking_for_player:
							player_position_known = false
				else:
					if not looking_for_player:
						player_position_known = false
		#endregion
			
		#region jump and fall
			if not is_on_floor():
				falling = true
				falling_velocity = velocity.y
				velocity.y -= gravity * delta
			else:
				if jump_cast.is_colliding():
					velocity.y = JUMP_VELOCITY
				if slippery_cast.is_colliding():
					slipping = true
				else:
					slipping = false
				if falling:
					falling = false
					#if falling_velocity <= FALL_DAMAGE_VELOCITY:
						#fall_damaged = true
						#animation_player.current_animation = "splits"
						#animation_player.speed_scale = 2.0
		#endregion
			
		#region movement
			var next_path_point: Vector3
			if global.nav_baked:
				next_path_point = navigation_agent_3d.get_next_path_position()
			else:
				next_path_point = global_position
			
			var input_vec3 := Vector3(next_path_point - global_position)
			var input_dir := Vector2(input_vec3.x, input_vec3.z)
			var input_strength := input_dir.length()
			
			if input_dir.is_equal_approx(Vector2.ZERO) and not stopped:
				stopped = true
			elif not input_dir.is_equal_approx(Vector2.ZERO) and stopped:
				stopped = false
			
			var direction : Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
			var body_face_angle = direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
			
			#if death_queued:
				#velocity.x = lerp(velocity.x, 0.0, 0.3)
				#velocity.z = lerp(velocity.z, 0.0, 0.3)
				#animation_player.current_animation = "death"
			#elif knockback:
				#print("knockback")
				#velocity = knockback_direction * knockback_strength
				#knockback = false
			#elif damaged:
				#velocity.x = lerp(velocity.x, 0.0, 0.1)
				#velocity.z = lerp(velocity.z, 0.0, 0.1)
				#animation_player.current_animation = "damaged"
				#animation_player.speed_scale = 1.0
			if stop_and_look:
				velocity.x = lerp(velocity.x, 0.0, 0.3)
				velocity.z = lerp(velocity.z, 0.0, 0.3)
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.2)
				animation_player.current_animation = "alerted"
				animation_player.speed_scale = 1.0
			elif direction:
				velocity.x = lerp(velocity.x, direction.x * SPEED, 0.1)
				velocity.z = lerp(velocity.z, direction.z * SPEED, 0.1)
				animation_player.current_animation = running_animation
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
				animation_player.speed_scale = RUN_SPEED * slipping_animation_multiplier
			elif falling:
				velocity.x = lerp(velocity.x, direction.x * SPEED, 0.01)
				velocity.z = lerp(velocity.z, direction.z * SPEED, 0.01)
				if not stopped:
					rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.01)
				animation_player.speed_scale = 4.0
			else:
				velocity.x = lerp(velocity.x, 0.0, 0.3)
				velocity.z = lerp(velocity.z, 0.0, 0.3)
			move_and_slide()
		#endregion


func _on_global_player_node_changed(value):
	if player_node_queued:
		player_node_queued = false
		player_node = value


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "alerted":
		stop_and_look = false
	elif anim_name == "damaged":
		damaged = false
		if health <= 0.0:
			death_queued = true
		elif not looking_for_player:
			looking_for_player = true
	elif anim_name == "death":
		queue_free()


func _on_search_timer_timeout():
	print("search timer timeout")
	looking_for_player = false


func _on_navigation_agent_3d_waypoint_reached(details):
	waypoint_stuck_counter = 0.0


func _on_nav_timer_timeout():
	can_nav = true


func _on_navigation_agent_3d_target_reached():
	if not stop_and_look: # work on this
		patrol_idx += 1
		if patrol_idx >= patrol_zone.get_children().size():
			patrol_idx = 0
		nav_target_pos = patrol_zone.get_children()[patrol_idx].global_position
		navigation_agent_3d.target_position = nav_target_pos


func _on_in_pot_area_body_entered(body):
	if body.is_in_group("player"):
		body.not_in_control = true
		body.x_form_ref = x_form_pot
		player_in_control = true


func _on_bounce_timer_timeout():
	double_jump_ready = false


func _on_control_timer_timeout():
	in_pot_area.monitoring = true


func _on_ui_gui_input(event):
	if event is InputEventMouseMotion and player_in_control:
		rot_h -= event.relative.x * SENSITIVITY * global.sensitivity_multiplier
		rot_v -= event.relative.y * SENSITIVITY * global.sensitivity_multiplier
