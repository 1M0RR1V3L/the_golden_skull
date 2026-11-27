extends Area2D
## Checkpoint (lanterna): ao passar, vira o ponto de retorno quando o player
## cai num buraco. Apagada = ainda não ativada; acesa = ativa.
## Pode ser colocado em qualquer altura acima do chão: ele se encaixa no chão.

const TEXTURE := preload("res://img/cemetery/PNG/Collectable Object/Light.png")

var _sprite: Sprite2D
var _active := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 120)
	shape.shape = rect
	shape.position = Vector2(0, -60)
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2(0.45, 0.45)
	_sprite.position = Vector2(0, -29)
	_sprite.modulate = Color(0.35, 0.35, 0.45)
	add_child(_sprite)
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
	if _active or not body.is_in_group("player"):
		return
	_active = true
	GameState.set_checkpoint(global_position + Vector2(0, -50))
	Audio.play("checkpoint")
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(1.6, 1.4, 0.8), 0.15)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.4)
