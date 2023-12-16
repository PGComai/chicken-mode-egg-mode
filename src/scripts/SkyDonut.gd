extends AnimatableBody3D

var count := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	count += delta * 0.0001
	rotate_z(delta * 0.2)
	#rotate_y(sin(count) * 10.0)
	#rotate_x(cos(count * 2.0) * 10.0)
	#orthonormalize()
