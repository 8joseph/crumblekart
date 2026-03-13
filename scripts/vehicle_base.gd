# this script is inherited by all vehicles, and has all of the base features for a vehicle to work, including the networking.
extends Node

#NODE REFS
export (NodePath) onready var ball = get_node(ball) as RigidBody
export (NodePath) onready var car_mesh = get_node(car_mesh) as Spatial
export (NodePath) onready var ground_ray = get_node(ground_ray) as RayCast
export (NodePath) onready var body_mesh = get_node(body_mesh) as MeshInstance
export (NodePath) onready var mesh_node = get_node(mesh_node) as Spatial
export (NodePath) onready var camera = get_node(camera) as InterpolatedCamera
export (NodePath) onready var timer = get_node(timer) as Timer
export (NodePath) onready var audioplayer = get_node(audioplayer) as AudioStreamPlayer3D
export (NodePath) onready var character_pos = get_node(character_pos) as Position3D
export (NodePath) onready var back_right_wheel = get_node(back_right_wheel) as Position3D
export (NodePath) onready var back_left_wheel = get_node(back_left_wheel) as Position3D
export (NodePath) onready var boost_spot = get_node(boost_spot) as Position3D
export (NodePath) onready var back_cam_target = get_node(back_cam_target) as Position3D
export (NodePath) onready var front_cam_target = get_node(front_cam_target) as Position3D

#where to base car mesh relative to the sphere
export var sphere_offset = Vector3()
#offset for where to place the name tag relative to sphere
var nametag_offset = Vector3(0, 0.5, 0)
#engine power
export var acceleration = 50
#turn amout
export var steering = 18
#turn amount when drifting, used as a multiplier
export var steering_drift = 20
#steering variable which is actually used
var usteer = 0.0
#how quickly car turns
export var turn_speed = 2.5
#how quickly the car turns whilst drifting
export var drift_turn_speed = 4
#the car doesnt turn below this speed
export var turn_stop_limit = 0.75
#amount the mesh of the vehicle should turn
export var mesh_turn_amount = 6

#input variables
#they are puppet as the player broadcasts them to all others, in order to allow things like the wheels to move
puppet var speed_input = 0 # NOT CURRENTLY USED
puppet var rotate_input = 0
puppet var drift_input = 0

#network variables
var net_rotation = Vector3()
var net_transform
var net_translation = Vector3()


var nametag = null

var can_move 

var drifting # determines whether or not the player can drift 
var driftrot = 0 # holds the rotation input at the time the drift is initiated
var switch_drift = false # used to make sure the start drift animaition only plays once
var drift_time = 0 # counts the time spent drifting in order to set the correct boost
var drift_boost_amount #holds how much the vehicle should be boosted by after a drift

var used_turn_speed = 0

var speed_lines = preload("res://scenes/misc/Speed Lines.tscn")

var character # this is the character which drives the vehicle

var vehicle_name # stores the name of the vehicle used

var hud = preload("res://scenes/ui/HUD.tscn").instance()

var rot_time # counts the frames after no input has been recieved, used when player changes rotation during drift

#sound location variables
var sound_up
var sound_down
var soundswitch

#audio player variables
var drift_sound = AudioStreamPlayer3D.new()
var spark_sound = AudioStreamPlayer3D.new()
var boost_sound = AudioStreamPlayer3D.new()

var boost_time = 0
var boost_amount = 0



#instance the spark particles
var l_spark = preload("res://scenes/particles/sparks.tscn").instance()
var r_spark = preload("res://scenes/particles/sparks.tscn").instance()

var l_spark2 = preload("res://scenes/particles/sparks_changed.tscn").instance()
var r_spark2 = preload("res://scenes/particles/sparks_changed.tscn").instance()
#instance the drift_dust particles
var l_drift_dust = load("res://scenes/particles/drift_dust.tscn").instance()
var r_drift_dust = load("res://scenes/particles/drift_dust.tscn").instance()
#instance the boost particle
var boost_p = load("res://scenes/particles/boost fire.tscn").instance()


