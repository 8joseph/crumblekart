extends Spatial


func _ready():
	
	
	var p = int(get_parent().get_parent().get_parent().get_parent().get_parent().name)
	var x = Network.player_info[p].vehicle
	
	
	match x:
		"Nyozuki":
			$AnimationPlayer.play("Nyozuki")
			print("zuki anim playing")
		"CM 5000":
			$AnimationPlayer.play("CM5000")
			print("cm5000 anim playing")
