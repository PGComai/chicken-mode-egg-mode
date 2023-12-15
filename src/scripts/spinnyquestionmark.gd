extends MeshInstance3D

var bob_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation.y += delta
	bob_time += delta
	position.y = sin(bob_time) * 0.05
