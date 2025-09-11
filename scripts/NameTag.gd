tool
extends Spatial

export var player_name = "default"

func _ready():
	$Viewport.size = $Viewport/Label.rect_size
	$Viewport/Label.text = player_name

