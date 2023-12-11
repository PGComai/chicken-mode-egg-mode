extends BoneAttachment3D


const FOOT_POOF = preload("res://scenes/foot_poof.tscn")

@export var poof := false:
	set(value):
		if value:
			_make_poof()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _make_poof():
	if is_inside_tree():
		var fp = FOOT_POOF.instantiate()
		add_child(fp)
		fp.global_position = global_position
		fp.emitting = true
