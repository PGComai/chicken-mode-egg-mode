extends CharacterBody3D

signal sprinting(value)
signal newshoes(value)
signal newhat(value)
signal ui_msg(message)
signal camera_shake(zero_to_one)

const SPEED = 10.0
const JUMP_VELOCITY = 7.0
const SENSITIVITY = 0.003
const EGG_RUN_SPEED_SCALE = 2.0
const SPRINT_MULTIPLIER = 1.5
const FALL_DAMAGE_VELOCITY = -18.0
const WIND_GUST = preload("res://scenes/wind_gust.tscn")
const MAX_HEALTH = 15.0
const ROLL_DAMAGE = 1.0
const ROLL_KNOCKBACK_STRENGTH = 10.0

@export var left_foot_back := false
@export var damaged := false:
	set(value):
		damaged = value
		_eggshell_effect()
@export var egg_mode := true:
	set(value):
		egg_mode = value
		_mode_switch()
@export var spawn_node: Node3D


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
@onready var attack_origin = $CamHingeH/CamHingeV/AttackOrigin
@onready var knockback_reciever = $KnockbackReciever
@onready var gust_timer = $GustTimer
@onready var tall_collision = $TallCollision
@onready var roll_body = $RollBody
@onready var roll_dust_launch = $RollDustLaunch
@onready var roll_dust = $RollDust
@onready var roll_boom = $RollBoom
@onready var before_roller = $"../Player Spawns/Before Roller"
@onready var start = $"../Player Spawns/Start"
@onready var before_stairs = $"../Player Spawns/Before Stairs"
@onready var crack_heal_timer = $CrackHealTimer
@onready var shoe_look = $ShoeLook
@onready var new_shoes_timer = $NewShoesTimer
@onready var fancy_boot = $Skeleton3D/FootL/FancyBoot
@onready var fancy_boot_2 = $Skeleton3D/FootR/FancyBoot2
@onready var question_mark_shoes = $"../Landing/ShoeUnlocker/QuestionMarkShoes"
@onready var egg_hat = $Skeleton3D/Egg/EggMesh/EggHat
@onready var head_hat = $Skeleton3D/Head/HeadMesh/HeadHat
@onready var question_mark_hat = $"../Landing/HatUnlocker/QuestionMarkHat"
@onready var hat_look = $HatLook
@onready var shadow_cast = $ShadowCast


var health := 15.0:
	set(value):
		health = value
		if health <= 0.0:
			_die()
var knockback := false
var knockback_direction := Vector3.ZERO
var knockback_strength := 1.0
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
		if falling and not value:
			print("starting bounce timer")
			bounce_timer.start()
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
var can_gust := true
var fire_wind_gust := false:
	set(value):
		if value:
			_fire_wind_gust()
var double_jump_ready := false
var rolling := false:
	set(value):
		if value != rolling:
			rolling = value
			roll_body.position = Vector3(0.0, 0.5, 0.0)
			roll_body.top_level = rolling
			if not rolling:
				roll_body.process_mode = Node.PROCESS_MODE_DISABLED
			else:
				roll_body.process_mode = Node.PROCESS_MODE_INHERIT
			tall_collision.disabled = rolling
var roll_intro := false
var roll_windup := 0.0:
	set(value):
		roll_windup = clamp(value, 0.0, 3.0)
var roll_timeout := 0.0
var roll_sent := false
var dead := false


var shoes_unlocked := false:
	set(value):
		shoes_unlocked = value
		fancy_boot.visible = shoes_unlocked
		fancy_boot_2.visible = shoes_unlocked
var new_shoes := false:
	set(value):
		new_shoes = value
		emit_signal("newshoes", new_shoes)
		if new_shoes:
			shoes_unlocked = true
			new_shoes_timer.start()
var hat_unlocked := false:
	set(value):
		hat_unlocked = value
		egg_hat.visible = hat_unlocked
		head_hat.visible = hat_unlocked
var new_hat := false:
	set(value):
		new_hat = value
		emit_signal("newhat", new_hat)
		if new_hat:
			hat_unlocked = true
			new_shoes_timer.start()
var not_in_control := false:
	set(value):
		not_in_control = value
		shadow_cast.enabled = not not_in_control
		if not not_in_control:
			global.player_node = self
			global.cam_x_form_node = cam_x_form
