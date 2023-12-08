extends Node


signal camxform_changed(value)
signal player_node_changed(value)


var cam_x_form_node: Node3D:
	set(value):
		cam_x_form_node = value
		emit_signal("camxform_changed", value)
var player_node: CharacterBody3D:
	set(value):
		player_node = value
		emit_signal("player_node_changed", value)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
