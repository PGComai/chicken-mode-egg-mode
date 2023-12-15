extends Control


const RES_OPTIONS = [Vector2i(1280, 720),
					Vector2i(1920, 1080),
					Vector2i(2560, 1440),
					Vector2i(3840, 2160)]
const WIN_OPTIONS = [DisplayServer.WINDOW_MODE_WINDOWED,
					DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


@onready var msg_fade = $MsgFade
@onready var msg = $Msg
@onready var color_rect = $ColorRect
@onready var pause_menu = $PauseMenu
@onready var window_option = $PauseMenu/MenuVBox/WindowOption
@onready var resolution_option = $PauseMenu/MenuVBox/ResolutionOption
@onready var confirm_display_timer = $ConfirmDisplayTimer
@onready var confirm_display = $PauseMenu/MenuVBox/ConfirmDisplay
@onready var confirm_label = $PauseMenu/MenuVBox/ConfirmLabel
@onready var texture_rect = $TextureRect
@onready var sub_viewport = $"../SubViewport"


var old_window_mode: DisplayServer.WindowMode
var old_res: Vector2i

var display_settings_confirmed := false
var counting_down := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		color_rect.visible = get_tree().paused
		pause_menu.visible = get_tree().paused
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_msg_fade_timeout():
	msg.visible = false


func _on_chicken_egg_ui_msg(message):
	msg.text = message
	msg.visible = true
	msg_fade.start()


func _on_apply_display_button_up():
	old_window_mode = DisplayServer.window_get_mode()
	old_res = DisplayServer.window_get_size()
	var selected_win : DisplayServer.WindowMode = WIN_OPTIONS[window_option.selected]
	var selected_res : Vector2i = RES_OPTIONS[resolution_option.selected]
	print(selected_res)
	print(selected_win)
	DisplayServer.window_set_mode(selected_win)
	sub_viewport.size = selected_res
	DisplayServer.window_set_size(selected_res)
	confirm_display.visible = true
	confirm_display_timer.start()
	counting_down = true
	display_settings_confirmed = false
	confirm_display.visible = true
	confirm_label.visible = true


func _on_resume_button_up():
	get_tree().paused = not get_tree().paused
	color_rect.visible = get_tree().paused
	pause_menu.visible = get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_quit_button_up():
	get_tree().quit()


func _on_confirm_display_button_up():
	display_settings_confirmed = true
	confirm_display.visible = false
	confirm_label.visible = false


func _on_confirm_display_timer_timeout():
	if not display_settings_confirmed:
		DisplayServer.window_set_mode(old_window_mode)
		sub_viewport.size = old_res
		DisplayServer.window_set_size(old_res)
		confirm_display.visible = false
		confirm_label.visible = false