var x_form_ref: Node3D


func _ready():
	if spawn_node:
		global_position = spawn_node.global_position
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
	if event is InputEventMouseMotion and not not_in_control:
		rot_h -= event.relative.x * SENSITIVITY
		rot_v -= event.relative.y * SENSITIVITY


func _process(delta):
	if not not_in_control:
		
		cam_hinge_h.rotation.y = rot_h
		cam_hinge_v.rotation.x = rot_v
		
		if Input.is_action_just_pressed("modeswitch") and not (rolling or roll_intro):
			egg_mode = not egg_mode
		
		cam_hinge_h.global_position = global_position
		foot_step_l.pitch_scale = randfn(1.0, 0.02)
		foot_step_r.pitch_scale = randfn(1.0, 0.02)
		
		
		if rolling and roll_body.get_colliding_bodies().size() > 0:
			roll_dust.emitting = true
			roll_dust_launch.emitting = false
		elif roll_intro:
			roll_dust.emitting = false
			roll_dust_launch.emitting = true
		else:
			roll_dust.emitting = false
			roll_dust_launch.emitting = false
		
		
		if not fall_damaged:
			if (Input.is_action_just_pressed("attack") and
					not attacking and
					not egg_mode and
					can_gust):
				attacking = true
				can_gust = false
				gust_timer.start()
			elif Input.is_action_pressed("attack") and egg_mode and not rolling:
				roll_windup += delta * 1.0
				if roll_windup > 0.25:
					roll_intro = true
			
			if Input.is_action_just_released("attack") and roll_windup > 0.25 and egg_mode:
				rolling = true
				print("rolling!")
				roll_intro = false
	else:
		global_transform = x_form_ref.global_transform


func _physics_process(delta):
	if Input.is_action_just_pressed("respawn"):
		velocity = Vector3.ZERO
		knockback = false
		roll_intro = false
		rolling = false
		attacking = false
		falling = false
		global_position = spawn_node.global_position
	
	if not not_in_control:
		var sprint := 1.0
		
		if not is_on_floor() and not rolling:
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
					emit_signal("camera_shake", 0.2)
		
		if not fall_damaged:
			
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
				emit_signal("sprinting", false)
			elif not input_dir.is_equal_approx(Vector2.ZERO) and stopped:
				stopped = false
			
			var direction : Vector3 = (cam_hinge_h.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
			var body_face_angle = direction.signed_angle_to(Vector3.FORWARD, Vector3.UP)
			if new_hat or new_shoes:
				velocity.x = lerp(velocity.x, 0.0, 0.3)
				velocity.z = lerp(velocity.z, 0.0, 0.3)
				animation_player.current_animation = "RESET"
			elif knockback:
				print("knockback")
				if not rolling:
					velocity = knockback_direction * knockback_strength
				else:
					roll_body.apply_central_impulse(knockback_direction * knockback_strength * 1.0)
				knockback = false
			elif roll_intro:
				velocity.x = lerp(velocity.x, 0.0, 0.3)
				velocity.z = lerp(velocity.z, 0.0, 0.3)
				animation_player.current_animation = "eggroll"
				body_face_angle = cam_hinge_h.basis.z.signed_angle_to(Vector3.BACK, Vector3.UP)
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
				animation_player.speed_scale = max(ceil(roll_windup), 0.5)
			elif rolling:
				if not roll_sent:
					roll_body.apply_central_impulse(-cam_hinge_h.transform.basis.z * ceil(roll_windup) * 10.0)
					roll_sent = true
					roll_windup = 0.0
					roll_boom.emitting = true
				else:
					roll_body.apply_central_force(direction * delta * 200.0)
				animation_player.current_animation = "eggroll"
				global_position = roll_body.global_position - Vector3(0.0, 0.5, 0.0)
				body_face_angle = roll_body.linear_velocity.signed_angle_to(Vector3.FORWARD, Vector3.UP)
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.05)
				if roll_body.linear_velocity.length_squared() < 1.0:
					roll_timeout += delta
					if roll_timeout > 1.0:
						rolling = false
						roll_timeout = 0.0
						roll_sent = false
			elif direction and not falling and not attacking:
				velocity.x = lerp(velocity.x, direction.x * 
													SPEED * 
													sprint * 
													mode_speed_multiplier, 0.1)
				velocity.z = lerp(velocity.z, direction.z * 
													SPEED * 
													sprint * 
													mode_speed_multiplier, 0.1)
				animation_player.current_animation = running_animation
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.1)
				var goofy_run = remap(velocity.length(), 0.0, SPEED * 
																sprint * 
																mode_speed_multiplier, 0.0, 1.0)
				goofy_run = clamp(goofy_run, 0.0, 1.0)
				goofy_run = 1.0 - goofy_run
				goofy_run += 1.0
				animation_player.speed_scale = (goofy_run * 
											EGG_RUN_SPEED_SCALE * 
											sprint * 
											slipping_animation_multiplier * 
											mode_speed_multiplier)
			elif attacking:
				body_face_angle = cam_hinge_h.transform.basis.z.signed_angle_to(Vector3.BACK, Vector3.UP)
				rotation.y = lerp_angle(rotation.y, -body_face_angle, 0.2)
				if not falling:
					velocity.x = lerp(velocity.x, 0.0, 0.3)
					velocity.z = lerp(velocity.z, 0.0, 0.3)
				else:
					velocity.x = lerp(velocity.x, direction.x * 
														SPEED * 
														sprint * 
														mode_speed_multiplier, 0.01)
					velocity.z = lerp(velocity.z, direction.z * 
														SPEED * 
														sprint * 
														mode_speed_multiplier, 0.01)
				animation_player.current_animation = "chickengust"
				animation_player.speed_scale = 3.0
			elif falling:
				velocity.x = lerp(velocity.x, direction.x * 
													SPEED * 
													sprint * 
													mode_speed_multiplier, 0.01)
				velocity.z = lerp(velocity.z, direction.z * 
													SPEED * 
													sprint * 
													mode_speed_multiplier, 0.01)
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
			else:
				velocity.x = lerp(velocity.x, 0.0, 0.3)
				velocity.z = lerp(velocity.z, 0.0, 0.3)
				animation_player.current_animation = "RESET"
			
			move_and_slide()


