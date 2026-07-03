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
@export var fuel_burn_rate: float = 10.0    # combustível/s enquanto empurra
@export var safe_land_speed: float = 250.0  # descida máx p/ pouso seguro; acima disso = crash
@export var weapon_duration: float = 15.0   # duração do powerup arma
@export var fire_interval: float = 0.15      # intervalo entre tiros

const BULLET := preload("res://bullet.tscn")
const ROCKET_IDLE := preload("res://assets/sprites/player/rocket_idle.png")
const ROCKET_FLAME := preload("res://assets/sprites/player/rocket_flame.png")

var fuel: float
var angular_velocity: float = 0.0
var _has_taken_off: bool = false
var _thrusting: bool = false
var _shield: bool = false
var _weapon_time: float = 0.0
var _fire_cd: float = 0.0

@onready var _shield_sprite: Sprite2D = $Shield
@onready var _rocket: Sprite2D = $Rocket

func _ready() -> void:
	fuel = max_fuel
	GameEvents.fuel_collected.connect(_on_fuel_collected)
	GameEvents.asteroid_hit.connect(_on_asteroid_hit)
	GameEvents.powerup_activated.connect(_on_powerup)
	$ScreenNotifier.screen_exited.connect(_on_screen_exited)
	_shield_sprite.texture = _make_shield_disc(96)   # placeholder círculo amarelo
	_shield_sprite.hide()
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _make_shield_disc(diameter: int) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := diameter / 2.0
	var center := Vector2(r, r)
	for y in diameter:
		for x in diameter:
			if Vector2(x, y).distance_to(center) <= r - 1.0:
				img.set_pixel(x, y, Color(1.0, 1.0, 0.2, 0.35))
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	# --- Auto-endireitamento (tende a apontar pra cima) + rajadas ---
	angular_velocity += -sin(rotation) * uprighting * delta
	angular_velocity += (randf() - 0.5) * wobble * delta

	# --- Gravidade ---
	velocity.y += gravity * delta

	# --- Toque/clique: empurra pra longe do ponto tocado + rotaciona ---
	# Polling do estado a cada frame (robusto; no mobile o toque emula o mouse).
	var thrusting := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fuel > 0.0
	if thrusting != _thrusting:
		_thrusting = thrusting
		GameEvents.thrust_changed.emit(thrusting)   # AudioManager liga/desliga o motor
		_rocket.texture = ROCKET_FLAME if thrusting else ROCKET_IDLE
	if thrusting:
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

	# --- Arma (powerup): tiro contínuo pra cima por 15s ---
	if _weapon_time > 0.0:
		_weapon_time -= delta
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = fire_interval
			_fire()

	# --- Amortecimentos ---
	angular_velocity -= angular_velocity * angular_drag * delta
	rotation += angular_velocity * delta
	velocity.x -= velocity.x * linear_drag * delta

	var descent := velocity.y   # velocidade de descida ANTES do move_and_slide zerar no impacto
	move_and_slide()

	if is_on_floor():
		if _has_taken_off:
			if descent > safe_land_speed:
				GameEvents.player_died.emit()   # bateu forte = crash
			else:
				GameEvents.landed_safely.emit() # pouso suave, ok (pode decolar de novo)
				_has_taken_off = false
		if velocity.y > 0.0:      # não deixa a gravidade acumular (senão o empuxo não levanta)
			velocity.y = 0.0
	elif not _has_taken_off:
		_has_taken_off = true
		GameEvents.lifted_off.emit()            # saiu do chão pela 1ª vez

func _on_fuel_collected(amount: float) -> void:
	fuel = minf(max_fuel, fuel + amount)
	GameEvents.fuel_changed.emit(fuel, max_fuel)

func _on_asteroid_hit() -> void:
	if _shield:
		_shield = false            # escudo absorve um hit
		_shield_sprite.hide()
	else:
		GameEvents.player_died.emit()

func _on_screen_exited() -> void:  # saiu da tela de jogo = game over
	GameEvents.player_died.emit()

func _on_powerup(kind: String) -> void:
	match kind:
		"shield":
			_shield = true
			_shield_sprite.show()
		"fuel":
			fuel = max_fuel
			GameEvents.fuel_changed.emit(fuel, max_fuel)
		"weapon":
			_weapon_time = weapon_duration
			_fire_cd = 0.0
		# "time" é tratado pelo GameManager

func _fire() -> void:
	var b := BULLET.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position + Vector2.UP.rotated(rotation) * 40.0
