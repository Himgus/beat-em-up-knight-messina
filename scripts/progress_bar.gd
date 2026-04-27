extends ProgressBar

@export var player:Player

func _ready()->void:
	if player:
		max_value=player.max_hp
		value=player.current_hp

func _process(_delta:float)->void:
	if player:
		value=player.current_hp
