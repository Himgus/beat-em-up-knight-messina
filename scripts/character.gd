extends CharacterBody2D

class_name baseCharacter

@export var velocidad :float
@export var max_hp :int
@export var daño :int
@export var JUMP_VELOCITY:int
@export var knockback:float

@onready var damage_reciever:Damage_Reciever=$damage_reciever

var attack_on_cooldown:bool=false
var damage_applied:bool=false
var current_hp:=0


func _ready() -> void:
	$CooldownTimer.timeout.connect(on_cooldown_timer_timeout)
	$AnimatedSprite2D.animation_finished.connect(on_animation_finished)
	current_hp=max_hp

func _process(delta: float) -> void:
	handle_input(delta)
	handle_movement()
	handle_animations()
	handle_damage()
	flip_sprites()
	move_and_slide()

func handle_input(_delta: float) -> void:
	pass
func handle_movement() -> void:
	pass
func handle_animations() -> void:
	pass
func handle_damage() -> void:
	pass

func on_animation_finished()->void:
	pass

func flip_sprites()->void:
	if velocity.x>0:
		$AnimatedSprite2D.flip_h=false
		$damage_emitter.scale.x=1
		damage_reciever.scale.x=1
		$character_collision.scale.x=1
	elif velocity.x<0:
		$AnimatedSprite2D.flip_h=true
		$damage_emitter.scale.x=-1
		damage_reciever.scale.x=-1
		$character_collision.scale.x=-1

func on_cooldown_timer_timeout()->void:
	attack_on_cooldown=false



func apply_damage_emitted(damage_reciever: Damage_Reciever)->void:
	var direccion:Vector2
	if damage_reciever.global_position.x<global_position.x:
		direccion=Vector2.LEFT
	else:
		direccion=Vector2.RIGHT
	damage_reciever.damage_recieved.emit(daño, direccion)
