extends Node2D

@onready var player:=$Player
@onready var camera:=$Camera2D
@onready var hud:=$hud


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hud.player=player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.position.x>camera.position.x:
		camera.position.x=player.position.x
