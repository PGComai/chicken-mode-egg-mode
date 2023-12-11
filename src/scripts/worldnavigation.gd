extends NavigationRegion3D


var global: Node
var mesh_baked := false
@onready var timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	#timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bake_finished():
	print("bake finished")
	global.nav_baked = true
	#mesh_baked = true
	#timer.start()


func _on_timer_timeout():
	pass
	#print("timer finished")
	#if mesh_baked:
		#global.nav_baked = true
	#else:
		#bake_navigation_mesh()
