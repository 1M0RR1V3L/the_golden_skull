extends Area2D
## Flecha disparada pelo player.
##   basic : 1 de dano
##   heavy : 2 de dano e atravessa inimigos
##   poison: 1 de dano + veneno (1 de dano a cada 0,8 s, 3 vezes)
##   quick : 1 de dano, mais rápida (a cadência maior fica no player)

const TEXTURES := {
	"basic": preload("res://img/player/Arrows/PNGs/Basic Arrow.png"),
	"heavy": preload("res://img/player/Arrows/PNGs/Heavy Arrow.png"),
	"poison": preload("res://img/player/Arrows/PNGs/Poison Arrow.png"),
	"quick": preload("res://img/player/Arrows/PNGs/Quick Arrow.png"),
}
const STATS := {
	"basic": {"speed": 650.0, "damage": 1, "pierce": false, "poison": 0},
	"heavy": {"speed": 520.0, "damage": 2, "pierce": true, "poison": 0},
	"poison": {"speed": 620.0, "damage": 1, "pierce": false, "poison": 3},
	"quick": {"speed": 850.0, "damage": 1, "pierce": false, "poison": 0},
}
const LIFETIME := 1.4

var kind := "basic"
var direction := 1.0
var _life := LIFETIME
var _hit := {}


static func create(arrow_kind: String, dir: float) -> Area2D:
	var a: Area2D = (load("res://scripts/arrow.gd") as GDScript).new()
	a.kind = arrow_kind
	a.direction = dir
	return a


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4          # mundo + inimigos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 6)
	shape.shape = rect
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURES[kind]
	sprite.scale = Vector2(2, 2) * direction
	sprite.scale.y = 2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += STATS[kind].speed * direction * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		if _hit.has(body):
			return
		_hit[body] = true
		body.take_damage(STATS[kind].damage, global_position)
		if STATS[kind].poison > 0 and body.has_method("apply_poison"):
			body.apply_poison(STATS[kind].poison)
		if not STATS[kind].pierce:
			queue_free()
	elif body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
