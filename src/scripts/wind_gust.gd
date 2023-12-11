extends Node3D


const SPEED = 0.3
const DAMAGE = 4.0
const WIND_GUST_IMPACT = preload("res://scenes/wind_gust_impact.tscn")

var velocity := Vector3.ZERO
var done := false

@onready var gpu_particles_3d = $GPUParticles3D
@onready var timer_2 = $Timer2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_position += velocity * SPEED


func _on_timer_timeout():
	if not done:
		done = true
		velocity = Vector3.ZERO
		gpu_particles_3d.emitting = false
		timer_2.start()
		_finish()


func _on_area_3d_body_entered(body):
	if body.is_in_group("damageable"):
		pass
	else:
		done = true
		velocity = Vector3.ZERO
		gpu_particles_3d.emitting = false
		timer_2.start()
		_finish()


func _finish():
	var wgi = WIND_GUST_IMPACT.instantiate()
	get_tree().root.add_child(wgi)
	wgi.global_transform = global_transform


func _on_timer_2_timeout():
	queue_free()


func _on_area_3d_2_body_entered(body):
	if body.is_in_group("damageable") and not done:
		print("damage")
		body.health -= DAMAGE
