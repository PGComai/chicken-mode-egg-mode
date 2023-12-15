extends AnimatableBody3D


@export var direction := Vector3.FORWARD
@export var distance := 5.0
@export var offset := 0.0
@export var speed := 1.0


var start_pos: Vector3
var end_pos: Vector3
var count := 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = global_position
	end_pos = start_pos + (direction * distance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	count += delta * speed
	global_position = start_pos.lerp(end_pos, pingpong(count + offset, 1.0))
