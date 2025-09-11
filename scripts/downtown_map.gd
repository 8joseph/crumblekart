extends "res://scripts/map_base.gd"


func _ready():
	
	#load the world envirmoent if the user has set it to do so
	if Global.cool_lighting == true:
		$WorldEnvironment.environment = load("res://assets/misc/enviroments/downtown.tres")
	elif Global.cool_lighting == false:
		$WorldEnvironment.environment = null

	#play the soundtrack
	if Global.music:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = load('res://assets/sounds/music/downtown.wav')
		p.set_volume_db(-15)
		p.play()
