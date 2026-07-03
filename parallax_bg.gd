extends Node2D
## DONO: Dev C — camadas de fundo. Área: pickups.
## Céu (gradiente por código) + estrelas (Parallax2D, aparecem no espaço) +
## marcos Terra (embaixo) e Lua (topo) em Y fixo no mundo.
##
## Escuta GameEvents.altitude_changed (0.0 = Terra, 1.0 = Lua).
##
## PLACEHOLDERS PROCEDURAIS: enquanto não chega a pixel art, gera texturas
## simples em código. Pra usar o sprite real: no editor, arraste o PNG pra
## `texture` do nó (StarsSprite / Earth / Moon) — o placeholder some sozinho.

@export var earth_sky: Color = Color(0.53, 0.81, 0.92)
@export var deep_space: Color = Color(0.02, 0.02, 0.08)
@export var earth_y: float = 1100.0    # deve casar com o início do player
@export var moon_y: float = -4050.0    # deve casar com moon de game_manager

@onready var sky_rect: ColorRect = $SkyLayer/SkyRect
@onready var stars: Parallax2D = $Stars
@onready var stars_sprite: Sprite2D = $Stars/StarsSprite
@onready var earth: Sprite2D = $Earth
@onready var moon: Sprite2D = $Moon

func _ready() -> void:
	GameEvents.altitude_changed.connect(_on_altitude_changed)

	if stars_sprite.texture == null:
		stars_sprite.texture = _make_star_tile(256)
		stars.repeat_size = Vector2(256, 256)
	if earth.texture == null:
		earth.texture = _make_disc(360, Color(0.2, 0.5, 0.9))
	earth.position = Vector2(360, earth_y)
	if moon.texture == null:
		moon.texture = _make_disc(240, Color(0.82, 0.82, 0.86))
	moon.position = Vector2(360, moon_y)

	_on_altitude_changed(0.0)

func _on_altitude_changed(ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	sky_rect.color = earth_sky.lerp(deep_space, r)
	stars_sprite.modulate.a = r   # estrelas surgem conforme sobe pro espaço

# --- Placeholders procedurais (remover quando a pixel art entrar) ---

func _make_star_tile(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 70:
		var b := randf_range(0.6, 1.0)
		img.set_pixel(randi() % size, randi() % size, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)

func _make_disc(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var radius := diameter / 2.0
	var center := Vector2(radius, radius)
	for y in diameter:
		for x in diameter:
			if Vector2(x, y).distance_to(center) <= radius - 1.0:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
