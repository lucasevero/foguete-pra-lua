extends Node2D
## DONO: Dev C — camadas de fundo. Área: pickups.
## Céu (gradiente por código) + nuvens (baixa altitude) + estrelas (surgem no
## espaço) + CIDADE/quintal no início + Lua (destino) no topo.
##
## Escuta GameEvents.altitude_changed (0.0 = chão, 1.0 = Lua).
## Estrelas ainda são placeholder procedural (sem asset bg_stars ainda).

const CLOUD_TEX := preload("res://assets/sprites/background/bg_clouds.png")

@export var earth_sky: Color = Color(0.53, 0.81, 0.92)
@export var deep_space: Color = Color(0.02, 0.02, 0.08)
@export var ground_y: float = 1150.0   # chão/cidade no início: baixado p/ a imagem encher até a base da tela (casar com player start)
@export var moon_y: float = -8850.0    # deve casar com moon de game_manager (start 1150 + offset -10000)
@export var cloud_count: int = 16      # nuvens pequenas espalhadas pela zona baixa

@onready var sky_rect: ColorRect = $SkyLayer/SkyRect
@onready var stars: Parallax2D = $Stars
@onready var stars_sprite: Sprite2D = $Stars/StarsSprite
@onready var clouds: Node2D = $Clouds
@onready var city: Sprite2D = $City
@onready var moon: Sprite2D = $Moon

func _ready() -> void:
	GameEvents.altitude_changed.connect(_on_altitude_changed)

	if stars_sprite.texture == null:
		stars_sprite.texture = _make_star_tile(256)
		stars.repeat_size = Vector2(256, 256)

	city.scale = Vector2(0.4, 0.4)          # bg_city 1800x700 -> ~720 de largura
	city.position = Vector2(360, ground_y)
	moon.scale = Vector2(0.9, 0.9)
	moon.position = Vector2(360, moon_y)
	_spawn_clouds()

	_on_altitude_changed(0.0)

func _spawn_clouds() -> void:
	# várias nuvens pequenas espalhadas pela zona baixa (não uma só no centro)
	for i in cloud_count:
		var c := Sprite2D.new()
		c.texture = CLOUD_TEX
		var s := randf_range(0.12, 0.30)
		c.scale = Vector2(s, s)
		c.position = Vector2(randf() * 720.0, ground_y - randf_range(200.0, 3200.0))
		c.modulate.a = randf_range(0.7, 1.0)
		clouds.add_child(c)

func _on_altitude_changed(ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	sky_rect.color = earth_sky.lerp(deep_space, r)
	stars_sprite.modulate.a = r                        # estrelas surgem no espaço
	clouds.modulate.a = clampf(1.0 - r * 2.5, 0.0, 1.0) # nuvens só na faixa baixa

# --- Placeholder procedural das estrelas (trocar quando chegar bg_stars) ---

func _make_star_tile(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 70:
		var b := randf_range(0.6, 1.0)
		img.set_pixel(randi() % size, randi() % size, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)
