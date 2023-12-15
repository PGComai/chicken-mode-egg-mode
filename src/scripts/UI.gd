extends Control


@onready var msg_fade = $MsgFade
@onready var msg = $Msg


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_msg_fade_timeout():
	msg.visible = false


func _on_chicken_egg_ui_msg(message):
	msg.text = message
	msg.visible = true
	msg_fade.start()
