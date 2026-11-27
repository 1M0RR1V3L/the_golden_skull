class_name EnemyBase
extends CharacterBody2D
## Base dos inimigos: vida, dano, veneno, piscar ao ser atingido,
## moedas ao morrer e dano no player pelo hurtbox.
##
## Cenas que usam: characters/enemies/enemy-skeleton.tscn e enemy_ghost.tscn.
## Nós esperados na cena: texture (Sprite2D antigo, fica escondido), anim
## (AnimationPlayer antigo, fica parado), wall_detector, hitbox e hurtbox.

@export var max_hp := 2
@export var coins_min := 1
@export var coins_max := 2

var hp := 2
var direction := 1.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var sprite: AnimatedSprite2D

@onready var wall_detector := $wall_detector as RayCast2D
@onready var hitbox := $hitbox as Area2D
@onready var hurtbox := $hurtbox as Area2D

var _poison_ticks := 0
var _poison_timer := 0.0
var _flash := 0.0


func _ready() -> void:
	hp = max_hp
	# A animação agora é um AnimatedSprite2D criado por código.
	$texture.visible = false
	$anim.stop()
	sprite = AnimatedSprite2D.new()
	sprite.position = $texture.position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _build_frames()
	add_child(sprite)
	hurtbox.body_entered.connect(_on_hurtbox_touch)
	_grow_hurtbox()


## O corpo do inimigo bloqueia o do player, então um hurtbox do mesmo tamanho
## do corpo nunca chega a encostar. Aumenta ele um pouco para fora.
func _grow_hurtbox() -> void:
	for cs in hurtbox.get_children():
		if cs is CollisionShape2D and cs.shape is RectangleShape2D:
			var r: RectangleShape2D = cs.shape.duplicate()
			r.size += Vector2(12, 4)
			cs.shape = r
		elif cs is CollisionShape2D and cs.shape is CircleShape2D:
			var c: CircleShape2D = cs.shape.duplicate()
			c.radius += 6
			cs.shape = c


## Subclasses devolvem as animações do inimigo.
func _build_frames() -> SpriteFrames:
	return SpriteFrames.new()


## O inimigo machuca o player ao encostar? (falso enquanto é pilha de ossos etc.)
func is_harmful() -> bool:
	return true


func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(1, 0.35, 0.35) if _flash > 0.0 else _base_color()
	_check_contact_damage()
	if _poison_ticks > 0:
		_poison_timer -= delta
		if _poison_timer <= 0.0:
			_poison_ticks -= 1
			_poison_timer = 0.8
			take_damage(1, global_position)
		if _poison_ticks == 0 and _flash <= 0.0:
			sprite.modulate = Color.WHITE


func _base_color() -> Color:
	return Color(0.6, 1.0, 0.5) if _poison_ticks > 0 else Color.WHITE


func take_damage(amount: int, _from: Vector2) -> void:
	if hp <= 0:
		return
	hp -= amount
	_flash = 0.15
	Audio.play("stomp", 0.1)
	if hp <= 0:
		_poison_ticks = 0
		_on_defeated()
	else:
		_on_hurt()


func apply_poison(ticks: int) -> void:
	if hp <= 0:
		return
	_poison_ticks = ticks
	_poison_timer = 0.8
	sprite.modulate = _base_color()


## Pisão do player (chamado pelo hitbox em cima do inimigo).
func stomped(player: Node) -> void:
	take_damage(1, player.global_position)


func _on_hurt() -> void:
	pass


## Morreu de vez: subclasses podem sobrescrever (ex.: esqueleto vira pilha de ossos).
func _on_defeated() -> void:
	die()


func die() -> void:
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	var parent := get_parent()
	SpriteUtil.spawn_poof(parent, global_position + Vector2(sprite.position.x, -16))
	GameState.spawn_coins(parent, global_position + Vector2(sprite.position.x, -16), randi_range(coins_min, coins_max))
	queue_free()


## Enquanto estiver encostado no player, continua machucando
## (a invencibilidade do player limita a frequência).
func _check_contact_damage() -> void:
	if hp <= 0 or not is_harmful() or not hurtbox.monitoring:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage.call_deferred(1, global_position)


func _on_hurtbox_touch(body: Node) -> void:
	if body.is_in_group("player") and is_harmful() and hp > 0:
		# Adiado: se no mesmo frame o player pisou no inimigo, o pisão tem prioridade.
		body.take_damage.call_deferred(1, global_position)


# Compatibilidade com as conexões antigas das cenas.
func _on_hurtbox_body_entered(_body) -> void:
	pass


func _on_anim_animation_finished(_anim_name) -> void:
	pass


func player_node() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D
