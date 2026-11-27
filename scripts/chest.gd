extends Area2D
## Baú do fim da fase: abre ao encostar e solta uma chuva de moedas.
## Pode ser colocado acima do chão: se encaixa nele.

@export var coins := 10

const SHEET := preload("res://img/items_ui/Common Pick-ups/Treasure_Chest (32 x 16).png")

var _sprite: AnimatedSprite2D
var _opened := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 60)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.frames_from_sheets({"open": [SHEET, 32, 10.0, false]})
	_sprite.scale = Vector2(3, 3)
	_sprite.position = Vector2(0, -24)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_sprite.animation = "open"
	_sprite.frame = 0
	body_entered.connect(_on_body_entered)
	_snap_to_floor()


func _snap_to_floor() -> void:
	# Espera a física do TileMap ficar pronta antes de procurar o chão.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var p = SpriteUtil.find_floor(self, global_position + Vector2(0, -20), 800)
	if p != null:
		global_position = p


func _on_body_entered(body: Node) -> void:
	if _opened or not body.is_in_group("player"):
		return
	_opened = true
	Audio.play("chest")
	_sprite.play("open")
	GameState.spawn_coins(get_parent(), global_position + Vector2(0, -40), coins)
