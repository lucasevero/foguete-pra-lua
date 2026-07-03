extends CharacterBody2D
## DONO: Dev A — física do foguete (o coração do jogo). Área: physics.
## Contrato: escuta GameEvents.fuel_collected / asteroid_hit. Emite fuel_changed.
##
## CONTROLE (mobile/toque): enquanto o dedo toca a tela, o foguete é empurrado
## PARA LONGE do ponto tocado (dedo embaixo → sobe; dedo na lateral → empurra e
## rotaciona pro lado). O empuxo acontece SEMPRE que há toque. Mouse simula toque
## (pra testar no desktop). Sem toque = só gravidade + instabilidade.
##
## MODELO: o foguete tende a apontar pra cima sozinho (torque restaurador); o
## toque nas laterais gira devagar. Todos os valores são @export → tunáveis no Inspector.

@export var gravity: float = 200.0          # px/s^2 (reduzida p/ facilitar)
@export var thrust_force: float = 1000.0    # empuxo pra longe do dedo
@export var touch_torque: float = 8.0       # rotação por offset horizontal do toque (menor = gira devagar)
@export var uprighting: float = 1.5         # torque SUAVE que tende a apontar pra cima
@export var wobble: float = 1.0             # rajadas aleatórias
@export var angular_drag: float = 2.0       # amortece rotação
@export var linear_drag: float = 0.4        # arrasto lateral
@export var max_fuel: float = 100.0
@export var fuel_burn_rate: float = 25.0    # combustível/s enquanto empurra

var fuel: float
var angular_velocity: float = 0.0

func _ready() -> void:
	fuel = max_fuel
	GameEvents.fuel_collected.connect(_on_fuel_collected)
	GameEvents.asteroid_hit.connect(_on_asteroid_hit)
	$ScreenNotifier.screen_exited.connect(_on_screen_exited)
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _physics_process(delta: float) -> void:
	# --- Auto-endireitamento (tende a apontar pra cima) + rajadas ---
	angular_velocity += -sin(rotation) * uprighting * delta
	angular_velocity += (randf() - 0.5) * wobble * delta

	# --- Gravidade ---
	velocity.y += gravity * delta

	# --- Toque/clique: empurra pra longe do ponto tocado + rotaciona ---
	# Polling do estado a cada frame (robusto; no mobile o toque emula o mouse).
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fuel > 0.0:
		var vp := get_viewport()
		var center := vp.get_visible_rect().size * 0.5
		var touch := vp.get_mouse_position()
		var push := center - touch                  # do dedo p/ o centro (foguete)
		if push.length() > 1.0:
			velocity += push.normalized() * thrust_force * delta
		var offset_x := touch.x - center.x          # toque lateral = rotação
		angular_velocity += (offset_x / 1000.0) * touch_torque * delta
		fuel = maxf(0.0, fuel - fuel_burn_rate * delta)
		GameEvents.fuel_changed.emit(fuel, max_fuel)

	# --- Amortecimentos ---
	angular_velocity -= angular_velocity * angular_drag * delta
	rotation += angular_velocity * delta
	velocity.x -= velocity.x * linear_drag * delta

	move_and_slide()

func _on_fuel_collected(amount: float) -> void:
	fuel = minf(max_fuel, fuel + amount)
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _on_asteroid_hit() -> void:
	GameEvents.player_died.emit()

func _on_screen_exited() -> void:  # saiu da tela de jogo = game over
	GameEvents.player_died.emit()
