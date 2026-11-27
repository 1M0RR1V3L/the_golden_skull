extends Area2D
## Osso arremessado pelo esqueleto (faz um arco e gira).

const SHEET := preload("res://img/enemies/3 - Skeleton/Spinning_Bone (16 x 16).png")
const GRAVITY := 700.0
const LIFETIME := 3.0

var velocity := Vector2.ZERO
var _life := LIFETIME


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2          # player + mundo
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	shape.shape = circle
	add_child(shape)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteUtil.frames_from_sheets({"spin": [SHEET, 16, 12.0, true]})
	sprite.scale = Vector2(2, 2)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.play("spin")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage.call_deferred(1, global_position)
		queue_free()
	elif body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