func _ready():
	ground_ray.add_exception(ball)
	
	can_move = true
	
	#timer config
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.wait_time = 0.02
	timer.autostart = true
	
	#connect stop movement signal, called in map_base.gd
	Global.connect("toggle_movement", self, "_toggle_movement")
	#let the player move
	can_move = false
	
	#connect speed pad collison signal, this is sent to every car but boost will only happen on one
	Global.connect("speed_pad_hit", self, "speed_pad_detected")
	
	drifting = false
	drift_time = 0
	drift_boost_amount = 0

	#cam config
	camera.far = 1000
	camera.current = is_network_master()
	
	var pos = 0
	
	audioplayer.playing = true
	soundswitch = false
	
	#load + place the name tag
	if !is_network_master():
		nametag = preload("res://scenes/misc/NameTag.tscn").instance()
		var id = int(name)
		nametag.player_name = Network.player_info[id].name
		add_child(nametag)
	
	#add speed lines
	if is_network_master():
		var x = speed_lines.instance()
		get_parent().add_child(x)
	
	#add the character model
	var load_path
	var c = Network.player_info[int(name)].character
	#find the correct load path
	for i  in Global.character_list:
		if Global.character_list[i].name == c:
			load_path = Global.character_list[i].location
			break
	#add the correct character scene in
	character = load(load_path).instance()
	character_pos.add_child(character)

	#add the spark particles
	back_left_wheel.add_child(l_spark)
	back_right_wheel.add_child(r_spark)
	back_left_wheel.add_child(l_spark2)
	back_right_wheel.add_child(r_spark2)
	
	l_spark.emitting = false
	r_spark.emitting = false
	#add the drift dust particles
	back_left_wheel.add_child(l_drift_dust)
	back_right_wheel.add_child(r_drift_dust)
	l_drift_dust.emitting = false
	r_drift_dust.emitting = false
	
	#add the boost particle
	boost_spot.add_child(boost_p)
	boost_p.emitting = false
	
	#load the hud
	if is_network_master():
		get_parent().add_child(hud)
	
	#set the usteer value to the base steering value
	usteer = steering
	#set the turn speed value to the base turn speed
	used_turn_speed = turn_speed
	rot_time = 0
	switch_drift = false
	
	#add the drift sound player
	drift_sound = AudioStreamPlayer3D.new()
	boost_spot.add_child(drift_sound)
	drift_sound.stream = load('res://assets/sounds/drift.wav')
	drift_sound.attenuation_model = 3
	drift_sound.set_unit_db(7) 
	#add the spark sound audio player
	spark_sound = AudioStreamPlayer3D.new()
	boost_spot.add_child(spark_sound)
	spark_sound.stream = load('res://assets/sounds/spark.wav')
	spark_sound.attenuation_model = 3
	spark_sound.unit_db = 13
	#add the boost sound
	boost_sound = AudioStreamPlayer3D.new()
	boost_spot.add_child(boost_sound)
	boost_sound.stream = load('res://assets/sounds/boost.wav')
	boost_sound.attenuation_model = 3
	boost_sound.set_unit_db(10) 
	