func _die():
	knockback = false
	roll_intro = false
	rolling = false
	attacking = false
	global_position = spawn_node.global_position
	health = MAX_HEALTH


func _fire_wind_gust():
	var wg = WIND_GUST.instantiate()
	wg.velocity = -attack_origin.global_transform.basis.z
	add_child(wg)
	wg.global_transform = attack_origin.global_transform


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
			crack_heal_timer.start()
		else:
			material.detail_enabled = false


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "splits":
		fall_damaged = false
	elif anim_name == "chickengust":
		attacking = false
		fire_wind_gust = true


func _on_gust_timer_timeout():
	can_gust = true


func _on_bounce_timer_timeout():
	double_jump_ready = false


func _on_roll_body_body_entered(body):
	if not body.is_in_group("player"):
		var damage_multiplier = roll_body.linear_velocity.length_squared()
		damage_multiplier = clamp(damage_multiplier, 1.0, 5.0)
		if body.is_in_group("damageable"):
			print("damage")
			body.health -= ROLL_DAMAGE * damage_multiplier
		if body.is_in_group("knockbackable"):
			body.knockback_strength = ROLL_KNOCKBACK_STRENGTH * damage_multiplier
			var dir = global_position.direction_to(body.knockback_reciever.global_position)
			body.knockback_direction = Vector3(dir.x, 1.0, dir.y).normalized()
			body.knockback = true


func _on_start_area_body_entered(body):
	if body == self:
		spawn_node = start


func _on_roller_area_body_entered(body):
	if body == self:
		spawn_node = before_roller


func _on_before_stairs_area_body_entered(body):
	if body == self:
		spawn_node = before_stairs


func _on_crack_heal_timer_timeout():
	damaged = false


func _on_new_shoes_timer_timeout():
	new_shoes = false
	new_hat = false


func _on_shoe_unlocker_body_entered(body):
	if body == self and not shoes_unlocked:
		question_mark_shoes.visible = false
		new_shoes = true
		emit_signal("ui_msg", "New Shoes Unlocked!")


func _on_defeat_ganon_timeout():
	emit_signal("ui_msg", "Defeat Ganon")


func _on_hat_unlocker_body_entered(body):
	if body == self and not hat_unlocked:
		question_mark_hat.visible = false
		new_hat = true
		emit_signal("ui_msg", "New Hat Unlocked!")
