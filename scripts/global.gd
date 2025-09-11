extends Node

var local_player_name # this isnt used i think, meant to store the name of the local player
var local_player_speed # this stores the current speed of the player, used for the speed lines
var lap # holds the local players lap
signal toggle_movement # signal which is called (w/ a boolean) which sends out whether or not local player should be able to move
signal player_left # signal which is sent when a player leaves the game , mid game
signal back_to_lobby # sent when the host presses escape, in order to leave the lobby
signal speed_pad_hit # emitted when a speed pad detects a collision
signal show_speed_lines # emtitted on local vehicle_base.gd when speed lines should be shown, along with how long for
signal end_game # emitted from the host to all players once the game has been finished
signal start_countdown # emitted for the local player when the hud should start to display the countdown



#graphincs settings 
var shadows = false
var cool_lighting = false

#sound settings
var music = true





#this is basically a JSON file

var cm5000 = {name = "CM 5000", location = "res://scenes/vehicles/cm5000.tscn"}
var Nyozuki = {name = "Nyozuki", location = "res://scenes/vehicles/nyozuki.tscn"}

var character1 = {name = "Kyrie", location = "res://assets/people/kyrie/Kyrie.tscn"}
var character2 = {name = "Peggy Sue", location = "res://assets/people/peggy sue/Peggy Sue.tscn"}

var testMap = {name = "Test Map", location = "res://scenes/maps/test_map.tscn"}
var crumbleStadium = {name = "Crumble Stadium", location = "res://scenes/maps/crumble stadium.tscn"}
var downtown = {name = "Downtown", location = "res://scenes/maps/downtown.tscn"}

var vehicle_list = {
	1 : cm5000,
	2 : Nyozuki
}

var character_list = {
	1 : character1,
	2 : character2
}

var map_list = {
	1 : testMap,
	2 : downtown,
	3 : crumbleStadium
}
