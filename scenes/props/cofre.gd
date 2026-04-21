extends StaticBody2D

@export var knockback:float

@onready var damage_reciever:Damage_Reciever=$damage_reciever
@onready var cofres:=$cofres

enum Estado{IDLE,OPEN}
var state:=Estado.IDLE

var GRAVITY:=980.0

var altura:=0.0
var altura_velocidad:=0.0
var velocidad:=Vector2.ZERO

func _ready() -> void:
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	
func _process(delta: float) -> void:
	position+=velocidad*delta
	cofres.position=Vector2.UP*altura
	handle_air_time(delta)
	
func on_recieve_damage(damage:int, direccion:Vector2)->void:
	if state==Estado.IDLE:
		cofres.frame=2
		altura_velocidad=knockback
		state=Estado.OPEN
		velocidad=direccion*knockback

func handle_air_time(delta:float)->void:
	if state==Estado.OPEN:
		altura_velocidad -= GRAVITY * delta
		altura += altura_velocidad * delta
		if altura <= 0:
			altura = 0
			altura_velocidad = 0.0
			velocidad = Vector2.ZERO
		
		