func _physics_process(delta):
	#place car so its alligned with the sphere
	mesh_node.transform.origin = ball.transform.origin + sphere_offset
	#accelerate based on cars forward direction
	ball.add_central_force(-car_mesh.global_transform.basis.z * speed_input)
	#cant steer/accelerate if ur in the air!
	if not ground_ray.is_colliding():
		return
	
	if is_network_master() and can_move == true:
		#get accelerate / brake input 
		speed_input = 0
		speed_input += Input.get_action_strength("accelerate")
		speed_input -= Input.get_action_strength("brake")
		speed_input *= acceleration
		#get steering input
		rotate_input = 0
		rotate_input += Input.get_action_strength("steer_left")
		rotate_input -= Input.get_action_strength("steer_right")
		#get drift input
		drift_input = int(Input.is_action_pressed("drift"))
		
		
		#send the values collected to other players
		rset_unreliable("speed_input", speed_input)
		rset_unreliable("rotate_input", rotate_input)
		rset_unreliable("drift_input", drift_input)
		
	if drifting == true:
		tick_drift()
		


	#########  START / STOP DRIFT LOGIC #########
	#this is carried out on all machines, not just network master becasue it determines whether or not partcles / animations play
	#start a drift if needed
	if switch_drift == false and drift_input == 1 and rotate_input != 0:
		switch_drift = true
		start_drift()
	#end drift if needed
	if switch_drift == true and drift_input == 0:
		switch_drift = false
		stop_drift()
	#set rot_time to 20 whenever a there is a rotation_input
	if rotate_input != 0:
		rot_time = 20
	#use the rot_time in order to stop a drift if no rotate input is received
	if drift_input == 1 and rotate_input == 0 and switch_drift == true:
		if rot_time > 0:
			rot_time = rot_time - 1
		elif rot_time <= 0:
			stop_drift()
			switch_drift = false
		

	
	# set the rotate input to use the steering varaible
	if drifting == true:
		if driftrot == 1:
			rotate_input = clamp(rotate_input, 0, 1)
		elif driftrot == -1:
			rotate_input = clamp(rotate_input, -1, 0)
	rotate_input *= deg2rad(usteer)


	#rotate the car mesh to fit with the turning direction
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = mesh_node.global_transform.basis.rotated(mesh_node.global_transform.basis.y, rotate_input)
		mesh_node.global_transform.basis = mesh_node.global_transform.basis.slerp(new_basis, used_turn_speed * delta)
		mesh_node.global_transform = mesh_node.global_transform.orthonormalized()


	var n = ground_ray.get_collision_normal()
	var xform = align_with_y(car_mesh.global_transform, n.normalized())
	#car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 10 * delta)
	
	###yeahyeahyeah
	if !is_network_master():
		ball.translation = lerp(ball.translation, net_translation, delta * 3)
#		mesh_node.rotation = lerp(mesh_node.rotation, net_rotation, delta * 3)
		mesh_node.rotation = net_rotation
		
	
	
	#boost if that needs to happen
	
	boost_time = clamp(boost_time, 0, 40)
	
	if boost_time > 0:
		ball.add_central_force(-car_mesh.global_transform.basis.z * boost_amount)
		boost_time = boost_time - 1


func _process(delta):
	#place the name tag in correct position
	if !is_network_master():
		nametag.translation = ball.translation + nametag_offset
	
	if Input.is_action_just_pressed("menu"):
		if Network.amhost:
			rpc("_all_to_lobby")
			_all_to_lobby()
		else:
			rpc("_player_left", get_tree().get_network_unique_id())
			get_tree().change_scene("res://scenes/menu.tscn")
		
	#if the player is presseing the back cam button, change camera position
	if is_network_master():
		if Input.is_action_pressed("switch_cam"):
			camera.set_target(back_cam_target)
		else:
			camera.set_target(front_cam_target)
	

	if Input.is_action_just_pressed("debug") and is_network_master():
		if Network.local_player_info.name == 'joe' or Network.local_player_info.name == 'NullSense':
			boost(2)
			print('this is happening')
			print(Global.name)
		
	if Input.is_action_just_pressed("debug2"):
		Global.emit_signal("toggle_movement", true)
		
	if is_network_master():
		Global.local_player_speed = ball.linear_velocity.length()


	#sfx stuff
	if speed_input == 0 and soundswitch == false:
		audioplayer.stream = sound_down
		audioplayer.play()
		audioplayer.pitch_scale = 1
		soundswitch = true
	elif speed_input != 0 and soundswitch == true:
		audioplayer.stream = sound_up
		audioplayer.play()
		soundswitch = false
		audioplayer.pitch_scale = 1
	
	if audioplayer.pitch_scale < 1.7:
		audioplayer.pitch_scale += 0.01


	#update hud settings
	if is_network_master():
		hud.speed = ball.linear_velocity.length()
		hud.engine_power = speed_input
	
func start_drift():
	rot_time = 20
	driftrot = rotate_input
	start_drift_anim()
	drifting = true
	l_drift_dust.emitting = true
	r_drift_dust.emitting = true
	usteer = steering_drift
	used_turn_speed = drift_turn_speed
	
	drift_sound.play()
	drift_time = 0
	drift_boost_amount = 0



