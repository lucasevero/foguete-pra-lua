extends Area2D
## DONO: Dev C — moeda coletável. Ao encostar no player emite coin_collected.

@export var amount: int = 1
@export var fall_speed: float = 100.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	var screen_y := get_global_transform_with_canvas().origin.y
	if screen_y > get_viewport().get_visible_rect().size.y + 100.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.coin_collected.emit(amount)
		queue_free()
