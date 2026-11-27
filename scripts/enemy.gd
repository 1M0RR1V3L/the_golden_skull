extends EnemyBase
## Esqueleto.
##
## DORMANT : pilha de ossos parada; levanta quando o player chega perto
## WALK    : anda mancando, vira em paredes e beiradas
## TOSS    : para e arremessa um osso quando o player está ao alcance
## CRUMBLE : ao zerar a vida desmonta numa pilha de ossos...
## PILE    : ...que remonta sozinha em REVIVE_TIME segundos,
##           a menos que o player acerte a pilha (aí some de vez e solta moedas)
##
## Variante "saltador" (jumper = true, tom avermelhado): em vez de arremessar ossos,
## se agacha (PREP), salta na direção do player (JUMP) e aterrissa (LAND).

const SHEETS := "res://img/enemies/3 - Skeleton/"
const SPEED := 40.0
const WAKE_RANGE := 260.0
const TOSS_RANGE := 420.0
const TOSS_COOLDOWN := 2.5
const REVIVE_TIME := 4.0
const JUMP_RANGE := 320.0
const JUMP_COOLDOWN := 2.2
const JUMP_VELOCITY := Vector2(230, -430)

enum State { DORMANT, WAKING, WALK, TOSS, HURT, CRUMBLE, PILE, PREP, JUMP, LAND }

@export var start_dormant := true
## Esqueleto saltador: pula em cima do player em vez de arremessar ossos.
@export var jumper := false

var state := State.WALK
var _toss_cooldown := 1.0
var _revive := 0.0
var _floor_ray: RayCast2D


func _init() -> void:
	max_hp = 2
	coins_min = 2
	coins_max = 3


func _ready() -> void:
	super._ready()
	sprite.animation_finished.connect(_on_sprite_finished)
	_floor_ray = RayCast2D.new()
	_floor_ray.collision_mask = 2
	_floor_ray.target_position = Vector2(0, 28)
	add_child(_floor_ray)
	if jumper:
		sprite.self_modulate = Color(1.0, 0.72, 0.62)
	if start_dormant:
		_set_state(State.DORMANT)
	else:
		_set_state(State.WALK)


func _build_frames() -> SpriteFrames:
	return SpriteUtil.frames_from_sheets({
		"pile": [load(SHEETS + "Bone_Pile (32 x 32).png"), 32, 1.0, false],
		"wakeup": [load(SHEETS + "Bone_Pile_Wakeup (32 x 32).png"), 32, 10.0, false],
		"walk": [load(SHEETS + "Limping_Movement (32 x 32).png"), 32, 8.0, true],
		"toss": [load(SHEETS + "Bone_Toss (32 x 32).png"), 32, 10.0, false],
		"hurt": [load(SHEETS + "Hurt (32 x 32).png"), 32, 10.0, false],
		"crumble": [load(SHEETS + "Crumbling_Into_Bone_Pile (32 x 32).png"), 32, 12.0, false],
		"prep": [load(SHEETS + "Preparing_Jump (32 x 32).png"), 32, 10.0, false],
		"jump": [load(SHEETS + "Jumping (32 x 32).png"), 32, 1.0, false],
		"land": [load(SHEETS + "Landed (32 x 32).png"), 32, 10.0, false],
	})


func is_harmful() -> bool:
	return state in [State.WALK, State.TOSS, State.HURT, State.PREP, State.JUMP, State.LAND]


func _set_state(s: State) -> void:
	state = s
	match s:
		State.DORMANT, State.PILE:
			sprite.play("pile")
		State.WAKING:
			sprite.play("wakeup")
			Audio.play("land", 0.2)
		State.WALK:
			sprite.play("walk")
		State.TOSS:
			sprite.play("toss")
		State.HURT:
			sprite.play("hurt")
		State.CRUMBLE:
			sprite.play("crumble")
		State.PREP:
			sprite.play("prep")
		State.JUMP:
			sprite.play("jump")
			velocity = Vector2(direction * JUMP_VELOCITY.x, JUMP_VELOCITY.y)
			Audio.play("jump", 0.2)
		State.LAND:
			sprite.play("land")
			Audio.play("land", 0.2)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if state != State.JUMP:
		velocity.x = 0.0
	_toss_cooldown = maxf(_toss_cooldown - delta, 0.0)
	var player := player_node()

	match state:
		State.DORMANT:
			if player and global_position.distance_to(player.global_position) < WAKE_RANGE:
				_set_state(State.WAKING)
		State.WALK:
			_patrol()
			if player and jumper and _can_jump(player):
				direction = signf(player.global_position.x - global_position.x)
				_set_state(State.PREP)
			elif player and not jumper and _can_toss(player):
				direction = signf(player.global_position.x - global_position.x)
				_set_state(State.TOSS)
		State.JUMP:
			if is_on_floor() and velocity.y >= 0.0:
				_toss_cooldown = JUMP_COOLDOWN
				_set_state(State.LAND)
		State.PILE:
			_revive -= delta
			sprite.visible = _revive > 1.0 or int(_revive * 10) % 2 == 0  # pisca antes de levantar
			if _revive <= 0.0:
				sprite.visible = true
				hp = max_hp
				_set_state(State.WAKING)

	sprite.flip_h = direction < 0
	move_and_slide()


func _patrol() -> void:
	_floor_ray.position = Vector2(sprite.position.x + direction * 14, -4)
	wall_detector.scale.x = direction
	if (wall_detector.is_colliding() or (is_on_floor() and not _floor_ray.is_colliding())):
		direction *= -1
	velocity.x = direction * SPEED


func _can_toss(player: Node2D) -> bool:
	var d := player.global_position - global_position
	return _toss_cooldown <= 0.0 and absf(d.x) < TOSS_RANGE and absf(d.x) > 60 and absf(d.y) < 150


func _can_jump(player: Node2D) -> bool:
	var d := player.global_position - global_position
	return _toss_cooldown <= 0.0 and is_on_floor() and absf(d.x) < JUMP_RANGE and absf(d.x) > 40 and absf(d.y) < 180


func _throw_bone() -> void:
	var player := player_node()
	var bone: Area2D = preload("res://scripts/bone.gd").new()
	var start := global_position + Vector2(sprite.position.x + direction * 10, -28)
	var dx := (player.global_position.x - start.x) if player else direction * 250.0
	bone.velocity = Vector2(clampf(dx / 0.9, -420, 420), -330)
	get_parent().add_child(bone)
	bone.global_position = start
	_toss_cooldown = TOSS_COOLDOWN


func _on_sprite_finished() -> void:
	match state:
		State.WAKING, State.HURT, State.LAND:
			_set_state(State.WALK)
		State.PREP:
			_set_state(State.JUMP)
		State.TOSS:
			_throw_bone()
			_set_state(State.WALK)
		State.CRUMBLE:
			_revive = REVIVE_TIME
			_set_state(State.PILE)


func take_damage(amount: int, from: Vector2) -> void:
	match state:
		State.PILE, State.CRUMBLE:
			Audio.play("stomp", 0.1)
			die()   # destruiu a pilha: some de vez e solta moedas
			return
		State.DORMANT:
			_set_state(State.WAKING)
	super.take_damage(amount, from)


func _on_hurt() -> void:
	if state in [State.WALK, State.TOSS, State.PREP, State.LAND]:
		_set_state(State.HURT)


func _on_defeated() -> void:
	_set_state(State.CRUMBLE)
