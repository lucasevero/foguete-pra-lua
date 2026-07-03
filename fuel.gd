extends Area2D
## DONO: Dev C — pickup de combustível. Ao encostar no player, emite fuel_collected.

@export var amount: float = 25.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.y += 100.0 * delta  # TODO(Dev C): ajustar/parametrizar
	if position.y > 800.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.fuel_collected.emit(amount)
		queue_free()
