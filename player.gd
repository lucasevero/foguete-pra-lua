extends CharacterBody2D
## DONO: Dev A — física do foguete (o coração do jogo).
## Contrato: escuta GameEvents.fuel_collected / asteroid_hit.
##           emite GameEvents.fuel_changed / player_reached_moon (moon = GameManager decide).
## Fique livre pra trocar TODA a implementação abaixo — só mantenha os signals.

@export var gravity: float = 400.0          # px/s^2 puxando pra baixo
@export var thrust_force: float = 900.0     # empuxo na direção que o foguete aponta
@export var rotation_speed: float = 2.5     # rad/s ao girar
@export var max_fuel: float = 100.0
@export var fuel_burn_rate: float = 25.0    # combustível/s enquanto empurra

var fuel: float

func _ready() -> void:
	fuel = max_fuel
	GameEvents.fuel_collected.connect(_on_fuel_collected)
	GameEvents.asteroid_hit.connect(_on_asteroid_hit)
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _physics_process(delta: float) -> void:
	# TODO(Dev A): esta é a mecânica central. Ajuste até o equilíbrio ficar
	# "difícil mas justo". Considere torque/inércia real em vez de rotação direta.

	# Girar (A/seta-esq, D/seta-dir)
	var turn := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		turn -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		turn += 1.0
	rotation += turn * rotation_speed * delta

	# Gravidade
	velocity.y += gravity * delta

	# Empuxo (segurar ESPAÇO) — na direção que o foguete aponta (topo = frente)
	if Input.is_key_pressed(KEY_SPACE) and fuel > 0.0:
		var dir := Vector2.UP.rotated(rotation)
		velocity += dir * thrust_force * delta
		fuel = maxf(0.0, fuel - fuel_burn_rate * delta)
		GameEvents.fuel_changed.emit(fuel, max_fuel)

	move_and_slide()

func _on_fuel_collected(amount: float) -> void:
	fuel = minf(max_fuel, fuel + amount)
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _on_asteroid_hit() -> void:
	GameEvents.player_died.emit()
