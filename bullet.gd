extends Area2D
## DONO: Dev A — projétil da arma (powerup). Sobe e destrói asteroides.

@export var speed: float = 900.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	if get_global_transform_with_canvas().origin.y < -50.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroid"):
		area.queue_free()
		queue_free()
