extends HBoxContainer

export var playername = ''
export var vehicle = ''
export var character = ''



func _ready():
	add_constant_override("separation", 4)
	$name.text = 'Name: ' + playername
	$vehicle.text = '  Vehicle: ' + vehicle
	$character.text = '  Character: ' + character
