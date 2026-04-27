extends ProgressBar

var boss: Boss

func _ready() -> void:
	visible = false

func set_boss(b: Boss) -> void:
	boss = b
	max_value = boss.max_hp
	value = boss.current_hp
	visible = true

func _process(_delta: float) -> void:
	if boss and is_instance_valid(boss):
		value = boss.current_hp
	elif visible and boss:
		visible = false
