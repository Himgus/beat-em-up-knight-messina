extends StaticBody2D

@export var knockback:float
@export var damage:int

@onready var damage_reciever:Damage_Reciever=$damage_reciever
@onready var damage_emitter:Area2D=$damage_emitter
@onready var cofres:=$cofres
@onready var sfx_open:AudioStreamPlayer2D=$SFXOpen

enum Estado{IDLE,OPEN}
var state:=Estado.IDLE

var GRAVITY:=980.0

var altura:=0.0
var altura_velocidad:=0.0
var velocidad:=Vector2.ZERO
var already_hit:Array=[]

func _ready() -> void:
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	
func _process(delta: float) -> void:
	position+=velocidad*delta
	cofres.position=Vector2.UP*altura
	handle_air_time(delta)
	if altura>0:
		handle_damage()
	
func on_recieve_damage(damage_taken:int, direccion:Vector2, hit_type:Damage_Reciever.Hit_type)->void:
	if state==Estado.IDLE:
		cofres.frame=2
		sfx_open.play()
		state=Estado.OPEN
		match hit_type:
			Damage_Reciever.Hit_type.NORMAL:
				altura_velocidad=knockback/2
				velocidad=direccion*(knockback/2)
			_:
				altura_velocidad=knockback
				velocidad=direccion*knockback


func handle_air_time(delta:float)->void:
	if state==Estado.OPEN:
		altura_velocidad -= GRAVITY * delta
		altura += altura_velocidad * delta
		if altura <= 0:
			altura = 0
			altura_velocidad = 0.0
			velocidad = Vector2.ZERO
			already_hit.clear()

func handle_damage()->void:
	for area in damage_emitter.get_overlapping_areas():
		if area not in already_hit and area is Damage_Reciever:
			already_hit.append(area)
			area.damage_recieved.emit(damage, Vector2(sign(velocidad.x), 0), Damage_Reciever.Hit_type.KNOCKDOWN)
