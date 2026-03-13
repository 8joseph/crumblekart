extends Control

onready var nametext = $Multiplayer/name
onready var joiniptext = $Multiplayer/JoinOptions/LineEdits/ip
onready var joinporttext = $Multiplayer/JoinOptions/LineEdits/port
onready var hostporttext  = $Multiplayer/HostOptions/LineEdits/port

func _ready():
	Network.reset_server_connection()
	$Multiplayer.hide()
	
	#set default volume, this script is one of the first to be loaded
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(0.8))
	
	var foo = get_viewport().size.x
	$NewButtons.rect_position = Vector2(0,get_viewport().size.x / 6)
	$HelpMenu.hide()


func _on_host_pressed():
	if nametext.text != "":
		var port
		fill_in_local_player_info()
		if hostporttext.text == "":
			port = Network.DEF_PORT
		else:
			port = hostporttext.text
		
		Network.create_server(port)
		Global.local_player_name = nametext.name
		go_to_lobby()

func _on_join_pressed():
	if nametext.text != "" and joiniptext.text != "":
		var port
		var ip
		fill_in_local_player_info()
		if joinporttext.text == "":
			port = Network.DEF_PORT
		else:
			port = joinporttext.text
		if joiniptext.text == "":
			ip = Network.DEF_IP
		else:
			ip = joiniptext.text
		
		Network.join_server(ip, port)
		Global.local_player_name = nametext.name
		go_to_lobby()

func go_to_lobby():
	get_tree().change_scene("res://scenes/ui/Lobby.tscn")

func fill_in_local_player_info():
	Network.local_player_info.name = nametext.text
	Network.local_player_info.character = Global.character_list[1].name
	Network.local_player_info.vehicle = Global.vehicle_list[1].name


func _on_QuitBttn_pressed():
	get_tree().quit()


func _on_MultiplayerBttn_pressed():
	hide_all()
	$Multiplayer.show()


func hide_all():
	$Multiplayer.hide()
	$Settings.hide()


func _on_SettingsBttn_pressed():
	hide_all()
	$Settings.show()


func _on_SingleplayerBttn_pressed():
	if nametext.text != "":
		var port
		fill_in_local_player_info()
		if hostporttext.text == "":
			port = Network.DEF_PORT
		else:
			port = hostporttext.text
		
		Network.create_server(port)
		Global.local_player_name = nametext.name
		go_to_lobby()


func _on_HelpBttn_pressed():
	$HelpMenu.show()


func _on_HelpCloseBttn_pressed():
	$HelpMenu.hide()
