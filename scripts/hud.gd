extends Control

export var speed = 0
export var lap = 1
export var engine_power= 0





onready var count_down = $CountDown

#score the names to display on the scoreboard
var first
var second
var third


const pointerbase = deg2rad(-70)

var pv = 5.2

var count # used to store what the countdown should be displaying


#timer variables
var mins
var secs
var milisecs
var booltime


var countdown_bleep = AudioStreamPlayer.new()


onready var pointer = $speedometer/pointer
onready var finish_stats = $FinishStats

func _ready():
	
	milisecs = 0
	secs =  0
	mins = 0
	booltime = false
	
	finish_stats.hide()
	Global.connect("end_game", self, "_show_game_stats")
	Global.connect("start_countdown", self, "_start_countdown")
	Global.connect("toggle_movement", self ,"_end_timer")
	
	first = ""
	second = ""
	third = ""
	
	$countdoown_bleep.pitch_scale = 1.4

func _process(delta):
	$tempInfo/speed.text = "speed: " + str(speed)
	$tempInfo/lap.text = "lap: " + str(Global.lap) + "/3"
	$tempInfo/engine_power.text = "engine power: " + str(engine_power)
	
	
	$Lap.text = "Lap: " +  str(Global.lap) + "/3"
	
	
	var r = (pointerbase + deg2rad(speed * pv))
	
	if r > 2:
		r = 1.4
	
	var e = lerp(pointer.get_rotation(), r, delta)

	pointer.set_rotation(e)
	
	
	if pointer.get_rotation() > 80:
		pointer.set_rotation(deg2rad(80))
	

func _show_game_stats(info):
	finish_stats.show()
	
	for x in info:
		if info[x].place == 1:
			first = str(Network.player_info[x].name)
		elif info[x].place == 2:
			second = str(Network.player_info[x].name)
		elif info[x].place == 3:
			third = str(Network.player_info[x].name)

	$FinishStats/FirstPlace.text = "1st: " + first
	$FinishStats/SecondPlace.text = "2nd:" + second
	$FinishStats/ThirdPlace.text = "3rd: " + third


func _start_countdown():
	count = ""
	$CountDown/Timer.connect("timeout", self, "next_count")
	$CountDown/Timer.start()
	
func next_count():
	$CountDown/AnimationPlayer.play("slide_down")
	match count:
		"":
			count = "3!"
			$countdoown_bleep.play()
		"3!":
			count = "2!"
			$countdoown_bleep.play()
		"2!":
			count = "1!"
			$countdoown_bleep.play()
		"1!":
			count = "GO!"
			$countdoown_bleep.pitch_scale = 1.4
			$countdoown_bleep.play()
		"GO!":
			count_down.hide()
			$CountDown/Timer.stop()
			$CountDown/AnimationPlayer.stop()
			$Time/Timer.start()
			booltime = true
	count_down.text = count



func _on_Timer_timeout():
	if booltime == true:
		milisecs += 1
		if milisecs == 10:
			milisecs = 0
			secs += 1
		if secs == 60:
			secs = 0
			mins += 1
			
		var s = "Time: " + str(mins) + ":" + str(secs) + ":" + str(milisecs)
		$Time.text = s
		
func _end_timer(a):
	if a == false:
		booltime = false
