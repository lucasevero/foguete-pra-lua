extends Node2D
## DONO: Dev C — camadas de fundo. Área: pickups.
## Céu (gradiente por código) + estrelas (Parallax2D, aparecem no espaço) +
## CIDADE/chão no início (skyline estilo São Paulo) + Lua (bola) no topo.
##
## Escuta GameEvents.altitude_changed (0.0 = chão, 1.0 = Lua).
##
## PLACEHOLDERS PROCEDURAIS: enquanto não chega a pixel art, gera texturas
## simples em código. Pra usar o sprite real: no editor, arraste o PNG pra
## `texture` do nó (StarsSprite / City / Moon) — o placeholder some sozinho.

@export var earth_sky: Color = Color(0.53, 0.81, 0.92)
@export var deep_space: Color = Color(0.02, 0.02, 0.08)
@export var ground_y: float = 1120.0   # chão/cidade no início (casar com player start ~950)
@export var moon_y: float = -4050.0    # deve casar com moon de game_manager

@onready var sky_rect: ColorRect = $SkyLayer/SkyRect
@onready var stars: Parallax2D = $Stars
@onready var stars_sprite: Sprite2D = $Stars/StarsSprite
@onready var city: Sprite2D = $City
@onready var moon: Sprite2D = $Moon

func _ready() -> void:
	GameEvents.altitude_changed.connect(_on_altitude_changed)

	if stars_sprite.texture == null:
		stars_sprite.texture = _make_star_tile(256)
		stars.repeat_size = Vector2(256, 256)
	if city.texture == null:
		city.texture = _make_city(720, 340)
	city.position = Vector2(360, ground_y)
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

func _make_city(w: int, h: int) -> ImageTexture:
	# Skyline placeholder: prédios silhueta com janelas acesas (troca por pixel art).
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x := 0
	while x < w:
		var bw := randi_range(28, 64)
		var bh := randi_range(90, h - 20)
		var col := Color(0.10, 0.10, 0.15).lerp(Color(0.20, 0.20, 0.27), randf())
		var right := mini(x + bw, w)
		for by in range(h - bh, h):
			for bx in range(x, right):
				img.set_pixel(bx, by, col)
		# janelas acesas
		var yy := h - bh + 8
		while yy < h - 6:
			var xx := x + 5
			while xx < right - 4:
				if randf() < 0.45:
					img.set_pixel(xx, yy, Color(1.0, 0.9, 0.5, 1.0))
				xx += 6
			yy += 9
		x += bw + randi_range(2, 8)
	return ImageTexture.create_from_image(img)
