extends "res://scripts/vehicle_base.gd"


export (NodePath) onready var Frame = get_node(Frame) as MeshInstance
export (NodePath) onready var FrontLeftWheel = get_node(FrontLeftWheel) as MeshInstance
export (NodePath) onready var FrontRightWheel = get_node(FrontRightWheel) as MeshInstance
export (NodePath) onready var BackRightWheel = get_node(BackRightWheel) as MeshInstance
export (NodePath) onready var BackLeftWheel = get_node(BackLeftWheel) as MeshInstance
export (NodePath) onready var AnimPlayer = get_node(AnimPlayer) as AnimationPlayer

var e #holds the amount the wheels have turnt
var drift_switch #helps toggle between drifting states
var d #holds direction of drift for what stop drift animation to play

var l_dust = load("res://scenes/particles/dust.tscn").instance()
var r_dust = load("res://scenes/particles/dust.tscn").instance()

var mat = load("res://assets/vehicles/Material.material")


func _ready():
	
	l_dust.emitting = false
	r_dust.emitting = false
#	l_spark.emitting = false
#	r_spark.emitting = false
	
	e = 0
	drift_switch = false
	sound_up = preload("res://assets/sounds/car up.wav")
	sound_down = preload("res://assets/sounds/car down.wav")
	
	#add dust particles
	BackRightWheel.add_child(r_dust)
	BackLeftWheel.add_child(l_dust)
	
	Frame.set_surface_material(0,mat)
	BackLeftWheel.set_surface_material(0,mat)
	BackRightWheel.set_surface_material(0,mat)
	FrontLeftWheel.set_surface_material(0,mat)
	FrontRightWheel.set_surface_material(0,mat)
	
func _process(delta):
	
#	#rotate front wheels (this doesnt work at all lol)
#	if FrontLeftWheel.rotation.y > -45 or FrontLeftWheel.rotation.y < 45:
#		FrontLeftWheel.rotate_y(rad2deg(rotate_input * 45))
	
	#rotate back wheels
	if speed_input > 0:
		e = 1
	elif speed_input < 0:
		e = -1
	
	BackLeftWheel.rotate_x(e *  ball.linear_velocity.length() / 30)
	BackRightWheel.rotate_x(e *  ball.linear_velocity.length() / 30)
	FrontLeftWheel.rotate_x(e *  ball.linear_velocity.length() / 30)
	FrontRightWheel.rotate_x(e *  ball.linear_velocity.length() / 30)


	#play the correct drifting animaitons
	


#	if drifting == true and rot_time != 0:
#		if drift_switch == false:
#			if rotate_input > 0:
#				AnimPlayer.play("start_drift_left")
#				d = -1
#			elif rotate_input < 0:
#				AnimPlayer.play("start_drift_right")
#				d = 1
#		drift_switch = true
#	if drifting == false:
#		if drift_switch == true:
#			if d == -1 and rot_time == 0:
#				AnimPlayer.play("stop_drift_left")
#			elif d == 1 and rot_time == 0:
#				AnimPlayer.play("stop_drift_right")
#		drift_switch = false


	if ball.linear_velocity.length() > 3 and rotate_input !=0 and speed_input > 0:
		l_dust.emitting = true
		r_dust.emitting = true
		var p = ball.linear_velocity.length() / 20
		var p3 = Vector3(p,p,p)
		l_dust.scale = p3
		r_dust.scale = p3
		
		rpc("showhide_dust", true, p3)
		
		
	else:
		l_dust.emitting = false
		r_dust.emitting = false
		rpc("showhide_dust", false, 0)


func start_drift_anim():
	if drift_switch == false:
		drift_switch = true
		if driftrot == 1:
			AnimPlayer.play("start_drift_left")
		elif driftrot == -1:
			AnimPlayer.play("start_drift_right")

func stop_drift_anim():
	if drift_switch == true:
		drift_switch = false
		if driftrot == 1:
			AnimPlayer.play("stop_drift_left")
		elif driftrot == -1:
			AnimPlayer.play("stop_drift_right")



remote func showhide_dust(b, p):
	if b == true:
		l_dust.emitting = true
		r_dust.emitting = true
		l_dust.scale = p
		r_dust.scale = p
	elif b == false:
		l_dust.emitting = false
		r_dust.emitting = false
