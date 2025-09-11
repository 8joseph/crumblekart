#this scipt sets up the basic map logic, and keeps track of all players in - game stats on the hosts machine
extends Node

#get spawnpoints
export (NodePath) onready var spawn1 = get_node(spawn1) as Position3D
export (NodePath) onready var spawn2 = get_node(spawn2) as Position3D
export (NodePath) onready var spawn3 = get_node(spawn3) as Position3D
export (NodePath) onready var spawn4 = get_node(spawn4) as Position3D
export (NodePath) onready var spawn5 = get_node(spawn5) as Position3D
export (NodePath) onready var spawn6 = get_node(spawn6) as Position3D

#get lap trackers
#instance tracker scene for these
#lapper - shows where the track loop starts/ends. only one of these
#marker - makes sure the player is on the correct track to the lapper. two of these
export (NodePath) onready var lapper = get_node(lapper) as Area
export (NodePath) onready var marker1 = get_node(marker1) as Area
export (NodePath) onready var marker2 = get_node(marker2) as Area


#get the directional light and the world enviroment in order to control the grpahics settings
export(NodePath) onready var dir_light = get_node(dir_light) as DirectionalLight

#instance lapper variables
var lapperbool
var marker1bool
var marker2bool

#dictionary which contains info for each players lap
var in_game_info = {}

#holds the amount of players connected
var players_connected
#counts the amount of player who have loaded in
var players_loaded

#holds the countdown time when the race begins
var countdown_time

#holds the timer used to countdown from 3 at start of race
var timer

#increases each time a player finishes, sets what place a player comes in when they finish
var place

#particle materials
var p_boostfire = preload('res://scenes/particles/materials/boost_fire.tres')
var p_driftdust = preload('res://scenes/particles/materials/drift_dust.tres')
var p_dust = preload ('res://scenes/particles/materials/dust.tres')
var p_sparks = preload('res://scenes/particles/materials/sparks.tres')
var p_sparkschanged = preload('res://scenes/particles/materials/sparks_change.tres')

var materials = [
	p_boostfire,
	p_driftdust,
	p_dust,
	p_sparks,
	p_sparkschanged
]


func _ready():
	Global.emit_signal("toggle_movement", false)
	players_loaded = 0
	
	#if you are the host, say how many players are connected. This is used to determine when game can finish loading.
	if Network.amhost == true:
		players_connected = len(get_tree().get_network_connected_peers()) + 1
		
	#load players into the map
	var c = 1 #used as a counter for how may players have loaded in, for allocating spawn points
	for n in Network.player_info:
		var id = Network.player_info[n]
		var player #holds the scene to load
		var load_path #holds the scene file path to load
		
		#list through every item in the vehicle list, if it matches player vehicle, then set the load_path to the the correct vehicle load path.
		for v in Global.vehicle_list:
			if Global.vehicle_list[v].name == Network.player_info[n].vehicle:
				load_path = Global.vehicle_list[v].location
				break
		
		player = load(str(load_path)).instance()

		player.set_network_master(n)
		player.name = str(n) # set the name of the new node to the net id of player, this is helpful.
		add_child(player)
		
		#put the player in the right spawn location
		var l
		if c == 1:
			l = spawn1.global_transform
		elif c == 2:
			l = spawn2.global_transform
		elif c == 3:
			spawn3.global_transform
		elif c == 4:
			l = spawn4.global_transform
		elif c == 5:
			l = spawn5.global_transform
		elif c == 6:
			l = spawn6.global_transform
		player.global_transform = l
		
		var entry = {lap = 1, m1 = false , m2 = false, place = -1} # this is what is loaded into the in game info dictionary for each player
		c = c + 1
		in_game_info[n] = entry
		
	# connect signals for tracker collision - only on network master
	if Network.amhost == true:
		lapper.connect("body_entered", self, "_passed_lapper")
		marker1.connect("body_entered", self, "_passed_marker_1")
		marker2.connect("body_entered", self, "_passed_marker_2")
	
	#set bool variables to see if vehicle has gone past each tracker
	lapperbool = false
	marker1bool = false
	marker2bool = false
	
	#set countdown time to 4 bc it will be recuced to 3 as soon as it is used
	countdown_time = 4

	#set place to one, so it can be counted up to more when players finish
	place = 1

	#tell host player has finished loading, last thing that should be called in _ready()
	if Network.amhost == false:
		rpc_id(1, "_finished_loading")
	else:
		_finished_loading()
		
	Global.connect("player_left", self, "_player_left")
	Global.connect("back_to_lobby", self, "_send_all_to_lobby")
	
	#set the lap variable used the hud to one
	Global.lap = 1
	
	#set the graphics settings the the users preference
	dir_light.shadow_enabled = Global.shadows
	

	#stop particle lag when they are first instanced
	for material in materials:
		var p = CPUParticles.new()
		p.set_material_override(material)
		p.set_one_shot(true)
		p.emitting = true
		self.add_child(p)


