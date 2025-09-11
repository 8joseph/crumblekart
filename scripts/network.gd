# this is script holds most of the basic network functionality
extends Node

const DEF_PORT = 28888
const DEF_IP = "127.0.0.1"
const MAX_PLAYERS = 6

var server = null
var client = null

var used_ip #if the player is hosting, stores local ip. If player is client, stores host ip.
var used_port #stores the port user is currently connected to
var amhost #if the player is the host or not

var local_player_info = {name = "", vehicle = "", character = "",}
puppet var player_info = {}

func _ready():
	get_tree().connect("network_peer_connected", self , "_player_connected")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func create_server(port):
	server = NetworkedMultiplayerENet.new()
	server.create_server(int(port), MAX_PLAYERS)
	get_tree().set_network_peer(server)
	print("made server on port " + str(port))
	amhost = true
	#get ipv4 address, displayed in lobby
	#this doesnt always work well, school ip is different
	for ip in IP.get_local_addresses():
		if ip.begins_with("10.111.") or ip.begins_with("192.168."):
			used_ip = ip

	used_port = port
	#adds the host players info to the player_info dictionary, as this cannot be done through the rpc call in the lobby script
	player_info[get_tree().get_network_unique_id()] = local_player_info


func join_server(ip, port):
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip, int(port))
	get_tree().set_network_peer(client)
	print("joined server with ip " + str(ip) + " on port " + str(port))
	used_ip = ip
	used_port = port
	amhost = false

	#if the server the user joined is invalid
#	if !get_tree().has_network_peer():
#		print("wtf man y is this here")

func reset_server_connection():
	if get_tree().has_network_peer():
		get_tree().network_peer = null
		client = null
		server = null
		amhost = null
		used_ip = null
		player_info.clear()
		print("server connection reset!")

func _player_connected(id):
	print("player " + str(id) + " connected")

func _connection_failed():
	print("connection failed!")
	reset_server_connection()

func _server_disconnected():
	print("server disconnected!")
	reset_server_connection()


# this causes slight error atm , prolly dont need 2 fix
# bc its called before network connection set up properly i think
func get_player_info():
	if amhost == false:
		rpc_id(1, "send_player_info")

remote func send_player_info():
	var id = get_tree().get_rpc_sender_id()
	rset_id(id, "player_info", player_info)

func update_host_info():
	rpc_id(1, "get_client_info", local_player_info)

remote func get_client_info(recieved_player_info):
	var id = get_tree().get_rpc_sender_id()
	player_info[id] = recieved_player_info

