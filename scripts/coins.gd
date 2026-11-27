extends Area2D
## Moeda. Pode estar parada na fase ou ser "derrubada" (dropped = true) por
## inimigos e baús: nesse caso pula, cai até o chão e é atraída pelo player
## quando ele chega perto.

const GRAVITY := 900.0
const MAGNET_RANGE := 110.0
const MAGNET_SPEED := 520.0
## Moedas derrubadas só podem ser pegas depois deste tempo (para dar tempo de "pular").
const PICKUP_DELAY := 0.35

var dropped := false
var velocity := Vector2.ZERO
var _collected := false
var _age := 0.0
var _resting := false


func _ready() -> void:
	if dropped:
		monitoring = false


func _physics_process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if dropped and _age > PICKUP_DELAY and not monitoring:
		monitoring = true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and (not dropped or _age > PICKUP_DELAY):
		var to_player := player.global_position - global_position
		if to_player.length() < MAGNET_RANGE:
			global_position += to_player.normalized() * MAGNET_SPEED * delta
			return
	if dropped and not _resting:
		velocity.y += GRAVITY * delta
		var step := velocity * delta
		var hit = SpriteUtil.find_floor(self, global_position, maxf(step.y, 0.0) + 10.0) if velocity.y > 0 else null
		if hit != null:
			global_position.y = hit.y - 10.0
			if velocity.y > 120.0:
				velocity = Vector2(velocity.x * 0.5, -velocity.y * 0.35)  # quica
			else:
				_resting = true
		else:
			global_position += step


func _on_body_entered(body):
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	GameState.add_coins(1)
	Audio.play("coin", 0.05)
	$anim.play("collect")


func _on_anim_animation_finished():
	if _collected:
		queue_free()
