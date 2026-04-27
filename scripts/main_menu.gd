extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.play_track(preload("res://assets/Minifantasy_Dungeon_Music/Music/Goblins_Den_(Regular).wav"))


func _process(delta: float) -> void:
	pass


func _on_start_pressed()->void:
	get_tree().change_scene_to_file("res://scenes/beat_em_up.tscn")

func _on_options_pressed()->void:
	get_tree().change_scene_to_file("res://scenes/options_menu.tscn")

func _on_quit_pressed()->void:
	get_tree().quit()
