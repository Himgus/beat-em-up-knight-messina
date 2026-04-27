extends CanvasLayer

@onready var icon:=$Sprite2D
@onready var boss_bar:=$boss_bar
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

func show_boss_bar(boss: Boss) -> void:
	boss_bar.set_boss(boss)
