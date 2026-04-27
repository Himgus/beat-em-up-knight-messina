extends Node2D

@onready var player:=$Player
@onready var camera:=$Camera2D
@onready var hud:=$hud
@onready var pause_menu:=$PauseMenu
@onready var enemies_s2:=$Section2Enemies.get_children()
@onready var enemies_s4:=$Section4Enemies.get_children()
@onready var enemies_s6:=$Section6Enemies.get_children()
@onready var enemies_boss:=$BossSectionEnemies.get_children()
@onready var win_area:=$win
@onready var win_screen:=$win_screen
@onready var pared_derecha:=$Camera2D/paredes_invisibles/pared_derecha

var boss_defeated:=false
var camera_locked:=false
var lock_position_x:=0.0
var section2_activated:=false
var section4_activated:=false
var section6_activated:=false
var boss_activated:=false

func _ready()->void:
	Global.play_track(preload("res://assets/Minifantasy_Dungeon_Music/Music/Goblins_Dance_(Battle).wav"))
	hud.player=player
	for enemy in enemies_s2+enemies_s4+enemies_s6+enemies_boss:
		enemy.player=null
		enemy.process_mode=Node.PROCESS_MODE_DISABLED
		enemy.visible=false
	win_area.body_entered.connect(_on_win_body_entered)

func _process(_delta: float)->void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			pause_menu.hide_menu()
		else:
			pause_menu.show_menu()
	if not camera_locked:
		if boss_activated:
			camera.position.x=player.position.x
		elif player.position.x>camera.position.x:
			camera.position.x=player.position.x
		var half_vp=get_viewport_rect().size.x/2.0/camera.zoom.x
		if boss_activated:
			camera.position.x=clamp(camera.position.x,1920+half_vp,2560-half_vp)
		else:
			camera.position.x=clamp(camera.position.x,0,2560-half_vp)
		var right_edge=camera.position.x+half_vp
		if right_edge>=2560 and not boss_activated:
			boss_activated=true
			for enemy in enemies_boss:
				if is_instance_valid(enemy):
					enemy.player=player
					enemy.process_mode=Node.PROCESS_MODE_INHERIT
					enemy.visible=true
					if enemy is Boss:
						hud.show_boss_bar(enemy)
	else:
		camera.position.x=lock_position_x
		var active_enemies=_get_active_enemies()
		if active_enemies.all(func(e): return not is_instance_valid(e)):
			camera_locked=false
	var right_edge=camera.position.x+get_viewport_rect().size.x/2.0/camera.zoom.x
	if right_edge>=640 and not section2_activated:
		_activate_section(enemies_s2,640)
		section2_activated=true
	if right_edge>=1280 and not section4_activated:
		_activate_section(enemies_s4,1280)
		section4_activated=true
	if right_edge>=1920 and not section6_activated:
		_activate_section(enemies_s6,1920)
		section6_activated=true
		
	if boss_activated and not boss_defeated:
		var boss_alive = enemies_boss.any(func(e): return is_instance_valid(e))
		if not boss_alive:
			boss_defeated = true
			pared_derecha.queue_free()

func _activate_section(enemies:Array, lock_x:float)->void:
	camera_locked=true
	lock_position_x=lock_x-get_viewport_rect().size.x/2.0/camera.zoom.x
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.player=player
			enemy.process_mode=Node.PROCESS_MODE_INHERIT
			enemy.visible=true

func _get_active_enemies()->Array:
	if section6_activated:
		return enemies_s6
	if section4_activated:
		return enemies_s4
	return enemies_s2


func _on_win_body_entered(body):
	if body is Player and boss_defeated:
		win_screen.show_win()
		body.queue_free()
