extends Control

onready var playerid = $Container/PlayerId
onready var playername = $Container/PlayerName

func _process(delta):
	if is_network_master():
		playerid.text = str(get_tree().get_network_unique_id())
	else:
		playerid.text = str(name)
