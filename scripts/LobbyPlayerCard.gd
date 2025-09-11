extends Control

export var playername = ''
export var vehicle = ''
export var character = ''


func _ready():
	$PlayerName.text = str(playername)
	

	if character == "Kyrie":
		$CharacterTex.texture = load("res://assets/ui elements/misc/ppl_snaps/kyrie.png")
	elif character == "Peggy Sue":
		$CharacterTex.texture = load("res://assets/ui elements/misc/ppl_snaps/peggysue.png")
		
		
	if vehicle == "CM 5000":
		$VehicleTex.texture = load('res://assets/ui elements/misc/vehicle_snaps/cm5000.png')
	elif vehicle == "Nyozuki":
		$VehicleTex.texture = load("res://assets/ui elements/misc/vehicle_snaps/nyozuki.png")
