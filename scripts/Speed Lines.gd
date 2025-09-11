extends Control

onready var p = $Control/Particles2D
onready var t = $Timer
var on

func _ready():
	Global.connect("show_speed_lines", self, "_show_speed_lines")
	hide()
	on = false

func _process(delta):
	if Global.local_player_speed < 10 and on:
		hide()

func _show_speed_lines(x):
	show()
	t.wait_time = x
	t.start()
	on = true

func _on_Timer_timeout():
	hide()
	on = false
