extends AnimatableBody3D


@export var speed := 1.0
@export var clockwise := true

var cw_factor := 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	if not clockwise:
		cw_factor = -1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotation.z -= delta * speed * cw_factor
