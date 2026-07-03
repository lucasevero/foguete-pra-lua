extends Area2D
## DONO: Dev B — obstáculo. Ao encostar no player, emite GameEvents.asteroid_hit.

@export var fall_speed: float = 150.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# TODO(Dev B): padrão de movimento (deriva lateral, rotação, tamanhos variados)
	position.y += fall_speed * delta
	# despawn ao sair por baixo da tela (posição na tela, não y do mundo)
	var screen_y := get_global_transform_with_canvas().origin.y
	if screen_y > get_viewport().get_visible_rect().size.y + 100.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.asteroid_hit.emit()
		queue_free()
