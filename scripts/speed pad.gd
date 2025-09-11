extends Spatial

func _on_detection_body_entered(body):
	var n = body.get_owner().name
	Global.emit_signal("speed_pad_hit", n)