func stop_drift():
#	print("stopped drift")
	stop_drift_anim()
	drifting = false
	l_spark.emitting = false
	r_spark.emitting = false
	l_drift_dust.emitting = false
	r_drift_dust.emitting = false
	usteer = steering
	used_turn_speed = turn_speed

	drift_sound.stop()
	spark_sound.stop()
	
	if drift_boost_amount > 0:
		boost(drift_boost_amount)
	


# when drifring, this funciton is called every frame in order to count how long the vehicle had been drifting for and what to do accordingly
func tick_drift():
	drift_time = drift_time + 1
	
	if drift_time > 300:
		if drift_boost_amount < 3:
			l_spark.set_color(Color( 0.4, 0.2, 0.6, 1 ))
			r_spark.set_color(Color( 0.4, 0.2, 0.6, 1 ))
			l_spark2.set_color(Color( 0.4, 0.2, 0.6, 1 ))
			r_spark2.set_color(Color( 0.4, 0.2, 0.6, 1 ))
			
			l_spark2.emitting = true
			r_spark2.emitting = true


			drift_boost_amount = 3
			
			spark_sound.pitch_scale = 1.4
		
	elif drift_time > 200:
		if drift_boost_amount < 2:
		
			l_spark.set_color(Color( 1, 1, 0, 1 ))
			r_spark.set_color(Color( 1, 1, 0, 1 ))
			l_spark2.set_color(Color( 1, 1, 0, 1 ))
			r_spark2.set_color(Color( 1, 1, 0, 1 ))
			
			l_spark2.emitting = true
			r_spark2.emitting = true

			drift_boost_amount = 2
			
			spark_sound.pitch_scale = 1.2
		
	elif drift_time > 100:
		if drift_boost_amount < 1:
		
			l_spark.emitting = true
			r_spark.emitting = true
			
			l_spark.set_color(Color( 0.5, 1, 0.83, 1 ))
			r_spark.set_color(Color( 0.5, 1, 0.83, 1 ))
			l_spark2.set_color(Color( 0.5, 1, 0.83, 1 ))
			r_spark2.set_color(Color( 0.5, 1, 0.83, 1 ))
			
			l_spark2.emitting = true
			r_spark2.emitting = true

			drift_boost_amount = 1
			
			spark_sound.play()
			spark_sound.pitch_scale = 1

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


func _on_timer_timeout():
	if is_network_master():
		rpc_unreliable("update_state", ball.transform.origin, mesh_node.rotation, ball.translation)
	else:
		timer.stop()


remote func update_state(sent_transform, sent_rot, sent_trans):
	net_rotation = sent_rot
	net_transform = sent_transform
	net_translation = sent_trans
	

func _toggle_movement(c):
	can_move = c
	if c == false:
		rotate_input = 0
		speed_input = 0
		print("movement stopped!")
	else:
		print("movement started!")

remote func _player_left(player_id):
	print("player " + str(player_id) + " left")
	
	if str(name) == str(player_id):
		get_parent().remove_child(self)
	
	Network.player_info.erase(player_id)
	Global.emit_signal("player_left", player_id)
	
remote func _all_to_lobby():
	Global.emit_signal("back_to_lobby")

func speed_pad_detected(n):
	if n == name and is_network_master():
		boost(2)


#note: the boost function should only receice values 1, 2 or 3. if it recieves a value which is not one of these 3, it will assume its 1.
func boost(lvl):
	#visual + sound
	boost_sound.play()
	rpc("_show_boost")
	Global.emit_signal("show_speed_lines", lvl * 1.5)
	boost_p.emitting = true
	
	#actual boost
	boost_time = boost_time + 20
	
	match lvl:
		1:
			boost_amount = 60
		2:
			boost_amount = 80
		3:
			boost_amount = 120
		_:
			boost_amount = 65
	


remote func _show_boost():
	boost_p.emitting = true
	boost_sound.play()

# the next two functions are empty, but can be replaced by the scrits of node which inherit this script when needed.
func start_drift_anim():
	pass

func stop_drift_anim():
	pass

