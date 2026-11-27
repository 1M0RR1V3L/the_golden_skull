extends Area2D
## Item coletável: kit médico (cura 1 coração) ou pacote de flechas especiais.
## Flutua levemente. Pode ser colocado acima do chão: se encaixa nele.

@export_enum("health", "heavy", "poison", "quick") var kind := "health"
## Quantidade de flechas (ignorado para "health").
@export var amount := 5

const TEXTURES := {
	"health": preload("res://img/items_ui/Common Pick-ups/Health_Kit (16 x 16).png"),
	"heavy": preload("res://img/player/Arrows/PNGs/Heavy Arrow.png"),
	"poison": preload("res://img/player/Arrows/PNGs/Poison Arrow.png"),
	"quick": preload("res://img/player/Arrows/PNGs/Quick Arrow.png"),
}

var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURES[kind]
	_sprite.scale = Vector2(3, 3) if kind == "health" else Vector2(2.5, 2.5)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	_snap_to_floor()


func _snap_to_floor() -> void:
	# Espera a física do TileMap ficar pronta antes de procurar o chão.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var p = SpriteUtil.find_floor(self, global_position + Vector2(0, -20), 800)
	if p != null:
		global_position = p + Vector2(0, -36)


func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 3.0) * 5.0


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if kind == "health":
		if not GameState.heal(1):
			return  # vida cheia: deixa o kit para depois
		Audio.play("heal")
	else:
		GameState.add_ammo(kind, amount)
		Audio.play("coin", 0.1)
	set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