# when the collision is detected, the name of node is checked to make sure it is not a static body.
# this might need to change in the future if moving items / obsticles are to be added. check if id name matches with that in name info
# following functions are called on host when cars go through the markers
# called on host to increase security, makes it harder for other players to cheat

func _passed_lapper(id):
	if str(id).begins_with("[StaticBody") or int(id.get_owner().name) == 0:
		pass
	else:
		if in_game_info[int(id.get_owner().name)].m1 == true and in_game_info[int(id.get_owner().name)].m2 == true:
			in_game_info[int(id.get_owner().name)].m1 = false
			in_game_info[int(id.get_owner().name)].m2 = false
			var lap =  in_game_info[int(id.get_owner().name)].lap
			
			#if the player has not yet done the required amount of laps, inrcrease the lap stat
			if lap < 3:
				print(lap)
				lap = lap + 1
				in_game_info[int(id.get_owner().name)].lap = lap
				
				#send the lap couter to the HUD if it is the hosts
				if int(id.get_owner().name) == get_tree().get_network_unique_id():
					Global.lap = lap
				#send the lap counter to the relevant player
				else:
					rpc_id(int(id.get_owner().name), "_update_local_lap", lap)
				
			
			#if the player has done the requruired amount of laps, set the position the player came in and stop the players movement
			elif lap == 3:
				print("player " + str(id.get_owner().name)  +  " finished!!!!")
				in_game_info[int(id.get_owner().name)].place = place
				print("you came in " + str(place) + " place")
				place = place + 1
				
				if place == players_connected + 1: #if all players have finished all their laps
					rpc("_game_finished")
					_game_finished()
				
				if int(id.get_owner().name) != 1:
					rpc_id(int(id.get_owner().name), "_stop_player_movement") # make it so the player stops moving
					
				elif int(id.get_owner().name) == 1:
					Global.emit_signal("toggle_movement", false)
					
			print(in_game_info)

#called on host, stops the local players movement when needed
remote func _stop_player_movement():
	Global.emit_signal("toggle_movement", false)


func _passed_marker_1(id):
	if str(id).begins_with("[StaticBody") or int(id.get_owner().name) == 0:
		pass
	else:
		if in_game_info[int(id.get_owner().name)].m1 == false and in_game_info[int(id.get_owner().name)].m2 == false:
			in_game_info[int(id.get_owner().name)].m1 = true

func _passed_marker_2(id):
	if str(id).begins_with("[StaticBody") or int(id.get_owner().name) == 0:
		pass
	else:
		if in_game_info[int(id.get_owner().name)].m1 == true and in_game_info[int(id.get_owner().name)].m2 == false:
			in_game_info[int(id.get_owner().name)].m2 = true

remote func _finished_loading():
	#count the amount of loaded players, make sure everyone is in before starting the load buffer
	players_loaded = players_loaded + 1
	print('players loaded:' + str(players_loaded))
	if players_loaded == players_connected:
		print('load buffer started')
		
		#load buffer
		#this is called to make sure all players are properly in before starting the countdown
		
		var t = Timer.new()
		self.add_child(t)
		t.wait_time = 3
		t.one_shot = true
		t.connect("timeout", self, "_load_buffer_ended")
		t.start()
	
	
func _load_buffer_ended():
	#start the game countown once the buffer countdown is over
	rpc("_start_game")
	_start_game()

		
remote func _start_game():
	print("start game called")
	timer = Timer.new()
	timer.wait_time = 1
	add_child(timer)
	timer.connect("timeout", self, "_count_down_timeout")
	timer.start()
	Global.emit_signal("start_countdown")
	
	
func _count_down_timeout():
	var output
	countdown_time = countdown_time - 1
	if countdown_time == 0:
		output = "GO!"
		timer.stop()
		Global.emit_signal("toggle_movement", true)
	else:
		output = str(countdown_time)
	print(output)

remote func _game_finished():
	print("game finished! all players have completed the required amount of laps!")
	print(in_game_info)
	rpc("_finish_game", in_game_info)
	_finish_game(in_game_info)

func _send_all_to_lobby():
	get_tree().change_scene("res://scenes/ui/Lobby.tscn")

remote func _player_left(player_id):
	in_game_info.erase(player_id)


remote func _update_local_lap(lap):
	Global.lap = str(lap)
	
	
remote func _finish_game(info):
	Global.emit_signal("end_game", info)
