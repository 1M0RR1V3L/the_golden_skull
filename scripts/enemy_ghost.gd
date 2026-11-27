extends EnemyBase
## Fantasma: flutua em onda patrulhando; quando o player chega perto,
## voa atrás dele devagar. Não sofre gravidade.

const SHEETS := "res://img/enemies/ghost/"
const PATROL_SPEED := 35.0
const CHASE_SPEED := 75.0
const CHASE_RANGE := 320.0
const GIVE_UP_RANGE := 520.0
const BOB_HEIGHT := 10.0

var _chasing := false
var _base_y := 0.0
var _t := 0.0
var _hurt := 0.0


func _init() -> void:
	max_hp = 2
	coins_min = 1
	coins_max = 2


func _ready() -> void:
	super._ready()
	_base_y = global_position.y
	_t = randf() * TAU
	sprite.play("float")


func _build_frames() -> SpriteFrames:
	return SpriteUtil.frames_from_sheets({
		"float": [load(SHEETS + "10 - Blankey_Floating (32 x 32).png"), 32, 8.0, true],
		"hurt": [load(SHEETS + "10 - Blankey_Hurt (32 x 32).png"), 32, 1.0, false],
	})


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_t += delta
	if _hurt > 0.0:
		_hurt -= delta
		if _hurt <= 0.0:
			sprite.play("float")

	var player := player_node()
	var dist := INF if player == null else global_position.distance_to(player.global_position)
	if not _chasing and dist < CHASE_RANGE:
		_chasing = true
	elif _chasing and dist > GIVE_UP_RANGE:
		_chasing = false
		_base_y = global_position.y

	if _chasing and player:
		var target := player.global_position + Vector2(0, -20)
		velocity = (target - global_position).normalized() * CHASE_SPEED
		direction = signf(velocity.x) if absf(velocity.x) > 1.0 else direction
	else:
		wall_detector.scale.x = direction
		if wall_detector.is_colliding():
			direction *= -1
		var bob_target := _base_y + sin(_t * 2.0) * BOB_HEIGHT
		velocity = Vector2(direction * PATROL_SPEED, (bob_target - global_position.y) * 4.0)

	if _hurt > 0.0:
		velocity *= 0.3
	sprite.flip_h = direction < 0
	move_and_slide()


func _on_hurt() -> void:
	_hurt = 0.3
	sprite.play("hurt")
