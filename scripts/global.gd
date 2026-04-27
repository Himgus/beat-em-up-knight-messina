extends Node

var musica := true
var music_player := AudioStreamPlayer.new()

func _ready()->void:
	add_child(music_player)
	music_player.bus = "Music"

func set_music(enabled: bool)->void:
	musica = enabled
	if enabled:
		if not music_player.playing:
			music_player.stream_paused = false
			music_player.play()
		else:
			music_player.stream_paused = false
	else:
		music_player.stream_paused = true

func play_track(track: AudioStream)->void:
	if music_player.stream == track:
		return
	music_player.stream = track
	music_player.stream_paused = not musica
	if musica:
		music_player.play()
