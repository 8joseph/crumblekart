extends Spatial

#signal vehicle_changed
#signal character_changed
#
#onready var cpos = $characterpos
#onready var vpos = $vehiclepos
#
#export var character = ""
#export var vehicle = ""
#
#var current_character
#var current_vehicle
#
#var vehicle_loc
#var character_loc
#
#var v
#
#
#func _ready():
#	connect("character_changed", self, "_character_changed")
#	connect("vehicle_changed", self, "_vehicle_changed")
#
#func _character_changed(l):
#	print(l)
#
#func _vehicle_changed(l):
#	for x in vpos.get_children():
#		vpos.remove_child(x)
#		x.queue_free()
#
#	v = load(str(l)).instance()
#
