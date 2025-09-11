extends Control

onready var vol_lbl = $VBoxContainer/Volume/VolLabel
onready var vol_slider = $VBoxContainer/Volume/VolSlider
onready var anistropic_dropdown = $VBoxContainer/AnisotropicFilter/AniDropdown

func _ready():
	vol_slider.value = db2linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	$VBoxContainer/Shadows/CheckBox.pressed = Global.shadows
	$VBoxContainer/CoolLighting/CheckBox2.pressed = Global.cool_lighting
	$VBoxContainer/Music/musiccheckbox.pressed = Global.music



func _on_VolSlider_value_changed(value):
	var showval = round(value * 100)
	vol_lbl.text = "Volume: " + str(showval)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(value))


func _on_AniDropdown_item_selected(index):
	match index:
		0:
			print("2")
			ProjectSettings.set_setting("rendering/quality/filters/msaa", 2)
			print(ProjectSettings.get_setting("rendering/quality/filters/msaa"))
		1:
			print("4")
			ProjectSettings.set_setting("rendering/quality/filters/msaa", 4)
			print(ProjectSettings.get_setting("rendering/quality/filters/msaa"))
		2:
			print("8")
			ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", 8)
		4:
			print("4")
			ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", 16)


func _on_CheckBox_toggled(button_pressed):
	if button_pressed == true:
		Global.shadows = true
	elif button_pressed == false:
		Global.shadows = false



func _on_CheckBox2_toggled(button_pressed):
	if button_pressed == true:
		Global.cool_lighting = true
	elif button_pressed == false:
		Global.cool_lighting = false



func _on_musiccheckbox_toggled(button_pressed):
	if button_pressed == true:
		Global.music = true
	elif button_pressed == false:
		Global.music = false
