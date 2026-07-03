extends Area2D
## DONO: Dev B — obstáculo voador (pombo/zepelim) da baixa altitude.
## Move por uma `velocity` setada no spawn. Ao encostar no player, emite
## asteroid_hit (mesmo canal de "bati num obstáculo"). Grupo "asteroid" p/ a
## arma também destruir. Sprite real entra depois (placeholder ColorRect).

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# vira o sprite pro lado do movimento (velocity setada no spawn, antes do add_child)
	var spr := get_node_or_null("Sprite")
	if spr != null and "flip_h" in spr:
		spr.flip_h = velocity.x > 0.0   # sprites apontam p/ esquerda nativamente; flip ao ir p/ direita

func _physics_process(delta: float) -> void:
	position += velocity * delta
	# despawn quando bem fora da tela (margem > offset de spawn)
	var p := get_global_transform_with_canvas().origin
	var sz := get_viewport().get_visible_rect().size
	if p.x < -250.0 or p.x > sz.x + 250.0 or p.y < -250.0 or p.y > sz.y + 250.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.asteroid_hit.emit()
		queue_free()
