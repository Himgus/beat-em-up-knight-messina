extends CanvasLayer

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_win():
	show()
	get_tree().paused = true

func _on_menu_button_pressed():
	Global.music_player.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
