extends Area3D


@export var knockback_strength := 1.0
@onready var knock_start = $KnockStart


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body.has_meta("playerball"):
		body = body.get_parent()
	if body.is_in_group("knockbackable"):
		body.knockback_strength = knockback_strength
		var dir = knock_start.global_position.direction_to(body.knockback_reciever.global_position)
		body.knockback_direction = dir.normalized()
		body.knockback = true
