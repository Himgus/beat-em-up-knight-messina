extends CanvasLayer

@onready var icon:=$Sprite2D
var player:Player

func _ready() -> void:
	print(player)

func _process(delta: float) -> void:
	if player==null:
		return
	if player.skills_active:
		icon.modulate=Color(1,1,1,1)
	else:
		icon.modulate=Color(0.3,0.3,0.3,1)
