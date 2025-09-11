extends "res://scripts/vehicle_base.gd"


export (NodePath) onready var FrontWheel = get_node(FrontWheel) as MeshInstance
export (NodePath) onready var BackWheel = get_node(BackWheel) as MeshInstance
export (NodePath) onready var Frame = get_node(Frame) as MeshInstance

var e #stores the value the wheels should rotate by

var mat = load("res://assets/vehicles/Material.material")
var mat2 = load("res://assets/vehicles/Material2.material")

func _ready():
	e = 0
	sound_up = load("res://assets/sounds/motorbike up2.wav")
	sound_down = load("res://assets/sounds/motorbike down.wav")
	
	#set the correct materials
	BackWheel.set_surface_material(0,mat)
	FrontWheel.set_surface_material(0,mat)
	Frame.set_surface_material(0,mat2)
	

func _process(delta):
	#rotate bike mesh
	if ball.linear_velocity.length() > turn_stop_limit:
		var t = rotate_input * ball.linear_velocity.length() / mesh_turn_amount

		t = clamp(t, -0.75, 0.75)
		$MeshNode/nyozuki.rotation.z = lerp($MeshNode/nyozuki.rotation.z, t, 2 * delta)


	#rotate the wheels
	if speed_input > 0:
		e =  ball.linear_velocity.length() / 30
	elif speed_input < 0:
		e = -1 * ball.linear_velocity.length() / 30
	elif speed_input == 0:
		e = 0
	
	FrontWheel.rotate_x(e)
	BackWheel.rotate_x(e)
