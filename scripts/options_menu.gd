extends CanvasLayer

@onready var music_button:=$HBoxContainer/musica
@onready var back_button:=$atras

func _ready()->void:
	_update_button_text()

func _on_back_pressed()->void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_btn_musica_pressed()->void:
	Global.set_music(not Global.musica)
	_update_button_text()

func _update_button_text()->void:
	if Global.musica:
		music_button.text= "Music: ON"
	else:
		music_button.text="Music: OFF"
