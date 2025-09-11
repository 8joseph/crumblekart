extends Control

onready var container = $playerinfo
onready var playerVehicleLabel = $LocalPlayerInfo/ShowInfo/ShowVehicle
onready var playerCharacterLabel = $LocalPlayerInfo/ShowInfo/ShowCharacter


#these variables are associated with what item is selected using the button
var vehicleButtonNum
var charaterButtonNum
var mapButtonNum

var connected = false
var connect_tick


var pbar = preload('res://scenes/ui/player_bar.tscn')
var pcard = preload('res://scenes/ui/LobbyPlayerCard.tscn')

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	vehicleButtonNum = 1
	charaterButtonNum = 1
	mapButtonNum = 1
	
#	update_player_info_labels()
	$LobbyInfo/LobbyIp.text = "IP: " + str(Network.used_ip)
	$LobbyInfo/LobbyPort.text = "Port: " + str(Network.used_port)
	$MapStuff/MapName.text = "Map: " + str(Global.map_list[mapButtonNum].name)

	
	if !get_tree().has_network_peer() and Network.amhost == false:
		Network.reset_server_connection()
		print("no server connection")
		get_tree().change_scene("res://scenes/ui/menuscene.tscn")
		
	if Network.amhost == false:
		print("yejhaea")
		$MapStuff/StartGameButton.disabled = true
		$MapStuff/MapSelectButton.disabled = true
	
	update_player_info_labels(Global.vehicle_list[vehicleButtonNum].location,Global.character_list[charaterButtonNum].location)
	
	connected = false
	connect_tick = 0
	

func _process(delta):
	update_list_of_players()
	
	
	if Input.is_action_just_pressed("debug"):
		print(get_tree().get_network_unique_id())
	
	
	if connected or Network.amhost:
		$noHost.hide()
	elif !Network.amhost and !connected:
		$noHost.hide()
	
	
	if !Network.amhost:
		if connect_tick < 50:
			connect_tick += 1
		else:
			if connected == false:
				print("the connected has failed!")
				get_tree().change_scene("res://scenes/ui/menuscene.tscn")
	

	
func _player_connected(id):
	rpc_id(id, "register_player", Network.local_player_info)
	rpc_id(id, "mapBttnPressed", mapButtonNum)
	rpc_id(id, "verify_connection")
	

func _player_disconnected(id):
	Network.player_info.erase(id)
	print("player disconnected!")
	

remote func register_player(player_info):
	if get_tree().is_network_server():
		var id = get_tree().get_rpc_sender_id()
		Network.player_info[id] = player_info


func _on_main_menu_pressed():
	Network.reset_server_connection()
	get_tree().change_scene("res://scenes/ui/menuscene.tscn")
	
func _server_disconnected():
	print("server disconnected!")
	get_tree().change_scene("res://scenes/ui/menuscene.tscn")

func update_list_of_players():
	Network.get_player_info()
	for b in $PlayerCards.get_children():
		b.free()
	for n in Network.player_info:
#		if n != get_tree().get_network_unique_id():
			#YEAJH YEAHJ
		var b = pcard.instance()
		b.playername = Network.player_info[n].name
		b.character = Network.player_info[n].character
		b.vehicle = Network.player_info[n].vehicle
		$PlayerCards.add_child(b)

func _on_ChangeVehicle_pressed():
	vehicleButtonNum = vehicleButtonNum + 1
	if vehicleButtonNum > Global.vehicle_list.size():
		vehicleButtonNum = 1
	Network.local_player_info.vehicle = Global.vehicle_list[vehicleButtonNum].name
	var l = Global.vehicle_list[vehicleButtonNum].location
	if Network.amhost == false:
			Network.update_host_info()
	update_player_info_labels(l, "")

func _on_ChangeCharacter_pressed():
	charaterButtonNum = charaterButtonNum + 1
	if charaterButtonNum > Global.character_list.size():
		charaterButtonNum = 1
	Network.local_player_info.character = Global.character_list[charaterButtonNum].name
	var l  = Global.character_list[charaterButtonNum].location
	if Network.amhost == false:
		Network.update_host_info()
	update_player_info_labels("", l)

func update_player_info_labels(vehicle_location, character_location):
	playerCharacterLabel.text = "character: " + Network.local_player_info.character
	playerVehicleLabel.text = "vehicle: " + Network.local_player_info.vehicle


func _on_StartGameButton_pressed():
	rpc("start_game")
	start_game()

remote func start_game():
	get_tree().change_scene(Global.map_list[mapButtonNum].location)


func _on_MapSelectButton_pressed():
	mapButtonNum = mapButtonNum + 1
	if mapButtonNum > Global.map_list.size():
		mapButtonNum = 1
	$MapStuff/MapName.text = "Map: " + str(Global.map_list[mapButtonNum].name)
	rpc("mapBttnPressed", mapButtonNum)
	
remote func mapBttnPressed(mapb):
	if Network.amhost == false:
		mapButtonNum = mapb
		$MapStuff/MapName.text = "Map: " + str(Global.map_list[mapButtonNum].name)
		
remote func verify_connection():
	connected = true
